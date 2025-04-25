import os
import sys

# Allow importing matching_ai from this folder
current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.insert(0, current_dir)

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

import firebase_admin
from firebase_admin import credentials, firestore, auth as fb_auth

from matching_ai import extract_features_request, get_best_matches, get_best_matches_debug

from pydantic import BaseModel
from typing import Optional

# ————— Firebase Admin Initialization —————
cred_path = os.getenv(
    "GOOGLE_APPLICATION_CREDENTIALS",
    os.path.join(current_dir, "serviceAccountKey.json")
)
if not os.path.exists(cred_path):
    print(f"Service account key not found at {cred_path}")
    exit(1)
if not firebase_admin._apps:
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)

db = firestore.client()

# ————— Collection References —————
volunteers_ref = db.collection("volunteers")
requests_ref   = db.collection("requests")
resources_ref  = db.collection("resources")
donations_ref  = db.collection("donations")
users_ref      = db.collection("users")

# ————— FastAPI App Setup —————
app = FastAPI(title="Crowdsourced Disaster Relief API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
    allow_credentials=True,
)

# ————— Pydantic Models —————
class ResourceIn(BaseModel):
    name: str
    quantity: int
    location: str

class RequestIn(BaseModel):
    name: str
    type: str
    description: str
    latitude: float
    longitude: float

class DonationIn(BaseModel):
    donor_name: str
    donation_type: str
    detail: str

class SignUpIn(BaseModel):
    email: str
    password: str
    display_name: Optional[str] = None

class SignInIn(BaseModel):
    id_token: str

# ————— Health Check —————
@app.get("/")
def root():
    return {"status": "API up"}

# ————— Resources —————
@app.get("/resources")
def list_resources():
    return [doc.to_dict() for doc in resources_ref.stream()]

@app.post("/resources")
def create_resource(r: ResourceIn):
    doc_ref = resources_ref.add(r.dict())
    return {"resource_id": doc_ref[1].id}

# ————— Requests & Matching —————
@app.get("/requests")
def list_requests():
    return [doc.to_dict() for doc in requests_ref.stream()]

@app.post("/requests")
def create_request(req: RequestIn):
    # save
    doc_ref = requests_ref.add(req.dict())
    req_id = doc_ref[1].id

    # load + match
    req_data = {**req.dict(), "id": req_id}
    vols = [d.to_dict() for d in volunteers_ref.stream()]
    features = extract_features_request(req_data)
    matches = get_best_matches(features, vols)
    return {"request_id": req_id, "matches": matches}

# ————— Donations —————
@app.get("/donations")
def list_donations():
    return [doc.to_dict() for doc in donations_ref.stream()]

@app.post("/donations")
def create_donation(d: DonationIn):
    doc_ref = donations_ref.add(d.dict())
    return {"donation_id": doc_ref[1].id}

# ————— Authentication —————
@app.post("/signup")
def signup(u: SignUpIn):
    try:
        user = fb_auth.create_user(
            email=u.email,
            password=u.password,
            display_name=u.display_name
        )
    except fb_auth.AuthError as e: # Catch the base AuthError
        # Provide a more informative detail based on the Firebase error code
        # Check if the error has a code attribute, otherwise use the general message
        error_code = getattr(e, 'code', 'UNKNOWN_AUTH_ERROR')
        error_detail = f"Firebase signup failed: {error_code}"
        print(f"AuthError during signup for {u.email}: {e}") # Log the specific error
        # Use specific status codes if possible, e.g., 409 for EMAIL_EXISTS
        status_code = 400 # Default to Bad Request
        if error_code == 'EMAIL_EXISTS':
            status_code = 409 # Conflict
        elif error_code == 'CONFIGURATION_NOT_FOUND':
             status_code = 500 # Internal Server Error (config issue)
        raise HTTPException(status_code=status_code, detail=error_detail)
    except Exception as e: # Catch other unexpected errors
        print(f"Unexpected error during signup for {u.email}: {e}") # Log unexpected errors
        raise HTTPException(status_code=500, detail="An unexpected server error occurred during signup.")

    # If create_user was successful, save additional info to Firestore
    try:
        users_ref.document(user.uid).set({
            "email": u.email, # Store email
            "display_name": u.display_name or "" # Store display name or empty string
            # Add any other profile fields you want to store initially
        })
    except Exception as e:
        # Log Firestore error, but maybe don't fail the whole signup?
        # Or decide if this should also cause signup to fail.
        print(f"Error saving user profile to Firestore for {user.uid}: {e}")
        # Optionally raise HTTPException here if Firestore save is critical

    return {"uid": user.uid} # Return UID on success

@app.post("/signin")
def signin(t: SignInIn):
    try:
        decoded = fb_auth.verify_id_token(t.id_token)
        uid = decoded["uid"]
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")
    profile = users_ref.document(uid).get().to_dict()
    if profile is None:
        raise HTTPException(status_code=404, detail="User not found")
    return {"uid": uid, "profile": profile}

# ————— Volunteer Matching —————
@app.get("/match/{request_id}")
def match_volunteers(request_id: str):
    req_doc = requests_ref.document(request_id).get()
    if not req_doc.exists:
        raise HTTPException(status_code=404, detail="Request not found")
    req_data = req_doc.to_dict(); req_data["id"] = request_id

    vols = [d.to_dict() for d in volunteers_ref.stream()]
    features = extract_features_request(req_data)
    matches = get_best_matches(features, vols)
    return {"matches": matches}

@app.get("/debug-match/{request_id}")
def debug_match(request_id: str):
    req_doc = requests_ref.document(request_id).get()
    if not req_doc.exists:
        raise HTTPException(status_code=404, detail="Request not found")
    req_data = req_doc.to_dict(); req_data["id"] = request_id

    vols = [d.to_dict() for d in volunteers_ref.stream()]
    features = extract_features_request(req_data)
    vec, matches = get_best_matches_debug(features, vols)
    return {"features": vec.tolist(), "matches": matches}
