//// Tests for food log handlers

import gleam/option.{None}
import gleeunit/should
import meal_planner/types.{Breakfast, FoodLogEntry, Macros}
import meal_planner/web/handlers/food_log

pub fn log_food_entry_creation_test() {
  // Test that we can create a food log entry with proper fields
  let entry =
    FoodLogEntry(
      id: "test-123",
      recipe_id: "recipe-456",
      recipe_name: "Test Recipe",
      servings: 1.5,
      macros: Macros(protein: 30.0, fat: 15.0, carbs: 45.0),
      micronutrients: None,
      meal_type: Breakfast,
      logged_at: "2025-12-04T12:00:00Z",
      source_type: "recipe",
      source_id: "recipe-456",
    )

  entry.recipe_id
  |> should.equal("recipe-456")

  entry.servings
  |> should.equal(1.5)
}

pub fn generate_entry_id_test() {
  // Test that generated entry IDs are non-empty and unique
  let id1 = food_log.generate_entry_id()
  let id2 = food_log.generate_entry_id()

  id1
  |> should.not_equal("")

  id1
  |> should.not_equal(id2)
}
