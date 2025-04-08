# test_matching.py

# this script tests the /match/{request_id} endpoint by sending sample requests
import requests
import pytest

# Parameterize test cases to check multiple request IDs
@pytest.mark.parametrize("request_id", [101, 102, 103, 104, 999])  # 999 tests error handling
def test_matching(request_id):
    url = f"http://localhost:8000/match/{request_id}"
    response = requests.get(url)

    # Assert that the response is either 200 (success) or 404 (not found)
    assert response.status_code in [200, 404], f"Unexpected status code: {response.status_code}"

    if response.status_code == 200:
        print(f"✅ Request ID {request_id} - Success:")
        print(response.json())
    else:
        print(f"❌ Request ID {request_id} - Failed:")
        print(f"Status: {response.status_code}, Error: {response.json()}")
