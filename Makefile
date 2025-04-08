# make setup         # One-time setup: create venv & install dependencies
# make run           # Run FastAPI backend from 1_code/main.py
# make test          # Run backend tests from 3_basic_function_testing/
# make populate-db   # Populate the database with initial data
# make docker-up     # Build and start Docker containers
# make docker-down   # Stop Docker containers
# make clean         # Remove __pycache__ directories

.PHONY: run setup test docker-up docker-down clean populate-db

# Path to the virtual environment
VENV_DIR=1_code/venv
ACTIVATE=. $(VENV_DIR)/bin/activate;

# FastAPI app entry point
APP=1_code.main:app

# Requirements file
REQS=requirements.txt

# Default target: run the FastAPI server
run:
	GOOGLE_APPLICATION_CREDENTIALS=1_code/serviceAccountKey.json $(ACTIVATE) uvicorn $(APP) --reload

# Set up virtual environment and install dependencies
setup:
	python3 -m venv $(VENV_DIR)
	$(ACTIVATE) pip install --upgrade pip
	$(ACTIVATE) pip install -r $(REQS)

# Run unit tests (if they exist in 3_basic_function_testing/)
test:
	$(ACTIVATE) pytest 3_basic_function_testing/

# Populate the database with initial data
populate-db:
	GOOGLE_APPLICATION_CREDENTIALS=1_code/serviceAccountKey.json $(ACTIVATE) python 1_code/scripts/populate_database.py

# Run Docker containers
docker-up:
	docker-compose up --build

# Tear down Docker containers
docker-down:
	docker-compose down

# Clean up __pycache__ and other generated files
clean:
	find . -type d -name '__pycache__' -exec rm -r {} +