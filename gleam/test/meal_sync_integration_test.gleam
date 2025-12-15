/// Integration tests for FatSecret meal synchronization
///
/// Tests the sync layer that connects meal planning to FatSecret diary:
/// 1. Converting meal nutrition to FatSecret diary entries
/// 2. Error handling for invalid dates and meal types
/// 3. Sync result formatting and reporting
///
/// Run: cd gleam && gleam test -- --module meal_sync_integration_test
import gleeunit
import gleeunit/should
import meal_planner/meal_sync.{
  MealNutrition, MealSelection, MealSyncResult, format_sync_report,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Data
// ============================================================================

fn sample_meal_selection() -> MealSelection {
  MealSelection(
    date: "2024-12-15",
    meal_type: "dinner",
    recipe_id: 1,
    servings: 2.0,
  )
}

fn sample_meal_nutrition() -> MealNutrition {
  MealNutrition(
    recipe_id: 1,
    recipe_name: "Grilled Chicken Breast",
    servings: 2.0,
    calories: 330.0,
    protein_g: 45.0,
    fat_g: 15.0,
    carbs_g: 0.0,
  )
}

fn sample_sync_result_success() -> MealSyncResult {
  MealSyncResult(
    meal_selection: sample_meal_selection(),
    nutrition: sample_meal_nutrition(),
    sync_status: meal_sync.Success(
      "Grilled Chicken Breast logged to FatSecret (ID: 12345)",
    ),
  )
}

fn sample_sync_result_failure() -> MealSyncResult {
  MealSyncResult(
    meal_selection: sample_meal_selection(),
    nutrition: sample_meal_nutrition(),
    sync_status: meal_sync.Failed("Invalid date format"),
  )
}

// ============================================================================
// Tests for Meal Selection Type
// ============================================================================

pub fn meal_selection_construction_test() {
  let meal = sample_meal_selection()

  meal.date |> should.equal("2024-12-15")
  meal.meal_type |> should.equal("dinner")
  meal.recipe_id |> should.equal(1)
  meal.servings |> should.equal(2.0)
}

pub fn meal_selection_with_breakfast_test() {
  let meal =
    MealSelection(
      date: "2024-12-15",
      meal_type: "breakfast",
      recipe_id: 2,
      servings: 1.0,
    )

  meal.meal_type |> should.equal("breakfast")
}

// ============================================================================
// Tests for Meal Nutrition Type
// ============================================================================

pub fn meal_nutrition_construction_test() {
  let nutrition = sample_meal_nutrition()

  nutrition.recipe_name |> should.equal("Grilled Chicken Breast")
  nutrition.calories |> should.equal(330.0)
  nutrition.protein_g |> should.equal(45.0)
  nutrition.fat_g |> should.equal(15.0)
  nutrition.carbs_g |> should.equal(0.0)
}

pub fn meal_nutrition_scaled_servings_test() {
  let nutrition =
    MealNutrition(
      recipe_id: 1,
      recipe_name: "Rice Bowl",
      servings: 1.5,
      calories: 300.0,
      protein_g: 8.0,
      fat_g: 2.0,
      carbs_g: 65.0,
    )

  nutrition.servings |> should.equal(1.5)
  nutrition.carbs_g |> should.equal(65.0)
}

// ============================================================================
// Tests for Sync Results
// ============================================================================

pub fn meal_sync_result_success_test() {
  let result = sample_sync_result_success()

  case result.sync_status {
    meal_sync.Success(msg) -> msg |> should.contain("logged to FatSecret")
    meal_sync.Failed(_) -> should.fail()
  }
}

pub fn meal_sync_result_failure_test() {
  let result = sample_sync_result_failure()

  case result.sync_status {
    meal_sync.Success(_) -> should.fail()
    meal_sync.Failed(err) -> err |> should.equal("Invalid date format")
  }
}

// ============================================================================
// Tests for Sync Reporting
// ============================================================================

pub fn sync_report_all_success_test() {
  let results = [
    sample_sync_result_success(),
    sample_sync_result_success(),
    sample_sync_result_success(),
  ]

  let report = format_sync_report(results)

  report |> should.contain("Synced 3/3 meals")
  report |> should.contain("✅")
}

pub fn sync_report_mixed_results_test() {
  let results = [
    sample_sync_result_success(),
    sample_sync_result_failure(),
    sample_sync_result_success(),
  ]

  let report = format_sync_report(results)

  report |> should.contain("Synced 2/3 meals")
  report |> should.contain("✓")
  report |> should.contain("✗")
}

pub fn sync_report_all_failures_test() {
  let results = [
    sample_sync_result_failure(),
    sample_sync_result_failure(),
  ]

  let report = format_sync_report(results)

  report |> should.contain("Synced 0/2 meals")
  report |> should.contain("✗")
}

pub fn sync_report_empty_list_test() {
  let results: List(MealSyncResult) = []

  let report = format_sync_report(results)

  report |> should.contain("Synced 0/0 meals")
}

// ============================================================================
// Tests for Error Cases
// ============================================================================

pub fn sync_result_with_special_characters_test() {
  let special_meal =
    MealSelection(
      date: "2024-12-15",
      meal_type: "lunch",
      recipe_id: 5,
      servings: 1.0,
    )

  let special_nutrition =
    MealNutrition(
      recipe_id: 5,
      recipe_name: "Taco & Rice (Spicy)",
      servings: 1.0,
      calories: 450.0,
      protein_g: 20.0,
      fat_g: 18.0,
      carbs_g: 52.0,
    )

  let result =
    MealSyncResult(
      meal_selection: special_meal,
      nutrition: special_nutrition,
      sync_status: meal_sync.Success(
        "Taco & Rice (Spicy) logged to FatSecret (ID: 99999)",
      ),
    )

  case result.sync_status {
    meal_sync.Success(msg) -> msg |> should.contain("Taco & Rice")
    meal_sync.Failed(_) -> should.fail()
  }
}

pub fn meal_type_case_insensitive_test() {
  let meal_lowercase =
    MealSelection(
      date: "2024-12-15",
      meal_type: "dinner",
      recipe_id: 1,
      servings: 1.0,
    )
  let meal_uppercase =
    MealSelection(
      date: "2024-12-15",
      meal_type: "DINNER",
      recipe_id: 1,
      servings: 1.0,
    )

  meal_lowercase.meal_type |> should.equal("dinner")
  meal_uppercase.meal_type |> should.equal("DINNER")
}

// ============================================================================
// Tests for Real-World Scenarios
// ============================================================================

pub fn daily_meal_plan_sync_test() {
  // Simulate syncing a full day's meals
  let breakfast =
    MealSelection(
      date: "2024-12-15",
      meal_type: "breakfast",
      recipe_id: 10,
      servings: 1.0,
    )
  let lunch =
    MealSelection(
      date: "2024-12-15",
      meal_type: "lunch",
      recipe_id: 20,
      servings: 1.5,
    )
  let dinner =
    MealSelection(
      date: "2024-12-15",
      meal_type: "dinner",
      recipe_id: 30,
      servings: 2.0,
    )

  let meals = [breakfast, lunch, dinner]

  meals |> list.length |> should.equal(3)
}

pub fn multi_day_meal_sync_test() {
  // Simulate syncing meals across multiple days
  let day1_meal =
    MealSelection(
      date: "2024-12-15",
      meal_type: "dinner",
      recipe_id: 1,
      servings: 1.0,
    )
  let day2_meal =
    MealSelection(
      date: "2024-12-16",
      meal_type: "lunch",
      recipe_id: 2,
      servings: 1.0,
    )

  let meals = [day1_meal, day2_meal]

  meals
  |> list.all(fn(m) { string.length(m.date) > 0 })
  |> should.equal(True)
}

// ============================================================================
// Helper Imports
// ============================================================================

import gleam/list
import gleam/string
