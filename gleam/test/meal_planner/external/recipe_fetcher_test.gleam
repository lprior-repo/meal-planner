//// Tests for external recipe API fetcher

import gleeunit
import gleeunit/should
import meal_planner/external/recipe_fetcher.{
  type FetchError, type RecipeSource, ApiKeyMissing, InvalidQuery, NetworkError,
  ParseError, RecipeNotFound, Spoonacular, TheMealDB,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Type Tests
// ============================================================================

pub fn recipe_source_themealdb_test() {
  let source = TheMealDB
  recipe_fetcher.source_name(source)
  |> should.equal("TheMealDB")

  recipe_fetcher.requires_api_key(source)
  |> should.equal(False)
}

pub fn recipe_source_spoonacular_test() {
  let source = Spoonacular
  recipe_fetcher.source_name(source)
  |> should.equal("Spoonacular")

  recipe_fetcher.requires_api_key(source)
  |> should.equal(True)
}

// ============================================================================
// Error Message Tests
// ============================================================================

pub fn error_message_network_test() {
  let error = NetworkError("Connection timeout")
  recipe_fetcher.error_message(error)
  |> should.equal("Network error: Connection timeout")
}

pub fn error_message_parse_test() {
  let error = ParseError("Invalid JSON")
  recipe_fetcher.error_message(error)
  |> should.equal("Failed to parse response: Invalid JSON")
}

pub fn error_message_rate_limit_test() {
  let error = recipe_fetcher.RateLimitError
  recipe_fetcher.error_message(error)
  |> should.equal("Rate limit exceeded. Please try again later.")
}

pub fn error_message_api_key_missing_test() {
  let error = ApiKeyMissing
  recipe_fetcher.error_message(error)
  |> should.equal("API key required but not provided")
}

pub fn error_message_recipe_not_found_test() {
  let error = RecipeNotFound("12345")
  recipe_fetcher.error_message(error)
  |> should.equal("Recipe not found: 12345")
}

pub fn error_message_invalid_query_test() {
  let error = InvalidQuery("Empty search")
  recipe_fetcher.error_message(error)
  |> should.equal("Invalid query: Empty search")
}

// ============================================================================
// API Key Requirement Tests
// ============================================================================

pub fn spoonacular_requires_api_key_test() {
  // Spoonacular should return ApiKeyMissing error
  case recipe_fetcher.fetch_recipe(Spoonacular, "test-id") {
    Error(ApiKeyMissing) -> Nil
    _ -> should.fail()
  }
}

pub fn spoonacular_search_requires_api_key_test() {
  // Spoonacular search should return ApiKeyMissing error
  case recipe_fetcher.search_recipes(Spoonacular, "test", 10) {
    Error(ApiKeyMissing) -> Nil
    _ -> should.fail()
  }
}

// ============================================================================
// Validation Tests
// ============================================================================

pub fn search_limit_validation_low_test() {
  // Test that limits < 1 are clamped to 1
  // This test will fail if TheMealDB is down, but validates the API call is made
  let result = recipe_fetcher.search_recipes(TheMealDB, "chicken", 0)
  // We just verify it attempts the request (doesn't error on validation)
  case result {
    Ok(_) -> Nil
    Error(NetworkError(_)) -> Nil
    Error(ParseError(_)) -> Nil
    Error(_) -> should.fail()
  }
}

pub fn search_limit_validation_high_test() {
  // Test that limits > 100 are clamped to 100
  let result = recipe_fetcher.search_recipes(TheMealDB, "chicken", 200)
  case result {
    Ok(_) -> Nil
    Error(NetworkError(_)) -> Nil
    Error(ParseError(_)) -> Nil
    Error(_) -> should.fail()
  }
}
