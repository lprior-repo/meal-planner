# FatSecret SDK Test Infrastructure

Comprehensive testing utilities for the FatSecret SDK, providing mock HTTP clients, realistic API fixtures, and helpful test assertions.

## Overview

This test infrastructure enables:
- **Fast unit tests** without network calls
- **Realistic API simulations** using actual FatSecret response formats
- **Comprehensive assertions** for common validation patterns
- **Edge case testing** for FatSecret quirks (single vs array results, numeric strings, etc.)

## Components

### 1. `http_mock.gleam` - Mock HTTP Client

A flexible mock system for simulating HTTP responses without making actual network requests.

#### Basic Usage

```gleam
import fatsecret/support/http_mock
import fatsecret/support/fixtures

pub fn my_test() {
  // Create mock client
  let client = http_mock.new()

  // Configure expected responses
  let client =
    client
    |> http_mock.expect(
      "foods.search",
      http_mock.json_response(200, fixtures.food_search_response()),
    )
    |> http_mock.expect(
      "food.get",
      http_mock.json_response(200, fixtures.food_response()),
    )

  // Make request
  let assert Ok(#(client, response)) =
    http_mock.make_request(
      client,
      "POST",
      "https://platform.fatsecret.com/rest/server.api?method=foods.search",
      dict.new(),
      "method=foods.search&search_expression=apple",
    )

  // Verify response
  response.status |> should.equal(200)

  // Verify calls were made
  client
  |> http_mock.assert_called("POST", "foods.search")
  |> should.be_true()
}
```

#### Error Simulation

```gleam
// Simulate API errors
let client =
  http_mock.new()
  |> http_mock.expect(
    "foods.search",
    http_mock.error_response(101, "Missing required parameter"),
  )

// Simulate network errors
let client =
  http_mock.new()
  |> http_mock.expect(
    "platform.fatsecret.com",
    http_mock.network_error(500, "Internal Server Error"),
  )

// Set default response for unmocked endpoints
let client =
  http_mock.new()
  |> http_mock.set_default(
    http_mock.error_response(404, "Method not found"),
  )
```

#### Call Verification

```gleam
// Get all recorded calls
let calls = http_mock.get_calls(client)
calls |> list.length |> should.equal(3)

// Assert specific call was made
client
|> http_mock.assert_called("POST", "foods.search")
|> should.be_true()

// Assert call with specific body
client
|> http_mock.assert_called_with_body("search_expression=apple")
|> should.be_true()

// Get last call
case http_mock.get_last_call(client) {
  Some(call) -> {
    call.method |> should.equal("POST")
    call.body |> should.contain("method=foods.search")
  }
  None -> should.fail()
}

// Count calls
http_mock.call_count(client) |> should.equal(5)

// Clear calls between tests
let client = http_mock.clear_calls(client)
```

### 2. `fixtures.gleam` - Realistic API Responses

Pre-built fixtures based on actual FatSecret API responses, including all edge cases.

#### Available Fixtures

##### Food API (food.get.v5)

```gleam
import fatsecret/support/fixtures

// Single serving (object format)
fixtures.food_response()

// Multiple servings (array format)
fixtures.food_multiple_servings_response()

// Branded food with brand_name
fixtures.branded_food_response()
```

##### Search API (foods.search.v3)

```gleam
// Multiple results (array format)
fixtures.food_search_response()

// Single result (object format) - Critical edge case!
fixtures.food_search_single_response()

// Branded results
fixtures.food_search_branded_response()

// Empty results
fixtures.empty_search_response()
```

##### Recipe API (recipe.get.v2)

```gleam
// Complete recipe with ingredients and directions
fixtures.recipe_response()
```

##### OAuth API

```gleam
// OAuth step 1: request token
fixtures.request_token_response()

// OAuth step 3: access token
fixtures.access_token_response()
```

##### User Profile API

```gleam
// User profile data
fixtures.profile_response()
```

##### Food Diary API

```gleam
// Food entries for a date
fixtures.food_entries_response()

// Empty diary
fixtures.empty_food_entries_response()
```

##### Error Responses

```gleam
// Custom error
fixtures.error_response(101, "Missing required parameter")

// Common errors
fixtures.missing_parameter_error()
fixtures.invalid_parameter_error()
fixtures.oauth_error()
fixtures.not_found_error()
```

#### Edge Cases Covered

1. **Single vs Array Results**: FatSecret returns an object for single results, array for multiple
2. **Numeric Strings**: All numbers are strings in FatSecret API
3. **Optional Fields**: Many nutrition fields are optional
4. **Branded vs Generic**: Different fields for branded foods

### 3. `test_helpers.gleam` - Test Utilities

Common helpers for building test data and making assertions.

#### Configuration Builders

```gleam
import fatsecret/support/test_helpers

// Test FatSecret config
let config = test_helpers.test_config()

// Custom config
let config = test_helpers.custom_test_config("my_key", "my_secret")

// Test access token
let token = test_helpers.test_access_token()
```

#### Test Data Builders

```gleam
// Build nutrition object
let nutrition = test_helpers.test_nutrition(
  calories: 100.0,
  carbs: 20.0,
  protein: 5.0,
  fat: 3.0,
)

// Complete nutrition with all fields
let nutrition = test_helpers.complete_nutrition()

// Build serving
let serving = test_helpers.test_serving(
  id: "12345",
  description: "1 cup",
  calories: 150.0,
)

// Build food
let food = test_helpers.test_food(
  id: "33691",
  name: "Apple",
  food_type: "Generic",
)

// Build search result
let result = test_helpers.test_search_result(
  id: "33691",
  name: "Apple",
  description: "Per 1 medium - Calories: 95kcal",
)
```

