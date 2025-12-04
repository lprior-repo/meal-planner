/// Integration Test: Macro Calculation Pipeline
///
/// Tests the complete macro calculation workflow:
/// 1. Create recipes with known macros
/// 2. Add multiple foods to a daily log
/// 3. Calculate total macros for the day
/// 4. Compare to daily targets from user profile
/// 5. Test percentage calculations
/// 6. Edge cases (no foods, zero targets, etc.)
///
/// This verifies the end-to-end pipeline from food logging to macro tracking.
/// Follows TDD principles with comprehensive coverage.
import gleeunit
import gleeunit/should
import meal_planner/storage
import meal_planner/types.{
  type DailyLog, type FoodLogEntry, type Macros, type UserProfile, Active,
  Breakfast, Dinner, Gain, Low, Lunch, Macros, Moderate, Recipe, RecipeSource,
  Sedentary, Snack,
}
import test_helper

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Helpers
// ============================================================================

/// Create a test recipe with known macros
fn create_test_recipe(
  id: String,
  name: String,
  macros: Macros,
) -> Result(Nil, storage.StorageError) {
  let db = test_helper.get_test_db()

  let sql =
    "INSERT INTO recipes (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
     ON CONFLICT (id) DO UPDATE SET
       protein = EXCLUDED.protein,
       fat = EXCLUDED.fat,
       carbs = EXCLUDED.carbs"

  let ingredients = "[{\"name\":\"ingredient\",\"quantity\":\"1 cup\"}]"
  let instructions = "[\"Cook it\"]"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(id))
    |> pog.parameter(pog.text(name))
    |> pog.parameter(pog.text(ingredients))
    |> pog.parameter(pog.text(instructions))
    |> pog.parameter(pog.float(macros.protein))
    |> pog.parameter(pog.float(macros.fat))
    |> pog.parameter(pog.float(macros.carbs))
    |> pog.parameter(pog.int(1))
    |> pog.parameter(pog.text("test"))
    |> pog.parameter(pog.text("low"))
    |> pog.parameter(pog.bool(True))
    |> pog.execute(db)
  {
    Ok(_) -> Ok(Nil)
    Error(_) -> Error(storage.DatabaseError("Failed to create test recipe"))
  }
}

/// Calculate percentage of target achieved
fn calculate_percentage(actual: Float, target: Float) -> Float {
  case target >. 0.0 {
    True -> { actual /. target } *. 100.0
    False -> 0.0
  }
}

/// Helper to clean up test data
fn cleanup_test_data(date: String) {
  let db = test_helper.get_test_db()
  let _ =
    pog.query("DELETE FROM food_logs WHERE date = $1")
    |> pog.parameter(pog.text(date))
    |> pog.execute(db)
  Nil
}

// ============================================================================
// Integration Tests: Macro Calculation Pipeline
// ============================================================================

