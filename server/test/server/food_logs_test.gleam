//// Tests for food logging functionality

import gleam/json
import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import server/storage
import shared/types

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Storage Tests
// ============================================================================

pub fn test_save_and_retrieve_food_log_test() {
  // Create an in-memory database for testing
  let test_db = ":memory:"

  storage.with_connection(test_db, fn(conn) {
    // Initialize database
    let assert Ok(_) = storage.init_db(conn)

    // Create a test recipe first
    let recipe =
      types.Recipe(
        id: "test-recipe-1",
        name: "Test Meal",
        ingredients: [
          types.Ingredient(name: "Test Ingredient", quantity: "100g"),
        ],
        instructions: ["Test instruction"],
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
        servings: 1,
        category: "test",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    // Create a food log entry
    let entry =
      types.FoodLogEntry(
        id: "log-123",
        recipe_id: "test-recipe-1",
        recipe_name: "Test Meal",
        servings: 1.5,
        macros: types.Macros(protein: 45.0, fat: 15.0, carbs: 60.0),
        meal_type: types.Lunch,
        logged_at: "2024-01-15T12:00:00Z",
      )

    // Save the entry
    let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-15", entry)

    // Retrieve the daily log
    let assert Ok(daily_log) = storage.get_daily_log(conn, "2024-01-15")

    // Verify the log
    daily_log.date
    |> should.equal("2024-01-15")

    list.length(daily_log.entries)
    |> should.equal(1)

    let assert [retrieved_entry] = daily_log.entries
    retrieved_entry.id
    |> should.equal("log-123")

    retrieved_entry.servings
    |> should.equal(1.5)

    retrieved_entry.meal_type
    |> should.equal(types.Lunch)

    // Verify macros are calculated correctly
    retrieved_entry.macros.protein
    |> should.equal(45.0)

    retrieved_entry.macros.fat
    |> should.equal(15.0)

    retrieved_entry.macros.carbs
    |> should.equal(60.0)

    // Verify total macros
    daily_log.total_macros.protein
    |> should.equal(45.0)
  })
}

pub fn test_multiple_log_entries_test() {
  let test_db = ":memory:"

  storage.with_connection(test_db, fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    // Create test recipe
    let recipe =
      types.Recipe(
        id: "test-recipe-2",
        name: "Test Meal 2",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 20.0, fat: 5.0, carbs: 30.0),
        servings: 1,
        category: "test",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    // Create multiple entries
    let entry1 =
      types.FoodLogEntry(
        id: "log-1",
        recipe_id: "test-recipe-2",
        recipe_name: "Test Meal 2",
        servings: 1.0,
        macros: types.Macros(protein: 20.0, fat: 5.0, carbs: 30.0),
        meal_type: types.Breakfast,
        logged_at: "2024-01-15T08:00:00Z",
      )

    let entry2 =
      types.FoodLogEntry(
        id: "log-2",
        recipe_id: "test-recipe-2",
        recipe_name: "Test Meal 2",
        servings: 2.0,
        macros: types.Macros(protein: 40.0, fat: 10.0, carbs: 60.0),
        meal_type: types.Lunch,
        logged_at: "2024-01-15T12:30:00Z",
      )

    let entry3 =
      types.FoodLogEntry(
        id: "log-3",
        recipe_id: "test-recipe-2",
        recipe_name: "Test Meal 2",
        servings: 1.5,
        macros: types.Macros(protein: 30.0, fat: 7.5, carbs: 45.0),
        meal_type: types.Dinner,
        logged_at: "2024-01-15T18:00:00Z",
      )

    // Save all entries
    let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-15", entry1)
    let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-15", entry2)
    let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-15", entry3)

    // Retrieve daily log
    let assert Ok(daily_log) = storage.get_daily_log(conn, "2024-01-15")

    // Verify count
    list.length(daily_log.entries)
    |> should.equal(3)

    // Verify total macros (sum of all entries)
    daily_log.total_macros.protein
    |> should.equal(90.0)

    daily_log.total_macros.fat
    |> should.equal(22.5)

    daily_log.total_macros.carbs
    |> should.equal(135.0)
  })
}

pub fn test_delete_food_log_entry_test() {
  let test_db = ":memory:"

  storage.with_connection(test_db, fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    // Create test recipe
    let recipe =
      types.Recipe(
        id: "test-recipe-3",
        name: "Test Meal 3",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 25.0, fat: 8.0, carbs: 35.0),
        servings: 1,
        category: "test",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    // Create and save entry
    let entry =
      types.FoodLogEntry(
        id: "log-delete-test",
        recipe_id: "test-recipe-3",
        recipe_name: "Test Meal 3",
        servings: 1.0,
        macros: types.Macros(protein: 25.0, fat: 8.0, carbs: 35.0),
        meal_type: types.Snack,
        logged_at: "2024-01-15T15:00:00Z",
      )
    let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-15", entry)

    // Verify it exists
    let assert Ok(log_before) = storage.get_daily_log(conn, "2024-01-15")
    list.length(log_before.entries)
    |> should.equal(1)

    // Delete the entry
    let assert Ok(_) = storage.delete_food_log_entry(conn, "log-delete-test")

    // Verify it's gone
    let assert Ok(log_after) = storage.get_daily_log(conn, "2024-01-15")
    list.length(log_after.entries)
    |> should.equal(0)
  })
}

