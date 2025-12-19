/// FatSecret batch sync tests (RED phase)
///
/// Tests batch meal logging with error scenarios following TDD/TCR workflow.
/// Uses complete_week_balanced.json fixture (7 meals).
import gleam/list
import gleam/option.{None}
import gleeunit
import gleeunit/should
import meal_planner/fatsecret/meal_logger
import meal_planner/fatsecret/meal_logger/errors.{InvalidServings}
import meal_planner/id
import meal_planner/types/macros.{Macros}
import meal_planner/types/recipe

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Helpers
// ============================================================================

/// Create test recipes from fixture data
fn create_test_recipes() -> List(#(recipe.MealPlanRecipe, Int, String, String)) {
  let assert Ok(recipe1) =
    recipe.new_meal_plan_recipe(
      id: id.recipe_id("recipe-101"),
      name: "Protein Pancakes",
      servings: 2,
      macros: Macros(protein: 25.0, fat: 9.0, carbs: 32.5),
      image: None,
      prep_time: 10,
      cook_time: 15,
    )

  let assert Ok(recipe2) =
    recipe.new_meal_plan_recipe(
      id: id.recipe_id("recipe-102"),
      name: "Grilled Chicken Salad",
      servings: 1,
      macros: Macros(protein: 40.0, fat: 12.0, carbs: 15.0),
      image: None,
      prep_time: 15,
      cook_time: 0,
    )

  let assert Ok(recipe3) =
    recipe.new_meal_plan_recipe(
      id: id.recipe_id("recipe-103"),
      name: "Salmon with Quinoa",
      servings: 1,
      macros: Macros(protein: 35.0, fat: 18.0, carbs: 45.0),
      image: None,
      prep_time: 10,
      cook_time: 20,
    )

  let assert Ok(recipe4) =
    recipe.new_meal_plan_recipe(
      id: id.recipe_id("recipe-104"),
      name: "Greek Yogurt Bowl",
      servings: 1,
      macros: Macros(protein: 20.0, fat: 8.0, carbs: 30.0),
      image: None,
      prep_time: 5,
      cook_time: 0,
    )

  let assert Ok(recipe5) =
    recipe.new_meal_plan_recipe(
      id: id.recipe_id("recipe-105"),
      name: "Turkey Wrap",
      servings: 2,
      macros: Macros(protein: 28.0, fat: 10.0, carbs: 35.0),
      image: None,
      prep_time: 10,
      cook_time: 0,
    )

  let assert Ok(recipe6) =
    recipe.new_meal_plan_recipe(
      id: id.recipe_id("recipe-106"),
      name: "Beef Stir Fry",
      servings: 1,
      macros: Macros(protein: 38.0, fat: 15.0, carbs: 40.0),
      image: None,
      prep_time: 15,
      cook_time: 12,
    )

  let assert Ok(recipe7) =
    recipe.new_meal_plan_recipe(
      id: id.recipe_id("recipe-107"),
      name: "Omelette with Veggies",
      servings: 1,
      macros: Macros(protein: 22.0, fat: 14.0, carbs: 8.0),
      image: None,
      prep_time: 10,
      cook_time: 8,
    )

  [
    #(recipe1, 2, "2025-12-22", "breakfast"),
    #(recipe2, 1, "2025-12-22", "lunch"),
    #(recipe3, 1, "2025-12-22", "dinner"),
    #(recipe4, 1, "2025-12-23", "breakfast"),
    #(recipe5, 2, "2025-12-23", "lunch"),
    #(recipe6, 1, "2025-12-23", "dinner"),
    #(recipe7, 1, "2025-12-24", "breakfast"),
  ]
}

// ============================================================================
// TEST 1: Batch sync logs multiple meals successfully
// ============================================================================

/// Test: Batch sync logs 7 meals successfully
///
/// Requirement: Log all 7 meals from complete_week_balanced.json fixture
///
/// Given: 7 meals with valid recipes, servings, dates, meal_types
/// When: We batch sync all meals to FatSecret
/// Then:
///   - All 7 meals logged successfully
///   - BatchResult.succeeded contains 7 entries
///   - BatchResult.failed is empty
///   - Each entry has correct macros calculated
///
/// Data from complete_week_balanced.json:
///   - Monday: breakfast (2 servings), lunch (1), dinner (1)
///   - Tuesday: breakfast (1), lunch (2), dinner (1)
///   - Wednesday: breakfast (1)
pub fn batch_sync_logs_multiple_meals_test() {
  // Create 7 meal entries from fixture
  let meals = create_test_recipes()

  // Create batch entries
  let batch_entries =
    meals
    |> list.map(fn(meal) {
      let #(recipe, servings, date, meal_type) = meal
      meal_logger.create_batch_entry(recipe, servings, date, meal_type)
    })

  // Batch log all meals
  let result = meal_logger.batch_log_meals(batch_entries)

  // Verify: batch operation succeeded
  should.be_ok(result)

  let assert Ok(batch_result) = result

  // Verify: all 7 meals logged successfully
  should.equal(list.length(batch_result.succeeded), 7)
  should.equal(list.length(batch_result.failed), 0)

  // Verify: first meal has correct macros (Protein Pancakes, 2 servings)
  let assert [first, ..] = batch_result.succeeded
  should.equal(first.recipe_id, "recipe-101")
  should.equal(first.protein_g, 50.0)
  should.equal(first.fat_g, 18.0)
  should.equal(first.carbs_g, 65.0)
}

// ============================================================================
// TEST 2: Batch sync handles partial failure
// ============================================================================

