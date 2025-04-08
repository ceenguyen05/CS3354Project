# CS 3354 Team 2 Project: Crowdsourced Disaster Relief Platform - AI Matching Backend

This project is a FastAPI-based volunteer/request matching system that interacts with a Firestore database. It includes a backend service, database population scripts, unit tests, and optional Docker support.

---

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/Sawyer-Anderson1/CS_3354_Team_2_Project.git
cd CS_3354_Team_2_Project
```

### 2. Set Up Your Environment

```bash
make setup
```

This will:

- Create a virtual environment at `1_code/venv/`
- Install all dependencies from `requirements.txt`

---

## Firebase Setup

1. **Download** your Firebase service account key JSON file.
2. **Place it** in the `1_code/` directory.
3. **Ensure the filename is:** `serviceAccountKey.json`

> This file is excluded from Git using `.gitignore` and must be added manually.

---

## Running the Backend Server (Locally)

```bash
make run
```

This:

- Activates the virtual environment
- Sets the `GOOGLE_APPLICATION_CREDENTIALS` variable
- Starts the FastAPI server at [http://localhost:8000](http://localhost:8000)

---

## Running Tests

To test `/match/{request_id}`:

```bash
make test
```

This:

- Uses `pytest` to run `test_matching.py`
- Validates matching logic (including error response for invalid ID)

**Sample output:**

```bash
3_basic_function_testing/test_matching.py ..... [100%]
```

---

## Populate the Firestore Database

```bash
make populate-db
```

This will:

- Connect to Firebase using the service key
- Clear existing `volunteers` and `requests` documents
- Upload 7 volunteers and 6 requests

---

## Docker (Optional)

> You **must** have Docker Desktop running before using these commands.

### Start the server in Docker:

```bash
make docker-up
```

If Docker Desktop isn't running, you might see:

```
❌ Docker daemon is not running. Please start Docker Desktop first.
make: *** [docker-up] Error 1
```

Make sure Docker Desktop is open, then retry.

### Stop the container:

```bash
ctrl c
make docker-down
```

---

## Project Structure

```
CS_3354_Team_2_Project/
├── 1_code/
│   ├── main.py                  # FastAPI app
│   ├── docker-compose.yml       # Docker configuration
│   ├── serviceAccountKey.json   # Firebase credentials (excluded)
│   └── venv/                    # Python virtual environment (excluded)
├── 2_data_collection/
│   └── populate_database.py     # Firestore data uploader
├── 3_basic_function_testing/
│   └── test_matching.py         # API test cases
├── Makefile                     # CLI shortcuts
├── requirements.txt             # Python deps
├── .gitignore                   # Keeps secrets and junk out of Git
└── README.md                    # You are here!
```

---

## Cleaning Up

To delete `__pycache__` folders and other auto-generated junk:

```bash
make clean
```

---

## Sample API Output

```http
GET http://localhost:8000/match/101
```

```json
{
  "matched_volunteers": [
    {
      "id": "Ez7DJu4ZGrTljzHbiazy",
      "name": "Alice",
      "skills": "Medical",
      "location": "Houston, TX"
    },
    {
      "id": "AbozkwHssJX2zBEWlLXb",
      "name": "Ethan",
      "skills": "Medical",
      "location": "Fort Worth, TX"
    },
    {
      "id": "CNMZLygFonduGYU06vrg",
      "name": "Fiona",
      "skills": "Transportation",
      "location": "Houston, TX"
    }
  ]
}
```

---

## Notes

- The `Makefile` streamlines most tasks.
- Be sure `Docker Desktop` is running for Docker commands to succeed.
- Your `serviceAccountKey.json` must **never be committed to Git**.
