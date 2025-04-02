# Crowdsourced Disaster Relief Platform

## Overview

This project is a **full-stack** Crowdsourced Disaster Relief Platform. It matches disaster relief requests with suitable volunteers based on **skills** and  **geographic proximity** , providing a centralized system where victims can request help, volunteers can register, and organizations can coordinate relief efforts.

* **Frontend** : Built with Flutter (mobile or web), providing user-facing features such as request submission, volunteer registration, live maps, and more.
* **Backend** : Implemented in Python using FastAPI, PostgreSQL, and SQLAlchemy. It applies **AI-powered matching** with scikit-learn’s K-Nearest Neighbors algorithm, enhanced by **geocoding** (via geopy) and **one-hot encoding** for volunteer skills.

### Key AI Matching Enhancements

1. **Geocoding** : Uses geopy to convert volunteer/request location strings into latitude/longitude.
2. **One-Hot Encoding** : Transforms volunteer skill sets into numerical vectors based on a predefined `KNOWN_SKILLS` list.
3. **Standard Scaling** : Applies sklearn’s StandardScaler to unify numeric features.
4. **Robust Error Handling** : Volunteers with unresolvable addresses are gracefully skipped; 404s or empty lists if no valid matches exist.

---

## Table of Contents

1. Tech Stack
2. Prerequisites
3. **Step-by-Step: Run & Test the Project**
4. Running the Backend (Detailed)
5. Populating the Database
6. Testing the Backend (Detailed)
7. Docker Deployment (Optional)
8. Flutter Frontend Notes
9. Troubleshooting
10. Contributors

---

## 1. Tech Stack

* **Frontend** : Flutter (mobile or web)
* **Backend** : FastAPI (Python)
* **Database** : PostgreSQL
* **ORM** : SQLAlchemy
* **AI Matching** : scikit-learn (K-Nearest Neighbors + geocoding + one-hot encoding)
* **Containerization** : Docker & Docker Compose (optional)

---

## 2. Prerequisites

1. **Python 3.9+**
2. **PostgreSQL** installed locally or accessible remotely
3. **Flutter** (if you plan to run or modify the frontend)
4. **Docker** (optional, if you want to containerize the entire project)

You should also have the Python libraries from `requirements.txt` installed:

* fastapi
* uvicorn
* sqlalchemy
* psycopg2-binary
* scikit-learn
* numpy
* geopy
* pydantic

  (etc.)

---

## 3. Step-by-Step: Run & Test the Project

Use these quick steps if you’re new to the repo:

1. **Clone the Repository**

   ```bash
   git clone <repository-url>
   cd <repository-folder>
   ```
2. **Create a Python Virtual Environment** (optional but recommended):

   ```bash
   python -m venv venv
   source venv/bin/activate  # macOS/Linux
   # or on Windows:
   venv\Scripts\activate
   ```
3. **Install Dependencies**

   ```bash
   pip install -r requirements.txt
   ```

   This ensures you have FastAPI, geopy, scikit-learn, etc.
4. **Set Up PostgreSQL**

   * Make sure PostgreSQL is running on your machine or in Docker.
   * Create the DB:
     ```sql
     CREATE DATABASE disaster_relief;
     CREATE USER postgres WITH PASSWORD 'password';
     ALTER DATABASE disaster_relief OWNER TO postgres;
     ```
   * Update `DATABASE_URL` in your code or environment if needed.
5. **Run the Backend**

   ```bash
   uvicorn main:app --reload
   ```

   * Visit [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs) to confirm it’s running.
6. **Populate Sample Data** (optional)

   ```bash
   python 2_data_collection/populate_database.py
   ```

   This script seeds your DB with volunteers/requests for testing.
7. **Test the Matching Endpoint**

   * Try a known request ID via curl/Postman:
     ```bash
     curl http://127.0.0.1:8000/match/101
     ```
   * If successful, you’ll see a JSON list of matched volunteers.
8. **Run Automated Tests** (if available)

   ```bash
   python 3_basic_function_testing/test_matching.py
   ```

   * Ensures the KNN matching and endpoints behave correctly.
