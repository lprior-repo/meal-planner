/// Integration test example showing how to use the test infrastructure
///
/// This demonstrates:
/// - Using http_mock for API testing
/// - Using fixtures for realistic responses
/// - Using test_helpers for assertions
import meal_planner/fatsecret/support/fixtures
import meal_planner/fatsecret/support/http_mock
import meal_planner/fatsecret/support/test_helpers
import gleam/dict
import gleam/string
import gleeunit/should

// ============================================================================
// Mock HTTP Client Examples
// ============================================================================

pub fn mock_client_basic_test() {
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

  // Simulate requests
  let assert Ok(#(client, response1)) =
    http_mock.make_request(
      client,
      "POST",
      "https://platform.fatsecret.com/rest/server.api?method=foods.search",
      dict.new(),
      "method=foods.search&search_expression=apple",
    )

  // Verify response
  response1.status
  |> should.equal(200)

  response1.body
  |> should.equal(fixtures.food_search_response())

  // Simulate second request
  let assert Ok(#(client, response2)) =
    http_mock.make_request(
      client,
      "POST",
      "https://platform.fatsecret.com/rest/server.api?method=food.get",
      dict.new(),
      "method=food.get&food_id=33691",
    )

  response2.status
  |> should.equal(200)

  // Verify calls were recorded
  http_mock.call_count(client)
  |> should.equal(2)

  http_mock.assert_called(client, "POST", "foods.search")
  |> should.be_true()

  http_mock.assert_called(client, "POST", "food.get")
  |> should.be_true()
}

pub fn mock_client_error_handling_test() {
  let client =
    http_mock.new()
    |> http_mock.expect(
      "foods.search",
      http_mock.error_response(101, "Missing required parameter"),
    )

  let assert Ok(#(_client, response)) =
    http_mock.make_request(
      client,
      "POST",
      "https://platform.fatsecret.com/rest/server.api?method=foods.search",
      dict.new(),
      "method=foods.search",
    )

  // Even errors return 200 status in FatSecret API
  response.status
  |> should.equal(200)

  // But body contains error
  response.body
  |> should.equal(fixtures.missing_parameter_error())
}

pub fn mock_client_network_error_test() {
  let client =
    http_mock.new()
    |> http_mock.expect(
      "platform.fatsecret.com",
      http_mock.network_error(500, "Internal Server Error"),
    )

  let assert Ok(#(_client, response)) =
    http_mock.make_request(
      client,
      "POST",
      "https://platform.fatsecret.com/rest/server.api",
      dict.new(),
      "method=foods.search",
    )

  response.status
  |> should.equal(500)
}

pub fn mock_client_default_response_test() {
  let client =
    http_mock.new()
    |> http_mock.set_default(http_mock.error_response(404, "Method not found"))

  // Request unmocked endpoint
  let assert Ok(#(_client, response)) =
    http_mock.make_request(
      client,
      "POST",
      "https://platform.fatsecret.com/rest/server.api?method=unknown",
      dict.new(),
      "method=unknown",
    )

  // Should get default response
  response.body
  |> test_helpers.assert_contains("404")
}

// ============================================================================
// Fixture Examples
// ============================================================================

pub fn fixtures_food_response_test() {
  let json = fixtures.food_response()

  // Should be valid JSON
  json
  |> test_helpers.assert_contains("\"food_id\":")

  json
  |> test_helpers.assert_contains("\"food_name\":")

  json
  |> test_helpers.assert_contains("\"servings\":")
}

pub fn fixtures_search_single_vs_multiple_test() {
  let single = fixtures.food_search_single_response()
  let multiple = fixtures.food_search_response()

  // Single result has object
  single
  |> test_helpers.assert_contains("\"food\": {")

  // Multiple results have array
  multiple
  |> test_helpers.assert_contains("\"food\": [")
}

pub fn fixtures_error_responses_test() {
  let error = fixtures.error_response(101, "Test error")

  error
  |> test_helpers.assert_contains("\"error\":")

  error
  |> test_helpers.assert_contains("\"code\": 101")

  error
  |> test_helpers.assert_contains("Test error")
}

// ============================================================================
// Test Helper Examples
// ============================================================================

pub fn test_helpers_builders_test() {
  let config = test_helpers.test_config()
  config.consumer_key
  |> should.equal("test_consumer_key")

  let token = test_helpers.test_access_token()
  token.oauth_token
  |> should.equal("test_token")

  let nutrition =
    test_helpers.test_nutrition(
      calories: 100.0,
      carbs: 20.0,
      protein: 5.0,
      fat: 3.0,
    )
  nutrition.calories
  |> should.equal(100.0)
}

pub fn test_helpers_assertions_test() {
  let nutrition =
    test_helpers.test_nutrition(
      calories: 95.0,
      carbs: 25.13,
      protein: 0.47,
      fat: 0.31,
    )

  // Macro assertions
  nutrition
  |> test_helpers.assert_macros(
    calories: 95.0,
    carbs: 25.13,
    protein: 0.47,
    fat: 0.31,
  )

  // Float equality with tolerance
  95.00001
  |> test_helpers.assert_float_equal(95.0)
}

pub fn test_helpers_validation_test() {
  // Valid food ID
  "33691"
  |> test_helpers.is_valid_food_id
  |> should.be_true()

  // Invalid food ID
  "abc"
  |> test_helpers.is_valid_food_id
  |> should.be_false()

  // Reasonable calories
  95.0
  |> test_helpers.are_reasonable_calories
  |> should.be_true()

  // Unreasonable calories
  99_999.0
  |> test_helpers.are_reasonable_calories
  |> should.be_false()
}

pub fn test_helpers_macro_validation_test() {
  let nutrition =
    test_helpers.test_nutrition(
      // Apple: 95 cal should match ~95 cal from macros
      // Carbs: 25.13g * 4 = 100.52
      // Protein: 0.47g * 4 = 1.88
      // Fat: 0.31g * 9 = 2.79
      // Total = 105.19 (within 10% tolerance of 95)
      calories: 95.0,
      carbs: 25.13,
      protein: 0.47,
      fat: 0.31,
    )

  nutrition
  |> test_helpers.macros_match_calories
  |> should.be_true()
}

// ============================================================================
// Complete Integration Example
// ============================================================================

pub fn complete_test_flow_test() {
  // 1. Setup mock client with fixture
  let client =
    http_mock.new()
    |> http_mock.expect(
      "foods.search",
      http_mock.json_response(200, fixtures.food_search_response()),
    )

  // 2. Make request
  let params =
    test_helpers.search_params("apple")
    |> test_helpers.with_max_results(20)

  let url = "https://platform.fatsecret.com/rest/server.api?method=foods.search"
  let body = "method=foods.search&search_expression=apple&max_results=20"

  let assert Ok(#(client, response)) =
    http_mock.make_request(client, "POST", url, dict.new(), body)

  // 3. Verify response
  response.status
  |> should.equal(200)

  response.body
  |> test_helpers.assert_contains("\"food_id\":")

  // 4. Verify calls
  client
  |> http_mock.assert_called("POST", "foods.search")
  |> should.be_true()

  client
  |> http_mock.assert_called_with_body("search_expression=apple")
  |> should.be_true()
}
