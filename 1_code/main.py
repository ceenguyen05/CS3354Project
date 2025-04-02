import os
from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.orm import sessionmaker, Session, declarative_base
import numpy as np
from sklearn.neighbors import NearestNeighbors
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from geopy.geocoders import Nominatim
from geopy.exc import GeocoderTimedOut, GeocoderServiceError
from fastapi.responses import JSONResponse

# --- database setup ---

# get database url from environment variable or use default
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:password@localhost/disaster_relief")
try:
    engine = create_engine(DATABASE_URL)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
except Exception as e:
    print(f"Error connecting to database: {e}")
    # handle connection error appropriately, maybe exit or raise
    raise

# base class for sqlalchemy models
Base = declarative_base()

# --- database models ---

class Volunteer(Base):
    """sqlalchemy model for volunteers."""
    __tablename__ = "volunteers"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    skills = Column(String) # assumes skills are stored as a single string, e.g., "medical, triage"
    location = Column(String) # e.g., "houston, tx"

class Request(Base):
    """sqlalchemy model for aid requests."""
    __tablename__ = "requests"
    id = Column(Integer, primary_key=True, index=True)
    type = Column(String, index=True) # corresponds to volunteer skills
    location = Column(String) # e.g., "dallas, tx"

# create database tables if they don't exist
# in production, consider using alembic for migrations
try:
    Base.metadata.create_all(bind=engine)
except Exception as e:
    print(f"Error creating database tables: {e}")
    # handle table creation error

# --- fastapi application setup ---

app = FastAPI(title="Crowdsourced Disaster Relief API")

# enable cors (cross-origin resource sharing)
# security note: for production, restrict allow_origins to your specific frontend url
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # allows all origins for development
    allow_credentials=True,
    allow_methods=["*"], # allows all methods (get, post, etc.)
    allow_headers=["*"], # allows all headers
)

# --- geocoding setup ---
# initialize geolocator (using openstreetmap nominatim)
# requires internet connection
geolocator = Nominatim(user_agent="disaster_relief_app_v1") # replace with your app's name/version

def get_coordinates(location_str):
    # this function attempts to convert a location string into latitude and longitude
    try:
        location = geolocator.geocode(location_str)  # this line sends a geocoding request using geolocator
        if location:
            return location.latitude, location.longitude  # returns the lat/lon if geocode succeeds
        else:
            print(f"Warning: Could not geocode location '{location_str}'. Returning (0, 0).")
            return 0.0, 0.0  # returns default coordinates if none found
    except (GeocoderTimedOut, GeocoderServiceError) as e:
        # this block handles geocoding timeouts or service errors
        print(f"Warning: Geocoding error for '{location_str}': {e}. Returning (0, 0).")
        return 0.0, 0.0
    except Exception as e:
        # this block catches any other unexpected errors
        print(f"Warning: Unexpected error during geocoding for '{location_str}': {e}. Returning (0, 0).")
        return 0.0, 0.0


# --- dependency injection for database session ---

