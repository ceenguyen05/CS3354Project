# Crowdsourced Disaster Relief Platform

## Overview

This project is a **backend system** for a Crowdsourced Disaster Relief Platform. It uses **AI-powered matching** to connect disaster relief requests with suitable volunteers based on **skills** and **geographic proximity**. The backend is built with **FastAPI**, **PostgreSQL**, **SQLAlchemy**, and **scikit-learn**, designed to integrate seamlessly with a Flutter frontend.

### Key Matching Features

- **Geocoding**: Converts volunteer/request location strings to latitude/longitude via [`geopy`](https://pypi.org/project/geopy/).
- **One-Hot Encoding**: Uses `sklearn.preprocessing.OneHotEncoder` for volunteer skills (based on a `KNOWN_SKILLS` list in `main.py`).
- **Standard Scaling**: Applies `sklearn.preprocessing.StandardScaler` to coordinate + encoded skill vectors, improving KNN distance calculations.
- **Robust Error Handling**:
  - Skips volunteers whose location cannot be geocoded (logged as a warning).
  - Gracefully handles cases where no volunteers (or none valid) exist, returning 404 or an appropriate message.

---

## Table of Contents

1. [Tech Stack](#tech-stack)
2. [Prerequisites](#prerequisites)
3. [Setup and Installation](#setup-and-installation)
4. [Running the Backend](#running-the-backend)
5. [Populating the Database](#populating-the-database)
6. [Testing the Backend](#testing-the-backend)
7. [Docker Deployment](#docker-deployment)
8. [Troubleshooting](#troubleshooting)
9. [Notes for Flutter Integration](#notes-for-flutter-integration)
10. [Contributors](#contributors)

---

## 1. Tech Stack

- **Backend Framework**: [FastAPI](https://fastapi.tiangolo.com/)
- **Database**: [PostgreSQL](https://www.postgresql.org/)
- **ORM**: [SQLAlchemy](https://www.sqlalchemy.org/)
- **AI Algorithm**: K-Nearest Neighbors (scikit-learn) with geocoded coordinates + one-hot-encoded skills
- **Geocoding**: [geopy](https://pypi.org/project/geopy/)
- **Containerization**: Docker & Docker Compose
- **Frontend**: Flutter (integration-ready)

---

## 2. Prerequisites

Before running the project, ensure you have the following installed:

1. **Python 3.9+**
2. **PostgreSQL**
3. **Docker** (optional, for containerized deployment)
4. **Python packages** listed in `requirements.txt`. Key ones include:
   - `fastapi`, `uvicorn`, `sqlalchemy`, `psycopg2-binary`, `scikit-learn`, `numpy`, `requests`, `geopy`, `pydantic`

You can install them with:

```bash
pip install -r requirements.txt
```

---

## 3. Setup and Installation

### (A) Clone the Repository

```bash
git clone <repository-url>
cd <repository-folder>
```

### (B) Environment Variables / Database URL

If not already set, create or modify your database connection string. For example, in `main.py`:

```python
DATABASE_URL = "postgresql://postgres:password@localhost/disaster_relief"
```

### (C) Install Dependencies

```bash
pip install -r requirements.txt
```

This ensures you have all libraries (FastAPI, geopy, etc.) for the AI matching features.

---

## 4. Running the Backend

1. **Start PostgreSQL**Ensure your PostgreSQL server is running.
2. **Run FastAPI**

   ```bash
   uvicorn main:app --reload
   ```

   By default, the API will be available at [http://localhost:8000](http://localhost:8000).
3. **Check Interactive Docs**

   - Go to [http://localhost:8000/docs](http://localhost:8000/docs) to see the automatically generated OpenAPI docs.

---

## 5. Populating the Database

### (A) Create the Database

```sql
CREATE DATABASE disaster_relief;
CREATE USER postgres WITH PASSWORD 'password';
ALTER DATABASE disaster_relief OWNER TO postgres;
```

### (B) Run Auto-Creation or Migrations

If your code auto-creates tables on startup, just run the app. Otherwise, run any migration script if required.

### (C) Insert Sample Data

Optionally, run `populate_database.py` (or a similar script) to add volunteers and aid requests:

```bash
python 2_data_collection/populate_database.py
```

This seeds the database with initial data. Volunteers’ locations will be geocoded when matching is requested.

---

## 6. Testing the Backend

### (A) Automated Tests

If you have a script like `test_matching.py`:

```bash
python 3_basic_function_testing/test_matching.py
```

Example:

```
✅ Request ID 101 - Success:
{"matched_volunteers": [{...}]}
------------------------------------------------------------
❌ Request ID 999 - Failed:
Status: 404, Error: {"error": "Request not found"}
------------------------------------------------------------
```

### (B) Manual Testing

Use `curl`, Postman, or a browser:

```bash
curl http://localhost:8000/match/101
```

**Response** (sample):

```json
{
  "matched_volunteers": [
    {
      "id": 1,
      "name": "Alice",
      "skills": "Medical",
      "location": "Houston, TX"
    },
    ...
  ]
}
```

**Under the Hood**:

1. Geocoding volunteer + request addresses to latitude/longitude.
2. Encoding volunteer skills with one-hot encoding.
3. Scaling numeric vectors.
4. Running KNN to find best matches.

---

## 7. Docker Deployment

### (A) Build and Run with Docker Compose

```bash
docker-compose up --build
```

This will:

- Start a **PostgreSQL** container (port 5432).
- Build and run the FastAPI container using `requirements.txt`.

### (B) Verify Services

- **API**: [http://localhost:8000/docs](http://localhost:8000/docs)
- **Database**: Check logs or connect via psql to ensure PostgreSQL is up.

---

## 8. Troubleshooting

1. **Database Connection Error**

   - Verify PostgreSQL is running and your `DATABASE_URL` is correct.
2. **Missing Dependencies**

   - Reinstall from `requirements.txt`:
     ```bash
     pip install -r requirements.txt
     ```
3. **Docker Issues**

   - Ensure Docker is installed and running.
   - Try rebuilding:
     ```bash
     docker-compose down
     docker-compose up --build
     ```
4. **Geocoding Failures**

   - Check addresses are valid or specific enough for `geopy`.
   - If `geopy` can’t resolve an address, that volunteer is skipped.
5. **Zero Matches**

   - Possibly no volunteers with overlapping skills or geocodable locations. The API may return an empty list or a `404` if the request doesn’t exist.

---

## 9. Notes for Flutter Integration

- CORS can be configured for cross-origin requests from Flutter.
- Example Flutter HTTP call:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> fetchMatchedVolunteers(int requestId) async {
  final response = await http.get(
    Uri.parse('http://localhost:8000/match/$requestId'),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    // handle data in your Flutter UI
  } else {
    print('Request failed: ${response.statusCode}');
  }
}
```

---

## 10. Contributors

- Casey Nguyen
- Kevin Pulikkottil
- Andy Jih
- Sawyer
