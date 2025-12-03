# Integration Tests for Food Search API

## Overview

The integration tests in `food_search_api_integration_test.gleam` verify the complete request/response cycle for the `/api/foods/search` endpoint.

## Test Coverage

The test suite covers:

1. **Successful Searches**
   - Valid search returns 200 with results
   - Common foods return USDA results
   - Minimum/maximum valid limits work

2. **Validation Errors**
   - Empty query returns 400
   - Short query (< 2 chars) returns 400
   - Excessive limit (> 100) returns 400
   - Negative/zero limit returns 400
   - Invalid JSON returns 400
   - Missing required fields returns 400

3. **Pagination & Limits**
   - Results respect limit parameter
   - Count fields are accurate

4. **Edge Cases**
   - Special characters handled properly
   - GET method returns 405
   - Custom foods ordered before USDA foods

## Running the Tests

### Prerequisites

1. **Database Setup**
   ```bash
   # Initialize the database with migrations
   cd /home/lewis/src/meal-planner
   ./scripts/init-database.sh
   ```

2. **Load Test Data**
   ```bash
   # The database needs USDA food data for meaningful tests
   # This should be loaded during initialization
   ```

3. **Start the Server**
   ```bash
   cd gleam
   gleam run
   # Server should be running on http://localhost:8080
   ```

### Running Unit Tests

The unit tests in `food_search_test.gleam` test the search logic without requiring a database:

```bash
cd gleam
gleam test
```

### Running Integration Tests Manually

Since the integration tests require a live server and database, they are currently implemented as documented test cases. You can verify them manually using:

```bash
# Use the provided test script
/tmp/test_food_search.sh

# Or use curl directly
curl -X POST http://localhost:8080/api/foods/search \
  -H "Content-Type: application/json" \
  -d '{"query": "chicken", "limit": 10}' \
  | python3 -m json.tool
```

### Future: Automated Integration Tests

To make these tests fully automated, we need:

1. **HTTP Client Library**
   - Add `gleam_httpc` or similar to dependencies
   - Create test helper functions for making requests

2. **Test Database**
   - Setup/teardown scripts for test database
   - Seed with known test data

3. **Test Server**
   - Start server programmatically in tests
   - Use random port to avoid conflicts

4. **JSON Assertions**
   - Parse and validate response structure
   - Assert on specific fields and values

## Test Structure

Each test follows this pattern:

```gleam
pub fn test_name_test() {
  // 1. Setup (if needed)
  
  // 2. Make HTTP request to endpoint
  
  // 3. Assert response status code
  
  // 4. Assert response headers
  
  // 5. Parse and assert response body
  
  // 6. Cleanup (if needed)
}
```

## Expected API Behavior

### Successful Request

**Request:**
```json
POST /api/foods/search
Content-Type: application/json

{
  "query": "chicken",
  "limit": 10
}
```

**Response:**
```json
HTTP/1.1 200 OK
Content-Type: application/json

{
  "results": [
    {
      "fdc_id": 171477,
      "description": "Chicken, broilers or fryers, breast, meat only, raw",
      "data_type": "sr_legacy_food",
      "category": "Poultry Products"
    }
  ],
  "total_count": 10,
  "custom_count": 0,
  "usda_count": 10
}
```

### Validation Error

**Request:**
```json
POST /api/foods/search
Content-Type: application/json

{
  "query": "",
  "limit": 10
}
```

**Response:**
```json
HTTP/1.1 400 Bad Request
Content-Type: application/json

{
  "error": "Invalid query",
  "details": "Query must be at least 2 characters"
}
```

## Contributing

When adding new API features:

1. Add integration test cases to this file
2. Document expected behavior in comments
3. Update this README with new test coverage
4. Create manual test scripts if needed

## Related Files

- Implementation: `gleam/src/meal_planner/web.gleam:1620` (api_foods_search)
- Unit Tests: `gleam/test/meal_planner/food_search_test.gleam`
- Manual Test Script: `/tmp/test_food_search.sh`
- API Spec: See bead notes for meal-planner-0uf
