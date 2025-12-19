//// Test Harness for Integration Tests
////
//// Provides unified setup/teardown, mock builders, and test utilities
//// for integration testing across the Autonomous Nutritional Control Plane.

import gleam/io
import gleam/option.{None, Some}

/// Test credentials container
pub type TestCredentials {
  TestCredentials(tandoor_url: String, fatsecret_token: String)
}

/// Test context containing all resources needed for integration tests
pub type TestContext {
  TestContext(credentials: TestCredentials, server_available: Bool)
}

// ============================================================================
// Setup and Teardown
// ============================================================================

/// Setup test context - loads credentials and checks server availability
pub fn setup() -> TestContext {
  // For now, return defaults
  // TODO: Load from environment or config file
  TestContext(
    credentials: TestCredentials(
      tandoor_url: "http://localhost:8080",
      fatsecret_token: "",
    ),
    server_available: False,
  )
}

/// Teardown test context - cleanup resources
pub fn teardown(_context: TestContext) -> Result(Nil, String) {
  // No cleanup needed for now
  Ok(Nil)
}

// ============================================================================
// Mock Builders
// ============================================================================

/// Create a mock HTTP response
pub fn create_mock_response(status: Int, body: String) -> MockResponse {
  MockResponse(status: status, body: body)
}

/// Mock HTTP response type
pub type MockResponse {
  MockResponse(status: Int, body: String)
}

/// Create mock FatSecret profile data
pub fn create_mock_fatsecret_profile() -> String {
  "{\"profile\":{\"goal_weight_kg\":75.0,\"target_protein_g\":180.0}}"
}

/// Create mock Tandoor recipe list
pub fn create_mock_tandoor_recipes() -> String {
  "[{\"id\":1,\"name\":\"Grilled Chicken\"},{\"id\":2,\"name\":\"Salmon Bowl\"}]"
}

/// Create mock meal plan JSON
pub fn create_mock_meal_plan() -> String {
  "{\"week_of\":\"2025-12-22\",\"days\":[{\"day\":\"Monday\",\"breakfast\":\"Eggs\",\"lunch\":\"Salad\",\"dinner\":\"Chicken\"}]}"
}

// ============================================================================
// Test Utilities
// ============================================================================

/// Run a test with the provided context
pub fn run_test(
  context: TestContext,
  test_fn: fn(TestContext) -> Result(a, String),
) -> Result(a, String) {
  test_fn(context)
}

/// Skip test if service is unavailable
pub fn skip_if_unavailable(
  context: TestContext,
  service: String,
  test_fn: fn(TestContext) -> Result(a, String),
) -> Result(a, String) {
  case service {
    "tandoor" ->
      case context.server_available {
        True -> test_fn(context)
        False -> {
          io.println("  ⚠️  Skipping - Tandoor not configured")
          Error("Skipping - Tandoor not configured")
        }
      }
    "fatsecret" ->
      case context.credentials.fatsecret_token {
        "" -> {
          io.println("  ⚠️  Skipping - FatSecret not configured")
          Error("Skipping - FatSecret not configured")
        }
        _ -> test_fn(context)
      }
    _ -> Error("Unknown service: " <> service)
  }
}

/// Assert mock response has expected status
pub fn assert_mock_status(
  response: MockResponse,
  expected: Int,
) -> Result(MockResponse, String) {
  case response.status == expected {
    True -> Ok(response)
    False ->
      Error(
        "Expected status "
        <> int_to_string(expected)
        <> " but got "
        <> int_to_string(response.status),
      )
  }
}

/// Convert Int to String (helper function)
fn int_to_string(i: Int) -> String {
  case i {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    _ -> "unknown"
  }
}
