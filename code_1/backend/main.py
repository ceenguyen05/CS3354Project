import os
import sys
import datetime # Import datetime for timestamps

# Allow importing matching_ai from this folder
current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.insert(0, current_dir)

# Use Flask for compatibility with potential frontend assumptions based on previous versions
from flask import Flask, request, jsonify
from flask_cors import CORS

import firebase_admin
from firebase_admin import credentials, firestore, auth as fb_auth
from werkzeug.security import generate_password_hash, check_password_hash

# Assuming matching_ai functions can be called directly
from matching_ai import extract_features_request, get_best_matches, get_best_matches_debug

# Import the ASGI middleware
from a2wsgi import ASGIMiddleware as WSGIMiddleware # Use this import

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
alerts_ref     = db.collection("alerts")

# ————— Flask App Setup —————
_flask_app = Flask(__name__) # Rename original Flask app instance
CORS(_flask_app) # Enable CORS for the Flask app

# --- Authentication Endpoints (Email/Password based) ---
@_flask_app.route('/signup', methods=['POST'])
def signup():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')
    name = data.get('name') # Assuming frontend sends 'name'
    user_type = data.get('userType', 'donor') # Assuming frontend might send userType

    if not all([email, password, name]):
        return jsonify({"error": "Missing email, password, or name"}), 400

    try:
        # Create Firebase Auth user
        user_record = fb_auth.create_user(
            email=email,
            password=password,
            display_name=name
        )
        uid = user_record.uid

        # Create Firestore user profile document
        profile_data = {
            "uid": uid,
            "email": email,
            "name": name,
            "userType": user_type,
            "createdAt": firestore.SERVER_TIMESTAMP
        }
        users_ref.document(uid).set(profile_data)

        # Return success message AND the created profile data
        return jsonify({
            "message": "User created successfully",
            "uid": uid,
            "email": email,
            "name": name,
            "userType": user_type
            # Add other fields if needed by frontend immediately after signup
        }), 201

    except fb_auth.EmailAlreadyExistsError:
        return jsonify({"error": f"Email already exists: {email}"}), 409
    except fb_auth.FirebaseAuthError as e:
        _flask_app.logger.error(f"Firebase Auth Error during signup for {email}: {e}")
        return jsonify({"error": f"Firebase signup failed: {e.code}"}), 400
    except Exception as e:
        _flask_app.logger.error(f"Unexpected error during signup for {email}: {e}")
        # Consider deleting the auth user if Firestore save fails critically
        # if 'user_record' in locals(): fb_auth.delete_user(user_record.uid)
        return jsonify({"error": "An unexpected server error occurred during signup."}), 500

@_flask_app.route('/signin', methods=['POST'])
def signin():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password') # Frontend sends email/password

    if not all([email, password]):
        return jsonify({"error": "Missing email or password"}), 400

    try:
        # Note: Firebase Admin SDK cannot directly sign in with email/password.
        # This requires client-side SDK.
        # As a workaround for this backend-only approach (matching the flawed frontend expectation):
        # 1. Get the user by email
        # 2. If user exists, fetch their profile from Firestore.
        # WARNING: This does NOT verify the password. True password verification MUST happen client-side with Firebase SDK.
        user_record = fb_auth.get_user_by_email(email)
        uid = user_record.uid

        # Fetch Firestore profile
        profile_doc = users_ref.document(uid).get()
        if profile_doc.exists:
            profile_data = profile_doc.to_dict()
            # Return profile data (frontend expects this on signin)
            return jsonify({
                "message": "Sign in successful (password not verified by backend)",
                "uid": uid,
                "email": profile_data.get('email'),
                "name": profile_data.get('name'),
                "userType": profile_data.get('userType')
                # Add any other fields the frontend ProfileScreen expects
            }), 200
        else:
             # Handle case where Auth user exists but Firestore profile doesn't
             _flask_app.logger.warning(f"Firestore profile missing for user {uid} during signin attempt.")
             # Return basic info from Auth user? Or error?
             return jsonify({
                 "message": "Sign in successful (profile missing, password not verified)",
                 "uid": uid,
                 "email": user_record.email,
                 "name": user_record.display_name,
                 "userType": "donor" # Default or guess
             }), 200
             # return jsonify({"error": "User profile not found in database"}), 404

    except fb_auth.UserNotFoundError:
        return jsonify({"error": "User not found for this email"}), 404
    except Exception as e:
        _flask_app.logger.error(f"Error during sign in attempt for {email}: {e}")
        return jsonify({"error": f"An error occurred during sign in: {e}"}), 500