/// Test: Batch sync handles partial failure gracefully
///
/// Requirement: Continue processing all meals even if some fail
///
/// Given: 7 meals, 2 with invalid data (negative servings)
/// When: We batch sync all meals
/// Then:
///   - 5 meals logged successfully
///   - 2 meals failed with validation errors
///   - BatchResult.succeeded contains 5 entries
///   - BatchResult.failed contains 2 entries with errors
///
/// Failure scenarios:
///   - Meal 3: Invalid servings (-1)
///   - Meal 5: Invalid servings (0)
pub fn batch_sync_handles_partial_failure_test() {
  // Create valid recipes
  let meals = create_test_recipes()

  // Extract recipes for manipulation
  let assert [meal1, meal2, meal3, meal4, meal5, meal6, meal7] = meals

  // Create batch with 2 invalid entries (negative/zero servings)
  let #(recipe3, _, date3, meal_type3) = meal3
  let #(recipe5, _, date5, meal_type5) = meal5

  let batch_entries = [
    meal_logger.create_batch_entry(meal1.0, meal1.1, meal1.2, meal1.3),
    meal_logger.create_batch_entry(meal2.0, meal2.1, meal2.2, meal2.3),
    // Invalid: negative servings
    meal_logger.create_batch_entry(recipe3, -1, date3, meal_type3),
    meal_logger.create_batch_entry(meal4.0, meal4.1, meal4.2, meal4.3),
    // Invalid: zero servings
    meal_logger.create_batch_entry(recipe5, 0, date5, meal_type5),
    meal_logger.create_batch_entry(meal6.0, meal6.1, meal6.2, meal6.3),
    meal_logger.create_batch_entry(meal7.0, meal7.1, meal7.2, meal7.3),
  ]

  // Batch log meals (should handle partial failure)
  let result = meal_logger.batch_log_meals(batch_entries)

  // Verify: batch operation succeeded (partial success is Ok)
  should.be_ok(result)

  let assert Ok(batch_result) = result

  // Verify: 5 succeeded, 2 failed
  should.equal(list.length(batch_result.succeeded), 5)
  should.equal(list.length(batch_result.failed), 2)

  // Verify: failed entries have correct error types
  let assert [#(_entry1, error1), #(_entry2, error2)] = batch_result.failed

  // Both should be InvalidServings errors
  case error1 {
    InvalidServings(value) -> should.equal(value, -1)
    _ -> should.fail()
  }

  case error2 {
    InvalidServings(value) -> should.equal(value, 0)
    _ -> should.fail()
  }
}

// ============================================================================
// TEST 3: Batch sync respects retry policy
// ============================================================================

/// Test: Batch sync respects retry policy on transient failures
///
/// Requirement: Retry failed meals with exponential backoff
///
/// Given: 7 meals, 1 with transient failure (network timeout)
/// When: We batch sync with retry enabled
/// Then:
///   - Failed meal is retried automatically
///   - Retry uses exponential backoff (1s, 2s, 4s)
///   - After 3 retries, all meals succeed
///   - Retry history logged for diagnostics
///
/// Retry scenario:
///   - Meal 4: Simulated timeout (retryable error)
///   - Should succeed on retry #2
pub fn batch_sync_respects_retry_policy_test() {
  // Create meals
  let meals = create_test_recipes()

  // Create batch entries
  let batch_entries =
    meals
    |> list.map(fn(meal) {
      let #(recipe, servings, date, meal_type) = meal
      meal_logger.create_batch_entry(recipe, servings, date, meal_type)
    })

  // Batch log with retry (default config: 3 attempts, exponential backoff)
  let result = meal_logger.sync_meals_batch_with_retry(batch_entries)

  // Verify: batch succeeded after retries
  should.be_ok(result)

  let assert Ok(batch_result) = result

  // Verify: all 7 meals eventually succeeded
  should.equal(list.length(batch_result.succeeded), 7)
  should.equal(list.length(batch_result.failed), 0)
  // TODO: Verify retry history once execution tracking is implemented
  // Expected retry log:
  //   - Meal 4: attempt 1 (timeout), attempt 2 (success)
  //   - Delay between attempts: 1000ms, 2000ms
}

// ============================================================================
// TEST 4: Batch sync tracks execution history
// ============================================================================

/// Test: Batch sync tracks all attempts in execution history
///
/// Requirement: Log all sync attempts for debugging and auditing
///
/// Given: 7 meals batch logged with retry
/// When: We query execution history
/// Then:
///   - All 7 meals have execution entries
///   - Failed attempts are logged with error details
///   - Retry attempts are logged with attempt number
///   - Final success/failure status is correct
///
/// Expected history:
///   - Meals 1-7: 1 attempt each (all succeed)
///   - Total execution log entries: 7
pub fn batch_sync_tracks_execution_history_test() {
  // Create meals
  let meals = create_test_recipes()

  // Create batch entries
  let batch_entries =
    meals
    |> list.map(fn(meal) {
      let #(recipe, servings, date, meal_type) = meal
      meal_logger.create_batch_entry(recipe, servings, date, meal_type)
    })

  // Batch log with retry
  let result = meal_logger.sync_meals_batch_with_retry(batch_entries)

  // Verify: batch succeeded
  should.be_ok(result)

  // TODO: Query execution history once tracking is implemented
  // Expected history structure:
  //   - execution_id: UUID
  //   - recipe_id: "recipe-101"
  //   - attempt_number: 1
  //   - status: "success"
  //   - error: None
  //   - timestamp: ISO8601
  //
  // For now, this test fails because execution tracking is not implemented
  should.fail()
}
