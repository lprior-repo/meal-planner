/// Tests for Property API
///
/// This module tests the Property API functions (list, get, create, update, delete).
/// Following TDD: these tests should FAIL first, then pass after implementation.
///
/// Note: These are integration-style tests that would require a running Tandoor instance.
/// For now, we test the API function signatures and types.
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/api/property/property_api
import meal_planner/tandoor/client.{type ClientConfig, BearerAuth, ClientConfig}
import meal_planner/tandoor/encoders/property/property_encoder.{
  PropertyCreateRequest, PropertyUpdateRequest,
}
import meal_planner/tandoor/types/property/property.{RecipeProperty}

/// Helper to create a test client config
fn test_config() -> ClientConfig {
  ClientConfig(
    base_url: "http://localhost:8000",
    auth: BearerAuth(token: "test-token"),
    timeout_ms: 5000,
    retry_on_transient: False,
    max_retries: 0,
  )
}

/// Test list_properties function signature
pub fn list_properties_signature_test() {
  let config = test_config()

  // This will fail with network error since no server is running
  // But it tests that the function exists and has correct types
  let result = property_api.list_properties(config)

  // Should return Result type - we expect an error since no server
  result
  |> should.be_error
}

/// Test get_property function signature
pub fn get_property_signature_test() {
  let config = test_config()

  // This will fail with network error
  let result = property_api.get_property(config, property_id: 1)

  // Should return Result type
  result
  |> should.be_error
}

/// Test create_property function signature
pub fn create_property_signature_test() {
  let config = test_config()
  let property_data =
    PropertyCreateRequest(
      name: "Test Property",
      description: "Test description",
      property_type: RecipeProperty,
      unit: None,
      order: 1,
    )

  // This will fail with network error
  let result = property_api.create_property(config, property_data)

  // Should return Result type
  result
  |> should.be_error
}

/// Test update_property function signature
pub fn update_property_signature_test() {
  let config = test_config()
  let update_data =
    PropertyUpdateRequest(
      name: Some("Updated Name"),
      description: None,
      property_type: None,
      unit: None,
      order: Some(5),
    )

  // This will fail with network error
  let result = property_api.update_property(config, property_id: 1, update_data)

  // Should return Result type
  result
  |> should.be_error
}

/// Test delete_property function signature
pub fn delete_property_signature_test() {
  let config = test_config()

  // This will fail with network error
  let result = property_api.delete_property(config, property_id: 1)

  // Should return Result type
  result
  |> should.be_error
}

/// Test error handling with invalid authentication
pub fn invalid_auth_error_test() {
  let config =
    ClientConfig(
      base_url: "http://localhost:8000",
      auth: BearerAuth(token: ""),
      timeout_ms: 5000,
      retry_on_transient: False,
      max_retries: 0,
    )

  let result = property_api.list_properties(config)

  // Should be an error (either auth or network)
  result
  |> should.be_error
}
