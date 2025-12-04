/// Integration Test Helper
///
/// Provides test infrastructure for integration tests following evolutionary design principles.
/// Supports:
/// - Database connection setup/teardown
/// - Test fixture generation (foods, meals, logs)
/// - Assertion helpers for integration tests
/// - Mock context creation utilities
///
/// Based on Martin Fowler's evolutionary design: comprehensive tests enable confident refactoring.
import gleam/dynamic
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/storage
import meal_planner/types.{
  type DailyLog, type FoodLogEntry, type Macros, type MealType,
  type Micronutrients, type Recipe, Breakfast, DailyLog, Dinner, FoodLogEntry,
  Lunch, Macros, Micronutrients, Recipe, Snack,
}
import pog

// ============================================================================
// Database Setup and Teardown
// ============================================================================

/// Test database configuration
/// Uses environment variables or defaults for test database
pub type TestDbConfig {
  TestDbConfig(
    host: String,
    port: Int,
    database: String,
    user: String,
    password: String,
  )
}

/// Get test database configuration from environment or use defaults
pub fn test_db_config() -> TestDbConfig {
  TestDbConfig(
    host: "localhost",
    port: 5432,
    database: "meal_planner_test",
    user: "meal_planner",
    password: "meal_planner",
  )
}

/// Connect to test database
/// Returns a connection that should be cleaned up with cleanup_test_db()
pub fn setup_test_db() -> Result(pog.Connection, String) {
  let config = test_db_config()
  let pool_name = process.new_name(prefix: "test_pool")

  pog.default_config(pool_name)
  |> pog.host(config.host)
  |> pog.port(config.port)
  |> pog.database(config.database)
  |> pog.user(config.user)
  |> pog.password(Some(config.password))
  |> pog.pool_size(5)
  |> pog.start
  |> result.map(fn(started) { started.data })
  |> result.map_error(fn(_) {
    "Failed to connect to test database. Ensure PostgreSQL is running and meal_planner_test database exists."
  })
}

/// Clean up test data and close database connection
/// Should be called after each test to ensure isolation
pub fn cleanup_test_db(conn: pog.Connection) -> Nil {
  // Clean up test data (in reverse foreign key dependency order)
  let _ =
    pog.query("DELETE FROM food_log WHERE logged_at >= '2024-01-01'")
    |> pog.execute(conn)

  let _ =
    pog.query("DELETE FROM recipes WHERE id LIKE 'test-%'")
    |> pog.execute(conn)

  let _ =
    pog.query("DELETE FROM custom_foods WHERE id LIKE 'test-%'")
    |> pog.execute(conn)

  // Note: We don't close the connection here as it's a pool connection
  // The pool will manage connection lifecycle
  Nil
}

// ============================================================================
// Test Fixture Generators
// ============================================================================

/// Generate a test recipe with known macros
/// Useful for testing food logging and macro calculation flows
pub fn fixture_recipe(
  id: String,
  name: String,
  macros: Macros,
  servings: Int,
) -> Recipe {
  Recipe(
    id: "test-" <> id,
    name: name,
    ingredients: [],
    instructions: ["Test recipe instructions"],
    macros: macros,
    servings: servings,
    category: "Test",
    fodmap_level: types.Low,
    micronutrients: None,
    prep_time: Some(10),
    cook_time: Some(20),
    total_time: Some(30),
    tags: ["test"],
    source: Some("test-fixture"),
  )
}

/// Generate a simple high-protein recipe for testing
/// 30g protein, 5g fat, 10g carbs per serving
pub fn fixture_high_protein_meal() -> Recipe {
  fixture_recipe(
    "high-protein-meal",
    "Test High Protein Meal",
    Macros(protein: 30.0, fat: 5.0, carbs: 10.0),
    1,
  )
}

