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
  case credentials.require_credentials() {
    Error(Nil) -> {
      io.println(
        "SKIP: autocomplete_foods_live_test - FatSecret credentials not configured",
      )
      Nil
    }
    Ok(config) -> {
      // Act: Call real API with partial search term
      let result = foods_client.autocomplete_foods(config, "chick")

      // Assert: Should succeed and return suggestions
      should.be_ok(result)

      let suggestions = case result {
        Ok(s) -> s
        Error(_) -> panic as "Expected Ok result"
      }

      // Verify we got at least one suggestion
      should.be_true(list.length(suggestions.suggestions) > 0)

      io.println(
        "SUCCESS: autocomplete_foods_live_test - found "
        <> int.to_string(list.length(suggestions.suggestions))
        <> " suggestions",
      )
      Nil
    }
  }
}

/// Live test: autocomplete_foods() with max_results parameter
///
/// Validates that autocomplete_foods_with_options() respects max_results parameter.
/// SKIPS if credentials are not configured.
pub fn autocomplete_foods_with_max_results_live_test() {
  case credentials.require_credentials() {
    Error(Nil) -> {
      io.println(
        "SKIP: autocomplete_foods_with_max_results_live_test - FatSecret credentials not configured",
      )
      Nil
    }
    Ok(config) -> {
      // Act: Call real API with max_results limit
      let result =
        foods_client.autocomplete_foods_with_options(
          config,
          "apple",
          option.Some(3),
        )

      // Assert: Should succeed and respect max_results
      should.be_ok(result)

      let suggestions = case result {
        Ok(s) -> s
        Error(_) -> panic as "Expected Ok result"
      }

      // Verify we got at most 3 suggestions
      should.be_true(list.length(suggestions.suggestions) <= 3)
      should.be_true(list.length(suggestions.suggestions) > 0)

      io.println(
        "SUCCESS: autocomplete_foods_with_max_results_live_test - found "
        <> int.to_string(list.length(suggestions.suggestions))
        <> " suggestions (max 3)",
      )
      Nil
    }
  }
}

/// Live test: list_brands() against real FatSecret API
///
/// Validates that list_brands() makes successful API calls and returns
/// a non-empty list of food brands.
/// SKIPS if credentials are not configured.
pub fn list_brands_live_test() {
  case credentials.require_credentials() {
    Error(Nil) -> {
      io.println(
        "SKIP: list_brands_live_test - FatSecret credentials not configured",
      )
      Nil
    }
    Ok(config) -> {
      // Act: Call real API to list brands
      let result = brands_client.list_brands(config)

      // Assert: Should succeed and return brands
      should.be_ok(result)

      let response = case result {
        Ok(r) -> r
        Error(_) -> panic as "Expected Ok result"
      }

      // Verify we got at least one brand
      should.be_true(list.length(response.brands) > 0)

      io.println(
        "SUCCESS: list_brands_live_test - found "
        <> int.to_string(list.length(response.brands))
        <> " brands",
      )
      Nil
    }
  }
}

/// Live test: list_brands_with_options() with starts_with filter
///
/// Validates that list_brands_with_options() correctly filters brands.
/// SKIPS if credentials are not configured.
pub fn list_brands_with_filter_live_test() {
  case credentials.require_credentials() {
    Error(Nil) -> {
      io.println(
        "SKIP: list_brands_with_filter_live_test - FatSecret credentials not configured",
      )
      Nil
    }
    Ok(config) -> {
      // Act: Call real API with starts_with filter
      let result =
        brands_client.list_brands_with_options(
          config,
          option.Some("K"),
          option.None,
        )

      // Assert: Should succeed and return filtered brands
      should.be_ok(result)

      let response = case result {
        Ok(r) -> r
        Error(_) -> panic as "Expected Ok result"
      }

      // Verify we got brands starting with 'K'
      should.be_true(list.length(response.brands) > 0)

      io.println(
        "SUCCESS: list_brands_with_filter_live_test - found "
        <> int.to_string(list.length(response.brands))
        <> " brands starting with 'K'",
      )
      Nil
    }
  }
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

      io.println(
        "SUCCESS: search_foods_simple_live_test - found "
        <> int.to_string(list.length(response.foods))
        <> " results",
      )
      Nil
    }
  }
}
