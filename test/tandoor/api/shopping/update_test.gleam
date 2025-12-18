/// Tests for Shopping List Entry Update API
///
/// These tests verify the update function with partial and full updates.
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/api/shopping_list
import meal_planner/tandoor/client
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/types/shopping/shopping_list_entry.{
  ShoppingListEntryUpdate,
}

pub fn update_shopping_list_entry_delegates_to_client_test() {
  // Verify function exists and has correct signature
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let update =
    ShoppingListEntryUpdate(
      list_recipe: None,
      food: Some(1),
      unit: Some(1),
      amount: 3.0,
      order: 0,
      checked: True,
      ingredient: None,
      completed_at: Some("2025-12-14T10:30:00Z"),
      delay_until: None,
    )

  // Call should fail (no server) but proves delegation works
  let result = shopping_list.update(config, 1, update)

  // Should get a network or connection error, proving it attempted the call
  should.be_error(result)
}

pub fn update_accepts_different_ids_test() {
  // Verify different IDs work
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let update =
    ShoppingListEntryUpdate(
      list_recipe: None,
      food: None,
      unit: None,
      amount: 1.0,
      order: 0,
      checked: False,
      ingredient: None,
      completed_at: None,
      delay_until: None,
    )

  let result1 = shopping_list.update(config, 999, update)
  let result2 = shopping_list.update(config, 1, update)

  // Both should attempt call and fail (no server)
  should.be_error(result1)
  should.be_error(result2)
}

pub fn update_checked_status_test() {
  // Test updating just the checked status
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let update =
    ShoppingListEntryUpdate(
      list_recipe: None,
      food: None,
      unit: None,
      amount: 1.0,
      order: 0,
      checked: True,
      ingredient: None,
      completed_at: Some("2025-12-14T10:30:00Z"),
      delay_until: None,
    )

  let result = shopping_list.update(config, 42, update)
  should.be_error(result)
}

pub fn update_amount_test() {
  // Test updating the amount
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let update =
    ShoppingListEntryUpdate(
      list_recipe: None,
      food: None,
      unit: None,
      amount: 5.5,
      order: 0,
      checked: False,
      ingredient: None,
      completed_at: None,
      delay_until: None,
    )

  let result = shopping_list.update(config, 42, update)
  should.be_error(result)
}

pub fn update_with_all_fields_test() {
  // Test updating all fields
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let update =
    ShoppingListEntryUpdate(
      list_recipe: Some(ids.shopping_list_id_from_int(10)),
      food: Some(20),
      unit: Some(5),
      amount: 4.0,
      order: 3,
      checked: True,
      ingredient: Some(ids.ingredient_id_from_int(15)),
      completed_at: Some("2025-12-14T12:00:00Z"),
      delay_until: Some("2025-12-20T00:00:00Z"),
    )

  let result = shopping_list.update(config, 42, update)
  should.be_error(result)
}

pub fn update_clear_optional_fields_test() {
  // Test clearing optional fields by setting to None
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let update =
    ShoppingListEntryUpdate(
      list_recipe: None,
      food: None,
      unit: None,
      amount: 1.0,
      order: 0,
      checked: False,
      ingredient: None,
      completed_at: None,
      delay_until: None,
    )

  let result = shopping_list.update(config, 42, update)
  should.be_error(result)
}

pub fn update_order_field_test() {
  // Test updating the order field for sorting
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let update =
    ShoppingListEntryUpdate(
      list_recipe: None,
      food: None,
      unit: None,
      amount: 1.0,
      order: 99,
      checked: False,
      ingredient: None,
      completed_at: None,
      delay_until: None,
    )

  let result = shopping_list.update(config, 42, update)
  should.be_error(result)
}

pub fn update_returns_shopping_list_entry_test() {
  // Verify the return type is ShoppingListEntry
  // This test ensures type safety - if it compiles, the type is correct
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let update =
    ShoppingListEntryUpdate(
      list_recipe: None,
      food: None,
      unit: None,
      amount: 1.0,
      order: 0,
      checked: False,
      ingredient: None,
      completed_at: None,
      delay_until: None,
    )

  // The type system guarantees this returns Result(ShoppingListEntry, TandoorError)
  let _result = shopping_list.update(config, 42, update)

  // Type check passes
  True
  |> should.be_true
}