/// Generate a balanced recipe for testing
/// 20g protein, 15g fat, 40g carbs per serving
pub fn fixture_balanced_meal() -> Recipe {
  fixture_recipe(
    "balanced-meal",
    "Test Balanced Meal",
    Macros(protein: 20.0, fat: 15.0, carbs: 40.0),
    4,
  )
}

/// Generate a low-carb recipe for testing
/// 25g protein, 20g fat, 5g carbs per serving
pub fn fixture_low_carb_meal() -> Recipe {
  fixture_recipe(
    "low-carb-meal",
    "Test Low Carb Meal",
    Macros(protein: 25.0, fat: 20.0, carbs: 5.0),
    2,
  )
}

/// Generate test macros with predictable values
pub fn fixture_macros(protein: Float, fat: Float, carbs: Float) -> Macros {
  Macros(protein: protein, fat: fat, carbs: carbs)
}

/// Generate test micronutrients with common vitamins/minerals
pub fn fixture_micronutrients() -> Micronutrients {
  Micronutrients(
    fiber: Some(5.0),
    sugar: Some(10.0),
    sodium: Some(400.0),
    cholesterol: Some(50.0),
    vitamin_a: Some(500.0),
    vitamin_c: Some(30.0),
    vitamin_d: Some(10.0),
    vitamin_e: Some(5.0),
    vitamin_k: Some(80.0),
    vitamin_b6: Some(1.5),
    vitamin_b12: Some(2.0),
    folate: Some(200.0),
    thiamin: Some(1.0),
    riboflavin: Some(1.2),
    niacin: Some(15.0),
    calcium: Some(300.0),
    iron: Some(8.0),
    magnesium: Some(100.0),
    phosphorus: Some(250.0),
    potassium: Some(500.0),
    zinc: Some(5.0),
  )
}

/// Generate a test food log entry
pub fn fixture_food_log_entry(
  id: String,
  recipe_id: String,
  recipe_name: String,
  servings: Float,
  macros: Macros,
  meal_type: MealType,
) -> FoodLogEntry {
  FoodLogEntry(
    id: "test-log-" <> id,
    recipe_id: recipe_id,
    recipe_name: recipe_name,
    servings: servings,
    macros: macros,
    micronutrients: None,
    meal_type: meal_type,
    logged_at: "2024-01-15T12:00:00Z",
    source_type: "recipe",
    source_id: recipe_id,
  )
}

/// Generate a test daily log with multiple entries
pub fn fixture_daily_log(date: String, entries: List(FoodLogEntry)) -> DailyLog {
  let total_macros =
    list.fold(entries, types.macros_zero(), fn(acc, entry) {
      types.macros_add(acc, entry.macros)
    })

  DailyLog(
    date: date,
    entries: entries,
    total_macros: total_macros,
    total_micronutrients: None,
  )
}

// ============================================================================
// Assertion Helpers
// ============================================================================

/// Assert that macros are within tolerance (±0.1g)
/// Useful for floating point comparisons in tests
pub fn assert_macros_equal(
  actual: Macros,
  expected: Macros,
  tolerance: Float,
) -> Result(Nil, String) {
  let protein_diff = float_abs(actual.protein -. expected.protein)
  let fat_diff = float_abs(actual.fat -. expected.fat)
  let carbs_diff = float_abs(actual.carbs -. expected.carbs)

  case
    protein_diff <=. tolerance
    && fat_diff <=. tolerance
    && carbs_diff <=. tolerance
  {
    True -> Ok(Nil)
    False -> {
      let message =
        "Macros not equal within tolerance "
        <> float_to_string(tolerance)
        <> "\n"
        <> "Expected: P="
        <> float_to_string(expected.protein)
        <> " F="
        <> float_to_string(expected.fat)
        <> " C="
        <> float_to_string(expected.carbs)
        <> "\n"
        <> "Actual:   P="
        <> float_to_string(actual.protein)
        <> " F="
        <> float_to_string(actual.fat)
        <> " C="
        <> float_to_string(actual.carbs)

      Error(message)
    }
  }
}

