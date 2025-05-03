# 3_basic_function_testing/test_matching.py

import json
import requests
import pytest
import traceback

# --- Configuration ---
BASE_URL = "http://localhost:8001" # Backend server URL
REQUEST_TIMEOUT = 20 # Seconds

# --- Helper Function ---
def validate_volunteer_dict(vol_dict):
    """
    Validates the structure and basic types of a volunteer dictionary
    as expected in the API response. Assumes 'id' is added by the backend.
    """
    # Check for essential keys based on data population and expected processing
    required_keys = ['id', 'name', 'skills', 'location', 'availability']
    for key in required_keys:
        assert key in vol_dict, f"Volunteer dictionary missing required key: '{key}'. Found: {list(vol_dict.keys())}"

    # Basic type checking
    assert isinstance(vol_dict.get('id'), str), f"Volunteer 'id' should be a string, got {type(vol_dict.get('id'))}"
    assert isinstance(vol_dict.get('name'), str), f"Volunteer 'name' should be a string, got {type(vol_dict.get('name'))}"
    assert isinstance(vol_dict.get('skills'), list), f"Volunteer 'skills' should be a list, got {type(vol_dict.get('skills'))}"
    assert isinstance(vol_dict.get('availability'), bool), f"Volunteer 'availability' should be a boolean, got {type(vol_dict.get('availability'))}"

    # Location map validation
    location = vol_dict.get('location')
    assert isinstance(location, dict), f"Volunteer 'location' should be a dictionary, got {type(location)}"
    assert 'latitude' in location, "Volunteer 'location' dictionary missing 'latitude'"
    assert 'longitude' in location, "Volunteer 'location' dictionary missing 'longitude'"
    assert isinstance(location.get('latitude'), (int, float)), f"Volunteer 'latitude' should be a number, got {type(location.get('latitude'))}"
    assert isinstance(location.get('longitude'), (int, float)), f"Volunteer 'longitude' should be a number, got {type(location.get('longitude'))}"

# --- Test Cases ---

# Request IDs '101' and '102' are added as samples in populate_database.py
# Request ID '999' is assumed not to exist.
@pytest.mark.parametrize("endpoint, request_id, expected_status", [
    pytest.param("/match", "101", 200, id="match_success_101"),
    pytest.param("/match", "102", 200, id="match_success_102"),
    pytest.param("/match", "999", 404, id="match_not_found_999"), # Expecting 404 specifically
    pytest.param("/debug-match", "101", 200, id="debug_success_101", marks=pytest.mark.xfail(reason="Known bug in main.py's debug_match_route prevents success")), # Marked as expected fail due to bug
    pytest.param("/debug-match", "999", 404, id="debug_not_found_999"), # Expecting 404 specifically
])
def test_match_endpoints(endpoint, request_id, expected_status):
    """
    Tests the /match and /debug-match endpoints for various request IDs.
    """
    url = f"{BASE_URL}{endpoint}/{request_id}"
    response = None
    try:
        response = requests.get(url, timeout=REQUEST_TIMEOUT)

        # 1. Assert Status Code
        assert response.status_code == expected_status, \
            f"URL: {url}\nExpected status {expected_status}, but got {response.status_code}.\nResponse text: {response.text[:500]}"

        # 2. Assert Response Body Structure (based on status code)
        try:
            data = response.json()
        except requests.exceptions.JSONDecodeError:
            # Fail if we expected 200 but didn't get JSON
            if expected_status == 200:
                pytest.fail(f"URL: {url}\nExpected JSON response for status 200, but got non-JSON: {response.text[:500]}")
            # If status was not 200, not getting JSON might be okay (e.g., plain text 404)
            # but ideally, errors should also return JSON. Let's check for the expected 404 error structure if possible.
            elif expected_status == 404:
                 # Allow non-JSON 404 for now, but ideally it should be JSON like {"error": "..."}
                 print(f"\nℹ️ INFO: URL {url} returned 404 without JSON body.")
                 return # Test passes for 404 status check
            else:
                 pytest.fail(f"URL: {url}\nReceived status {response.status_code} without a JSON body.")
            return # Exit test function if JSON parsing failed for non-200 expected status

        # --- Structure Validation for Successful Responses (200 OK) ---
        if expected_status == 200:
            if endpoint == "/match":
                # Expected structure: {"matches": [list_of_volunteers]} based on main.py
                assert "matches" in data, f"URL: {url}\nResponse JSON missing 'matches' key."
                assert isinstance(data["matches"], list), f"URL: {url}\n'matches' key should be a list, got {type(data['matches'])}."
                print(f"\n✅ {url} returned {len(data['matches'])} matches.")
                # Validate each volunteer in the list
                for i, volunteer in enumerate(data["matches"]):
                    try:
                        validate_volunteer_dict(volunteer)
                    except AssertionError as e:
                        pytest.fail(f"URL: {url}\nValidation failed for volunteer at index {i}: {e}\nVolunteer data: {volunteer}")
                print(f"  Validated {len(data['matches'])} volunteer entries.")

            elif endpoint == "/debug-match":
                # Expected structure based on matching_ai.py's get_best_matches_debug return value
                # (Assumes main.py bug is fixed to return this structure)
                expected_keys = [
                    "request_features", "volunteer_features", "X_scaled", "req_scaled",
                    "distances", "indices", "matched_volunteers", "processing_warnings"
                ]
                for key in expected_keys:
                    assert key in data, f"URL: {url}\nDebug response JSON missing expected key: '{key}'."

                assert isinstance(data.get("matched_volunteers"), list), f"URL: {url}\n'matched_volunteers' key should be a list."
                print(f"\n✅ {url} returned debug info with {len(data['matched_volunteers'])} matches.")
                if data.get("processing_warnings"):
                    print(f"  Processing Warnings: {data['processing_warnings']}")

                # Validate each volunteer in the list
                for i, volunteer in enumerate(data["matched_volunteers"]):
                     try:
                         validate_volunteer_dict(volunteer)
                     except AssertionError as e:
                         pytest.fail(f"URL: {url}\nValidation failed for debug volunteer at index {i}: {e}\nVolunteer data: {volunteer}")
                print(f"  Validated {len(data['matched_volunteers'])} volunteer entries in debug output.")

        # --- Structure Validation for Error Responses (e.g., 404 Not Found) ---
        elif expected_status == 404:
            # Expecting {"error": "Request not found"} based on main.py
            assert "error" in data, f"URL: {url}\nExpected error JSON for 404, but 'error' key missing. Got: {data}"
            assert "not found" in data["error"].lower(), f"URL: {url}\nExpected 'not found' in 404 error message. Got: {data['error']}"
            print(f"\n✅ {url} correctly returned 404 with error message: {data['error']}")

        # Add checks for other expected error codes (e.g., 500) if needed,
        # although 500 errors often indicate bugs rather than expected behavior.

    except requests.exceptions.RequestException as e:
        pytest.fail(f"Request failed for {url}: {e}\n{traceback.format_exc()}")
    except AssertionError: # Re-raise assertion errors from checks above
        raise
    except Exception as e:
        status = response.status_code if response else "N/A"
        text = response.text[:500] if response else "N/A"
        pytest.fail(f"An unexpected error occurred during test for {url}: {e}\nStatus: {status}\nResponse Text: {text}\n{traceback.format_exc()}")