/// Test 1: Add multiple foods and calculate total macros
pub fn multiple_foods_macro_calculation_test() {
  let db = test_helper.get_test_db()
  let date = "2024-12-04"

  // Cleanup any existing test data
  cleanup_test_data(date)

  // Create test recipes with known macros
  let assert Ok(_) =
    create_test_recipe(
      "test-breakfast",
      "Scrambled Eggs",
      Macros(protein: 24.0, fat: 18.0, carbs: 2.0),
    )

  let assert Ok(_) =
    create_test_recipe(
      "test-lunch",
      "Grilled Chicken Salad",
      Macros(protein: 35.0, fat: 12.0, carbs: 8.0),
    )

  let assert Ok(_) =
    create_test_recipe(
      "test-dinner",
      "Steak with Rice",
      Macros(protein: 45.0, fat: 20.0, carbs: 50.0),
    )

  let assert Ok(_) =
    create_test_recipe(
      "test-snack",
      "Protein Shake",
      Macros(protein: 30.0, fat: 5.0, carbs: 10.0),
    )

  // Log foods to daily log
  let assert Ok(breakfast_entry) =
    storage.save_food_to_log(
      db,
      date,
      RecipeSource("test-breakfast"),
      1.0,
      Breakfast,
    )

  let assert Ok(lunch_entry) =
    storage.save_food_to_log(db, date, RecipeSource("test-lunch"), 1.5, Lunch)

  let assert Ok(dinner_entry) =
    storage.save_food_to_log(db, date, RecipeSource("test-dinner"), 1.0, Dinner)

  let assert Ok(snack_entry) =
    storage.save_food_to_log(db, date, RecipeSource("test-snack"), 2.0, Snack)

  // Get daily log and verify entries
  let assert Ok(daily_log) = storage.get_daily_log(db, date)

  // Verify we have all 4 entries
  should.equal(4, count_entries(daily_log.entries))

  // Calculate expected totals
  // Breakfast: 1.0 * (24p, 18f, 2c) = (24p, 18f, 2c)
  // Lunch: 1.5 * (35p, 12f, 8c) = (52.5p, 18f, 12c)
  // Dinner: 1.0 * (45p, 20f, 50c) = (45p, 20f, 50c)
  // Snack: 2.0 * (30p, 5f, 10c) = (60p, 10f, 20c)
  // Total: (181.5p, 66f, 84c)
  let expected_protein = 24.0 +. { 35.0 *. 1.5 } +. 45.0 +. { 30.0 *. 2.0 }
  let expected_fat = 18.0 +. { 12.0 *. 1.5 } +. 20.0 +. { 5.0 *. 2.0 }
  let expected_carbs = 2.0 +. { 8.0 *. 1.5 } +. 50.0 +. { 10.0 *. 2.0 }

  // Verify total macros (with small floating point tolerance)
  should.be_true(float_near(daily_log.total_macros.protein, expected_protein))
  should.be_true(float_near(daily_log.total_macros.fat, expected_fat))
  should.be_true(float_near(daily_log.total_macros.carbs, expected_carbs))

  // Cleanup
  cleanup_test_data(date)
}

/// Test 2: Compare to daily targets and calculate percentages
pub fn compare_to_daily_targets_test() {
  let db = test_helper.get_test_db()
  let date = "2024-12-05"

  cleanup_test_data(date)

  // Create test recipe
  let assert Ok(_) =
    create_test_recipe(
      "test-meal",
      "Balanced Meal",
      Macros(protein: 50.0, fat: 25.0, carbs: 75.0),
    )

  // Log one meal (2 servings)
  let assert Ok(_) =
    storage.save_food_to_log(db, date, RecipeSource("test-meal"), 2.0, Lunch)

  // Get daily log
  let assert Ok(daily_log) = storage.get_daily_log(db, date)

  // Create user profile with known targets
  // Bodyweight: 200 lbs, Active, Gain
  // Expected targets: protein ~200g, fat ~60g, carbs calculated
  let user_profile =
    types.UserProfile(
      id: "test-user",
      bodyweight: 200.0,
      activity_level: Active,
      goal: Gain,
      meals_per_day: 3,
    )

  let targets = types.daily_macro_targets(user_profile)

  // Actual consumed: 2.0 * (50p, 25f, 75c) = (100p, 50f, 150c)
  let consumed = daily_log.total_macros

  // Calculate percentages
  let protein_pct = calculate_percentage(consumed.protein, targets.protein)
  let fat_pct = calculate_percentage(consumed.fat, targets.fat)
  let carbs_pct = calculate_percentage(consumed.carbs, targets.carbs)

  // Verify percentages are reasonable (50% achieved for protein)
  should.be_true(protein_pct >. 40.0 && protein_pct <. 60.0)
  should.be_true(fat_pct >. 70.0 && fat_pct <. 90.0)

  // Verify consumed matches expected
  should.be_true(float_near(consumed.protein, 100.0))
  should.be_true(float_near(consumed.fat, 50.0))
  should.be_true(float_near(consumed.carbs, 150.0))

  cleanup_test_data(date)
}

/// Test 3: Edge case - No foods logged (empty day)
pub fn empty_day_macro_calculation_test() {
  let db = test_helper.get_test_db()
  let date = "2024-12-06"

  cleanup_test_data(date)

  // Get daily log for a day with no entries
  let assert Ok(daily_log) = storage.get_daily_log(db, date)

  // Verify no entries
  should.equal(0, count_entries(daily_log.entries))

  // Verify total macros are zero
  should.be_true(float_near(daily_log.total_macros.protein, 0.0))
  should.be_true(float_near(daily_log.total_macros.fat, 0.0))
  should.be_true(float_near(daily_log.total_macros.carbs, 0.0))

  cleanup_test_data(date)
}

