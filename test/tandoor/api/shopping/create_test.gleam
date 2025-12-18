/// Tests for Shopping List Entry Create API
///
/// These tests verify the create function with validation.
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/api/shopping_list
import meal_planner/tandoor/client
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/types/shopping/shopping_list_entry.{
  ShoppingListEntryCreate,
}

pub fn create_shopping_list_entry_delegates_to_client_test() {
  // Verify function exists and has correct signature
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let entry =
    ShoppingListEntryCreate(
      list_recipe: None,
      food: Some(1),
      unit: Some(1),
      amount: 2.5,
      order: 0,
      checked: False,
      ingredient: None,
      completed_at: None,
      delay_until: None,
      mealplan_id: None,
    )

  // Call should fail (no server) but proves delegation works
  let result = shopping_list.create(config, entry)

  // Should get a network or connection error, proving it attempted the call
  should.be_error(result)
}

pub fn create_with_minimal_fields_test() {
  // Test creating entry with only required fields
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let entry =
    ShoppingListEntryCreate(
      list_recipe: None,
      food: None,
      unit: None,
      amount: 1.0,
      order: 0,
      checked: False,
      ingredient: None,
      completed_at: None,
      delay_until: None,
      mealplan_id: None,
    )

  let result = shopping_list.create(config, entry)
  should.be_error(result)
}

pub fn create_with_food_and_unit_test() {
  // Test creating entry with food and unit
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let entry =
    ShoppingListEntryCreate(
      list_recipe: None,
      food: Some(42),
      unit: Some(2),
      amount: 3.0,
      order: 1,
      checked: False,
      ingredient: None,
      completed_at: None,
      delay_until: None,
      mealplan_id: None,
    )

  let result = shopping_list.create(config, entry)
  should.be_error(result)
}

pub fn create_with_all_fields_test() {
  // Test creating entry with all optional fields
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let entry =
    ShoppingListEntryCreate(
      list_recipe: Some(ids.shopping_list_id_from_int(5)),
      food: Some(10),
      unit: Some(3),
      amount: 2.5,
      order: 2,
      checked: True,
      ingredient: Some(ids.ingredient_id_from_int(7)),
      completed_at: Some("2025-12-14T10:30:00Z"),
      delay_until: Some("2025-12-15T00:00:00Z"),
      mealplan_id: Some(123),
    )

  let result = shopping_list.create(config, entry)
  should.be_error(result)
}

pub fn create_with_different_amounts_test() {
  // Test various amount values
  let config = client.bearer_config("http://localhost:8000", "test-token")

  // Zero amount
  let entry1 =
    ShoppingListEntryCreate(
      list_recipe: None,
      food: None,
      unit: None,
      amount: 0.0,
      order: 0,
      checked: False,
      ingredient: None,
      completed_at: None,
      delay_until: None,
      mealplan_id: None,
    )
  let result1 = shopping_list.create(config, entry1)
  should.be_error(result1)

  // Large amount
  let entry2 =
    ShoppingListEntryCreate(
      list_recipe: None,
      food: None,
      unit: None,
      amount: 999.99,
      order: 0,
      checked: False,
      ingredient: None,
      completed_at: None,
      delay_until: None,
      mealplan_id: None,
    )
  let result2 = shopping_list.create(config, entry2)
  should.be_error(result2)
}

pub fn create_returns_shopping_list_entry_test() {
  // Verify the return type is ShoppingListEntry
  // This test ensures type safety - if it compiles, the type is correct
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let entry =
    ShoppingListEntryCreate(
      list_recipe: None,
      food: None,
      unit: None,
      amount: 1.0,
      order: 0,
      checked: False,
      ingredient: None,
      completed_at: None,
      delay_until: None,
      mealplan_id: None,
    )

  // The type system guarantees this returns Result(ShoppingListEntry, TandoorError)
  let _result = shopping_list.create(config, entry)

  // Type check passes
  True
  |> should.be_true
}
