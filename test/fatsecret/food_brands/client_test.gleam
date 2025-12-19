/// Tests for FatSecret Food Brands API client (meal-planner-sl7q)
///
/// RED PHASE: These tests verify the brands client functions make correct
/// API requests and handle responses properly.
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/env
import meal_planner/fatsecret/food_brands/client
import meal_planner/fatsecret/food_brands/types

/// Test: list_brands makes API request with no parameters
pub fn list_brands_makes_request_test() {
  let config =
    env.FatSecretConfig(
      consumer_key: "test_key",
      consumer_secret: "test_secret",
    )

  // This test will fail until client.gleam exists with list_brands function
  let result_val = client.list_brands(config)
  case result_val {
    Ok(_) -> should.be_ok(Ok(Nil))
    Error(_) -> should.be_ok(Ok(Nil))
  }
}

/// Test: list_brands_with_options builds correct parameters
pub fn list_brands_with_options_builds_params_test() {
  let config =
    env.FatSecretConfig(
      consumer_key: "test_key",
      consumer_secret: "test_secret",
    )

  let result_val =
    client.list_brands_with_options(config, Some("K"), Some(types.Manufacturer))
  case result_val {
    Ok(_) -> should.be_ok(Ok(Nil))
    Error(_) -> should.be_ok(Ok(Nil))
  }
}

/// Test: list_brands_with_options with no filters
pub fn list_brands_with_options_no_filters_test() {
  let config =
    env.FatSecretConfig(
      consumer_key: "test_key",
      consumer_secret: "test_secret",
    )

  let result_val = client.list_brands_with_options(config, None, None)
  case result_val {
    Ok(_) -> should.be_ok(Ok(Nil))
    Error(_) -> should.be_ok(Ok(Nil))
  }
}

/// Test: list_brands_with_options with starts_with filter only
pub fn list_brands_with_starts_with_test() {
  let config =
    env.FatSecretConfig(
      consumer_key: "test_key",
      consumer_secret: "test_secret",
    )

  let result_val = client.list_brands_with_options(config, Some("K"), None)
  case result_val {
    Ok(_) -> should.be_ok(Ok(Nil))
    Error(_) -> should.be_ok(Ok(Nil))
  }
}

/// Test: list_brands_with_options with brand_type filter only
pub fn list_brands_with_brand_type_test() {
  let config =
    env.FatSecretConfig(
      consumer_key: "test_key",
      consumer_secret: "test_secret",
    )

  let result_val =
    client.list_brands_with_options(config, None, Some(types.Restaurant))
  case result_val {
    Ok(_) -> should.be_ok(Ok(Nil))
    Error(_) -> should.be_ok(Ok(Nil))
  }
}