/// Assert that calories are calculated correctly from macros
/// 4cal/g protein, 9cal/g fat, 4cal/g carbs
pub fn assert_calories_correct(macros: Macros) -> Result(Nil, String) {
  let expected_calories = types.macros_calories(macros)
  let calculated =
    { macros.protein *. 4.0 }
    +. { macros.fat *. 9.0 }
    +. { macros.carbs *. 4.0 }

  case float_abs(calculated -. expected_calories) <=. 0.1 {
    True -> Ok(Nil)
    False ->
      Error(
        "Calories mismatch: expected "
        <> float_to_string(expected_calories)
        <> ", got "
        <> float_to_string(calculated),
      )
  }
}

/// Assert that a list has expected length
pub fn assert_list_length(
  list: List(a),
  expected: Int,
  label: String,
) -> Result(Nil, String) {
  let actual = list.length(list)
  case actual == expected {
    True -> Ok(Nil)
    False ->
      Error(
        label
        <> ": expected length "
        <> int.to_string(expected)
        <> ", got "
        <> int.to_string(actual),
      )
  }
}

/// Assert that a value is Some and unwrap it
pub fn assert_some(opt: Option(a), label: String) -> Result(a, String) {
  case opt {
    Some(value) -> Ok(value)
    None -> Error(label <> ": expected Some, got None")
  }
}

/// Assert that a value is None
pub fn assert_none(opt: Option(a), label: String) -> Result(Nil, String) {
  case opt {
    None -> Ok(Nil)
    Some(_) -> Error(label <> ": expected None, got Some")
  }
}

// ============================================================================
// Helper Utilities
// ============================================================================

/// Absolute value for floats
fn float_abs(x: Float) -> Float {
  case x >=. 0.0 {
    True -> x
    False -> 0.0 -. x
  }
}

/// Convert float to string for error messages
fn float_to_string(x: Float) -> String {
  // Use string interpolation when available, fallback to simple conversion
  let s = string.inspect(x)
  s
}

/// Save a test recipe to database
/// Returns the saved recipe or error
pub fn save_test_recipe(
  conn: pog.Connection,
  recipe: Recipe,
) -> Result(Recipe, String) {
  // Use storage module to save recipe
  // Note: This assumes storage.save_recipe exists or we need to use raw SQL
  let sql =
    "INSERT INTO recipes (id, name, category, servings,
                          protein, fat, carbs,
                          prep_time, cook_time, total_time)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
     RETURNING id"

  pog.query(sql)
  |> pog.parameter(pog.text(recipe.id))
  |> pog.parameter(pog.text(recipe.name))
  |> pog.parameter(pog.text(recipe.category))
  |> pog.parameter(pog.int(recipe.servings))
  |> pog.parameter(pog.float(recipe.macros.protein))
  |> pog.parameter(pog.float(recipe.macros.fat))
  |> pog.parameter(pog.float(recipe.macros.carbs))
  |> pog.parameter(pog.nullable(pog.int, recipe.prep_time))
  |> pog.parameter(pog.nullable(pog.int, recipe.cook_time))
  |> pog.parameter(pog.nullable(pog.int, recipe.total_time))
  |> pog.returning(decode.element(0, decode.string))
  |> pog.execute(conn)
  |> result.map(fn(response) {
    // Recipe saved successfully
    recipe
  })
  |> result.map_error(fn(err) {
    "Failed to save test recipe: " <> string.inspect(err)
  })
}

/// Query food log entries for a specific date
pub fn get_test_food_log(
  conn: pog.Connection,
  date: String,
) -> Result(List(FoodLogEntry), String) {
  // Use storage.get_daily_log if available
  storage.get_daily_log(conn, date)
  |> result.map(fn(daily_log) { daily_log.entries })
  |> result.map_error(fn(_) { "Failed to get food log for date " <> date })
}
