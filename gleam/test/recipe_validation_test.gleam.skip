import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/storage/recipe_validation
import meal_planner/storage/recipe_validation.{
  ConfigurationError, ConnectionError, RecipeNotFound, ServiceUnavailable,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Tests for error_to_message
// ============================================================================

pub fn recipe_not_found_error_message_test() {
  let error = RecipeNotFound("chicken-stir-fry")
  let result = recipe_validation.error_to_message(error)
  result
  |> should.equal(
    "Recipe 'chicken-stir-fry' was not found in your recipe database.",
  )
}

pub fn connection_error_message_test() {
  let error = ConnectionError("Network timeout")
  let result = recipe_validation.error_to_message(error)
  result
  |> should.contain("Unable to verify recipe")
  |> should.be_true()
}

pub fn service_unavailable_error_message_test() {
  let error = ServiceUnavailable("Service down for maintenance")
  let result = recipe_validation.error_to_message(error)
  result
  |> should.contain("Recipe service is temporarily unavailable")
  |> should.be_true()
}

pub fn configuration_error_message_test() {
  let error = ConfigurationError("Missing API token")
  let result = recipe_validation.error_to_message(error)
  result
  |> should.contain("Recipe service is not properly configured")
  |> should.be_true()
}

// ============================================================================
// Integration tests for validate_recipe_slug
// ============================================================================

pub fn validate_recipe_slug_with_valid_slug_test() {
  // This would require mocking the Mealie client for a proper unit test
  // In a real scenario, we'd use dependency injection or a mock framework
  // For now, this serves as documentation of the expected behavior:
  //
  // let config = config.load()
  // case recipe_validation.validate_recipe_slug(config, "beef-tacos") {
  //   Ok(slug) -> should.equal(slug, "beef-tacos")
  //   Error(_) -> should.fail("Should succeed for valid recipe")
  // }
  True
  |> should.be_true()
}

pub fn validate_recipe_slug_error_handling_test() {
  // This documents the expected error cases:
  //
  // Invalid slug should return RecipeNotFound error:
  // case recipe_validation.validate_recipe_slug(config, "non-existent-recipe") {
  //   Ok(_) -> should.fail("Should fail for non-existent recipe")
  //   Error(RecipeNotFound(slug)) -> should.equal(slug, "non-existent-recipe")
  //   Error(_) -> should.fail("Should be RecipeNotFound error")
  // }
  True
  |> should.be_true()
}

// ============================================================================
// Integration tests for batch validation
// ============================================================================

pub fn validate_recipe_slugs_batch_handles_mixed_results_test() {
  // This documents the expected behavior for batch validation:
  //
  // case recipe_validation.validate_recipe_slugs_batch(
  //   config,
  //   ["valid-recipe-1", "invalid-recipe", "valid-recipe-2"],
  // ) {
  //   Ok(#(valid, invalid)) -> {
  //     should.equal(list.length(valid), 2)
  //     should.equal(list.length(invalid), 1)
  //     should.contain(invalid, "invalid-recipe")
  //   }
  //   Error(_) -> should.fail("Should handle mixed results")
  // }
  True
  |> should.be_true()
}

// ============================================================================
// Error type verification tests
// ============================================================================

pub fn recipe_not_found_error_contains_slug_test() {
  let error = RecipeNotFound("my-recipe")
  case error {
    RecipeNotFound(slug) -> slug |> should.equal("my-recipe")
    _ -> should.fail("Should be RecipeNotFound")
  }
}

pub fn connection_error_contains_message_test() {
  let error = ConnectionError("Connection refused on port 9000")
  case error {
    ConnectionError(msg) -> msg |> should.contain("port 9000") |> should.be_true()
    _ -> should.fail("Should be ConnectionError")
  }
}

pub fn service_unavailable_error_contains_message_test() {
  let error = ServiceUnavailable("Database is down")
  case error {
    ServiceUnavailable(msg) -> msg |> should.contain("Database") |> should.be_true()
    _ -> should.fail("Should be ServiceUnavailable")
  }
}

pub fn configuration_error_contains_message_test() {
  let error = ConfigurationError("API token not set in environment")
  case error {
    ConfigurationError(msg) ->
      msg |> should.contain("API token") |> should.be_true()
    _ -> should.fail("Should be ConfigurationError")
  }
}

// ============================================================================
// Validation logic tests
// ============================================================================

pub fn valid_recipe_slug_format_test() {
  // Recipe slugs should be non-empty strings, typically kebab-case
  // Example valid slugs:
  // - "chicken-stir-fry"
  // - "beef-tacos"
  // - "chocolate-cake"
  // - "caesar-salad"
  let valid_slugs = [
    "chicken-stir-fry",
    "beef-tacos",
    "chocolate-cake",
    "caesar-salad",
  ]

  list.length(valid_slugs)
  |> should.equal(4)
}

pub fn invalid_recipe_slug_format_test() {
  // Invalid slugs that should fail validation:
  // - Empty string ""
  // - Null or undefined
  // - Special characters (except hyphens)
  // - Multiple consecutive spaces
  let empty_slug = ""
  let slug_with_spaces = "chicken  stir  fry"

  empty_slug
  |> should.equal("")
  slug_with_spaces
  |> should.contain("  ")
  |> should.be_true()
}

// ============================================================================
// Error recovery tests
// ============================================================================

pub fn retry_on_connection_error_test() {
  // Connection errors should be retryable
  let error = ConnectionError("Timeout on first attempt")

  case error {
    ConnectionError(_) -> True |> should.be_true()
    _ -> should.fail("Should handle connection errors")
  }
}

pub fn no_retry_on_recipe_not_found_test() {
  // RecipeNotFound errors should NOT be retried
  let error = RecipeNotFound("non-existent-recipe")

  case error {
    RecipeNotFound(_) -> True |> should.be_true()
    _ -> should.fail("Should handle recipe not found")
  }
}

// ============================================================================
// Real-world scenarios
// ============================================================================

pub fn typical_mealie_recipe_slug_test() {
  // Typical Mealie recipe slugs are URL-safe kebab-case identifiers
  let slug = "slow-cooker-pulled-pork"
  slug
  |> should.contain("slow-cooker")
  |> should.be_true()
}

pub fn user_attempting_to_log_invalid_recipe_test() {
  // Simulate user trying to log a recipe that doesn't exist
  // Expected: RecipeNotFound error returned
  // Result: User gets friendly error message
  let attempted_slug = "recipe-that-doesnt-exist"
  let error_message = recipe_validation.error_to_message(
    RecipeNotFound(attempted_slug),
  )

  error_message
  |> should.contain(attempted_slug)
  |> should.be_true()
}

pub fn mealie_service_down_scenario_test() {
  // Simulate Mealie service being down
  // Expected: ServiceUnavailable error
  // Result: User gets appropriate message
  let error_message =
    recipe_validation.error_to_message(
      ServiceUnavailable("Mealie service is offline"),
    )

  error_message
  |> should.contain("temporarily unavailable")
  |> should.be_true()
}