def get_db():
    """dependency to get a database session per request."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- ai matching configuration ---

# define the known skill categories for one-hot encoding
# important: this list should contain all possible skills your system recognizes.
# it should be consistent with the skills stored in the database and request types.
KNOWN_SKILLS = ['Medical', 'Food Logistics', 'Rescue', 'Shelter Management', 'Transportation', 'Communication', 'General Labor'] # example list - expand as needed

# initialize the onehotencoder
# handle_unknown='ignore' will create all-zero vectors for skills not in known_skills
encoder = OneHotEncoder(categories=[KNOWN_SKILLS], sparse_output=False, handle_unknown='ignore')
# fit the encoder (needs to be done once, ideally at startup, but fitting here is simpler for this example)
# note: fitting requires a list of lists/2d array structure
encoder.fit(np.array(KNOWN_SKILLS).reshape(-1, 1))

# initialize the standardscaler for feature scaling
scaler = StandardScaler()

# --- api endpoints ---

@app.get("/")
def read_root():
    """root endpoint providing basic api info."""
    return {"message": "Welcome to the Crowdsourced Disaster Relief API"}


@app.get("/match/{request_id}")
def match_volunteers(request_id: int, db: Session = Depends(get_db)):
    """
    matches volunteers to a specific aid request using knn based on skills and location.
    """
    # 1. retrieve the request from the database
    req = db.query(Request).filter(Request.id == request_id).first()
    if not req:
        # use httpexception for standard fastapi error handling
        raise HTTPException(status_code=404, detail="Request not found")

    # 2. retrieve all volunteers from the database
    volunteers = db.query(Volunteer).all()
    if not volunteers:
        # if no volunteers exist at all
        return {"matched_volunteers": []} # return empty list, not an error

    # 3. feature engineering
    volunteer_features = []
    request_feature_list = []
    valid_volunteers = [] # keep track of volunteers for whom features could be generated

    # geocode request location
    req_lat, req_lon = get_coordinates(req.location)
    if req_lat == 0.0 and req_lon == 0.0:
         print(f"Warning: Failed to geocode request location '{req.location}'. Matching may be inaccurate.")
         # decide handling: raise error, or proceed with (0,0)? proceeding for now.

    # encode request type (skill)
    # reshape needed for single sample
    req_skill_encoded = encoder.transform(np.array([[req.type]]))

    # combine request features: [lat, lon] + [encoded_skill_vector]
    request_feature_list = [req_lat, req_lon] + list(req_skill_encoded[0])


    # process volunteers
    for v in volunteers:
        # geocode volunteer location
        v_lat, v_lon = get_coordinates(v.location)
        if v_lat == 0.0 and v_lon == 0.0:
            print(f"Warning: Skipping volunteer {v.id} ('{v.name}') due to geocoding failure for location '{v.location}'.")
            continue # skip volunteer if geocoding fails

        # encode volunteer skills (assuming single skill string for simplicity)
        # if multiple skills (e.g., "medical, rescue"), split and handle appropriately
        # for simplicity here, we assume v.skills matches one of the known_skills
        v_skill_encoded = encoder.transform(np.array([[v.skills]]))

        # combine features: [lat, lon] + [encoded_skill_vector]
        features = [v_lat, v_lon] + list(v_skill_encoded[0])
        volunteer_features.append(features)
        valid_volunteers.append(v) # add volunteer to the list used for matching

    # check if any valid volunteers remain after geocoding/encoding
    if not valid_volunteers:
        return {"matched_volunteers": []}

    # convert features to numpy arrays
    X_volunteers = np.array(volunteer_features)
    X_request = np.array([request_feature_list]) # reshape for single request

    # 4. feature scaling
    # fit the scaler on volunteer data and transform both volunteer and request data
    try:
        X_volunteers_scaled = scaler.fit_transform(X_volunteers)
        X_request_scaled = scaler.transform(X_request) # use the same scaler fitted on volunteers
    except ValueError as e:
         # handle potential errors during scaling (e.g., if only one volunteer remains)
         print(f"Error during feature scaling: {e}. Returning raw volunteers.")
         # fallback: maybe return closest by raw distance or just return empty/error
         raise HTTPException(status_code=500, detail=f"Feature scaling error: {e}")


    # 5. k-nearest neighbors matching
    # determine number of neighbors (up to 3, or fewer if fewer valid volunteers)
    n_neighbors_to_find = min(3, len(valid_volunteers))

    if n_neighbors_to_find == 0: # should be caught earlier, but double-check
         return {"matched_volunteers": []}

    knn = NearestNeighbors(n_neighbors=n_neighbors_to_find, metric='euclidean')
    knn.fit(X_volunteers_scaled)

    # find the nearest neighbors for the scaled request vector
    distances, indices = knn.kneighbors(X_request_scaled)

    # 6. prepare response
    # get the matched volunteers based on knn results from the *valid_volunteers* list
    matched_volunteers_info = []
    for i in indices[0]:
        matched_v = valid_volunteers[i]
        matched_volunteers_info.append({
            "id": matched_v.id,
            "name": matched_v.name,
            "skills": matched_v.skills,
            "location": matched_v.location
            # optionally include distance: distances[0][idx] where idx is the loop index
        })

    return {"matched_volunteers": matched_volunteers_info}

# --- optional: add other endpoints as needed (e.g., for crud operations) ---

# example: endpoint to list volunteers (useful for debugging)
@app.get("/volunteers/")
def list_volunteers(db: Session = Depends(get_db)):
    volunteers = db.query(Volunteer).all()
    return [{"id": v.id, "name": v.name, "skills": v.skills, "location": v.location} for v in volunteers]

# example: endpoint to list requests (useful for debugging)
@app.get("/requests/")
def list_requests(db: Session = Depends(get_db)):
    requests_data = db.query(Request).all()
    return [{"id": r.id, "type": r.type, "location": r.location} for r in requests_data]


# --- run the application (for local development) ---
# this block is typically not included when deploying with docker,
# as docker uses the cmd instruction. kept here for potential direct execution.
# if __name__ == "__main__":
#     import uvicorn
#     uvicorn.run(app, host="0.0.0.0", port=8000)

