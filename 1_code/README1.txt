README1.txt

Crowdsourced Disaster Relief Platform – AI Matching Backend
===========================================================
Project Information

    Project: Crowdsourced Disaster Relief Platform

    Course: CS 3354 Spring 2025

    Group Number: 2

    Group Members: Casey Nguyen, Kevin Pulikkottil, Andy Jih, Sawyer

Description

This backend system implements an AI-powered matching algorithm using FastAPI, PostgreSQL, SQLAlchemy, and K-Nearest Neighbors (KNN) from scikit-learn. It efficiently matches disaster-relief aid requests with suitable volunteers based on skills and geographic proximity. The solution integrates geocoding (via geopy) and one-hot encoding for volunteer skills, ensuring more accurate and robust matches. It’s designed to work seamlessly with a Flutter frontend.
Tech Stack

    FastAPI (Python)

    PostgreSQL

    SQLAlchemy

    scikit-learn (KNN algorithm, one-hot encoding, scaling)

    geopy (for geocoding addresses)

    Docker & Docker Compose (optional)

    Flutter (frontend integration)

Prerequisites

    Python 3.9+

    PostgreSQL installed and running

    Docker (optional, for containerized deployment)

    Dependencies listed in requirements.txt:

        fastapi, uvicorn, sqlalchemy, psycopg2-binary, scikit-learn, numpy, requests, geopy, etc.

You can install them all by running:

pip install -r requirements.txt

Database Setup

    Create & configure the PostgreSQL database (if not using Docker):

CREATE DATABASE disaster_relief;
CREATE USER postgres WITH PASSWORD 'password';
ALTER DATABASE disaster_relief OWNER TO postgres;

Set your DATABASE_URL in main.py or as an environment variable if needed:

    DATABASE_URL = os.getenv(
        "DATABASE_URL",
        "postgresql://postgres:password@localhost/disaster_relief"
    )

Installation & Running the Application

    Install dependencies:

pip install -r requirements.txt

Start the backend API using Uvicorn:

uvicorn main:app --reload

Access the API at:

    http://localhost:8000

    or view interactive docs at http://localhost:8000/docs.

Flutter Integration

This backend supports a Flutter frontend that can communicate with FastAPI endpoints. Ensure you enable or configure CORS if needed.

Example Flutter HTTP call:

import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> fetchMatchedVolunteers(int requestId) async {
  final response = await http.get(
    Uri.parse('http://localhost:8000/match/$requestId'),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    print(data);  // handle/display data in Flutter UI
  } else {
    print('Request failed: ${response.statusCode}');
  }
}

Sample API Call

To retrieve matched volunteers for a specific request:

GET http://localhost:8000/match/101

Sample Response:

{
  "matched_volunteers": [
    {"id": 1, "name": "Alice", "skills": "Medical", "location": "Houston"},
    {"id": 2, "name": "Bob", "skills": "Food Logistics", "location": "Austin"},
    {"id": 3, "name": "Charlie", "skills": "Rescue", "location": "Dallas"}
  ]
}

Docker Deployment

Use Docker Compose to build & run both the backend (API) and PostgreSQL database:

docker-compose up --build

Then visit http://localhost:8000 for the API.
Troubleshooting

    Database Connection: Ensure PostgreSQL is running and DATABASE_URL is correct.

    Dependencies: Check you ran pip install -r requirements.txt.

    Docker: If using Docker, ensure docker-compose.yml matches your credentials.