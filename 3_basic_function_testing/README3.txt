README3.txt - Testing and Output

Testing the Matching System:

1. To run tests:
   make test
   - This runs pytest on test_matching.py

2. What the tests check:
   - Valid `/match/{request_id}` endpoints return status 200
   - Invalid request IDs (like 999) return appropriate errors
   - Matching logic: skills, location, availability

3. Example Output:
   When calling:
     GET http://localhost:8000/match/101

   You may receive a JSON like:
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

4. Test Summary:
   A typical passing test run will show:
   3_basic_function_testing/test_matching.py ..... [100%]

5. Notes:
   - Be sure to populate Firestore before testing
   - Make sure your serviceAccountKey.json is present