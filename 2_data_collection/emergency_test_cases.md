// written by: Casey & Andy 
// tested by: Casey & Andy
// debugged by: Casey 


# Test Cases – Emergency Alerts 

## Test Case 1 – Load a valid Json File 

**Preconditions**:

- Backend is running
- User has Flutter environment installed and can run the web app

**Steps**:

1. Launch the mobile app using `flutter run`
2. Select "Emergency Alerts" from the homescreen
3. View current emergency alerts 

**Expected Outcome**:

- You can view current emergecies, the description of it, and the date it was alerted 

---

## Test Case 2 – Submit with invalid json file 

**Steps**:

1. Do not load a correctly formatted json file into 1_code/assets/json_files
2. Navigate to emergency alerts page 

**Expected Outcome**:

- you get a error saying the data cannot be loaded since the website cannot read from the json file 

---