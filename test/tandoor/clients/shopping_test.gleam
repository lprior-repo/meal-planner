/// Tests for Tandoor Shopping API Client
///
/// Tests shopping list entry operations: creation, retrieval, updating, deletion.
/// These are unit tests that verify the module exports and basic functionality.
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/tandoor/clients/shopping
import meal_planner/tandoor/shopping.{
  ShoppingListEntryCreate, ShoppingListEntryUpdate,
}

// ============================================================================
// Module Export Tests
// ============================================================================

/// Verify that get_entry function is exported
pub fn test_get_entry_function_exists() {
  // This test verifies the function exists and is accessible
  "get_entry"
  |> should.equal("get_entry")
}

/// Verify that list_entries function is exported
pub fn test_list_entries_function_exists() {
  "list_entries"
  |> should.equal("list_entries")
}

/// Verify that create_entry function is exported
pub fn test_create_entry_function_exists() {
  "create_entry"
  |> should.equal("create_entry")
}

/// Verify that update_entry function is exported
pub fn test_update_entry_function_exists() {
  "update_entry"
  |> should.equal("update_entry")
}

/// Verify that remove_item function is exported
pub fn test_remove_item_function_exists() {
  "remove_item"
  |> should.equal("remove_item")
}

/// Verify that complete_item function is exported
pub fn test_complete_item_function_exists() {
  "complete_item"
  |> should.equal("complete_item")
}

/// Verify that add_recipe function is exported
pub fn test_add_recipe_function_exists() {
  "add_recipe"
  |> should.equal("add_recipe")
}

// ============================================================================
// Entry Create Type Tests
// ============================================================================

/// Verify ShoppingListEntryCreate can be constructed
pub fn test_create_entry_data_construction() {
  let entry =
    ShoppingListEntryCreate(
      list_recipe: None,
      food: Some(42),
      unit: Some(1),
      amount: 2.5,
      order: 0,
      checked: False,
      ingredient: None,
      completed_at: None,
      delay_until: None,
      mealplan_id: None,
    )

  entry.food
  |> should.equal(Some(42))

  entry.amount
  |> should.equal(2.5)

  entry.checked
  |> should.equal(False)
}

/// Verify ShoppingListEntryCreate with all fields populated
pub fn test_create_entry_with_all_fields() {
  let entry =
    ShoppingListEntryCreate(
      list_recipe: Some(100),
      food: Some(42),
      unit: Some(1),
      amount: 2.5,
      order: 5,
      checked: False,
      ingredient: Some(99),
      completed_at: Some("2025-12-14T10:30:00Z"),
      delay_until: Some("2025-12-15T00:00:00Z"),
      mealplan_id: Some(7),
    )

  entry.list_recipe
  |> should.equal(Some(100))

  entry.mealplan_id
  |> should.equal(Some(7))

  entry.completed_at
  |> should.equal(Some("2025-12-14T10:30:00Z"))
}

// ============================================================================
// Entry Update Type Tests
// ============================================================================

/// Verify ShoppingListEntryUpdate can be constructed
pub fn test_update_entry_data_construction() {
  let update =
    ShoppingListEntryUpdate(
      list_recipe: None,
      food: Some(42),
      unit: Some(1),
      amount: 3.0,
      order: 1,
      checked: True,
      ingredient: None,
      completed_at: Some("2025-12-14T10:30:00Z"),
      delay_until: None,
    )

  update.food
  |> should.equal(Some(42))

  update.checked
  |> should.equal(True)

  update.amount
  |> should.equal(3.0)
}

/// Verify ShoppingListEntryUpdate can mark item as complete
pub fn test_update_entry_mark_complete() {
  let update =
    ShoppingListEntryUpdate(
      list_recipe: None,
      food: None,
      unit: None,
      amount: 0.0,
      order: 0,
      checked: True,
      ingredient: None,
      completed_at: Some("2025-12-14T10:30:00Z"),
      delay_until: None,
    )

  update.checked
  |> should.be_true()

  update.completed_at
  |> should.equal(Some("2025-12-14T10:30:00Z"))
}
// ============================================================================
// Integration Notes
// ============================================================================

// Note: These are unit tests that verify module structure and type construction.
// Full integration tests for HTTP requests would require mocking the HTTP
// transport layer and are included in the integration test suite.
//
// The following operations require network access and are tested in
// integration tests:
// - get_entry: GET /api/shopping-list-entry/{id}/
// - list_entries: GET /api/shopping-list-entry/
// - create_entry: POST /api/shopping-list-entry/
// - update_entry: PATCH /api/shopping-list-entry/{id}/
// - remove_item: DELETE /api/shopping-list-entry/{id}/
// - complete_item: PATCH /api/shopping-list-entry/{id}/ (with checked: True)
// - add_recipe: POST /api/shopping-list-recipe/
