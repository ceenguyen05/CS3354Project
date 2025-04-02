README2.txt

Crowdsourced Disaster Relief Platform – Data Collection Scripts
===============================================================
Project

    CS 3354 Spring 2025, Group 2

    Members: Casey Nguyen, Kevin Pulikkottil, Andy Jih, Sawyer

Description

This folder provides scripts to populate your PostgreSQL database with initial test data. This data is essential for demonstrating and testing your backend API, particularly for verifying that volunteer and request entries exist for matching.
Included Files

    populate_database.py: Inserts predefined volunteers and disaster aid requests into the disaster_relief PostgreSQL database.

Prerequisites

    Python 3.9+

    PostgreSQL (database named disaster_relief)

    Dependencies: If you haven’t already, install them via:

    pip install -r requirements.txt

    (This includes sqlalchemy, psycopg2-binary, etc.)

Running the Data Collection Script

    Ensure PostgreSQL is running, and DATABASE_URL is configured (either in the environment or in populate_database.py):

export DATABASE_URL="postgresql://postgres:password@localhost/disaster_relief"

Execute the script:

python populate_database.py

Expected output:

    Database populated successfully with volunteers and aid requests.

    This means your database now has sample entries with location strings and associated skills.

Flutter Integration Notes

This sample data is structured to support straightforward testing from a Flutter frontend. For instance, you might have requests like ID 101 referencing “Medical” in Houston, and volunteers who have matching skills or live in a similar location. Use these IDs and skill sets to confirm the Flutter app retrieves volunteer matches correctly.