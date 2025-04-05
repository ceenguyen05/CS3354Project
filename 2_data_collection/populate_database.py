import os
import sys
import firebase_admin
from firebase_admin import credentials, firestore

# --- Firebase Admin SDK Setup ---
# Duplicated from main.py for standalone execution, ensure consistency
try:
    # Determine path relative to the script file if needed
    script_dir = os.path.dirname(__file__)
    default_key_path = os.path.join(script_dir, "serviceAccountKey.json")

    cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", default_key_path)
    if not os.path.exists(cred_path):
         raise FileNotFoundError(f"Service account key file not found at: {cred_path}. Set GOOGLE_APPLICATION_CREDENTIALS or place key file correctly.")

    # Avoid initializing app multiple times if run after main.py in some contexts
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

# Get Firestore client
try:
    db = firestore.client()
    print("Firestore client obtained successfully.")
except Exception as e:
    print(f"Error obtaining Firestore client: {e}")
    sys.exit(1)


# --- Firestore Collection References ---
volunteers_ref = db.collection('volunteers')
requests_ref = db.collection('requests')


def clear_collection(collection_ref):
    """Deletes all documents in a Firestore collection (use with caution!)."""
    docs = collection_ref.stream()
    deleted_count = 0
    # Use batch delete for efficiency if available and needed, simple loop for clarity here
    for doc in docs:
        print(f"Deleting doc {doc.id} from {collection_ref.id}...")
        doc.reference.delete()
        deleted_count += 1
    print(f"Deleted {deleted_count} documents from {collection_ref.id}.")


def populate():
    """Populates Firestore with sample volunteers and requests."""
    print("Attempting to populate Firestore...")

    try:
        # Clear existing data (optional, use carefully!)
        print("Clearing existing data...")
        clear_collection(volunteers_ref)
        clear_collection(requests_ref)
        print("Existing data cleared.")

        # Define sample volunteers as dictionaries
        volunteers_data = [
            {'name': 'Alice', 'skills': 'Medical', 'location': 'Houston, TX'},
            {'name': 'Bob', 'skills': 'Food Logistics', 'location': 'Austin, TX'},
            {'name': 'Charlie', 'skills': 'Rescue', 'location': 'Dallas, TX'},
            {'name': 'Diana', 'skills': 'Shelter Management', 'location': 'San Antonio, TX'},
            {'name': 'Ethan', 'skills': 'Medical', 'location': 'Fort Worth, TX'},
            {'name': 'Fiona', 'skills': 'Transportation', 'location': 'Houston, TX'},
            {'name': 'George', 'skills': 'Communication', 'location': 'Dallas, TX'},
        ]

        # Define sample requests as dictionaries
        # Using specific string IDs matching previous examples for consistency in testing
        requests_data = {
            '101': {'type': 'Medical', 'location': 'Houston, TX'},
            '102': {'type': 'Food Logistics', 'location': 'Austin, TX'},
            '103': {'type': 'Rescue', 'location': 'Dallas, TX'},
            '104': {'type': 'Shelter Management', 'location': 'San Antonio, TX'},
            '105': {'type': 'Medical', 'location': 'Dallas, TX'},
            '106': {'type': 'Transportation', 'location': 'Houston, TX'},
        }

        # Use batch writes for efficiency
        batch = db.batch()

        print(f"Adding {len(volunteers_data)} volunteers...")
        for v_data in volunteers_data:
            # Let Firestore auto-generate volunteer IDs
            doc_ref = volunteers_ref.document()
            batch.set(doc_ref, v_data)

        print(f"Adding {len(requests_data)} requests...")
        for req_id, r_data in requests_data.items():
            # Use specific IDs for requests
            doc_ref = requests_ref.document(req_id)
            batch.set(doc_ref, r_data)

        # Commit the batch
        batch.commit()
        print("Firestore populated successfully using batch writes.")

    except Exception as e:
        print(f"Error during Firestore population: {e}")
        # Batches don't have explicit rollback, but partial writes might occur before error.


if __name__ == "__main__":
    print("Running Firestore population script...")
    populate()
    print("Population script finished.")