#### Assertions

```gleam
// Assert macros match
nutrition
|> test_helpers.assert_macros(
  calories: 95.0,
  carbs: 25.13,
  protein: 0.47,
  fat: 0.31,
)

// Assert serving values
serving
|> test_helpers.assert_serving(
  id: "12345",
  description: "1 cup",
  calories: 150.0,
)

// Assert food values
food
|> test_helpers.assert_food(
  id: "33691",
  name: "Apple",
  food_type: "Generic",
  serving_count: 1,
)

// Optional value assertions
nutrition.fiber
|> test_helpers.assert_some
|> should.equal(4.4)

nutrition.vitamin_d
|> test_helpers.assert_none

// List assertions
food.servings
|> test_helpers.assert_length(3)

search_results.foods
|> test_helpers.assert_not_empty

// String assertions
food.food_description
|> test_helpers.assert_contains("Calories:")

// Float comparison with tolerance
95.00001
|> test_helpers.assert_float_equal(95.0)
```

#### Parameter Builders

```gleam
// Build search parameters
let params =
  test_helpers.search_params("apple")
  |> test_helpers.with_max_results(20)
  |> test_helpers.with_page_number(0)

// Build food.get parameters
let params = test_helpers.food_get_params("33691")

// Build food_entries.get parameters
let params = test_helpers.food_entries_params("2025-12-14")
```

#### Validation Helpers

```gleam
// Validate food ID format
"33691"
|> test_helpers.is_valid_food_id
|> should.be_true()

// Validate serving ID
"12345"
|> test_helpers.is_valid_serving_id
|> should.be_true()

// Validate reasonable calories
95.0
|> test_helpers.are_reasonable_calories
|> should.be_true()

// Validate macros match calories (Atwater coefficients)
nutrition
|> test_helpers.macros_match_calories
|> should.be_true()
```

## Common Testing Patterns

### 1. Testing API Client Methods

```gleam
import fatsecret/support/fixtures
import fatsecret/support/http_mock
import fatsecret/support/test_helpers

pub fn search_foods_test() {
  // Setup
  let client =
    http_mock.new()
    |> http_mock.expect(
      "foods.search",
      http_mock.json_response(200, fixtures.food_search_response()),
    )

  let config = test_helpers.test_config()
  let params = test_helpers.search_params("apple")

  // Execute (would call your actual API client)
  // let result = foods_client.search(config, params)

  // Verify
  // result |> should.be_ok()
}
```

### 2. Testing Decoders

```gleam
import gleam/json
import fatsecret/support/fixtures

pub fn decode_food_response_test() {
  let json_str = fixtures.food_response()

  case json.parse(json_str, using: decoders.decode_food_response) {
    Ok(food) -> {
      food
      |> test_helpers.assert_food(
        id: "33691",
        name: "Apple",
        food_type: "Generic",
        serving_count: 1,
      )
    }
    Error(_) -> should.fail()
  }
}
```

### 3. Testing Edge Cases

```gleam
// Test single vs array results
pub fn single_result_edge_case_test() {
  let single = fixtures.food_search_single_response()
  let multiple = fixtures.food_search_response()

  // Both should decode correctly
  json.parse(single, using: decoders.decode_food_search_response)
  |> should.be_ok()

  json.parse(multiple, using: decoders.decode_food_search_response)
  |> should.be_ok()
}
```

### 4. Testing Error Handling

```gleam
pub fn api_error_handling_test() {
  let client =
    http_mock.new()
    |> http_mock.expect(
      "foods.search",
      http_mock.error_response(101, "Missing required parameter"),
    )

  // Your API client should detect and handle the error
  // let result = foods_client.search(config, dict.new())
  // result |> should.be_error()
}
```

## Best Practices

1. **Use fixtures for realistic data**: Don't hand-craft JSON - use fixtures to ensure you're testing against actual API formats

2. **Test edge cases**: FatSecret has many quirks (single vs array, numeric strings). Use fixtures that cover these

3. **Verify all calls**: Use `assert_called` to ensure your code makes the right requests

4. **Test error paths**: Use `error_response` and `network_error` to test failure handling

5. **Use builders for test data**: Use `test_*` helpers to create consistent test objects

6. **Validate business logic**: Use `macros_match_calories` and other validators to ensure data makes sense

## Examples

See `integration_example_test.gleam` for complete working examples of all features.

## FatSecret API Quirks

This test infrastructure helps you handle FatSecret's unique behaviors:

1. **Single vs Array Results**:
   - One result → `{"food": {...}}`
   - Multiple → `{"food": [...]}`
   - Use fixtures to test both cases

2. **Numeric Strings**:
   - All numbers are strings: `"95.0"` not `95.0`
   - Decoders must handle both formats
   - Use `decode_nutrition` helpers

3. **Optional Fields**:
   - Many nutrition fields can be missing
   - Test with both complete and minimal fixtures

4. **Brand vs Generic**:
   - Generic: no `brand_name` field
   - Brand: has `brand_name` field
   - Test both with appropriate fixtures

## Adding New Fixtures

When adding new fixtures:

1. Copy actual API responses (use curl or Postman)
2. Preserve exact formatting (single vs array, strings vs numbers)
3. Document what case it represents
4. Add example usage in comments

Example:
```gleam
/// Food response with international characters
///
/// Tests proper UTF-8 handling in food names and descriptions.
pub fn international_food_response() -> String {
  "{
    \"food\": {
      \"food_id\": \"999\",
      \"food_name\": \"Crème Brûlée\",
      ...
    }
  }"
}
```
