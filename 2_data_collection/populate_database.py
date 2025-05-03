import os
import sys
import json
import firebase_admin
from firebase_admin import credentials
# Import the google cloud firestore client library
from google.cloud import firestore
# IMPORT Python's datetime
from datetime import datetime, timezone # Import timezone as well

# --- Configuration ---
CLEAR_COLLECTIONS_BEFORE_POPULATING = True # Set to False to append data instead of replacing

# --- Firebase Admin SDK Setup (for credentials only) ---
try:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    backend_dir = os.path.abspath(os.path.join(script_dir, '../code_1/backend'))
    default_key_path = os.path.join(backend_dir, "serviceAccountKey.json")
    cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", default_key_path)

    if not os.path.exists(cred_path):
        raise FileNotFoundError(f"Service account key file not found at: {cred_path}. Set GOOGLE_APPLICATION_CREDENTIALS or place key file correctly.")

    # Initialize firebase_admin ONLY if not already done (needed for credential loading)
    if not firebase_admin._apps:
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        print("Firebase Admin SDK initialized successfully for population script (for credentials).")
    else:
        print("Firebase Admin SDK already initialized.")

except FileNotFoundError as fnf_error:
    print(f"Error: {fnf_error}")
    sys.exit(1)
except ValueError as val_error:
    print(f"Error initializing Firebase Admin SDK: {val_error}")
    sys.exit(1)
except Exception as e:
    print(f"An unexpected error occurred during Firebase Admin SDK setup: {e}")
    sys.exit(1)


# --- Get Firestore Client and Collection References (using google-cloud-firestore) ---
try:
    # Use the google-cloud-firestore client directly
    db = firestore.Client() # Use the imported firestore module
    print("Firestore client obtained successfully (using google.cloud.firestore).")

    # Collection references
    volunteers_ref = db.collection('volunteers')
    requests_ref = db.collection('requests')
    resources_ref = db.collection('resources')
    donations_ref = db.collection('donations')
    users_ref = db.collection('users')
    alerts_ref = db.collection('alerts') # Make sure alerts_ref is defined

except Exception as e:
    print(f"Error obtaining Firestore client or collection references: {e}")
    sys.exit(1)

# --- Helper Functions ---
def clear_collection(coll_ref):
    """Deletes all documents in a given collection."""
    docs = coll_ref.stream()
    deleted_count = 0
    for doc in docs:
        doc.reference.delete()
        deleted_count += 1
    print(f"Deleted {deleted_count} documents from {coll_ref.id}.")

