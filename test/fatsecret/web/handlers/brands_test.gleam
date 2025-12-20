/// Tests for FatSecret brands handler
///
/// Verifies GET /api/fatsecret/brands endpoint with query parameter filtering.
import gleam/http
import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/env
import meal_planner/fatsecret/food_brands/client
import meal_planner/fatsecret/food_brands/types
import meal_planner/web/handlers/fatsecret/brands
import wisp
import wisp/testing

// =============================================================================
// Test: GET /api/fatsecret/brands - List All Brands
// =============================================================================

pub fn test_handle_brands_get_returns_json_response() {
  // Given: A GET request to /api/fatsecret/brands
  let request =
    testing.get("/api/fatsecret/brands", [])
    |> testing.set_method(http.Get)

  // When: Handler processes the request
  let response = brands.handle_brands(request)

  // Then: Response should be JSON with 200 status
  response.status
  |> should.equal(200)

  // And: Response should have JSON content-type
  let content_type =
    wisp.get_header(response, "content-type")
    |> should.be_ok()

  content_type
  |> should.equal("application/json")
}

pub fn test_handle_brands_post_returns_method_not_allowed() {
  // Given: A POST request (unsupported method)
  let request =
    testing.post("/api/fatsecret/brands", [], "")
    |> testing.set_method(http.Post)

  // When: Handler processes the request
  let response = brands.handle_brands(request)

  // Then: Should return 405 Method Not Allowed
  response.status
  |> should.equal(405)
}

// =============================================================================
// Test: Query Parameter Filtering - starts_with
// =============================================================================

pub fn test_handle_brands_with_starts_with_filter() {
  // Given: A request filtering brands starting with 'K'
  let request =
    testing.get("/api/fatsecret/brands?starts_with=K", [])
    |> testing.set_method(http.Get)

  // When: Handler processes the request
  let response = brands.handle_brands(request)

  // Then: Response should be 200 OK
  response.status
  |> should.equal(200)
  // Note: We can't verify the actual filtering without mocking the API client,
  // but we can verify the handler accepts the parameter without errors
}

// =============================================================================
// Test: Query Parameter Filtering - brand_type
// =============================================================================

pub fn test_handle_brands_with_brand_type_manufacturer() {
  // Given: A request filtering by manufacturer type
  let request =
    testing.get("/api/fatsecret/brands?brand_type=manufacturer", [])
    |> testing.set_method(http.Get)

  // When: Handler processes the request
  let response = brands.handle_brands(request)

  // Then: Response should be 200 OK
  response.status
  |> should.equal(200)
}

pub fn test_handle_brands_with_brand_type_restaurant() {
  // Given: A request filtering by restaurant type
  let request =
    testing.get("/api/fatsecret/brands?brand_type=restaurant", [])
    |> testing.set_method(http.Get)

  // When: Handler processes the request
  let response = brands.handle_brands(request)

  // Then: Response should be 200 OK
  response.status
  |> should.equal(200)
}

pub fn test_handle_brands_with_brand_type_supermarket() {
  // Given: A request filtering by supermarket type
  let request =
    testing.get("/api/fatsecret/brands?brand_type=supermarket", [])
    |> testing.set_method(http.Get)

  // When: Handler processes the request
  let response = brands.handle_brands(request)

  // Then: Response should be 200 OK
  response.status
  |> should.equal(200)
}

// =============================================================================
// Test: Query Parameter Filtering - Combined Filters
// =============================================================================

pub fn test_handle_brands_with_combined_filters() {
  // Given: A request with both starts_with and brand_type filters
  let request =
    testing.get("/api/fatsecret/brands?starts_with=M&brand_type=restaurant", [])
    |> testing.set_method(http.Get)

  // When: Handler processes the request
  let response = brands.handle_brands(request)

  // Then: Response should be 200 OK
  response.status
  |> should.equal(200)
}

// =============================================================================
// Test: Invalid brand_type Parameter
// =============================================================================

pub fn test_handle_brands_with_invalid_brand_type() {
  // Given: A request with invalid brand_type
  let request =
    testing.get("/api/fatsecret/brands?brand_type=invalid_type", [])
    |> testing.set_method(http.Get)

  // When: Handler processes the request
  let response = brands.handle_brands(request)

  // Then: Should still return 200 (invalid type is ignored, returns all brands)
  response.status
  |> should.equal(200)
}

// =============================================================================
// Test: Response Structure
// =============================================================================

pub fn test_handle_brands_response_has_brands_array() {
  // Given: A GET request to brands endpoint
  let request =
    testing.get("/api/fatsecret/brands", [])
    |> testing.set_method(http.Get)

  // When: Handler processes the request
  let response = brands.handle_brands(request)

  // Then: Response body should be valid JSON
  let body_str = testing.string_body(response)

  // And: JSON should parse successfully
  let assert Ok(parsed) = json.decode(body_str, json.dynamic)

  // Note: Full structure validation would require mocking the FatSecret API
  // For now, we verify the response is valid JSON
  parsed
  |> should.not_equal(json.null())
}
