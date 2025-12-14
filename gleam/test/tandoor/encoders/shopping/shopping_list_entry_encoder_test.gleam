/// Tests for shopping list entry encoder
import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/encoders/shopping/shopping_list_entry_encoder
import meal_planner/tandoor/types/shopping/shopping_list_entry.{
  ShoppingListEntryCreate, ShoppingListEntryUpdate,
}

pub fn encode_shopping_list_entry_create_minimal_test() {
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

  let encoded =
    shopping_list_entry_encoder.encode_shopping_list_entry_create(entry)
  let json_string = json.to_string(encoded)

  // Should contain all fields with null for optional ones
  json_string
  |> should.equal(
    "{\"list_recipe\":null,\"food\":null,\"unit\":null,\"amount\":1.0,\"order\":0,\"checked\":false,\"ingredient\":null,\"completed_at\":null,\"delay_until\":null,\"mealplan_id\":null}",
  )
}

pub fn encode_shopping_list_entry_create_with_values_test() {
  let entry =
    ShoppingListEntryCreate(
      list_recipe: Some(ids.shopping_list_id_from_int(1)),
      food: Some(ids.food_id_from_int(42)),
      unit: Some(ids.unit_id_from_int(5)),
      amount: 2.5,
      order: 3,
      checked: True,
      ingredient: Some(ids.ingredient_id_from_int(100)),
      completed_at: Some("2025-12-14T14:00:00Z"),
      delay_until: Some("2025-12-15T10:00:00Z"),
      mealplan_id: Some(10),
    )

  let encoded =
    shopping_list_entry_encoder.encode_shopping_list_entry_create(entry)
  let json_string = json.to_string(encoded)

  // Verify it contains expected values
  json_string
  |> should.equal(
    "{\"list_recipe\":1,\"food\":42,\"unit\":5,\"amount\":2.5,\"order\":3,\"checked\":true,\"ingredient\":100,\"completed_at\":\"2025-12-14T14:00:00Z\",\"delay_until\":\"2025-12-15T10:00:00Z\",\"mealplan_id\":10}",
  )
}

pub fn encode_shopping_list_entry_update_minimal_test() {
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

  let encoded =
    shopping_list_entry_encoder.encode_shopping_list_entry_update(update)
  let json_string = json.to_string(encoded)

  json_string
  |> should.equal(
    "{\"list_recipe\":null,\"food\":null,\"unit\":null,\"amount\":1.0,\"order\":0,\"checked\":false,\"ingredient\":null,\"completed_at\":null,\"delay_until\":null}",
  )
}

pub fn encode_shopping_list_entry_update_with_values_test() {
  let update =
    ShoppingListEntryUpdate(
      list_recipe: Some(ids.shopping_list_id_from_int(2)),
      food: Some(ids.food_id_from_int(99)),
      unit: Some(ids.unit_id_from_int(7)),
      amount: 3.0,
      order: 1,
      checked: True,
      ingredient: Some(ids.ingredient_id_from_int(200)),
      completed_at: Some("2025-12-14T15:00:00Z"),
      delay_until: None,
    )

  let encoded =
    shopping_list_entry_encoder.encode_shopping_list_entry_update(update)
  let json_string = json.to_string(encoded)

  json_string
  |> should.equal(
    "{\"list_recipe\":2,\"food\":99,\"unit\":7,\"amount\":3.0,\"order\":1,\"checked\":true,\"ingredient\":200,\"completed_at\":\"2025-12-14T15:00:00Z\",\"delay_until\":null}",
  )
}
