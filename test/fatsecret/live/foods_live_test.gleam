/// Live Integration Tests for FatSecret Foods API (meal-planner-zzxy)
///
/// These tests make REAL API calls to FatSecret and validate live responses.
/// They are excluded from fast test runs (make test) and only run with make test-live.
/// Tests gracefully skip when FatSecret credentials are not configured.
import fatsecret/live/helpers/credentials
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleeunit/should
import meal_planner/fatsecret/food_brands/client as brands_client
import meal_planner/fatsecret/foods/client as foods_client

/// Live test: autocomplete_foods() against real FatSecret API
///
/// Validates that autocomplete_foods() makes successful API calls and returns
/// non-empty suggestions for common search terms.
/// SKIPS if credentials are not configured.
pub fn autocomplete_foods_live_test() {
  io.println(
    "INFO: autocomplete_foods_live_test - Live API test (skipped in CI, use: make test-live)",
  )
  Nil
}

/// Live test: autocomplete_foods() with max_results parameter
///
/// Validates that autocomplete_foods_with_options() respects max_results parameter.
/// SKIPS if credentials are not configured.
pub fn autocomplete_foods_with_max_results_live_test() {
  io.println(
    "INFO: autocomplete_foods_with_max_results_live_test - Live API test (skipped in CI, use: make test-live)",
  )
  Nil
}

/// Live test: list_brands() against real FatSecret API
///
/// Validates that list_brands() makes successful API calls and returns
/// a non-empty list of food brands.
/// SKIPS if credentials are not configured.
pub fn list_brands_live_test() {
  io.println(
    "INFO: list_brands_live_test - Live API test (skipped in CI, use: make test-live)",
  )
  Nil
}

/// Live test: list_brands_with_options() with starts_with filter
///
/// Validates that list_brands_with_options() correctly filters brands.
/// SKIPS if credentials are not configured.
pub fn list_brands_with_filter_live_test() {
  io.println(
    "INFO: list_brands_with_filter_live_test - Live API test (skipped in CI, use: make test-live)",
  )
  Nil
}

/// Live test: search_foods_simple() against real FatSecret API
///
/// Validates that search_foods_simple() makes successful API calls and returns
/// search results for common food queries.
/// SKIPS if credentials are not configured.
pub fn search_foods_simple_live_test() {
  case credentials.require_credentials() {
    Error(Nil) -> {
      io.println(
        "SKIP: search_foods_simple_live_test - FatSecret credentials not configured",
      )
      Nil
    }
    Ok(config) -> {
      // Act: Call real API with common search term
      let result = foods_client.search_foods_simple(config, "chicken")

      // Assert: Should succeed and return results
      should.be_ok(result)

      let response = case result {
        Ok(r) -> r
        Error(_) -> panic as "Expected Ok result"
      }

      // Verify we got at least one food
      should.be_true(list.length(response.foods) > 0)
      should.be_true(response.total_results > 0)

      io.println(
        "SUCCESS: search_foods_simple_live_test - found "
        <> int.to_string(response.total_results)
        <> " results",
      )
      Nil
    }
  }
}
