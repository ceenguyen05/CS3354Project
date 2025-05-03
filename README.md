# Crowdsourced Disaster Relief Platform

A full-stack web application designed to facilitate disaster response efforts through crowdsourcing. The platform connects individuals in need with volunteers and donors, providing real-time data on available resources and emergency alerts.

## Features

- **AI-Based Volunteer Matching**: Matches aid requests with suitable volunteers using KNN algorithm.
- **Resource Management**: Real-time resource inventory by region.
- **Donation & Request Handling**: Interfaces for submitting aid requests and making donations.
- **Emergency Alerts**: Live and historical alert system for disaster events.
- **Secure Firebase Backend**: Cloud-hosted NoSQL database via Firestore.
- **Mobile-Friendly**: Built with Flutter for cross-platform deployment.

## Tech Stack

**Frontend**

- Flutter (Dart)

**Backend**

- FastAPI (Python)
- Firebase Firestore
- AI Matching: scikit-learn, NumPy, Geopy, Joblib

**Other Tools**

- Docker (optional deployment)
- VSCode
- Pytest for testing

## Architecture

- **Frontend** interacts with users and posts data to backend APIs.
- **Backend** handles logic, including AI-based volunteer matching.
- **Database** stores all structured data like users, requests, donations, alerts, and resources.

## Data Models

- **Users**: Basic login info.
- **Requests**: Type, location, and description of help needed.
- **Donations**: Donor info and donation type/description.
- **Alerts**: Emergency type, description, severity, and date.
- **Resources**: Inventory tracking by area.

## AI Matching

- Uses one-hot encoding and K-Nearest Neighbors (KNN).
- Inputs: Request type, location, urgency.
- Matches with volunteers based on skills, location, and availability.

## API Endpoints

* **Root:**
  [http://localhost:8001/](vscode-file://vscode-app/Applications/Visual%20Studio%20Code.app/Contents/Resources/app/out/vs/code/electron-sandbox/workbench/workbench.html)
* **Production Match Endpoint:**
  [http://localhost:8001/match/{request_id}](vscode-file://vscode-app/Applications/Visual%20Studio%20Code.app/Contents/Resources/app/out/vs/code/electron-sandbox/workbench/workbench.html)
* **Debug Match Endpoint:**
  [http://localhost:8001/debug-match/{request_id}](vscode-file://vscode-app/Applications/Visual%20Studio%20Code.app/Contents/Resources/app/out/vs/code/electron-sandbox/workbench/workbench.html)
* **Swagger UI:**
  [http://localhost:8001/docs](vscode-file://vscode-app/Applications/Visual%20Studio%20Code.app/Contents/Resources/app/out/vs/code/electron-sandbox/workbench/workbench.html)
* **ReDoc:**
  [http://localhost:8001/redoc](vscode-file://vscode-app/Applications/Visual%20Studio%20Code.app/Contents/Resources/app/out/vs/code/electron-sandbox/workbench/workbench.html)

## Frontend Pages

- Home: Navigation to all features.
- Request Help: Submit aid requests.
- Donate: Monetary or material contributions.
- Emergency Alerts: View disaster warnings.
- Resource Inventory: Check resource availability.
- Sign Up / Sign In: UI for user authentication.

## Testing

- READ code_1/README1.txt for how to get started and run the application 

## Deployment

- **Backend**: Run with Uvicorn or via Docker. `127.0.0.1:8001/match/101`
- **Frontend**: Flutter web app deployable via standard web server. `127.0.0.1:PORT`
- Docker setup provided for containerized deployment.

## Security

- Firebase credentials are secured and excluded via `.gitignore`.
- Placeholder user auth exists in frontend, backend integration pending.

## Files and What They Do 
Files and What They Are:
- code_1 contains the entire website application, has front and backends and needed files to run it 
- 2_data_collection contains a data collection program to populate our data base. It also has test cases of our features 
- 3_basic_function_testing contains testing the AI matching aspect of our website 
- 4_documentaion has all previous reports, final report, and the presentation powerpoint 
- code_1/lib has all the frontend 
- code_1/backend has all the backend 

## Team

- Casey Nguyen
- Kevin Pulikkottil
- Andy Jih

---

2025 Group 2 - CS 3354
