Overview:
This module contains automated tests for the AI volunteer matching system using pytest.
These tests verify that the /match and /debug-match endpoints work as expected for valid and invalid request IDs.
This represents basic function testing for the core matching API.

Prerequisites:
  - Populate the Firestore database with sample data using:
      make populate-db
  - Start the FastAPI backend server (ensure it is accessible at http://localhost:8001) using:
      make run

Running Tests:
Execute the following command in your terminal from the project root:
   make test

Testing Details:
  - The tests in `test_matching.py` use `pytest` and the `requests` library to interact with the running backend.
  - **Endpoint Validation:**
      - Tests cover both `/match/{request_id}` and `/debug-match/{request_id}` endpoints.
      - **Valid Request IDs** (e.g., `/match/101`, `/match/102`): Expected to return an HTTP 200 status.
          - For `/match`, the response JSON must contain a `"matches"` key with a list of volunteer objects.
          - For `/debug-match`, the response JSON must contain keys like `"request_features"`, `"volunteer_features"`, `"X_scaled"`, `"req_scaled"`, `"distances"`, `"indices"`, `"matched_volunteers"`, and `"processing_warnings"`.
          - **Note:** Tests involving `/debug-match/101` are marked with `pytest.mark.xfail` due to a known bug in the `main.py` debug route implementation.
      - **Invalid Request ID** (e.g., `/match/999`, `/debug-match/999`): Expected to return an HTTP 404 status with a JSON payload like `{"error": "Request not found"}`.
  - **Data Structure Validation:**
      - A helper function (`validate_volunteer_dict`) rigorously checks the structure and data types of each volunteer object returned in successful responses (both `/match` and `/debug-match`). It ensures keys like `id`, `name`, `skills`, `location` (with `latitude`/`longitude`), and `availability` are present and have the correct types.
  - **Consistency Check:**
      - `test_consistency_between_endpoints` verifies that for the same valid request ID (e.g., '101'), both `/match` and `/debug-match` return the same set of matched volunteer IDs.
      - **Note:** This test is also marked with `pytest.mark.xfail` as it relies on the `/debug-match` endpoint, which currently has a known bug.

Sample Test Output (will show failures for xfail tests if the bug persists):
   3_basic_function_testing/test_matching.py ..x.x. [100%]

Note:
  - Ensure the backend server and Firebase connection are active before running `make test`.
  - The `xfail` markers indicate tests that are expected to fail due to known issues. They will report as 'x' (xfail) or 'X' (XPASS - unexpected pass) in the pytest output.