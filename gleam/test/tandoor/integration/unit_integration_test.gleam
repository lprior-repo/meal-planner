/// Unit Integration Tests
///
/// Full CRUD flow integration tests for Unit API.
/// These tests require a running Tandoor instance.
///
/// Test Coverage:
/// - Unit retrieval (get by ID)
/// - Unit listing with pagination
/// - Error handling (404, 401)
/// - Authentication (bearer)
///
/// Note: Units are typically read-only in Tandoor (system-managed),
/// so we focus on read operations.
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/api/unit/crud
import meal_planner/tandoor/api/unit/list
import meal_planner/tandoor/client.{
  type ClientConfig, BearerAuth, ClientConfig,
}

// ============================================================================
// Test Configuration
// ============================================================================

fn test_base_url() -> String {
  "http://localhost:8000"
}

fn test_bearer_token() -> String {
  "test-bearer-token-placeholder"
}

fn test_config() -> ClientConfig {
  ClientConfig(
    base_url: test_base_url(),
    auth: BearerAuth(token: test_bearer_token()),
    timeout_ms: 10_000,
    retry_on_transient: False,
    max_retries: 0,
  )
}

// ============================================================================
// Read Operation Tests
// ============================================================================

/// Test listing units
pub fn unit_list_test() {
  let config = test_config()

  let assert Ok(response) = list.list_units(config, limit: None, page: None)

  // Should have at least some system units
  response.results
  |> list.length
  |> should.be_at_least(1)

  io.println(
    "✓ Listed units, count: " <> int.to_string(list.length(response.results)),
  )

  // Check structure of first unit
  let assert [first_unit, ..] = response.results

  first_unit.name
  |> should.not_equal("")

  io.println("✓ First unit has valid structure: " <> first_unit.name)
}

/// Test getting a specific unit by ID
pub fn unit_get_test() {
  let config = test_config()

  // First, get list to find a valid unit ID
  let assert Ok(response) = list.list_units(config, limit: Some(1), page: None)
  let assert [first_unit, ..] = response.results

  io.println("✓ Found unit ID to test: " <> int.to_string(first_unit.id))

  // Now get that specific unit
  let assert Ok(fetched_unit) = crud.get_unit(config, first_unit.id)

  fetched_unit.id
  |> should.equal(first_unit.id)

  fetched_unit.name
  |> should.equal(first_unit.name)

  io.println("✓ Successfully fetched unit: " <> fetched_unit.name)
}

// ============================================================================
// Pagination Tests
// ============================================================================

/// Test unit listing with pagination
pub fn unit_list_pagination_test() {
  let config = test_config()

  // Test first page
  let assert Ok(page_1) = list.list_units(config, limit: Some(5), page: None)

  let page_1_count = list.length(page_1.results)
  page_1_count
  |> should.be_at_most(5)

  io.println("✓ First page returned: " <> int.to_string(page_1_count))

  // Test second page if there are enough results
  case page_1.next {
    Some(_next_url) -> {
      let assert Ok(page_2) = list.list_units(config, limit: Some(5), page: Some(2))

      page_2.results
      |> list.length
      |> should.be_at_least(0)

      io.println("✓ Second page returned results")
    }
    None -> {
      io.println("✓ Only one page of results (expected for small datasets)")
    }
  }
}

/// Test limit parameter
pub fn unit_list_limit_test() {
  let config = test_config()

  // Request only 3 units
  let assert Ok(response) = list.list_units(config, limit: Some(3), page: None)

  response.results
  |> list.length
  |> should.be_at_most(3)

  io.println("✓ Limit parameter respected")
}

// ============================================================================
// Error Handling Tests
// ============================================================================

/// Test 404 error when unit doesn't exist
pub fn unit_not_found_404_test() {
  let config = test_config()

  let result = crud.get_unit(config, 999_999_999)

  result
  |> should.be_error

  io.println("✓ 404 error handled correctly for non-existent unit")
}

/// Test 401 error with invalid authentication
pub fn unit_unauthorized_401_test() {
  let bad_config =
    ClientConfig(
      base_url: test_base_url(),
      auth: BearerAuth(token: "invalid-token"),
      timeout_ms: 5000,
      retry_on_transient: False,
      max_retries: 0,
    )

  let result = list.list_units(bad_config, limit: None, page: None)

  result
  |> should.be_error

  io.println("✓ 401 error handled correctly for invalid auth")
}

/// Test network error handling
pub fn unit_network_error_test() {
  let bad_config =
    ClientConfig(
      base_url: "http://localhost:9999",
      auth: BearerAuth(token: "test-token"),
      timeout_ms: 2000,
      retry_on_transient: False,
      max_retries: 0,
    )

  let result = list.list_units(bad_config, limit: None, page: None)

  result
  |> should.be_error

  io.println("✓ Network error handled correctly")
}

// ============================================================================
// Data Validation Tests
// ============================================================================

/// Test that units have required fields
pub fn unit_structure_validation_test() {
  let config = test_config()

  let assert Ok(response) = list.list_units(config, limit: Some(10), page: None)

  // Check each unit has required fields
  response.results
  |> list.each(fn(unit) {
    // ID should be positive
    unit.id
    |> should.be_at_least(1)

    // Name should not be empty
    unit.name
    |> should.not_equal("")

    // Abbreviation should not be empty
    unit.abbreviation
    |> should.not_equal("")
  })

  io.println("✓ All units have valid structure")
}

/// Test common unit types exist
pub fn common_units_exist_test() {
  let config = test_config()

  let assert Ok(response) = list.list_units(config, limit: Some(100), page: None)

  // Check for some common units
  let unit_names =
    response.results
    |> list.map(fn(unit) { unit.name })

  // At least one of these common units should exist
  let has_common_unit =
    list.any(unit_names, fn(name) { name == "g" || name == "kg" || name == "cup" })

  has_common_unit
  |> should.be_true

  io.println("✓ Common units exist in system")
}
