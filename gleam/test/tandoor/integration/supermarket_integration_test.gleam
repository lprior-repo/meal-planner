/// Supermarket Integration Tests
///
/// Integration tests for Supermarket and Supermarket Category APIs.
/// These tests require a running Tandoor instance.
///
/// Test Coverage:
/// - Supermarket CRUD operations
/// - Supermarket Category CRUD operations
/// - Listing with pagination
/// - Error handling (404, 401)
/// - Authentication (bearer)
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/api/supermarket/category
import meal_planner/tandoor/api/supermarket/create
import meal_planner/tandoor/api/supermarket/delete
import meal_planner/tandoor/api/supermarket/get
import meal_planner/tandoor/api/supermarket/list
import meal_planner/tandoor/client.{
  type ClientConfig, BearerAuth, ClientConfig,
}

import meal_planner/tandoor/types/supermarket/supermarket_category_create.{
  type SupermarketCategoryCreateRequest, SupermarketCategoryCreateRequest,
}
import meal_planner/tandoor/types/supermarket/supermarket_create.{
  type SupermarketCreateRequest, SupermarketCreateRequest,
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
// Test Helpers
// ============================================================================

fn create_test_supermarket_data(
  name_suffix: String,
) -> SupermarketCreateRequest {
  SupermarketCreateRequest(
    name: "Test Supermarket " <> name_suffix,
    description: Some("Test supermarket for integration testing"),
  )
}

fn create_test_category_data(
  name_suffix: String,
  _supermarket_id: Int,
) -> SupermarketCategoryCreateRequest {
  SupermarketCategoryCreateRequest(
    name: "Test Category " <> name_suffix,
    description: Some("Test category"),
  )
}

fn cleanup_supermarket(config: ClientConfig, supermarket_id: Int) -> Nil {
  let _result = delete.delete_supermarket(config, supermarket_id)
  Nil
}

fn cleanup_category(config: ClientConfig, category_id: Int) -> Nil {
  let _result = category.delete_category(config, category_id)
  Nil
}

// ============================================================================
// Supermarket CRUD Tests
// ============================================================================

/// Test complete CRUD flow for Supermarket
pub fn supermarket_crud_flow_test() {
  let config = test_config()

  // Create
  let supermarket_data = create_test_supermarket_data("CRUD")
  let assert Ok(created) =
    create.create_supermarket(config, supermarket_data)

  io.println("✓ Created supermarket with ID: " <> int.to_string(created.id))

  created.name
  |> should.equal("Test Supermarket CRUD")

  // Read
  let assert Ok(fetched) = get.get_supermarket(config, created.id)

  io.println("✓ Fetched supermarket by ID: " <> int.to_string(fetched.id))

  fetched.id
  |> should.equal(created.id)

  // Update
  let updated_data =
    SupermarketCreateRequest(
      name: "Test Supermarket CRUD (Updated)",
      description: Some("Updated description"),
    )

  let assert Ok(updated) =
    update.update_supermarket(config, created.id, updated_data)

  io.println("✓ Updated supermarket: " <> updated.name)

  updated.name
  |> should.equal("Test Supermarket CRUD (Updated)")

  // Delete
  let assert Ok(_) = delete.delete_supermarket(config, created.id)

  io.println("✓ Deleted supermarket ID: " <> int.to_string(created.id))

  // Verify deletion
  let delete_result = get.get_supermarket(config, created.id)
  delete_result
  |> should.be_error
}

// ============================================================================
// Supermarket List Tests
// ============================================================================

/// Test supermarket listing
pub fn supermarket_list_test() {
  let config = test_config()

  // Create test supermarkets
  let data_1 = create_test_supermarket_data("List-1")
  let data_2 = create_test_supermarket_data("List-2")

  let assert Ok(supermarket_1) = create.create_supermarket(config, data_1)
  let assert Ok(supermarket_2) = create.create_supermarket(config, data_2)

  io.println("✓ Created 2 test supermarkets")

  // List supermarkets
  let assert Ok(response) =
    list.list_supermarkets(config, limit: None, page: None)

  response.results
  |> list.length
  |> should.be_at_least(2)

  io.println(
    "✓ Listed supermarkets, count: "
    <> int.to_string(list.length(response.results)),
  )

  // Cleanup
  cleanup_supermarket(config, supermarket_1.id)
  cleanup_supermarket(config, supermarket_2.id)
}

/// Test supermarket pagination
pub fn supermarket_list_pagination_test() {
  let config = test_config()

  // Create test supermarkets
  let data_1 = create_test_supermarket_data("Page-1")
  let data_2 = create_test_supermarket_data("Page-2")
  let data_3 = create_test_supermarket_data("Page-3")

  let assert Ok(supermarket_1) = create.create_supermarket(config, data_1)
  let assert Ok(supermarket_2) = create.create_supermarket(config, data_2)
  let assert Ok(supermarket_3) = create.create_supermarket(config, data_3)

  io.println("✓ Created 3 test supermarkets for pagination")

  // Test first page
  let assert Ok(page_1) =
    list.list_supermarkets(config, limit: Some(2), page: None)

  page_1.results
  |> list.length
  |> should.be_at_most(2)

  io.println("✓ First page returned results")

  // Cleanup
  cleanup_supermarket(config, supermarket_1.id)
  cleanup_supermarket(config, supermarket_2.id)
  cleanup_supermarket(config, supermarket_3.id)
}

// ============================================================================
// Supermarket Category CRUD Tests
// ============================================================================

/// Test complete CRUD flow for Supermarket Category
pub fn category_crud_flow_test() {
  let config = test_config()

  // First create a supermarket
  let supermarket_data = create_test_supermarket_data("Category-Parent")
  let assert Ok(created_supermarket) =
    create.create_supermarket(config, supermarket_data)

  io.println(
    "✓ Created parent supermarket with ID: "
    <> int.to_string(created_supermarket.id),
  )

  // Create category
  let category_data =
    create_test_category_data("CRUD", created_supermarket.id)
  let assert Ok(created_category) =
    category.create_category(config, category_data)

  io.println(
    "✓ Created category with ID: " <> int.to_string(created_category.id),
  )

  created_category.name
  |> should.equal("Test Category CRUD")

  // Read category
  let assert Ok(fetched_category) =
    category.get_category(config, created_category.id)

  io.println(
    "✓ Fetched category by ID: " <> int.to_string(fetched_category.id),
  )

  fetched_category.id
  |> should.equal(created_category.id)

  // Update category
  let updated_category_data =
    SupermarketCategoryCreateRequest(
      name: "Test Category CRUD (Updated)",
      description: Some("Updated description"),
    )

  let assert Ok(updated_category) =
    category.update_category(config, created_category.id, updated_category_data)

  io.println("✓ Updated category: " <> updated_category.name)

  updated_category.name
  |> should.equal("Test Category CRUD (Updated)")

  // Delete category
  let assert Ok(_) = category.delete_category(config, created_category.id)

  io.println("✓ Deleted category ID: " <> int.to_string(created_category.id))

  // Cleanup supermarket
  cleanup_supermarket(config, created_supermarket.id)
}

// ============================================================================
// Category List Tests
// ============================================================================

/// Test category listing
pub fn category_list_test() {
  let config = test_config()

  // Create parent supermarket
  let supermarket_data = create_test_supermarket_data("Category-List")
  let assert Ok(created_supermarket) =
    create.create_supermarket(config, supermarket_data)

  // Create categories
  let cat_data_1 = create_test_category_data("List-1", created_supermarket.id)
  let cat_data_2 = create_test_category_data("List-2", created_supermarket.id)

  let assert Ok(category_1) = category.create_category(config, cat_data_1)
  let assert Ok(category_2) = category.create_category(config, cat_data_2)

  io.println("✓ Created 2 test categories")

  // List categories
  let assert Ok(response) =
    category.list_categories(config, limit: None, page: None)

  response.results
  |> list.length
  |> should.be_at_least(2)

  io.println(
    "✓ Listed categories, count: "
    <> int.to_string(list.length(response.results)),
  )

  // Cleanup
  cleanup_category(config, category_1.id)
  cleanup_category(config, category_2.id)
  cleanup_supermarket(config, created_supermarket.id)
}

// ============================================================================
// Error Handling Tests
// ============================================================================

/// Test 404 error when supermarket doesn't exist
pub fn supermarket_not_found_404_test() {
  let config = test_config()

  let result = get.get_supermarket(config, 999_999_999)

  result
  |> should.be_error

  io.println("✓ 404 error handled correctly for non-existent supermarket")
}

/// Test 401 error with invalid authentication
pub fn supermarket_unauthorized_401_test() {
  let bad_config =
    ClientConfig(
      base_url: test_base_url(),
      auth: BearerAuth(token: "invalid-token"),
      timeout_ms: 5000,
      retry_on_transient: False,
      max_retries: 0,
    )

  let result =
    list.list_supermarkets(bad_config, limit: None, page: None)

  result
  |> should.be_error

  io.println("✓ 401 error handled correctly for invalid auth")
}

/// Test network error handling
pub fn supermarket_network_error_test() {
  let bad_config =
    ClientConfig(
      base_url: "http://localhost:9999",
      auth: BearerAuth(token: "test-token"),
      timeout_ms: 2000,
      retry_on_transient: False,
      max_retries: 0,
    )

  let result =
    list.list_supermarkets(bad_config, limit: None, page: None)

  result
  |> should.be_error

  io.println("✓ Network error handled correctly")
}

// ============================================================================
// Hierarchical Relationship Tests
// ============================================================================

/// Test supermarket-category relationship
pub fn supermarket_category_relationship_test() {
  let config = test_config()

  // Create supermarket
  let supermarket_data = create_test_supermarket_data("Relationship")
  let assert Ok(created_supermarket) =
    create.create_supermarket(config, supermarket_data)

  io.println("✓ Created supermarket")

  // Create multiple categories under same supermarket
  let cat_1 = create_test_category_data("Produce", created_supermarket.id)
  let cat_2 = create_test_category_data("Dairy", created_supermarket.id)
  let cat_3 = create_test_category_data("Bakery", created_supermarket.id)

  let assert Ok(category_1) = category.create_category(config, cat_1)
  let assert Ok(category_2) = category.create_category(config, cat_2)
  let assert Ok(category_3) = category.create_category(config, cat_3)

  io.println("✓ Created 3 categories under supermarket")

  // Verify categories belong to correct supermarket
  category_1.supermarket_id
  |> should.equal(created_supermarket.id)

  category_2.supermarket_id
  |> should.equal(created_supermarket.id)

  category_3.supermarket_id
  |> should.equal(created_supermarket.id)

  io.println("✓ All categories correctly linked to supermarket")

  // Cleanup
  cleanup_category(config, category_1.id)
  cleanup_category(config, category_2.id)
  cleanup_category(config, category_3.id)
  cleanup_supermarket(config, created_supermarket.id)
}