# ————— Resources —————
# WARNING: These endpoints are now unprotected without token verification.
@_flask_app.route('/resources', methods=['GET'])
def list_resources():
    resources = []
    try:
        docs = resources_ref.order_by("createdAt", direction=firestore.Query.DESCENDING).stream()
        for doc in docs:
            data = doc.to_dict()
            data["id"] = doc.id
            # Ensure field names match frontend Resource model (name, description, quantity, category, location?)
            # Example: Rename backend field if needed: data['frontendFieldName'] = data.pop('backendFieldName')
            resources.append(data)
        return jsonify(resources), 200
    except Exception as e:
        _flask_app.logger.error(f"Error listing resources: {e}")
        return jsonify({"error": "Failed to retrieve resources"}), 500

@_flask_app.route('/resources', methods=['POST'])
def create_resource():
    data = request.get_json()
    # Extract fields based on frontend Resource model
    name = data.get('name')
    quantity = data.get('quantity')
    description = data.get('description')
    category = data.get('category')
    # location = data.get('location') # Add if frontend sends location

    if not all([name, quantity is not None]): # Check quantity is present, even if 0
         return jsonify({"error": "Missing required resource data (name, quantity)"}), 400

    try:
        resource_data = {
            "name": name,
            "quantity": quantity,
            "description": description,
            "category": category,
            # "location": location,
            # "addedByUid": uid, # Cannot add UID reliably without auth
            "createdAt": firestore.SERVER_TIMESTAMP
        }
        timestamp, doc_ref = resources_ref.add(resource_data)
        new_doc = doc_ref.get()
        if new_doc.exists:
             response_data = new_doc.to_dict()
             response_data["id"] = new_doc.id
             return jsonify(response_data), 201
        else:
             return jsonify({"error": "Failed to retrieve created resource"}), 500
    except Exception as e:
        _flask_app.logger.error(f"Error creating resource: {e}")
        return jsonify({"error": "Failed to create resource"}), 500

# ————— Requests & Matching —————
@_flask_app.route('/requests', methods=['GET'])
def list_requests():
    requests_list = []
    try:
        docs = requests_ref.order_by("createdAt", direction=firestore.Query.DESCENDING).stream()
        for doc in docs:
            data = doc.to_dict()
            data["id"] = doc.id
            # Ensure field names match frontend Request model
            # Frontend uses 'name', backend used 'title'. Rename here for compatibility.
            if 'title' in data:
                data['name'] = data.pop('title')
            requests_list.append(data)
        return jsonify(requests_list), 200
    except Exception as e:
        _flask_app.logger.error(f"Error listing requests: {e}")
        return jsonify({"error": "Failed to retrieve requests"}), 500