pub fn test_empty_daily_log_test() {
  let test_db = ":memory:"

  storage.with_connection(test_db, fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    // Retrieve log for a date with no entries
    let assert Ok(daily_log) = storage.get_daily_log(conn, "2024-01-20")

    // Should return empty log
    daily_log.date
    |> should.equal("2024-01-20")

    list.length(daily_log.entries)
    |> should.equal(0)

    daily_log.total_macros.protein
    |> should.equal(0.0)

    daily_log.total_macros.fat
    |> should.equal(0.0)

    daily_log.total_macros.carbs
    |> should.equal(0.0)
  })
}

// ============================================================================
// Macro Calculation Tests
// ============================================================================

pub fn test_macro_scaling_test() {
  let original = types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0)

  // Test 1.5 servings
  let scaled = types.macros_scale(original, 1.5)
  scaled.protein
  |> should.equal(45.0)

  scaled.fat
  |> should.equal(15.0)

  scaled.carbs
  |> should.equal(60.0)

  // Test 0.5 servings
  let half = types.macros_scale(original, 0.5)
  half.protein
  |> should.equal(15.0)

  half.fat
  |> should.equal(5.0)

  half.carbs
  |> should.equal(20.0)
}

pub fn test_macros_add_test() {
  let macros1 = types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0)
  let macros2 = types.Macros(protein: 20.0, fat: 5.0, carbs: 30.0)

  let total = types.macros_add(macros1, macros2)

  total.protein
  |> should.equal(50.0)

  total.fat
  |> should.equal(15.0)

  total.carbs
  |> should.equal(70.0)
}

// ============================================================================
// Meal Type Tests
// ============================================================================

pub fn test_meal_type_encoding_test() {
  types.meal_type_to_string(types.Breakfast)
  |> should.equal("breakfast")

  types.meal_type_to_string(types.Lunch)
  |> should.equal("lunch")

  types.meal_type_to_string(types.Dinner)
  |> should.equal("dinner")

  types.meal_type_to_string(types.Snack)
  |> should.equal("snack")
}

// ============================================================================
// JSON Serialization Tests
// ============================================================================

pub fn test_food_log_entry_json_test() {
  let entry =
    types.FoodLogEntry(
      id: "log-json-test",
      recipe_id: "recipe-1",
      recipe_name: "Test Recipe",
      servings: 1.5,
      macros: types.Macros(protein: 45.0, fat: 15.0, carbs: 60.0),
      meal_type: types.Lunch,
      logged_at: "2024-01-15T12:00:00Z",
    )

  let json_str = json.to_string(types.food_log_entry_to_json(entry))

  // Verify JSON contains expected fields
  json_str
  |> should.not_equal("")

  // Should contain the ID
  should.be_true(json_str |> contains_string("log-json-test"))

  // Should contain the recipe name
  should.be_true(json_str |> contains_string("Test Recipe"))

  // Should contain the meal type
  should.be_true(json_str |> contains_string("lunch"))
}

pub fn test_daily_log_json_test() {
  let entry1 =
    types.FoodLogEntry(
      id: "log-1",
      recipe_id: "recipe-1",
      recipe_name: "Breakfast Meal",
      servings: 1.0,
      macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
      meal_type: types.Breakfast,
      logged_at: "2024-01-15T08:00:00Z",
    )

  let entry2 =
    types.FoodLogEntry(
      id: "log-2",
      recipe_id: "recipe-2",
      recipe_name: "Lunch Meal",
      servings: 1.0,
      macros: types.Macros(protein: 40.0, fat: 15.0, carbs: 50.0),
      meal_type: types.Lunch,
      logged_at: "2024-01-15T12:00:00Z",
    )

  let daily_log =
    types.DailyLog(
      date: "2024-01-15",
      entries: [entry1, entry2],
      total_macros: types.Macros(protein: 70.0, fat: 25.0, carbs: 90.0),
    )

  let json_str = json.to_string(types.daily_log_to_json(daily_log))

  // Verify JSON structure
  should.be_true(json_str |> contains_string("2024-01-15"))
  should.be_true(json_str |> contains_string("Breakfast Meal"))
  should.be_true(json_str |> contains_string("Lunch Meal"))
  should.be_true(json_str |> contains_string("total_macros"))
}

// ============================================================================
// Helper Functions
// ============================================================================

fn contains_string(haystack: String, needle: String) -> Bool {
  case haystack {
    _ if haystack == "" -> False
    _ -> string.contains(haystack, needle)
  }
}
