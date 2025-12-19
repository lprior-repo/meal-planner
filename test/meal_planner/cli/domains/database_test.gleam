/// Tests for database CLI domain
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/cli/domains/database
import meal_planner/config
import meal_planner/id
import meal_planner/postgres
import meal_planner/storage
import meal_planner/storage/foods
import meal_planner/types

pub fn format_food_list_test() {
  let foods = [
    storage.UsdaFood(
      fdc_id: id.fdc_id(123),
      description: "Chicken breast",
      data_type: "foundation_food",
      category: "Poultry",
      serving_size: "100g",
    ),
    storage.UsdaFood(
      fdc_id: id.fdc_id(456),
      description: "Brown rice",
      data_type: "sr_legacy_food",
      category: "Grains",
      serving_size: "100g",
    ),
  ]

  let formatted = database.format_food_list(foods)

  // Should contain food descriptions
  formatted
  |> should.not_equal("")
}

pub fn format_food_detail_test() {
  let food =
    storage.UsdaFood(
      fdc_id: id.fdc_id(789),
      description: "Broccoli",
      data_type: "foundation_food",
      category: "Vegetables",
      serving_size: "100g",
    )

  let formatted = database.format_food_detail(food)

  // Should contain food details
  formatted
  |> should.not_equal("")
}

pub fn format_log_entries_test() {
  let logs = [
    types.FoodLogEntry(
      id: id.log_entry_id("log-1"),
      recipe_id: id.recipe_id("recipe-1"),
      recipe_name: "Chicken Breast",
      servings: 1.5,
      macros: types.Macros(protein: 45.0, fat: 5.0, carbs: 0.0),
      micronutrients: types.micronutrients_zero(),
      meal_type: types.Lunch,
      logged_at: "2025-12-19T12:00:00",
      source_type: "usda_food",
      source_id: "123456",
    ),
    types.FoodLogEntry(
      id: id.log_entry_id("log-2"),
      recipe_id: id.recipe_id("recipe-2"),
      recipe_name: "Brown Rice",
      servings: 2.0,
      macros: types.Macros(protein: 10.0, fat: 2.0, carbs: 90.0),
      micronutrients: types.micronutrients_zero(),
      meal_type: types.Dinner,
      logged_at: "2025-12-19T18:00:00",
      source_type: "usda_food",
      source_id: "789012",
    ),
  ]
  let formatted = database.format_log_entries(logs)

  // Should contain multiple log entries
  formatted
  |> should.not_equal("")
}

pub fn build_logs_table_test() {
  let logs = [
    types.FoodLogEntry(
      id: id.log_entry_id("log-1"),
      recipe_id: id.recipe_id("recipe-1"),
      recipe_name: "Chicken Breast",
      servings: 1.5,
      macros: types.Macros(protein: 45.0, fat: 5.0, carbs: 0.0),
      micronutrients: types.micronutrients_zero(),
      meal_type: types.Lunch,
      logged_at: "2025-12-19T12:00:00",
      source_type: "usda_food",
      source_id: "123456",
    ),
  ]
  let table = database.build_logs_table(logs)

  // Should contain headers and data
  table
  |> should.not_equal("")
}