@_flask_app.route('/requests', methods=['POST'])
def create_request():
    data = request.get_json()
    # Extract fields based on frontend Request model
    # Frontend uses 'name', backend expects 'title'. Adjust here.
    title = data.get('name') # Map frontend 'name' to backend 'title' concept
    description = data.get('description')
    request_type = data.get('type') # Frontend uses 'type'
    required_skills = data.get('required_skills', [])
    location = data.get('location')
    urgency = data.get('urgency')
    contact_email = data.get('contact_email')

    if not all([title, description, request_type]):
         return jsonify({"error": "Missing required request data (name, description, type)"}), 400

    try:
        request_data = {
            "title": title, # Store as 'title' internally
            "description": description,
            "type": request_type,
            "required_skills": required_skills,
            "location": location,
            "urgency": urgency,
            "contact_email": contact_email,
            # "user_id": uid, # Cannot add UID reliably without auth
            "status": "open",
            "createdAt": firestore.SERVER_TIMESTAMP
        }

        timestamp, doc_ref = requests_ref.add(request_data)
        req_id = doc_ref.id
        request_data["id"] = req_id # Add ID for matching function

        # Perform matching
        matches = []
        try:
            vols_docs = volunteers_ref.stream()
            vols = [d.to_dict() for d in vols_docs]
            if vols:
                 # Pass data matching matching_ai expectation (might need internal 'title')
                 matching_input = request_data.copy()
                 features = extract_features_request(matching_input)
                 matches = get_best_matches(features, vols)
            else:
                 _flask_app.logger.info("No volunteers found to match against.")
        except Exception as match_e:
            _flask_app.logger.error(f"Error during volunteer matching for request {req_id}: {match_e}")

        # Fetch created doc and return data matching frontend model
        created_doc = doc_ref.get()
        if created_doc.exists:
            response_data = created_doc.to_dict()
            response_data["id"] = created_doc.id
            # Rename 'title' back to 'name' for frontend compatibility
            if 'title' in response_data:
                 response_data['name'] = response_data.pop('title')
            response_data["matches"] = matches # Include matches if frontend expects them
            return jsonify(response_data), 201
        else:
            return jsonify({"error": "Failed to retrieve created request"}), 500

    except Exception as e:
        _flask_app.logger.error(f"Error creating request: {e}")
        return jsonify({"error": "Failed to create request"}), 500


# ————— Donations —————
@_flask_app.route('/donations', methods=['GET'])
def list_donations():
    donations = []
    try:
        docs = donations_ref.order_by("createdAt", direction=firestore.Query.DESCENDING).stream()
        for doc in docs:
            data = doc.to_dict()
            data["id"] = doc.id
            # Ensure field names match frontend Donation model (name, type, detail)
            # Backend uses itemDescription, quantity, estimatedValue, donorInfo, donation_type
            # Map fields for frontend:
            mapped_data = {
                "id": data.get("id"),
                "name": data.get("itemDescription"), # Map itemDescription to name
                "type": data.get("donation_type"), # Map donation_type to type
                "detail": f"Qty: {data.get('quantity', 'N/A')}, Value: ${data.get('estimatedValue', 'N/A')}" # Combine details
                # Add other fields if frontend expects them
            }
            donations.append(mapped_data)
        return jsonify(donations), 200
    except Exception as e:
        _flask_app.logger.error(f"Error listing donations: {e}")
        return jsonify({"error": "Failed to retrieve donations"}), 500

@_flask_app.route('/donations', methods=['POST'])
def create_donation():
    # This endpoint likely corresponds to NON-MONETARY donations based on frontend
    data = request.get_json()
    # Extract fields based on frontend Donation model (name, type, detail)
    item_description = data.get('name') # Map frontend 'name' to itemDescription
    donation_type = data.get('type') # Frontend 'type' might be 'Non-Monetary'/'Item'
    detail = data.get('detail') # Frontend 'detail' might contain quantity/value info

    # Attempt to parse quantity/value from detail if possible (highly unreliable)
    quantity = 1 # Default
    estimated_value = None
    # Basic parsing attempt (adjust if frontend format is known)
    if detail:
        parts = detail.lower().split(',')
        for part in parts:
            if 'qty:' in part:
                try: quantity = int(part.split(':')[-1].strip())
                except: pass
            if 'value:' in part or '$' in part:
                try: estimated_value = float(part.replace('value:','').replace('$','').strip())
                except: pass

    if not item_description:
         return jsonify({"error": "Missing required donation data (name)"}), 400

    try:
        donation_data = {
            "itemDescription": item_description,
            "quantity": quantity,
            "estimatedValue": estimated_value,
            # "donorInfo": ??? # Cannot get donor info reliably without auth
            "donation_type": "non-monetary", # Assume non-monetary from frontend context
            # "donorUid": uid, # Cannot add UID reliably without auth
            "createdAt": firestore.SERVER_TIMESTAMP
        }

        timestamp, doc_ref = donations_ref.add(donation_data)
        new_doc = doc_ref.get()
        if new_doc.exists:
             response_data = new_doc.to_dict()
             response_data["id"] = new_doc.id
             # Map response back to frontend model if needed
             mapped_response = {
                 "id": response_data.get("id"),
                 "name": response_data.get("itemDescription"),
                 "type": response_data.get("donation_type"),
                 "detail": f"Qty: {response_data.get('quantity', 'N/A')}, Value: ${response_data.get('estimatedValue', 'N/A')}"
             }
             return jsonify(mapped_response), 201
        else:
             return jsonify({"error": "Failed to retrieve created donation"}), 500
    except Exception as e:
        _flask_app.logger.error(f"Error creating donation: {e}")
        return jsonify({"error": "Failed to create donation"}), 500

