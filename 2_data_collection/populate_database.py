import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
# import models and base from main.py
# ensure main.py is in the same directory or python path
try:
    from main import Volunteer, Request, Base, SessionLocal, engine
except ImportError:
    print("Error: Could not import from main.py. Make sure it's in the correct path.")
    exit(1)
except Exception as e:
    print(f"An unexpected error occurred during import: {e}")
    exit(1)


def populate():
    """Populates the database with sample volunteers and requests."""
    db = SessionLocal()
    print("Attempting to populate database...")

    try:
        # clear existing data to avoid duplicates during re-runs
        print("Clearing existing data...")
        db.query(Volunteer).delete()
        db.query(Request).delete()
        db.commit() # commit deletions
        print("Existing data cleared.")

        # define sample volunteers
        # locations should be specific enough for geocoding (e.g., "houston, tx")
        volunteers = [
            Volunteer(name='Alice', skills='Medical', location='Houston, TX'),
            Volunteer(name='Bob', skills='Food Logistics', location='Austin, TX'),
            Volunteer(name='Charlie', skills='Rescue', location='Dallas, TX'),
            Volunteer(name='Diana', skills='Shelter Management', location='San Antonio, TX'),
            Volunteer(name='Ethan', skills='Medical', location='Fort Worth, TX'),
            Volunteer(name='Fiona', skills='Transportation', location='Houston, TX'), # added more diverse skills/locations
            Volunteer(name='George', skills='Communication', location='Dallas, TX'),
        ]

        # define sample requests
        # ensure 'type' corresponds to skills in known_skills (defined in main.py)
        requests = [
            Request(id=101, type='Medical', location='Houston, TX'),
            Request(id=102, type='Food Logistics', location='Austin, TX'), # changed type to match skill
            Request(id=103, type='Rescue', location='Dallas, TX'),
            Request(id=104, type='Shelter Management', location='San Antonio, TX'), # changed type to match skill
            Request(id=105, type='Medical', location='Dallas, TX'), # added more requests
            Request(id=106, type='Transportation', location='Houston, TX'),
        ]

        print(f"Adding {len(volunteers)} volunteers and {len(requests)} requests...")
        db.add_all(volunteers)
        db.add_all(requests)

        # commit changes
        db.commit()
        print("Database populated successfully with volunteers and aid requests.")

    except Exception as e:
        print(f"Error during database population: {e}")
        db.rollback() # rollback changes on error
    finally:
        db.close() # ensure session is closed
        print("Database session closed.")


if __name__ == "__main__":
    print("Running database population script...")
    # ensure tables are created before populating
    # this might be redundant if main.py already does it, but safe to include
    try:
        print("Ensuring database tables exist...")
        Base.metadata.create_all(bind=engine)
        print("Tables verified/created.")
    except Exception as e:
        print(f"Error creating/verifying database tables: {e}")
        exit(1)

    # populate the database
    populate()
    print("Population script finished.")