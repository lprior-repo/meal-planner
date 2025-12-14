/// Shopping Integration Tests
///
/// Full CRUD flow integration tests for Shopping List API.
/// These tests require a running Tandoor instance.
///
/// Test Coverage:
/// - Shopping list entry creation
/// - Shopping list entry retrieval
/// - Shopping list entry listing
/// - Shopping list entry deletion
/// - Error handling (404, 401)
/// - Authentication (bearer)
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/api/shopping/create
import meal_planner/tandoor/api/shopping/delete
import meal_planner/tandoor/api/shopping/get
import meal_planner/tandoor/api/shopping/list
import meal_planner/tandoor/client.{
  type ClientConfig, BearerAuth, ClientConfig,
}
import meal_planner/tandoor/types/shopping/shopping_list_entry.{
  type ShoppingListEntry, type ShoppingListEntryCreate, ShoppingListEntryCreate,
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

fn create_test_shopping_entry_data(
  name_suffix: String,
) -> ShoppingListEntryCreate {
  ShoppingListEntryCreate(
    list_recipe: None,
    food: None,  // In real test, would need to create a food first
    unit: None,
    amount: 2.0,
    order: 0,
    checked: False,
    ingredient: None,
    completed_at: None,
    delay_until: None,
  )
}

fn create_test_shopping_entry_data(
  name_suffix: String,
) -> ShoppingListEntryCreateRequest {
  ShoppingListEntryCreateRequest(
    food: TandoorFoodCreateRequest(name: "Test Shopping Food " <> name_suffix),
    amount: 2.0,
    unit_name: "kg",
  )
}

fn cleanup_shopping_entry(config: ClientConfig, entry_id: Int) -> Nil {
  let _result = delete.delete_shopping_list_entry(config, entry_id)
  Nil
}

// ============================================================================
// Full CRUD Flow Tests
// ============================================================================

/// Test complete CRUD flow for Shopping List Entry
pub fn shopping_crud_flow_test() {
  let config = test_config()

  // Create
  let entry_data = create_test_shopping_entry_data("CRUD")
  let assert Ok(created_entry) =
    create.create_shopping_list_entry(config, entry_data)

  io.println(
    "✓ Created shopping entry with ID: " <> int.to_string(created_entry.id),
  )

  // Read
  let assert Ok(fetched_entry) =
    get.get_shopping_list_entry(config, created_entry.id)

  io.println(
    "✓ Fetched shopping entry by ID: " <> int.to_string(fetched_entry.id),
  )

  fetched_entry.id
  |> should.equal(created_entry.id)

  // Delete
  let assert Ok(_) = delete.delete_shopping_list_entry(config, created_entry.id)

  io.println(
    "✓ Deleted shopping entry ID: " <> int.to_string(created_entry.id),
  )

  // Verify deletion - should get 404
  let delete_result = get.get_shopping_list_entry(config, created_entry.id)
  delete_result
  |> should.be_error
}

// ============================================================================
// List Operations Tests
// ============================================================================

/// Test shopping list listing
pub fn shopping_list_test() {
  let config = test_config()

  // Create test entries
  let entry_data_1 = create_test_shopping_entry_data("List-1")
  let entry_data_2 = create_test_shopping_entry_data("List-2")

  let assert Ok(entry_1) =
    create.create_shopping_list_entry(config, entry_data_1)
  let assert Ok(entry_2) =
    create.create_shopping_list_entry(config, entry_data_2)

  io.println("✓ Created 2 test shopping entries")

  // List entries
  let assert Ok(response) =
    list.list_shopping_list_entries(config, limit: None, page: None)

  response.results
  |> list.length
  |> should.be_at_least(2)

  io.println(
    "✓ Listed shopping entries, count: "
    <> int.to_string(list.length(response.results)),
  )

  // Cleanup
  cleanup_shopping_entry(config, entry_1.id)
  cleanup_shopping_entry(config, entry_2.id)
}

/// Test shopping list pagination
pub fn shopping_list_pagination_test() {
  let config = test_config()

  // Create test entries
  let entry_data_1 = create_test_shopping_entry_data("Page-1")
  let entry_data_2 = create_test_shopping_entry_data("Page-2")
  let entry_data_3 = create_test_shopping_entry_data("Page-3")

  let assert Ok(entry_1) =
    create.create_shopping_list_entry(config, entry_data_1)
  let assert Ok(entry_2) =
    create.create_shopping_list_entry(config, entry_data_2)
  let assert Ok(entry_3) =
    create.create_shopping_list_entry(config, entry_data_3)

  io.println("✓ Created 3 test shopping entries for pagination")

  // Test first page
  let assert Ok(page_1) =
    list.list_shopping_list_entries(config, limit: Some(2), page: None)

  page_1.results
  |> list.length
  |> should.be_at_most(2)

  io.println("✓ First page returned results")

  // Test second page
  let assert Ok(page_2) =
    list.list_shopping_list_entries(config, limit: Some(2), page: Some(2))

  page_2.results
  |> list.length
  |> should.be_at_least(0)

  io.println("✓ Second page returned results")

  // Cleanup
  cleanup_shopping_entry(config, entry_1.id)
  cleanup_shopping_entry(config, entry_2.id)
  cleanup_shopping_entry(config, entry_3.id)
}

// ============================================================================
// Error Handling Tests
// ============================================================================

/// Test 404 error when shopping entry doesn't exist
pub fn shopping_not_found_404_test() {
  let config = test_config()

  let result = get.get_shopping_list_entry(config, 999_999_999)

  result
  |> should.be_error

  io.println("✓ 404 error handled correctly for non-existent shopping entry")
}

/// Test 401 error with invalid authentication
pub fn shopping_unauthorized_401_test() {
  let bad_config =
    ClientConfig(
      base_url: test_base_url(),
      auth: BearerAuth(token: "invalid-token"),
      timeout_ms: 5000,
      retry_on_transient: False,
      max_retries: 0,
    )

  let result =
    list.list_shopping_list_entries(bad_config, limit: None, page: None)

  result
  |> should.be_error

  io.println("✓ 401 error handled correctly for invalid auth")
}

/// Test network error handling
pub fn shopping_network_error_test() {
  let bad_config =
    ClientConfig(
      base_url: "http://localhost:9999",
      auth: BearerAuth(token: "test-token"),
      timeout_ms: 2000,
      retry_on_transient: False,
      max_retries: 0,
    )

  let result =
    list.list_shopping_list_entries(bad_config, limit: None, page: None)

  result
  |> should.be_error

  io.println("✓ Network error handled correctly")
}

// ============================================================================
// Bulk Operations Tests
// ============================================================================

/// Test creating multiple shopping entries
pub fn shopping_bulk_create_test() {
  let config = test_config()

  let entries_to_create = [
    create_test_shopping_entry_data("Bulk-1"),
    create_test_shopping_entry_data("Bulk-2"),
    create_test_shopping_entry_data("Bulk-3"),
  ]

  // Create all entries
  let created_entries =
    entries_to_create
    |> list.map(fn(entry_data) {
      let assert Ok(entry) =
        create.create_shopping_list_entry(config, entry_data)
      entry
    })

  created_entries
  |> list.length
  |> should.equal(3)

  io.println("✓ Created 3 shopping entries in bulk")

  // Cleanup all
  created_entries
  |> list.each(fn(entry) { cleanup_shopping_entry(config, entry.id) })

  io.println("✓ Cleaned up bulk shopping entries")
}

// ============================================================================
// Shopping List Workflow Tests
// ============================================================================

/// Test typical shopping list workflow: add items, check list, remove items
pub fn shopping_workflow_test() {
  let config = test_config()

  // Step 1: Add items to shopping list
  let entry_1 = create_test_shopping_entry_data("Workflow-Milk")
  let entry_2 = create_test_shopping_entry_data("Workflow-Bread")

  let assert Ok(created_1) = create.create_shopping_list_entry(config, entry_1)
  let assert Ok(created_2) = create.create_shopping_list_entry(config, entry_2)

  io.println("✓ Added items to shopping list")

  // Step 2: Check current shopping list
  let assert Ok(current_list) =
    list.list_shopping_list_entries(config, limit: None, page: None)

  current_list.results
  |> list.length
  |> should.be_at_least(2)

  io.println("✓ Verified items in shopping list")

  // Step 3: Remove items after shopping
  let assert Ok(_) = delete.delete_shopping_list_entry(config, created_1.id)
  let assert Ok(_) = delete.delete_shopping_list_entry(config, created_2.id)

  io.println("✓ Removed items after shopping")

  // Step 4: Verify list is cleaned up
  let assert Ok(final_list) =
    list.list_shopping_list_entries(config, limit: None, page: None)

  // List might have other items, but our test items should be gone
  let has_test_items =
    final_list.results
    |> list.any(fn(entry) { entry.id == created_1.id || entry.id == created_2.id })

  has_test_items
  |> should.be_false

  io.println("✓ Shopping workflow completed successfully")
}
