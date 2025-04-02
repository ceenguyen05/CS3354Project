README3.txt

Crowdsourced Disaster Relief Platform – Basic Function Testing
==============================================================
Project

    CS 3354 Spring 2025, Group 2

    Members: Casey Nguyen, Kevin Pulikkottil, Andy Jih, Sawyer

Description

This folder contains scripts for running basic functional tests against the backend API endpoints. These tests help verify the server’s correctness before integrating with the Flutter frontend.
Included Files

    test_matching.py: A Python script that automatically tests the volunteer matching endpoint (/match/{request_id}).

Prerequisites

    Python 3.9+

    FastAPI backend running at http://localhost:8000

    Dependencies: You need requests installed (already included in requirements.txt).

Running the Basic Functional Tests

    Launch your FastAPI backend:

uvicorn main:app --reload

Run the test script:

python test_matching.py

Observe results:

    ✅ Request ID 101 - Success:
    {"matched_volunteers": [{...}]}
    ------------------------------------------------------------
    ❌ Request ID 999 - Failed:
    Status: 404, Error: {"error": "Request not found"}
    ------------------------------------------------------------

        “Success” means the endpoint returned expected volunteers.

        “Failed” with 404 indicates the request doesn’t exist, confirming proper error handling.

Flutter Integration Notes

    The test cases illustrate sample request IDs and expected JSON structures. This helps ensure that the Flutter app can properly parse and display volunteer match data.

Expanding Tests

    Add or modify request IDs in test_matching.py to match new data in your database.

    Check geocoding-based matches (if volunteers’ location strings differ significantly).