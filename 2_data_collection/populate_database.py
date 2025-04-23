import os
import sys
import firebase_admin
from firebase_admin import credentials, firestore

# Firebase Admin SDK Setup
# This section initializes the Firebase Admin SDK. It first checks for the 
# GOOGLE_APPLICATION_CREDENTIALS environment variable. If not set, it looks
# for the serviceAccountKey.json file in the same directory as this script.
try:
    # Get the directory of the current script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    # Default key path relative to this script
    default_key_path = os.path.join(script_dir, "serviceAccountKey.json")
    # Use environment variable, if available; otherwise, use the default path.
    cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", default_key_path)
    
    if not os.path.exists(cred_path):
        raise FileNotFoundError(f"Service account key file not found at: {cred_path}. Set GOOGLE_APPLICATION_CREDENTIALS or place key file correctly.")
    
    # Initialize the Firebase Admin SDK only if not already initialized
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

# Get the Firestore client
try:
    db = firestore.client()
    print("Firestore client obtained successfully.")
except Exception as e:
    print(f"Error obtaining Firestore client: {e}")
    sys.exit(1)

# Firestore Collection References
volunteers_ref = db.collection('volunteers')
requests_ref = db.collection('requests')

# Helper Functions
def clear_collection(collection_ref):
    """
    Deletes all documents in a Firestore collection. Use with caution!
    """
    docs = collection_ref.stream()
    deleted_count = 0
    for doc in docs:
        print(f"Deleting doc {doc.id} from {collection_ref.id}...")
        doc.reference.delete()
        deleted_count += 1
    print(f"Deleted {deleted_count} documents from {collection_ref.id}.")

def populate():
    """
    Populates Firestore with sample data for volunteers and aid requests.
    
    For Volunteers:
        - name: Volunteer name
        - skills: Volunteer skill (e.g., 'Medical', 'Food Logistics', etc.)
        - location: Volunteer location (e.g., 'Houston, TX')
        - availability: "available" or "unavailable"
    
    For Requests:
        - type: Type of request (e.g., 'Medical', 'Food Logistics', etc.)
        - location: Request location (e.g., 'Houston, TX')
        - urgency: Urgency level ('low', 'medium', or 'high')
    """
    print("Attempting to populate Firestore...")
    try:
        # Clear existing data (optional; use carefully)
        print("Clearing existing data...")
        clear_collection(volunteers_ref)
        clear_collection(requests_ref)
        print("Existing data cleared.")

        # Define sample volunteers with additional attribute 'availability'
        volunteers_data = [
            {'name': 'Alice', 'skills': 'Medical', 'location': 'Houston, TX', 'availability': 'available'},
            {'name': 'Bob', 'skills': 'Food Logistics', 'location': 'Austin, TX', 'availability': 'available'},
            {'name': 'Charlie', 'skills': 'Rescue', 'location': 'Dallas, TX', 'availability': 'available'},
            {'name': 'Diana', 'skills': 'Shelter Management', 'location': 'San Antonio, TX', 'availability': 'available'},
            {'name': 'Ethan', 'skills': 'Medical', 'location': 'Fort Worth, TX', 'availability': 'available'},
            {'name': 'Fiona', 'skills': 'Transportation', 'location': 'Houston, TX', 'availability': 'available'},
            {'name': 'George', 'skills': 'Communication', 'location': 'Dallas, TX', 'availability': 'available'},
        ]

        # Define sample requests with all required fields
        requests_data = {
            '101': {
                'name': 'Urgent Medical Aid Needed',
                'type': 'Medical',
                'description': 'Requires immediate medical attention near downtown.',
                'latitude': 29.7604,  # Example Houston Lat
                'longitude': -95.3698, # Example Houston Lon
                'location': 'Houston, TX', # Keep original location string if needed elsewhere
                'urgency': 'high'
            },
            '102': {
                'name': 'Food Distribution Point',
                'type': 'Food Logistics',
                'description': 'Setting up food distribution, need volunteers.',
                'latitude': 30.2672,  # Example Austin Lat
                'longitude': -97.7431, # Example Austin Lon
                'location': 'Austin, TX',
                'urgency': 'medium'
            },
            '103': {
                'name': 'Search and Rescue Op',
                'type': 'Rescue',
                'description': 'Search operation underway in flooded area.',
                'latitude': 32.7767,  # Example Dallas Lat
                'longitude': -96.7970, # Example Dallas Lon
                'location': 'Dallas, TX',
                'urgency': 'high'
            },
            '104': {
                'name': 'Shelter Support Required',
                'type': 'Shelter Management',
                'description': 'Need help managing temporary shelter.',
                'latitude': 29.4241,  # Example San Antonio Lat
                'longitude': -98.4936, # Example San Antonio Lon
                'location': 'San Antonio, TX',
                'urgency': 'medium'
            },
            '105': {
                'name': 'Medical Supplies Request',
                'type': 'Medical',
                'description': 'Requesting specific medical supplies.',
                'latitude': 32.7767,  # Example Dallas Lat
                'longitude': -96.7970, # Example Dallas Lon
                'location': 'Dallas, TX',
                'urgency': 'high'
            },
            '106': {
                'name': 'Transport for Evacuees',
                'type': 'Transportation',
                'description': 'Need drivers for evacuee transport.',
                'latitude': 29.7604,  # Example Houston Lat
                'longitude': -95.3698, # Example Houston Lon
                'location': 'Houston, TX',
                'urgency': 'low'
            },
        }

        # Use batch writes for efficient insertion
        batch = db.batch()

        print(f"Adding {len(volunteers_data)} volunteers...")
        for v_data in volunteers_data:
            # Auto-generate an ID for each volunteer
            doc_ref = volunteers_ref.document()
            batch.set(doc_ref, v_data)

        print(f"Adding {len(requests_data)} requests...")
        for req_id, r_data in requests_data.items():
            # Use predefined IDs for requests to simplify testing
            doc_ref = requests_ref.document(req_id)
            batch.set(doc_ref, r_data)

        # Commit the batch to apply all writes
        batch.commit()
        print("Firestore populated successfully using batch writes.")

    except Exception as e:
        print(f"Error during Firestore population: {e}")
        # Note: Partial writes might occur if an error is raised

if __name__ == "__main__":
    print("Running Firestore population script...")
    populate()
    print("Population script finished.")