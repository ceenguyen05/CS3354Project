# 1_code/matching_ai.py

import numpy as np
from sklearn.neighbors import NearestNeighbors
from sklearn.preprocessing import OneHotEncoder, StandardScaler
import joblib  # For persistence (if needed in the future)
from geopy.geocoders import Nominatim
from geopy.exc import GeocoderTimedOut, GeocoderServiceError

# Configuration and Encoder Setup
KNOWN_SKILLS = ['Medical', 'Food Logistics', 'Rescue', 'Shelter Management', 'Transportation', 'Communication', 'General Labor', 'Food', 'Shelter'] # Added types from requests JSON
# Ensure all known skills/types are included for the encoder
ALL_CATEGORIES = sorted(list(set(KNOWN_SKILLS))) # Get unique sorted list

encoder = OneHotEncoder(categories=[ALL_CATEGORIES], sparse_output=False, handle_unknown='ignore')
encoder.fit(np.array(ALL_CATEGORIES).reshape(-1, 1))

# Initialize geolocator
geolocator = Nominatim(user_agent="disaster_matching_ai_v2") # Use a unique agent name

# Geocoding Function (Keep as fallback, but prioritize lat/lon)
def get_lat_long(address):
    """
    Convert an address string to a (latitude, longitude) tuple.
    Returns (0.0, 0.0) if the address cannot be resolved or is empty.
    """
    if not address or not isinstance(address, str): # Check if address is valid string
        return (0.0, 0.0)
    try:
        # Add delay and retries if needed, but keep simple for now
        location = geolocator.geocode(address, timeout=10)
        if location:
            return location.latitude, location.longitude
    except (GeocoderTimedOut, GeocoderServiceError, Exception) as e: # Catch generic exceptions too
        print(f"Warning: Geocoding failed for '{address}': {e}")
        pass
    return (0.0, 0.0)

# Feature Extraction Functions (Updated)
def extract_features_request(request_data):
    """
    Extract features from an aid request dictionary (from Firestore).
    Uses 'latitude', 'longitude' directly. Handles missing 'urgency'.
    """
    req_type = request_data.get('type', '') # Get request type (e.g., 'Medical', 'Food')
    # Ensure the type is in the categories known by the encoder
    if req_type not in ALL_CATEGORIES:
        print(f"Warning: Request type '{req_type}' not in known categories. Treating as unknown.")
        # Optionally map to a default or handle as truly unknown if encoder allows
        req_type = '' # Or handle based on encoder's 'handle_unknown' setting

    encoded_type = encoder.transform([[req_type]])[0]

    # --- Use lat/lon directly from Firestore data ---
    lat = request_data.get('latitude', 0.0)
    lon = request_data.get('longitude', 0.0)
    # Basic validation: if lat/lon are zero, maybe log a warning
    if lat == 0.0 and lon == 0.0:
        print(f"Warning: Request '{request_data.get('id', 'N/A')}' has zero lat/lon.")
    # --- End location handling ---

    # --- Handle missing 'urgency' ---
    # Urgency is not in the database schema from populate_database.py
    # We'll assign a default urgency or omit it. Let's use a default medium.
    urgency_score = 2 # Default to medium urgency
    # --- End urgency handling ---

    # Ensure all parts are numpy arrays before concatenating
    return np.concatenate((np.array([lat, lon]), encoded_type, np.array([urgency_score])))

def extract_features_volunteer(volunteer_data):
    """
    Extract features from a volunteer dictionary (from Firestore).
    Handles 'skills' list, 'location' map, and boolean 'availability'.
    """
    # --- Handle skills list (use first skill or empty string) ---
    skills_list = volunteer_data.get('skills', [])
    # Use the first skill if available, ensure it's known to encoder
    v_skill = skills_list[0] if skills_list else ''
    if v_skill not in ALL_CATEGORIES:
         print(f"Warning: Volunteer skill '{v_skill}' not in known categories. Treating as unknown.")
         v_skill = '' # Or handle based on encoder's 'handle_unknown' setting
    encoded_skill = encoder.transform([[v_skill]])[0]
    # --- End skills handling ---

    # --- Use lat/lon from location map if present ---
    location_map = volunteer_data.get('location', {})
    lat = location_map.get('latitude', 0.0)
    lon = location_map.get('longitude', 0.0)
    # Basic validation
    if lat == 0.0 and lon == 0.0:
         print(f"Warning: Volunteer '{volunteer_data.get('id', 'N/A')}' has zero lat/lon.")
         # Optional: Fallback to geocoding if a string 'location' field existed
         # addr_str = volunteer_data.get('location_string', '') # Example if you had another field
         # if addr_str: lat, lon = get_lat_long(addr_str)
    # --- End location handling ---

    # --- Handle boolean availability ---
    availability_bool = volunteer_data.get('availability', False) # Default to False if missing
    availability_flag = 1 if availability_bool else 0
    # --- End availability handling ---

    # Ensure all parts are numpy arrays before concatenating
    return np.concatenate((np.array([lat, lon]), encoded_skill, np.array([availability_flag])))

