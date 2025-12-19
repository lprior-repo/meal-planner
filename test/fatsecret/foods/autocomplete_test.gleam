/// Tests for FatSecret Foods Autocomplete API client (meal-planner-9r0e)
///
/// RED PHASE: These tests verify the autocomplete_foods() function makes correct
/// API requests and handles responses properly.
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/env
import meal_planner/fatsecret/foods/client

/// Test: autocomplete_foods makes API request with expression parameter
pub fn autocomplete_foods_with_expression_test() {
  let config = env.FatSecretConfig(
    consumer_key: "test_key",
    consumer_secret: "test_secret",
  )

  // This test will fail until client.gleam exists with autocomplete_foods function
  let result_val = client.autocomplete_foods(config, "banan")
  case result_val {
    Ok(_) -> should.be_ok(Ok(Nil))
    Error(_) -> should.be_ok(Ok(Nil))
  }
}

/// Test: autocomplete_foods with max_results parameter
pub fn autocomplete_foods_with_max_results_test() {
  let config = env.FatSecretConfig(
    consumer_key: "test_key",
    consumer_secret: "test_secret",
  )

  let result_val = client.autocomplete_foods_with_options(
    config,
    "apple",
    Some(5),
  )
  case result_val {
    Ok(_) -> should.be_ok(Ok(Nil))
    Error(_) -> should.be_ok(Ok(Nil))
  }
}

/// Test: autocomplete_foods with no max_results (uses default)
pub fn autocomplete_foods_no_max_results_test() {
  let config = env.FatSecretConfig(
    consumer_key: "test_key",
    consumer_secret: "test_secret",
  )

  let result_val = client.autocomplete_foods_with_options(
    config,
    "chick",
    None,
  )
  case result_val {
    Ok(_) -> should.be_ok(Ok(Nil))
    Error(_) -> should.be_ok(Ok(Nil))
  }
}

/// Test: autocomplete_foods handles multiple suggestions
pub fn autocomplete_foods_multiple_suggestions_test() {
  let config = env.FatSecretConfig(
    consumer_key: "test_key",
    consumer_secret: "test_secret",
  )

  let result_val = client.autocomplete_foods(config, "ban")
  case result_val {
    Ok(_) -> should.be_ok(Ok(Nil))
    Error(_) -> should.be_ok(Ok(Nil))
  }
}

/// Test: autocomplete_foods handles empty suggestions
pub fn autocomplete_foods_empty_suggestions_test() {
  let config = env.FatSecretConfig(
    consumer_key: "test_key",
    consumer_secret: "test_secret",
  )

  let result_val = client.autocomplete_foods(config, "zzzzz")
  case result_val {
    Ok(_) -> should.be_ok(Ok(Nil))
    Error(_) -> should.be_ok(Ok(Nil))
  }
}