def load_json_data(filename):
    """Loads data from a JSON file located in code_1/assets/json_files/."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    # Correct path relative to this script to find code_1/assets/json_files
    project_root = os.path.abspath(os.path.join(script_dir, '..'))
    json_dir = os.path.join(project_root, 'code_1', 'assets', 'json_files')
    filepath = os.path.join(json_dir, filename)
    try:
        with open(filepath, 'r', encoding='utf-8') as f: # Specify encoding
            data = json.load(f)
            if isinstance(data, list):
                print(f"Successfully loaded {len(data)} items from {filename}.")
                return data
            else:
                print(f"Warning: Expected a list in {filename}, but found {type(data)}. Returning empty list.")
                return []
    except FileNotFoundError:
        print(f"Warning: JSON file not found at {filepath}. Returning empty list.")
        return []
    except json.JSONDecodeError as e:
        print(f"Error reading or parsing {filepath}: {e}. Returning empty list.")
        return []
    except Exception as e:
        print(f"An unexpected error occurred loading {filepath}: {e}. Returning empty list.")
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
    items_processed = 0 # Add counter for processed items

    try:
        # --- 1. Add Sample Data (Hardcoded) ---
        # Use standard types for now
        volunteers_data = {
            # Store location as a map/dict instead of GeoPoint
            'volunteer1': {'name': 'Alice', 'skills': ['medical', 'driving'], 'availability': True, 'location': {'latitude': 29.76, 'longitude': -95.36}},
            'volunteer2': {'name': 'Bob', 'skills': ['logistics'], 'availability': False, 'location': {'latitude': 30.26, 'longitude': -97.74}}
        }
        requests_data = {
             # Use datetime.now(timezone.utc) for timestamp
            '101': {'name': 'Urgent Medical Aid Needed', 'type': 'Medical', 'description': 'Requires immediate medical attention near downtown.', 'latitude': 29.7604, 'longitude': -95.3698, 'timestamp': datetime.now(timezone.utc)},
            '102': {'name': 'Food Distribution Point', 'type': 'Food', 'description': 'Setting up food distribution, need volunteers.', 'latitude': 30.2672, 'longitude': -97.7431, 'timestamp': datetime.now(timezone.utc)},
        }
        # Add sample volunteers
        for doc_id, data in volunteers_data.items():
            doc_ref = volunteers_ref.document(doc_id)
            batch.set(doc_ref, data)
            total_added += 1
        # Add sample requests
        for doc_id, data in requests_data.items():
            doc_ref = requests_ref.document(doc_id)
            batch.set(doc_ref, data)
            total_added += 1
        print(f"Added {len(volunteers_data)} sample volunteers and {len(requests_data)} sample requests.")

        # --- 2. Load and Add Data from JSON Files ---
        print("\n--- Loading data from JSON files ---")

        # Resources
        json_resources = load_json_data("resources.json")
        print(f"--- Processing resources.json ({len(json_resources)} items) ---")
        for i, item in enumerate(json_resources):
            items_processed += 1
            print(f"  Resource item {i}: {item}")
            doc_data = {
                "name": item.get("name"),
                "location": item.get("location"),
                "quantity": item.get("quantity"),
                "timestamp": datetime.now(timezone.utc) # Use datetime
            }
            if doc_data["name"] and doc_data["location"] and doc_data["quantity"] is not None:
                print(f"    -> VALID: Adding {doc_data['name']}")
                doc_ref = resources_ref.document()
                batch.set(doc_ref, doc_data)
                total_added += 1
            else:
                print(f"    -> INVALID: Skipping item {i} due to missing fields.")

        # Requests
        json_requests = load_json_data("current_requests.json")
        print(f"--- Processing current_requests.json ({len(json_requests)} items) ---")
        for i, item in enumerate(json_requests):
            items_processed += 1
            print(f"  Request item {i}: {item}")
            doc_data = {
                "name": item.get("name"),
                "type": item.get("type"),
                "description": item.get("description"),
                "latitude": item.get("latitude"),
                "longitude": item.get("longitude"),
                "timestamp": datetime.now(timezone.utc) # Use datetime
            }
            if (doc_data["name"] and doc_data["type"] and doc_data["description"] and
                doc_data["latitude"] is not None and doc_data["longitude"] is not None):
                print(f"    -> VALID: Adding {doc_data['name']}")
                doc_ref = requests_ref.document()
                batch.set(doc_ref, doc_data)
                total_added += 1
            else:
                print(f"    -> INVALID: Skipping item {i} due to missing fields.")

        # Donations
        json_donations = load_json_data("donations.json")
        print(f"--- Processing donations.json ({len(json_donations)} items) ---")
        for i, item in enumerate(json_donations):
            items_processed += 1
            print(f"  Donation item {i}: {item}")
            doc_data = {
                 "name": item.get("name"),
                 "type": item.get("type"),
                 "detail": item.get("detail"),
                 "timestamp": datetime.now(timezone.utc) # Use datetime
             }
            if doc_data["name"] and doc_data["type"] and doc_data["detail"]:
                print(f"    -> VALID: Adding {doc_data['name']}")
                doc_ref = donations_ref.document()
                batch.set(doc_ref, doc_data)
                total_added += 1
            else:
                print(f"    -> INVALID: Skipping item {i} due to missing fields.")

        # Alerts
        # Use existing load_json_data function and correct filename
        alerts_list = load_json_data('emergency_alerts.json')
        if alerts_list: # Check if the list is not None and not empty
            print(f"--- Processing emergency_alerts.json ({len(alerts_list)} items) ---") # Add count here
            for i, item in enumerate(alerts_list): # Iterate with index
                items_processed += 1 # Increment processed items
                doc_id = item.get('id') # Use 'id' from JSON if available (though not present in your example)

                # --- FIX FIELD MAPPING HERE ---
                doc_data = {
                    # Map 'alertDescription' from JSON to 'message' in Firestore
                    "message": item.get('alertDescription', 'No description provided'),
                    # Map 'alertTitle' from JSON to 'severity' in Firestore (or use a default)
                    "severity": item.get('alertTitle', 'Unknown'),
                    # Keep adding the timestamp during population
                    "timestamp": datetime.now(timezone.utc)
                    # Optionally add location if needed later:
                    # "location": item.get('alertLocation')
                }
                # --- END FIX ---

                # Basic validation example (now checks the mapped message)
                if doc_data["message"] != 'No description provided':
                    print(f"  Alert item {i}: {item}") # Print item being processed
                    print(f"    -> VALID Alert: {doc_id or '(auto-id)'} - {doc_data['message'][:30]}...")
                    if doc_id:
                        doc_ref = alerts_ref.document(doc_id) # Use alerts_ref
                    else:
                        doc_ref = alerts_ref.document() # Use alerts_ref
                    batch.set(doc_ref, doc_data)
                    total_added += 1 # Increment total added
                else:
                    print(f"  Alert item {i}: {item}") # Print invalid item
                    print(f"    -> INVALID Alert data (missing alertDescription): {item}")
        else:
            # Message updated for clarity
            print("  Skipping alerts (file empty, not found, or invalid).")


        # Users
        json_users = load_json_data("users.json")
        print(f"--- Processing users.json ({len(json_users)} items) ---")
        for i, item in enumerate(json_users):
            items_processed += 1
            print(f"  User item {i}: {item}")
            doc_data = {
                 "email": item.get("email"),
                 "name": item.get("name"),
                 "userType": item.get("userType", "donor"), # Default to 'donor' if missing
                 "createdAt": datetime.now(timezone.utc) # Use datetime
             }
            if doc_data["email"] and doc_data["name"]:
                print(f"    -> VALID: Adding {doc_data['name']}")
                # Use email as document ID for users if appropriate, otherwise auto-generate
                # doc_ref = users_ref.document(doc_data["email"])
                doc_ref = users_ref.document() # Using auto-generated ID for now
                batch.set(doc_ref, doc_data)
                total_added += 1
            else:
                print(f"    -> INVALID: Skipping item {i} due to missing fields.")

        # --- 3. Commit Batch ---
        print(f"\nProcessed {items_processed} items from JSON files.")
        print(f"Committing batch of {total_added} total documents (including samples)...")
        batch.commit()
        print("Firestore populated successfully.")

    except Exception as e:
        print(f"Error during Firestore population: {e}")

# --- Main Execution ---
if __name__ == "__main__":
    print("Running Firestore population script...")
    populate()
    print("Population script finished.")