# Matching Functions (build_feature_matrix, get_best_matches, get_best_matches_debug)
# These functions remain structurally the same, but will now receive correctly processed features.

def build_feature_matrix(volunteers):
    """
    Build a feature matrix from a list of volunteer dictionaries.
    Each row represents one volunteer's feature vector.
    Handles potential errors during feature extraction for individual volunteers.
    """
    features = []
    valid_volunteers_indices = [] # Keep track of which volunteers were successfully processed
    for i, vol in enumerate(volunteers):
        try:
            vol_features = extract_features_volunteer(vol)
            features.append(vol_features)
            valid_volunteers_indices.append(i)
        except Exception as e:
            # Log error for the specific volunteer
            print(f"Error extracting features for volunteer {vol.get('id', 'N/A')}: {e}")
            # Skip this volunteer
            continue

    if not features: # If no volunteers could be processed
        return None, [] # Return None for matrix, empty list for indices

    # Return the matrix and the indices of the volunteers included in it
    return np.vstack(features), valid_volunteers_indices

def get_best_matches(request_features, volunteers, k=3):
    """
    Production function: Uses KNN to find the top k matching volunteers.
    Returns a list of volunteer dictionaries for the best matches.
    Handles cases where feature extraction fails for some/all volunteers.
    """
    if not volunteers:
        return []

    # Build feature matrix, getting back only features for valid volunteers and their original indices
    X, valid_indices = build_feature_matrix(volunteers)

    if X is None or X.shape[0] == 0: # Check if matrix is None or empty
        print("Warning: No valid volunteer features could be extracted.")
        return []

    # Filter the original volunteers list to match the rows in X
    valid_volunteers = [volunteers[i] for i in valid_indices]

    # Scale features (only valid ones)
    scaler_local = StandardScaler()
    # Use try-except for scaling in case of issues (e.g., variance is zero)
    try:
        X_scaled = scaler_local.fit_transform(X)
        req_scaled = scaler_local.transform([request_features])
    except ValueError as e:
        print(f"Error during scaling: {e}. Returning empty matches.")
        return []


    # Perform KNN
    # Adjust k if there are fewer valid volunteers than requested
    actual_k = min(k, X_scaled.shape[0])
    if actual_k == 0:
        return []

    nn = NearestNeighbors(n_neighbors=actual_k, metric='euclidean')
    nn.fit(X_scaled)
    distances, indices = nn.kneighbors(req_scaled)

    # Map indices from KNN (which refer to rows in X_scaled) back to the original volunteers list
    # using the valid_volunteers list
    matches = [valid_volunteers[i] for i in indices[0]]
    return matches

def get_best_matches_debug(request_features, volunteers, k=3):
    """
    Debug function: Similar to get_best_matches, but returns detailed matching info.
    Handles cases where feature extraction fails for some/all volunteers.
    """
    debug_output = {
        "request_features": request_features.tolist() if request_features is not None else [],
        "volunteer_features": [],
        "X_scaled": [],
        "req_scaled": [],
        "distances": [],
        "indices": [],
        "matched_volunteers": [],
        "processing_warnings": []
    }

    if not volunteers:
        debug_output["processing_warnings"].append("No volunteers provided.")
        return debug_output

    # Build feature matrix
    X, valid_indices = build_feature_matrix(volunteers)

    if X is None or X.shape[0] == 0:
        debug_output["processing_warnings"].append("No valid volunteer features could be extracted.")
        return debug_output

    valid_volunteers = [volunteers[i] for i in valid_indices]
    debug_output["volunteer_features"] = X.tolist() # Raw features of valid volunteers

    # Scale features
    scaler_local = StandardScaler()
    try:
        X_scaled = scaler_local.fit_transform(X)
        req_scaled = scaler_local.transform([request_features])
        debug_output["X_scaled"] = X_scaled.tolist()
        debug_output["req_scaled"] = req_scaled[0].tolist()
    except ValueError as e:
        debug_output["processing_warnings"].append(f"Error during scaling: {e}. Aborting match.")
        return debug_output

    # Perform KNN
    actual_k = min(k, X_scaled.shape[0])
    if actual_k == 0:
         debug_output["processing_warnings"].append("No volunteers available for KNN after filtering/scaling.")
         return debug_output

    nn = NearestNeighbors(n_neighbors=actual_k, metric='euclidean')
    nn.fit(X_scaled)
    distances, indices = nn.kneighbors(req_scaled)

    distances_list = distances[0].tolist()
    indices_list = indices[0].tolist() # Indices relative to X_scaled / valid_volunteers

    debug_output["distances"] = distances_list
    debug_output["indices"] = indices_list # Store indices relative to the scaled matrix

    # Map matched indices back to the valid volunteers
    matched_vols = [valid_volunteers[i] for i in indices_list]
    debug_output["matched_volunteers"] = matched_vols

    return debug_output