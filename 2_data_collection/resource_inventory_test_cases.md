// written by: Casey  
// tested by: Casey 
// debugged by: Casey 

# Test Cases – Resource Inventory 

## Test Case 1 – Load a proper json file for this deliverable 1 test case 

**Preconditions**:

- Backend is running
- User has Flutter environment installed and can run the web app
- load in a json under 1_code/assets/json_files

**Steps**:

1. Launch the mobile app using `flutter run`
2. Select "Resource Inventory" from the top of the page
3. View available resources 

**Expected Outcome**:

- Able to view all the available resources in the json file from the resource inventory screen

---

## Test Case 2 – Submit with invalid json file 

**Steps**:

1. Do not load a correctly formatted json file into 1_code/assets/json_files
2. Navigate to emergency alerts page 

**Expected Outcome**:

- you get a error saying the data cannot be loaded since the website cannot read from the json file 


