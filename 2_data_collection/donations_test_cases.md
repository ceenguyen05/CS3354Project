# Test Cases – Donations 

## Test Case 1 – Submit a valid Donation

**Preconditions**:

- Backend is running
- User has Flutter environment installed and can run the web app

**Steps**:

1. Launch the mobile app using `flutter run`
2. Select "Donations" from the homescreen
3. Enter your name 
4. Select the donation type: Money or Resource 
5. Enter in the Description: "$100" or "10 water bottles
6. Tap “Donate”

**Expected Outcome**:

- A snackbar appears: "Thanks for your donations (Money or Resource)"
- The request appears in the backend (Firebase/DB logs or GET /requests)

---

## Test Case 2 – Submit without Name or Description

**Steps**:

1. Do not enter a name or description 
2. Tap “Donate”

**Expected Outcome**:

- The name or description is highlighed and red indicating you need to enter it
- No request is sent to the backend

---

