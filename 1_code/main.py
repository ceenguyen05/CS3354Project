import os
import numpy as np
from fastapi import FastAPI, Depends, HTTPException # Keep Depends for potential future use, but not for DB session
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sklearn.neighbors import NearestNeighbors
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from geopy.geocoders import Nominatim
from geopy.exc import GeocoderTimedOut, GeocoderServiceError

# --- Firebase Admin SDK Setup ---
import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase Admin SDK
# Expects the service account key file path via environment variable
# Set by docker-compose.yml or manually for local execution
try:
    cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "serviceAccountKey.json") # Default for local
    if not os.path.exists(cred_path):
         raise FileNotFoundError(f"Service account key file not found at: {cred_path}. Set GOOGLE_APPLICATION_CREDENTIALS.")

    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)
    print("Firebase Admin SDK initialized successfully.")
except FileNotFoundError as fnf_error:
     print(f"Error: {fnf_error}")
     # Exit or raise depending on desired behavior if key is missing
     exit(1) # Exit if key is essential for startup
except ValueError as val_error:
     # Catch potential errors during initialization (e.g., invalid key file)
     print(f"Error initializing Firebase Admin SDK: {val_error}")
     exit(1)
except Exception as e:
    # Catch any other unexpected errors during initialization
    print(f"An unexpected error occurred during Firebase initialization: {e}")
    exit(1)


# Get Firestore client
try:
    db = firestore.client()
    print("Firestore client obtained successfully.")
except Exception as e:
    print(f"Error obtaining Firestore client: {e}")
    exit(1)

# --- FastAPI Application Setup ---

app = FastAPI(title="Crowdsourced Disaster Relief API (Firebase)")

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Adjust for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Geocoding Setup ---
geolocator = Nominatim(user_agent="disaster_relief_app_firebase_v1")

def get_coordinates(location_str):
    """Geocodes a location string to (latitude, longitude)."""
    if not location_str: # Handle empty location string
        print("Warning: Empty location string provided. Returning (0, 0).")
        return 0.0, 0.0
    try:
        location = geolocator.geocode(location_str, timeout=10) # Added timeout
        if location:
            return location.latitude, location.longitude
        else:
            print(f"Warning: Could not geocode location '{location_str}'. Returning (0, 0).")
            return 0.0, 0.0
    except (GeocoderTimedOut, GeocoderServiceError) as e:
        print(f"Warning: Geocoding error for '{location_str}': {e}. Returning (0, 0).")
        return 0.0, 0.0
    except Exception as e:
        print(f"Warning: Unexpected error during geocoding for '{location_str}': {e}. Returning (0, 0).")
        return 0.0, 0.0

# --- AI Matching Configuration ---
KNOWN_SKILLS = ['Medical', 'Food Logistics', 'Rescue', 'Shelter Management', 'Transportation', 'Communication', 'General Labor'] # Example list
encoder = OneHotEncoder(categories=[KNOWN_SKILLS], sparse_output=False, handle_unknown='ignore')
encoder.fit(np.array(KNOWN_SKILLS).reshape(-1, 1))
scaler = StandardScaler()

# --- Firestore Collection References ---
volunteers_ref = db.collection('volunteers')
requests_ref = db.collection('requests')

# --- API Endpoints ---

@app.get("/")
def read_root():
    """Root endpoint."""
    return {"message": "Welcome to the Crowdsourced Disaster Relief API (Firebase)"}

