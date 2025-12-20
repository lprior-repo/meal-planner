/// TDD Tests for NCP Nutrition Functions
/// RED PHASE: Write tests that MUST FAIL initially
/// Tests the 5 core nutrition calculation functions:
/// 1. calculate_daily_totals - Aggregate nutrition data from multiple meals
/// 2. calculate_macro_percentages - Calculate macro percentages from absolute values
/// 3. check_macro_targets - Verify if macros meet daily goals
/// 4. suggest_macro_adjustments - Recommend adjustments to reach goals
/// 5. estimate_daily_calories - Calculate total calories from macros
import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/ncp

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// TEST DATA: Nutrition fixtures for testing
// ============================================================================

/// Create a nutrition data point
fn nutrition_data(
  protein: Float,
  fat: Float,
  carbs: Float,
  calories: Float,
) -> ncp.NutritionData {
  ncp.NutritionData(
    protein: protein,
    fat: fat,
    carbs: carbs,
    calories: calories,
  )
}

/// Create a nutrition state for a meal
fn nutrition_state(
  date: String,
  protein: Float,
  fat: Float,
  carbs: Float,
  calories: Float,
) -> ncp.NutritionState {
  ncp.NutritionState(
    date: date,
    consumed: nutrition_data(protein, fat, carbs, calories),
    synced_at: "2025-12-20T12:00:00Z",
  )
}

/// Create nutrition goals
fn nutrition_goals(
  protein: Float,
  fat: Float,
  carbs: Float,
  calories: Float,
) -> ncp.NutritionGoals {
  ncp.NutritionGoals(
    daily_protein: protein,
    daily_fat: fat,
    daily_carbs: carbs,
    daily_calories: calories,
  )
}

// ============================================================================
// RED PHASE TEST 1: calculate_daily_totals
// ============================================================================

/// Test: Calculate totals from a single meal
/// EXPECTED FAILURE: Function does not exist
pub fn calculate_daily_totals_single_meal_test() {
  let breakfast = nutrition_state("2025-12-20", 30.0, 10.0, 45.0, 350.0)

  let total = ncp.calculate_daily_totals([breakfast])

  // Should return the same values as the single meal
  total.protein |> should.equal(30.0)
  total.fat |> should.equal(10.0)
  total.carbs |> should.equal(45.0)
  total.calories |> should.equal(350.0)
}

/// Test: Calculate totals from multiple meals
/// EXPECTED FAILURE: Function does not exist
pub fn calculate_daily_totals_multiple_meals_test() {
  let breakfast = nutrition_state("2025-12-20", 30.0, 10.0, 45.0, 350.0)
  let lunch = nutrition_state("2025-12-20", 50.0, 15.0, 60.0, 500.0)
  let dinner = nutrition_state("2025-12-20", 40.0, 12.0, 55.0, 450.0)

  let total = ncp.calculate_daily_totals([breakfast, lunch, dinner])

  // Should sum all meals
  total.protein |> should.equal(120.0)
  total.fat |> should.equal(37.0)
  total.carbs |> should.equal(160.0)
  total.calories |> should.equal(1300.0)
}

/// Test: Calculate totals from empty list
/// EXPECTED FAILURE: Function does not exist
pub fn calculate_daily_totals_empty_test() {
  let total = ncp.calculate_daily_totals([])

  // Should return zeros
  total.protein |> should.equal(0.0)
  total.fat |> should.equal(0.0)
  total.carbs |> should.equal(0.0)
  total.calories |> should.equal(0.0)
}

// ============================================================================
// RED PHASE TEST 2: calculate_macro_percentages
// ============================================================================

/// Test: Calculate macro percentages from nutrition data
/// EXPECTED FAILURE: Function does not exist
pub fn calculate_macro_percentages_standard_test() {
  let data = nutrition_data(180.0, 65.0, 250.0, 2500.0)

  let percentages = ncp.calculate_macro_percentages(data)

  // Protein: (180 * 4) / 2500 * 100 = 28.8%
  percentages.0 |> should.equal(28.8)

  // Fat: (65 * 9) / 2500 * 100 = 23.4%
  percentages.1 |> should.equal(23.4)

  // Carbs: (250 * 4) / 2500 * 100 = 40.0%
  percentages.2 |> should.equal(40.0)
}

/// Test: Calculate macro percentages when calories is zero
/// EXPECTED FAILURE: Function does not exist
pub fn calculate_macro_percentages_zero_calories_test() {
  let data = nutrition_data(100.0, 50.0, 100.0, 0.0)

  let percentages = ncp.calculate_macro_percentages(data)

  // Should return 0.0 for all percentages when calories is zero
  percentages.0 |> should.equal(0.0)
  percentages.1 |> should.equal(0.0)
  percentages.2 |> should.equal(0.0)
}