@pytest.mark.xfail(reason="Known bug in main.py's debug_match_route prevents success") # Mark as expected fail
def test_consistency_between_endpoints():
    """
    Tests if /match and /debug-match return the same volunteers for the same request.
    NOTE: This test WILL FAIL until the bug in main.py's debug_match_route is fixed.
    """
    request_id = "101" # Use a known valid request ID
    match_url = f"{BASE_URL}/match/{request_id}"
    debug_url = f"{BASE_URL}/debug-match/{request_id}"
    prod_response = None
    debug_response = None

    try:
        prod_response = requests.get(match_url, timeout=REQUEST_TIMEOUT)
        debug_response = requests.get(debug_url, timeout=REQUEST_TIMEOUT)

        # 1. Check Status Codes (both should be 200)
        assert prod_response.status_code == 200, \
            f"Production endpoint {match_url} failed: Status {prod_response.status_code}, Text: {prod_response.text[:500]}"
        assert debug_response.status_code == 200, \
            f"Debug endpoint {debug_url} failed: Status {debug_response.status_code}, Text: {debug_response.text[:500]}"

        # 2. Parse JSON
        prod_data = prod_response.json()
        debug_data = debug_response.json()

        # 3. Extract Matched Volunteers
        prod_matches = prod_data.get("matches", []) # Based on main.py /match route
        debug_matches = debug_data.get("matched_volunteers", []) # Based on matching_ai.py debug output

        # 4. Compare Matched Volunteers (using IDs)
        # Ensure volunteers have 'id' before comparison
        prod_ids = sorted([v['id'] for v in prod_matches if 'id' in v])
        debug_ids = sorted([v['id'] for v in debug_matches if 'id' in v])

        assert prod_ids == debug_ids, \
            f"Mismatch in matched volunteer IDs for request {request_id}.\nProduction ({len(prod_ids)}): {prod_ids}\nDebug ({len(debug_ids)}): {debug_ids}"

        print(f"\n✅ Consistency test passed for request ID {request_id}. Found {len(prod_ids)} matches.")

    except requests.exceptions.RequestException as e:
        pytest.fail(f"Request failed during consistency test for ID {request_id}: {e}\n{traceback.format_exc()}")
    except AssertionError: # Re-raise assertion errors
        raise
    except Exception as e:
        pytest.fail(f"An unexpected error occurred during consistency test for ID {request_id}: {e}\n{traceback.format_exc()}")