@app.get("/match/{request_id}")
def match_volunteers_firebase(request_id: str): # Request ID is likely a string in Firestore
    """
    Matches volunteers to a specific aid request using KNN (data from Firestore).
    """
    # 1. Retrieve the request from Firestore
    try:
        request_doc = requests_ref.document(request_id).get()
        if not request_doc.exists:
            raise HTTPException(status_code=404, detail="Request not found")
        req_data = request_doc.to_dict()
        req_data['id'] = request_doc.id # Add document ID to the data dict
    except Exception as e:
        print(f"Error fetching request {request_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Error fetching request data: {e}")

    # 2. Retrieve all volunteers from Firestore
    # WARNING: Fetching all documents can be inefficient/costly at scale!
    try:
        all_volunteers_stream = volunteers_ref.stream()
        all_volunteers_data = []
        for doc in all_volunteers_stream:
            v_data = doc.to_dict()
            v_data['id'] = doc.id # Add document ID
            all_volunteers_data.append(v_data)

        if not all_volunteers_data:
            return {"matched_volunteers": []}
    except Exception as e:
        print(f"Error fetching volunteers: {e}")
        raise HTTPException(status_code=500, detail=f"Error fetching volunteer data: {e}")

    # 3. Feature Engineering (using data from Firestore dictionaries)
    volunteer_features = []
    request_feature_list = []
    valid_volunteers = [] # Keep track of volunteers for whom features could be generated

    # Geocode request location
    req_lat, req_lon = get_coordinates(req_data.get('location', '')) # Use .get for safety
    if req_lat == 0.0 and req_lon == 0.0:
         print(f"Warning: Failed to geocode request location '{req_data.get('location', '')}'. Matching may be inaccurate.")

    # Encode request type (skill)
    req_type = req_data.get('type', '')
    req_skill_encoded = encoder.transform(np.array([[req_type]]))

    # Combine request features
    request_feature_list = [req_lat, req_lon] + list(req_skill_encoded[0])

    # Process volunteers
    for v_data in all_volunteers_data:
        # Geocode volunteer location
        v_location = v_data.get('location', '')
        v_lat, v_lon = get_coordinates(v_location)
        if v_lat == 0.0 and v_lon == 0.0:
            print(f"Warning: Skipping volunteer {v_data.get('id')} ('{v_data.get('name')}') due to geocoding failure for location '{v_location}'.")
            continue

        # Encode volunteer skills
        v_skills = v_data.get('skills', '')
        v_skill_encoded = encoder.transform(np.array([[v_skills]]))

        # Combine features
        features = [v_lat, v_lon] + list(v_skill_encoded[0])
        volunteer_features.append(features)
        valid_volunteers.append(v_data) # Add original volunteer dict

    # Check if any valid volunteers remain
    if not valid_volunteers:
        return {"matched_volunteers": []}

    # Convert features to NumPy arrays
    X_volunteers = np.array(volunteer_features)
    X_request = np.array([request_feature_list])

    # 4. Feature Scaling
    try:
        X_volunteers_scaled = scaler.fit_transform(X_volunteers)
        X_request_scaled = scaler.transform(X_request)
    except ValueError as e:
         print(f"Error during feature scaling: {e}. Returning empty list.")
         # Consider more robust error handling or fallback
         return {"matched_volunteers": []}

    # 5. K-Nearest Neighbors Matching
    n_neighbors_to_find = min(3, len(valid_volunteers))
    if n_neighbors_to_find == 0:
         return {"matched_volunteers": []}

    knn = NearestNeighbors(n_neighbors=n_neighbors_to_find, metric='euclidean')
    knn.fit(X_volunteers_scaled)
    distances, indices = knn.kneighbors(X_request_scaled)

    # 6. Prepare Response
    matched_volunteers_info = []
    for i in indices[0]:
        matched_v_data = valid_volunteers[i]
        # Return only necessary fields, including the Firestore document ID
        matched_volunteers_info.append({
            "id": matched_v_data.get('id'), # Firestore document ID
            "name": matched_v_data.get('name'),
            "skills": matched_v_data.get('skills'),
            "location": matched_v_data.get('location')
        })

    return {"matched_volunteers": matched_volunteers_info}


# --- Optional: Endpoints for adding data (replace populate_database.py logic) ---

# Example: Add a volunteer (Not fully replacing populate_database.py)
@app.post("/volunteers/")
async def add_volunteer(volunteer_data: dict): # Use dict for flexibility or Pydantic model
    try:
        # Add a new document with an auto-generated ID
        update_time, doc_ref = volunteers_ref.add(volunteer_data)
        print(f"Added volunteer with ID: {doc_ref.id} at {update_time}")
        return {"id": doc_ref.id, "status": "success"}
    except Exception as e:
        print(f"Error adding volunteer: {e}")
        raise HTTPException(status_code=500, detail=f"Error adding volunteer: {e}")

# Example: Add a request (Not fully replacing populate_database.py)
@app.post("/requests/")
async def add_request(request_data: dict):
    try:
        # If you want to use a specific ID (like 101, 102), use .document(id).set()
        # request_id = str(request_data.get('id')) # Assuming ID is in the dict
        # if not request_id:
        #     raise ValueError("Request data must include an 'id' field")
        # doc_ref = requests_ref.document(request_id)
        # update_time = doc_ref.set(request_data)

        # Or add with auto-generated ID:
        update_time, doc_ref = requests_ref.add(request_data)

        print(f"Added request with ID: {doc_ref.id} at {update_time}")
        return {"id": doc_ref.id, "status": "success"}
    except Exception as e:
        print(f"Error adding request: {e}")
        raise HTTPException(status_code=500, detail=f"Error adding request: {e}")

# Example: List volunteers (for debugging)
@app.get("/volunteers/")
def list_volunteers_firebase():
    try:
        volunteers = []
        docs = volunteers_ref.stream()
        for doc in docs:
            v_data = doc.to_dict()
            v_data['id'] = doc.id
            volunteers.append(v_data)
        return volunteers
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error listing volunteers: {e}")

# Example: List requests (for debugging)
@app.get("/requests/")
def list_requests_firebase():
    try:
        requests_list = []
        docs = requests_ref.stream()
        for doc in docs:
            r_data = doc.to_dict()
            r_data['id'] = doc.id
            requests_list.append(r_data)
        return requests_list
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error listing requests: {e}")


# Note: populate_database.py needs to be rewritten separately using firebase-admin
# Note: test_matching.py might need slight adjustments if request IDs change format (int vs string)