// ============================================================================
// RED PHASE TEST 3: check_macro_targets
// ============================================================================

/// Test: Check if macros meet targets (on target)
/// EXPECTED FAILURE: Function does not exist
pub fn check_macro_targets_on_target_test() {
  let consumed = nutrition_data(180.0, 60.0, 250.0, 2500.0)
  let goals = nutrition_goals(180.0, 60.0, 250.0, 2500.0)

  let result = ncp.check_macro_targets(consumed, goals)

  // Should indicate all macros are on target
  result |> should.equal(True)
}

/// Test: Check if macros meet targets (slightly off)
/// EXPECTED FAILURE: Function does not exist
pub fn check_macro_targets_slightly_off_test() {
  let consumed = nutrition_data(175.0, 62.0, 252.0, 2480.0)
  let goals = nutrition_goals(180.0, 60.0, 250.0, 2500.0)

  let result = ncp.check_macro_targets(consumed, goals)

  // Should indicate macros are close enough (within reasonable tolerance)
  result |> should.equal(True)
}

/// Test: Check if macros meet targets (significantly off)
/// EXPECTED FAILURE: Function does not exist
pub fn check_macro_targets_significantly_off_test() {
  let consumed = nutrition_data(100.0, 80.0, 200.0, 2000.0)
  let goals = nutrition_goals(180.0, 60.0, 250.0, 2500.0)

  let result = ncp.check_macro_targets(consumed, goals)

  // Should indicate macros do not meet targets
  result |> should.equal(False)
}

// ============================================================================
// RED PHASE TEST 4: suggest_macro_adjustments
// ============================================================================

/// Test: Suggest adjustments for protein deficit
/// EXPECTED FAILURE: Function does not exist
pub fn suggest_macro_adjustments_protein_deficit_test() {
  let consumed = nutrition_data(100.0, 65.0, 250.0, 2500.0)
  let goals = nutrition_goals(180.0, 65.0, 250.0, 2500.0)

  let suggestion = ncp.suggest_macro_adjustments(consumed, goals)

  // Should recommend adding protein
  suggestion
  |> should.contain("protein")
}

/// Test: Suggest adjustments for carbs deficit
/// EXPECTED FAILURE: Function does not exist
pub fn suggest_macro_adjustments_carbs_deficit_test() {
  let consumed = nutrition_data(180.0, 65.0, 150.0, 2000.0)
  let goals = nutrition_goals(180.0, 65.0, 250.0, 2500.0)

  let suggestion = ncp.suggest_macro_adjustments(consumed, goals)

  // Should recommend adding carbs
  suggestion
  |> should.contain("carbs")
}

/// Test: Suggest adjustments when on target
/// EXPECTED FAILURE: Function does not exist
pub fn suggest_macro_adjustments_on_target_test() {
  let consumed = nutrition_data(180.0, 65.0, 250.0, 2500.0)
  let goals = nutrition_goals(180.0, 65.0, 250.0, 2500.0)

  let suggestion = ncp.suggest_macro_adjustments(consumed, goals)

  // Should indicate no adjustments needed - checking for positive feedback
  let has_positive_feedback =
    string.contains(suggestion, "excellent")
    || string.contains(suggestion, "perfect")
    || string.contains(suggestion, "on target")
  has_positive_feedback |> should.equal(True)
}

// ============================================================================
// RED PHASE TEST 5: estimate_daily_calories
// ============================================================================

/// Test: Estimate calories from standard macros
/// EXPECTED FAILURE: Function does not exist
pub fn estimate_daily_calories_standard_test() {
  let protein = 180.0
  let fat = 65.0
  let carbs = 250.0

  let calories = ncp.estimate_daily_calories(protein, fat, carbs)

  // Calories = (protein * 4) + (fat * 9) + (carbs * 4)
  // = (180 * 4) + (65 * 9) + (250 * 4)
  // = 720 + 585 + 1000
  // = 2305
  calories |> should.equal(2305.0)
}

/// Test: Estimate calories with zero macros
/// EXPECTED FAILURE: Function does not exist
pub fn estimate_daily_calories_zero_macros_test() {
  let calories = ncp.estimate_daily_calories(0.0, 0.0, 0.0)

  calories |> should.equal(0.0)
}

/// Test: Estimate calories with typical day
/// EXPECTED FAILURE: Function does not exist
pub fn estimate_daily_calories_typical_day_test() {
  let protein = 120.0
  let fat = 45.0
  let carbs = 200.0

  let calories = ncp.estimate_daily_calories(protein, fat, carbs)

  // Calories = (120 * 4) + (45 * 9) + (200 * 4)
  // = 480 + 405 + 800
  // = 1685
  calories |> should.equal(1685.0)
}