/// Test 4: Edge case - Zero targets (percentage calculation)
pub fn zero_targets_percentage_test() {
  // Create user with zero bodyweight (edge case)
  let user_profile =
    types.UserProfile(
      id: "test-user-zero",
      bodyweight: 0.0,
      activity_level: Sedentary,
      goal: types.Maintain,
      meals_per_day: 3,
    )

  let targets = types.daily_macro_targets(user_profile)

  // All targets should be zero or very small
  should.be_true(targets.protein <. 1.0)
  should.be_true(targets.fat <. 1.0)

  // Calculate percentage with zero target (should return 0.0, not crash)
  let pct = calculate_percentage(50.0, 0.0)
  should.equal(0.0, pct)
}

/// Test 5: Different servings sizes
pub fn different_servings_macro_calculation_test() {
  let db = test_helper.get_test_db()
  let date = "2024-12-07"

  cleanup_test_data(date)

  // Create test recipe
  let assert Ok(_) =
    create_test_recipe(
      "test-variable",
      "Variable Portions",
      Macros(protein: 20.0, fat: 10.0, carbs: 30.0),
    )

  // Log with different serving sizes
  let assert Ok(_) =
    storage.save_food_to_log(
      db,
      date,
      RecipeSource("test-variable"),
      0.5,
      Breakfast,
    )

  let assert Ok(_) =
    storage.save_food_to_log(
      db,
      date,
      RecipeSource("test-variable"),
      1.0,
      Lunch,
    )

  let assert Ok(_) =
    storage.save_food_to_log(
      db,
      date,
      RecipeSource("test-variable"),
      2.5,
      Dinner,
    )

  // Get daily log
  let assert Ok(daily_log) = storage.get_daily_log(db, date)

  // Calculate expected: 0.5 + 1.0 + 2.5 = 4.0 total servings
  // Total: 4.0 * (20p, 10f, 30c) = (80p, 40f, 120c)
  let expected_protein = { 0.5 +. 1.0 +. 2.5 } *. 20.0
  let expected_fat = { 0.5 +. 1.0 +. 2.5 } *. 10.0
  let expected_carbs = { 0.5 +. 1.0 +. 2.5 } *. 30.0

  should.be_true(float_near(daily_log.total_macros.protein, expected_protein))
  should.be_true(float_near(daily_log.total_macros.fat, expected_fat))
  should.be_true(float_near(daily_log.total_macros.carbs, expected_carbs))

  cleanup_test_data(date)
}

/// Test 6: Calorie calculation from macros
pub fn calorie_calculation_test() {
  let db = test_helper.get_test_db()
  let date = "2024-12-08"

  cleanup_test_data(date)

  // Create recipe with known macros
  // Protein: 30g * 4 cal/g = 120 cal
  // Fat: 20g * 9 cal/g = 180 cal
  // Carbs: 50g * 4 cal/g = 200 cal
  // Total: 500 calories
  let assert Ok(_) =
    create_test_recipe(
      "test-calories",
      "Calorie Test Meal",
      Macros(protein: 30.0, fat: 20.0, carbs: 50.0),
    )

  // Log 2 servings
  let assert Ok(_) =
    storage.save_food_to_log(
      db,
      date,
      RecipeSource("test-calories"),
      2.0,
      Lunch,
    )

  // Get daily log
  let assert Ok(daily_log) = storage.get_daily_log(db, date)

  // Calculate calories from macros
  let total_calories = types.macros_calories(daily_log.total_macros)

  // Expected: 2 servings * 500 cal = 1000 calories
  let expected_calories = 1000.0
  should.be_true(float_near(total_calories, expected_calories))

  cleanup_test_data(date)
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Count entries in a list (for readability)
fn count_entries(entries: List(FoodLogEntry)) -> Int {
  list.fold(entries, 0, fn(count, _) { count + 1 })
}

/// Check if two floats are nearly equal (within 0.01 tolerance)
fn float_near(a: Float, b: Float) -> Bool {
  let diff = case a >. b {
    True -> a -. b
    False -> b -. a
  }
  diff <. 0.01
}

@external(erlang, "gleam@erlang", "rescue")
fn rescue(a: fn() -> a) -> Result(a, b)

// Import list for helper
import gleam/list
import pog
