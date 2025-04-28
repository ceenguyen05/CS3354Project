import os
import sys
import json # Import json module
import firebase_admin
from firebase_admin import credentials, firestore

# --- Configuration ---
CLEAR_COLLECTIONS_BEFORE_POPULATING = True # Set to False to append data instead of replacing

# --- Firebase Admin SDK Setup ---
try:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    # Go up one level to project root, then into code_1/backend for the key
    backend_dir = os.path.abspath(os.path.join(script_dir, '../code_1/backend'))
    default_key_path = os.path.join(backend_dir, "serviceAccountKey.json")
    cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", default_key_path)

    if not os.path.exists(cred_path):
        raise FileNotFoundError(f"Service account key file not found at: {cred_path}. Set GOOGLE_APPLICATION_CREDENTIALS or place key file correctly.")

    if not firebase_admin._apps:
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        print("Firebase Admin SDK initialized successfully for population script.")
    else:
        print("Firebase Admin SDK already initialized.")

except FileNotFoundError as fnf_error:
    print(f"Error: {fnf_error}")
    sys.exit(1)
except ValueError as val_error:
    print(f"Error initializing Firebase Admin SDK: {val_error}")
    sys.exit(1)
except Exception as e:
    print(f"An unexpected error occurred during Firebase initialization: {e}")
    sys.exit(1)

# --- Get Firestore Client and Collection References ---
try:
    db = firestore.client()
    print("Firestore client obtained successfully.")
    # Add references for all collections used
    volunteers_ref = db.collection('volunteers')
    requests_ref = db.collection('requests')
    resources_ref = db.collection('resources')
    donations_ref = db.collection('donations')
    users_ref = db.collection('users')
    alerts_ref = db.collection('alerts')
except Exception as e:
    print(f"Error obtaining Firestore client or collection references: {e}")
    sys.exit(1)

# --- Helper Functions ---
def clear_collection(collection_ref):
    """Deletes all documents in a Firestore collection."""
    docs = collection_ref.stream()
    deleted_count = 0
    batch = db.batch()
    for doc in docs:
        batch.delete(doc.reference)
        deleted_count += 1
        if deleted_count % 400 == 0: # Commit batch periodically for large collections
             print(f"Deleting batch of 400 from {collection_ref.id}...")
             batch.commit()
             batch = db.batch()
    if deleted_count % 400 != 0: # Commit remaining deletes
         print(f"Deleting final batch from {collection_ref.id}...")
         batch.commit()
    print(f"Deleted {deleted_count} documents from {collection_ref.id}.")

def load_json_data(filename):
    """Loads data from a JSON file in code_1/assets/json_files/"""
    # Path relative to this script's location (2_data_collection)
    # Go up to project root, then down to code_1/assets/json_files
    json_dir = os.path.abspath(os.path.join(script_dir, '../code_1/assets/json_files'))
    file_path = os.path.join(json_dir, filename)
    if not os.path.exists(file_path):
        print(f"Warning: JSON file not found at {file_path}. Skipping.")
        return []
    try:
        with open(file_path, 'r') as f:
            data = json.load(f)
            print(f"Successfully loaded {len(data)} items from {filename}.")
            return data if isinstance(data, list) else [] # Ensure it's a list
    except Exception as e:
        print(f"Error reading or parsing {filename}: {e}. Skipping.")
        return []

