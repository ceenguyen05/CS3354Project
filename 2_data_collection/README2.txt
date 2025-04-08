README2.txt - Setup Instructions

To get the project running on your local machine, follow these steps:

1. Clone the repository:
   git clone https://github.com/Sawyer-Anderson1/CS_3354_Team_2_Project.git
   cd CS_3354_Team_2_Project

2. Run initial setup:
   make setup
   - Creates a virtual environment inside 1_code/venv/
   - Installs all dependencies from requirements.txt

3. Firebase Credentials:
   - Download your Firebase service account key
   - Rename it to serviceAccountKey.json
   - Place it in the 1_code/ directory

4. Populate the Firestore database:
   make populate-db
   - Clears existing documents and uploads sample requests and volunteers

5. Run the application:
   make run
   - FastAPI will launch at http://localhost:8000
   - Swagger UI available at http://localhost:8000/docs

6. Run tests:
   make test
   - Executes test_matching.py to verify match logic

7. Docker (optional):
   - Make sure Docker Desktop is running
   - Build and start containers:
     make docker-up
   - Stop Docker services:
     make docker-down