# --- Stripe ---
# Cannot implement dynamic Stripe checkout to match frontend's hardcoded URL launch
# without modifying the frontend.

# ————— Alerts —————
@_flask_app.route('/alerts', methods=['GET'])
def list_alerts():
    alerts = []
    try:
        docs = alerts_ref.order_by("createdAt", direction=firestore.Query.DESCENDING).stream()
        for doc in docs:
            data = doc.to_dict()
            data["id"] = doc.id
            # Ensure fields match frontend Alert model (likely title, message, timestamp?)
            alerts.append(data)
        return jsonify(alerts), 200
    except Exception as e:
        _flask_app.logger.error(f"Error listing alerts: {e}")
        return jsonify({"error": "Failed to retrieve alerts"}), 500

# Optional: POST /alerts - would need frontend changes to call this
# @app.route('/alerts', methods=['POST'])
# def create_alert():
#     # ... implementation ...
#     pass


# ————— Volunteer Matching (Endpoints remain, but unprotected) —————
@_flask_app.route('/match/<request_id>', methods=['GET'])
def match_volunteers_route(request_id): # Renamed function to avoid conflict
    try:
        req_doc = requests_ref.document(request_id).get()
        if not req_doc.exists:
            return jsonify({"error": "Request not found"}), 404
        req_data = req_doc.to_dict(); req_data["id"] = request_id

        vols_docs = volunteers_ref.stream()
        vols = [d.to_dict() for d in vols_docs]
        if not vols:
             return jsonify({"matches": []}), 200

        # Ensure request data passed to matching uses internal field names if needed
        features = extract_features_request(req_data)
        matches = get_best_matches(features, vols)
        return jsonify({"matches": matches}), 200
    except Exception as e:
        _flask_app.logger.error(f"Error matching volunteers for request {request_id}: {e}")
        return jsonify({"error": "Failed to match volunteers"}), 500


@_flask_app.route('/debug-match/<request_id>', methods=['GET'])
def debug_match_route(request_id): # Renamed function
    try:
        req_doc = requests_ref.document(request_id).get()
        if not req_doc.exists:
            return jsonify({"error": "Request not found"}), 404
        req_data = req_doc.to_dict(); req_data["id"] = request_id

        vols_docs = volunteers_ref.stream()
        vols = [d.to_dict() for d in vols_docs]
        if not vols:
             return jsonify({"features": [], "matches": []}), 200

        features = extract_features_request(req_data)
        vec, matches = get_best_matches_debug(features, vols)
        feature_list = vec.tolist() if hasattr(vec, 'tolist') else vec
        return jsonify({"features": feature_list, "matches": matches}), 200
    except Exception as e:
        _flask_app.logger.error(f"Error debugging match for request {request_id}: {e}")
        return jsonify({"error": "Failed to debug match"}), 500

# Wrap the Flask app with the ASGI middleware for Uvicorn
app = WSGIMiddleware(_flask_app)

# --- (Remove or comment out the if __name__ == '__main__': block if Uvicorn runs this file directly) ---
# if __name__ == '__main__':
#    _flask_app.run(debug=True, port=8001) # This won't be used by Uvicorn