# --- Main Population Logic ---
def populate():
    """Populates Firestore with sample data AND data from JSON files."""
    print("Attempting to populate Firestore...")
    all_collections = [volunteers_ref, requests_ref, resources_ref, donations_ref, users_ref, alerts_ref]

    if CLEAR_COLLECTIONS_BEFORE_POPULATING:
        print("Clearing existing data...")
        for coll_ref in all_collections:
            clear_collection(coll_ref)
        print("Existing data cleared.")
    else:
        print("CLEAR_COLLECTIONS_BEFORE_POPULATING is False. Appending data.")

    batch = db.batch()
    total_added = 0

    try:
        # --- 1. Add Sample Data (Hardcoded) ---
        print("Adding hardcoded sample data...")
        # Sample volunteers
        volunteers_data = [
            {'name': 'Alice', 'skills': 'Medical', 'location': 'Houston, TX', 'availability': 'available'},
            {'name': 'Bob', 'skills': 'Food Logistics', 'location': 'Austin, TX', 'availability': 'available'},
            # ... (add other sample volunteers if needed)
        ]
        for v_data in volunteers_data:
            doc_ref = volunteers_ref.document()
            batch.set(doc_ref, v_data)
            total_added += 1

        # Sample requests (using predefined IDs)
        requests_data = {
            '101': {'name': 'Urgent Medical Aid Needed', 'type': 'Medical', 'description': 'Requires immediate medical attention near downtown.', 'latitude': 29.7604, 'longitude': -95.3698, 'location': 'Houston, TX', 'urgency': 'high', 'createdAt': firestore.SERVER_TIMESTAMP},
            '102': {'name': 'Food Distribution Point', 'type': 'Food Logistics', 'description': 'Setting up food distribution, need volunteers.', 'latitude': 30.2672, 'longitude': -97.7431, 'location': 'Austin, TX', 'urgency': 'medium', 'createdAt': firestore.SERVER_TIMESTAMP},
             # ... (add other sample requests if needed)
        }
        for req_id, r_data in requests_data.items():
             # Map 'name' from sample data to 'title' for internal consistency if needed by matching_ai
             r_data['title'] = r_data.pop('name', None) # Use title internally
             doc_ref = requests_ref.document(req_id)
             batch.set(doc_ref, r_data)
             total_added += 1
        print(f"Added {len(volunteers_data)} sample volunteers and {len(requests_data)} sample requests.")

        # --- 2. Load and Add Data from JSON Files ---
        print("\nLoading data from JSON files...")

        # Resources
        json_resources = load_json_data("resources.json")
        for item in json_resources:
            # Map JSON fields (name, quantity, location) to backend fields (name, quantity, description, category)
            doc_data = {
                "name": item.get("name"),
                "quantity": item.get("quantity"),
                "description": item.get("description"), # Add if exists in JSON
                "category": item.get("category"),     # Add if exists in JSON
                # "location": item.get("location"), # Backend doesn't store location for resources currently
                "createdAt": firestore.SERVER_TIMESTAMP
            }
            if doc_data["name"] and doc_data["quantity"] is not None:
                doc_ref = resources_ref.document()
                batch.set(doc_ref, doc_data)
                total_added += 1

        # Requests (current_requests.json)
        json_requests = load_json_data("current_requests.json")
        for item in json_requests:
            # Map JSON fields (name, type, description, latitude, longitude, etc.) to backend fields
            doc_data = {
                "title": item.get("name"), # Map frontend 'name' to backend 'title'
                "type": item.get("type"),
                "description": item.get("description"),
                "latitude": item.get("latitude"),
                "longitude": item.get("longitude"),
                "location": item.get("location"),
                "urgency": item.get("urgency", "medium"), # Default if missing
                "required_skills": item.get("required_skills", []), # Default if missing
                "contact_email": item.get("contact_email"), # Add if exists
                "status": "open",
                "createdAt": firestore.SERVER_TIMESTAMP
                # "user_id": ??? # Cannot link to user without auth info
            }
            if doc_data["title"] and doc_data["type"] and doc_data["description"]:
                doc_ref = requests_ref.document() # Auto-generate ID
                batch.set(doc_ref, doc_data)
                total_added += 1

        # Donations
        json_donations = load_json_data("donations.json")
        for item in json_donations:
             # Map JSON fields (name, type, detail) to backend fields (itemDescription, quantity, etc.)
             # This requires parsing the 'detail' field if it contains quantity/value
             quantity = 1 # Default
             estimated_value = None
             detail_str = item.get('detail', '')
             # Basic parsing attempt (same as in main.py)
             if detail_str:
                 parts = detail_str.lower().split(',')
                 for part in parts:
                     if 'qty:' in part:
                         try: quantity = int(part.split(':')[-1].strip())
                         except: pass
                     if 'value:' in part or '$' in part:
                         try: estimated_value = float(part.replace('value:','').replace('$','').strip())
                         except: pass

             doc_data = {
                 "itemDescription": item.get("name"), # Map 'name' to 'itemDescription'
                 "quantity": quantity,
                 "estimatedValue": estimated_value,
                 "donation_type": "non-monetary", # Assume non-monetary from JSON context
                 # "donorInfo": ???
                 # "donorUid": ???
                 "createdAt": firestore.SERVER_TIMESTAMP
             }
             if doc_data["itemDescription"]:
                 doc_ref = donations_ref.document()
                 batch.set(doc_ref, doc_data)
                 total_added += 1

        # Alerts
        json_alerts = load_json_data("emergency_alerts.json")
        for item in json_alerts:
             # Map JSON fields (title, message, severity, etc.)
             doc_data = {
                 "title": item.get("title"),
                 "message": item.get("message"),
                 "severity": item.get("severity", "info"),
                 "target_area": item.get("target_area"),
                 "createdAt": firestore.SERVER_TIMESTAMP # Use server timestamp
                 # "postedByUid": ???
             }
             if doc_data["title"] and doc_data["message"]:
                 doc_ref = alerts_ref.document()
                 batch.set(doc_ref, doc_data)
                 total_added += 1

        # Users (Optional - Be careful not to overwrite real user data if not clearing)
        # Note: This JSON likely doesn't contain password hashes needed for Firebase Auth.
        # This will only populate the Firestore 'users' collection, not Firebase Auth itself.
        json_users = load_json_data("users.json")
        for item in json_users:
             # Map JSON fields (email, name, userType, etc.)
             doc_data = {
                 "email": item.get("email"),
                 "name": item.get("name"),
                 "userType": item.get("userType", "donor"),
                 "createdAt": firestore.SERVER_TIMESTAMP
                 # "uid": ??? # Cannot determine UID without Firebase Auth interaction
             }
             # Use email as document ID for simplicity IF clearing collection, otherwise might conflict
             # A better approach would be to skip seeding users or use auto-generated IDs.
             if doc_data["email"] and doc_data["name"]:
                 # Using email as ID - ONLY SAFE IF CLEARING or emails are guaranteed unique
                 # doc_ref = users_ref.document(doc_data["email"])
                 doc_ref = users_ref.document() # Safer: Use auto-generated ID
                 batch.set(doc_ref, doc_data)
                 total_added += 1

        # --- 3. Commit Batch ---
        print(f"\nCommitting batch of {total_added} total documents...")
        batch.commit()
        print("Firestore populated successfully.")

    except Exception as e:
        print(f"Error during Firestore population: {e}")

# --- Main Execution ---
if __name__ == "__main__":
    print("Running Firestore population script...")
    populate()
    print("Population script finished.")