9. **(Optional) Flutter Frontend**

   * Go to your Flutter folder, run `flutter pub get`, then `flutter run` (or build for web).
   * Update your Flutter code’s base URL to match `http://127.0.0.1:8000` (or wherever your backend is hosted).

With these steps, you’ll have a running backend and can see how volunteer matching works via geocoding + one-hot encoding.

---

## 4. Running the Backend (Detailed)

1. **Ensure PostgreSQL is Running**
   * On macOS, you might install and start it via Homebrew.
   * On Windows, use the official installer or Docker.
2. **Launch FastAPI**
   ```bash
   uvicorn main:app --reload
   ```
3. **Interactive API**
   * Check [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs).
   * You can test endpoints directly there.

---

## 5. Populating the Database

### (A) Create the Database

If you haven’t already, open your psql shell (or a GUI) and run:

```sql
CREATE DATABASE disaster_relief;
CREATE USER postgres WITH PASSWORD 'password';
ALTER DATABASE disaster_relief OWNER TO postgres;
```

### (B) Auto-Creation / Migration

If your code auto-creates tables on startup, you’re good. Otherwise, run any migration scripts if needed.

### (C) Insert Sample Data

From the project’s `2_data_collection` folder, run:

```bash
python populate_database.py
```

This seeds your DB with basic volunteers and requests that have various location strings and skills.

---

## 6. Testing the Backend (Detailed)

### (A) Automated Script

If you have `test_matching.py` or similar in `3_basic_function_testing`:

```bash
python 3_basic_function_testing/test_matching.py
```

Look for output indicating success (matched volunteers) or 404 errors if a request doesn’t exist.

### (B) Manual Testing

Using `curl` or Postman:

```bash
curl http://127.0.0.1:8000/match/101
```

If `101` is a valid request in your DB, you’ll get a JSON response with matched volunteers.

 **What Happens Internally** :

1. The request’s location is geocoded to lat/long (if possible).
2. Each volunteer’s location is also geocoded.
3. Skills are encoded via a `KNOWN_SKILLS` list in `main.py`, using scikit-learn’s OneHotEncoder.
4. Everything is scaled by StandardScaler so that distance computations consider both location and skill similarities.
5. KNN returns the closest matches.

---

## 7. Docker Deployment (Optional)

### (A) Build & Run with Docker Compose

```bash
docker-compose up --build
```

This typically spins up:

* A PostgreSQL container on port 5432
* The FastAPI container at port 8000

### (B) Verify

* **API** : Check [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs).
* **Database** : Use psql or the logs to confirm the DB is running.

---

## 8. Flutter Frontend Notes

* The Flutter app can live in a separate folder (e.g., `frontend/`).
* Run `flutter pub get`, then `flutter run` to start it.
* In your Dart code, set the base URL to point to [http://127.0.0.1:8000](http://127.0.0.1:8000) (or your chosen host).
* For iOS/Android emulators, you might need `10.0.2.2:8000` or `127.0.0.1:8000` depending on your environment.

Example Flutter snippet:

```dart
final response = await http.get(Uri.parse('http://127.0.0.1:8000/match/$requestId'));
if (response.statusCode == 200) {
  final data = json.decode(response.body);
  // do something with "data"
}
```

---

## 9. Troubleshooting

1. **Database Connection Error**
   * Confirm PostgreSQL is running, and your `DATABASE_URL` is correct.
2. **Missing Dependencies**
   * Run `pip install -r requirements.txt` again.
3. **Docker Issues**
   * Ensure Docker Desktop or daemon is running.
   * Rebuild containers if needed:
     ```bash
     docker-compose down
     docker-compose up --build
     ```
4. **Geocoding Failures**
   * If `geopy` can’t parse the address, the volunteer or request location is skipped.
5. **No Volunteers Matched**
   * Possibly none share the needed skills or have valid lat/long data.

---

## 10. Contributors

* Casey Nguyen
* Kevin Pulikkottil
* Andy Jih
* Sawyer
