/// Integration Test: Macro Calculation Pipeline
///
/// Tests the end-to-end macro calculation workflow:
/// 1. Multiple foods logged throughout the day
/// 2. Individual meal macros calculated correctly
/// 3. Daily totals aggregated accurately
/// 4. Macro scaling with servings
/// 5. Precision and rounding behavior
///
/// This is a critical calculation path that must remain accurate.
import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/integration/test_helper
import meal_planner/types.{
  type DailyLog, type FoodLogEntry, type Macros, Breakfast, Dinner, Lunch,
  Macros, Snack,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Daily Macro Aggregation Tests
// ============================================================================

/// Test: Single meal macros calculated correctly
///
/// User logs one meal, daily totals should match that meal
pub fn single_meal_daily_totals_test() {
  // Create a breakfast entry
  let breakfast_macros = Macros(protein: 25.0, fat: 10.0, carbs: 30.0)
  let entry =
    test_helper.fixture_food_log_entry(
      "1",
      "test-recipe-1",
      "Test Breakfast",
      1.0,
      breakfast_macros,
      Breakfast,
    )

  let daily_log = test_helper.fixture_daily_log("2024-01-15", [entry])

  // Daily totals should equal the single entry
  let result =
    test_helper.assert_macros_equal(
      daily_log.total_macros,
      breakfast_macros,
      0.01,
    )

  should.be_ok(result)
}

/// Test: Multiple meals aggregate correctly
///
/// Breakfast + Lunch + Dinner + Snack = Daily Total
pub fn multiple_meals_aggregate_test() {
  // Create entries for each meal type
  let breakfast = Macros(protein: 25.0, fat: 10.0, carbs: 30.0)
  let lunch = Macros(protein: 35.0, fat: 15.0, carbs: 45.0)
  let dinner = Macros(protein: 40.0, fat: 20.0, carbs: 35.0)
  let snack = Macros(protein: 5.0, fat: 5.0, carbs: 10.0)

  let entries = [
    test_helper.fixture_food_log_entry(
      "1",
      "breakfast",
      "Breakfast",
      1.0,
      breakfast,
      Breakfast,
    ),
    test_helper.fixture_food_log_entry("2", "lunch", "Lunch", 1.0, lunch, Lunch),
    test_helper.fixture_food_log_entry(
      "3",
      "dinner",
      "Dinner",
      1.0,
      dinner,
      Dinner,
    ),
    test_helper.fixture_food_log_entry("4", "snack", "Snack", 1.0, snack, Snack),
  ]

  let daily_log = test_helper.fixture_daily_log("2024-01-15", entries)

  // Expected total: sum of all meals
  let expected =
    Macros(
      protein: 25.0 +. 35.0 +. 40.0 +. 5.0,
      fat: 10.0 +. 15.0 +. 20.0 +. 5.0,
      carbs: 30.0 +. 45.0 +. 35.0 +. 10.0,
    )
  // = 105g protein, 50g fat, 120g carbs

  let result =
    test_helper.assert_macros_equal(daily_log.total_macros, expected, 0.01)

  should.be_ok(result)
}

/// Test: Empty day returns zero macros
///
/// Day with no logged foods should have 0/0/0 macros
pub fn empty_day_zero_macros_test() {
  let daily_log = test_helper.fixture_daily_log("2024-01-15", [])

  let zero = types.macros_zero()
  let result =
    test_helper.assert_macros_equal(daily_log.total_macros, zero, 0.01)

  should.be_ok(result)
}

// ============================================================================
// Serving Size Scaling Tests
// ============================================================================

/// Test: Double servings double the macros
///
/// Logging 2 servings should scale macros by 2x
pub fn double_servings_double_macros_test() {
  let base_macros = Macros(protein: 20.0, fat: 10.0, carbs: 30.0)

  // Scale by 2
  let scaled = types.macros_scale(base_macros, 2.0)

  let expected = Macros(protein: 40.0, fat: 20.0, carbs: 60.0)

  let result = test_helper.assert_macros_equal(scaled, expected, 0.01)
  should.be_ok(result)
}

/// Test: Half serving halves the macros
///
/// Logging 0.5 servings should scale macros by 0.5x
pub fn half_serving_halves_macros_test() {
  let base_macros = Macros(protein: 30.0, fat: 20.0, carbs: 40.0)

  // Scale by 0.5
  let scaled = types.macros_scale(base_macros, 0.5)

  let expected = Macros(protein: 15.0, fat: 10.0, carbs: 20.0)

  let result = test_helper.assert_macros_equal(scaled, expected, 0.01)
  should.be_ok(result)
}

/// Test: Zero servings result in zero macros
///
/// Edge case: 0 servings should give 0/0/0
pub fn zero_servings_zero_macros_test() {
  let base_macros = Macros(protein: 30.0, fat: 20.0, carbs: 40.0)

  let scaled = types.macros_scale(base_macros, 0.0)

  let zero = types.macros_zero()
  let result = test_helper.assert_macros_equal(scaled, zero, 0.01)

  should.be_ok(result)
}

/// Test: Fractional servings scale precisely
///
/// 1.5 servings should scale by 1.5x
pub fn fractional_servings_scale_test() {
  let base_macros = Macros(protein: 20.0, fat: 10.0, carbs: 30.0)

  let scaled = types.macros_scale(base_macros, 1.5)

  let expected = Macros(protein: 30.0, fat: 15.0, carbs: 45.0)

  let result = test_helper.assert_macros_equal(scaled, expected, 0.01)
  should.be_ok(result)
}

// ============================================================================
// Calorie Calculation Tests
// ============================================================================

/// Test: Calories calculated using 4/9/4 rule
///
/// Protein: 4 cal/g
/// Fat: 9 cal/g
/// Carbs: 4 cal/g
pub fn calories_4_9_4_rule_test() {
  let macros = Macros(protein: 30.0, fat: 10.0, carbs: 40.0)

  // Expected: (30*4) + (10*9) + (40*4) = 120 + 90 + 160 = 370
  let calories = types.macros_calories(macros)

  should.equal(calories, 370.0)
}

/// Test: Zero macros give zero calories
pub fn zero_macros_zero_calories_test() {
  let zero = types.macros_zero()
  let calories = types.macros_calories(zero)

  should.equal(calories, 0.0)
}

/// Test: High protein macros calculate correctly
///
/// Pure protein: 100g protein = 400 calories
pub fn high_protein_calories_test() {
  let macros = Macros(protein: 100.0, fat: 0.0, carbs: 0.0)
  let calories = types.macros_calories(macros)

  should.equal(calories, 400.0)
}

/// Test: High fat macros calculate correctly
///
/// Pure fat: 50g fat = 450 calories
pub fn high_fat_calories_test() {
  let macros = Macros(protein: 0.0, fat: 50.0, carbs: 0.0)
  let calories = types.macros_calories(macros)

  should.equal(calories, 450.0)
}

/// Test: High carb macros calculate correctly
///
/// Pure carbs: 100g carbs = 400 calories
pub fn high_carb_calories_test() {
  let macros = Macros(protein: 0.0, fat: 0.0, carbs: 100.0)
  let calories = types.macros_calories(macros)

  should.equal(calories, 400.0)
}

/// Test: Realistic daily macros
///
/// Typical day: 150g protein, 60g fat, 200g carbs
/// = 600 + 540 + 800 = 1940 calories
pub fn realistic_daily_macros_test() {
  let macros = Macros(protein: 150.0, fat: 60.0, carbs: 200.0)
  let calories = types.macros_calories(macros)

  should.equal(calories, 1940.0)
}

// ============================================================================
// Macro Addition Tests
// ============================================================================

/// Test: Adding two macros sums each component
pub fn add_two_macros_test() {
  let m1 = Macros(protein: 20.0, fat: 10.0, carbs: 30.0)
  let m2 = Macros(protein: 15.0, fat: 5.0, carbs: 25.0)

  let sum = types.macros_add(m1, m2)

  let expected = Macros(protein: 35.0, fat: 15.0, carbs: 55.0)

  let result = test_helper.assert_macros_equal(sum, expected, 0.01)
  should.be_ok(result)
}

/// Test: Adding zero macros is identity
///
/// Macros + Zero = Macros
pub fn add_zero_is_identity_test() {
  let macros = Macros(protein: 25.0, fat: 12.0, carbs: 35.0)
  let zero = types.macros_zero()

  let sum = types.macros_add(macros, zero)

  let result = test_helper.assert_macros_equal(sum, macros, 0.01)
  should.be_ok(result)
}

/// Test: Addition is commutative
///
/// A + B = B + A
pub fn addition_is_commutative_test() {
  let m1 = Macros(protein: 20.0, fat: 10.0, carbs: 30.0)
  let m2 = Macros(protein: 15.0, fat: 5.0, carbs: 25.0)

  let sum1 = types.macros_add(m1, m2)
  let sum2 = types.macros_add(m2, m1)

  let result = test_helper.assert_macros_equal(sum1, sum2, 0.01)
  should.be_ok(result)
}

/// Test: Sum a list of macros
///
/// Verifies macros_sum function
pub fn sum_list_of_macros_test() {
  let macros_list = [
    Macros(protein: 10.0, fat: 5.0, carbs: 15.0),
    Macros(protein: 20.0, fat: 10.0, carbs: 25.0),
    Macros(protein: 15.0, fat: 8.0, carbs: 20.0),
  ]

  let sum = types.macros_sum(macros_list)

  let expected = Macros(protein: 45.0, fat: 23.0, carbs: 60.0)

  let result = test_helper.assert_macros_equal(sum, expected, 0.01)
  should.be_ok(result)
}

/// Test: Sum empty list gives zero
pub fn sum_empty_list_zero_test() {
  let sum = types.macros_sum([])

  let zero = types.macros_zero()
  let result = test_helper.assert_macros_equal(sum, zero, 0.01)

  should.be_ok(result)
}

// ============================================================================
// Precision and Rounding Tests
// ============================================================================

/// Test: Floating point precision maintained
///
/// Small decimal values should be preserved
pub fn floating_point_precision_test() {
  let macros = Macros(protein: 20.5, fat: 10.25, carbs: 30.75)

  // Verify each component
  should.equal(macros.protein, 20.5)
  should.equal(macros.fat, 10.25)
  should.equal(macros.carbs, 30.75)
}

/// Test: Very small servings preserve precision
///
/// 0.1 servings should scale correctly
pub fn tiny_servings_precision_test() {
  let base = Macros(protein: 30.0, fat: 20.0, carbs: 40.0)
  let scaled = types.macros_scale(base, 0.1)

  let expected = Macros(protein: 3.0, fat: 2.0, carbs: 4.0)

  let result = test_helper.assert_macros_equal(scaled, expected, 0.01)
  should.be_ok(result)
}

/// Test: Large servings scale correctly
///
/// 10 servings should scale by 10x
pub fn large_servings_scale_test() {
  let base = Macros(protein: 15.0, fat: 8.0, carbs: 25.0)
  let scaled = types.macros_scale(base, 10.0)

  let expected = Macros(protein: 150.0, fat: 80.0, carbs: 250.0)

  let result = test_helper.assert_macros_equal(scaled, expected, 0.01)
  should.be_ok(result)
}

// ============================================================================
// Integration Tests with Real-World Scenarios
// ============================================================================

/// Test: Typical bodybuilder day (high protein)
///
/// 200g protein, 70g fat, 250g carbs
/// = 800 + 630 + 1000 = 2430 calories
pub fn bodybuilder_day_macros_test() {
  let breakfast = Macros(protein: 40.0, fat: 15.0, carbs: 50.0)
  let lunch = Macros(protein: 50.0, fat: 20.0, carbs: 60.0)
  let pre_workout = Macros(protein: 10.0, fat: 5.0, carbs: 40.0)
  let dinner = Macros(protein: 60.0, fat: 20.0, carbs: 50.0)
  let evening_snack = Macros(protein: 40.0, fat: 10.0, carbs: 50.0)

  let daily =
    types.macros_sum([
      breakfast,
      lunch,
      pre_workout,
      dinner,
      evening_snack,
    ])

  let expected = Macros(protein: 200.0, fat: 70.0, carbs: 250.0)

  let result = test_helper.assert_macros_equal(daily, expected, 0.01)
  should.be_ok(result)

  // Verify calories
  let calories = types.macros_calories(daily)
  should.equal(calories, 2430.0)
}

/// Test: Keto diet day (high fat, low carb)
///
/// 120g protein, 150g fat, 30g carbs
/// = 480 + 1350 + 120 = 1950 calories
pub fn keto_day_macros_test() {
  let breakfast = Macros(protein: 25.0, fat: 30.0, carbs: 5.0)
  let lunch = Macros(protein: 35.0, fat: 45.0, carbs: 8.0)
  let dinner = Macros(protein: 40.0, fat: 50.0, carbs: 10.0)
  let snack = Macros(protein: 20.0, fat: 25.0, carbs: 7.0)

  let daily = types.macros_sum([breakfast, lunch, dinner, snack])

  let expected = Macros(protein: 120.0, fat: 150.0, carbs: 30.0)

  let result = test_helper.assert_macros_equal(daily, expected, 0.01)
  should.be_ok(result)

  // Verify calories
  let calories = types.macros_calories(daily)
  should.equal(calories, 1950.0)
}

/// Test: Low-calorie diet day
///
/// 100g protein, 30g fat, 80g carbs
/// = 400 + 270 + 320 = 990 calories
pub fn low_calorie_day_test() {
  let breakfast = Macros(protein: 25.0, fat: 8.0, carbs: 20.0)
  let lunch = Macros(protein: 35.0, fat: 10.0, carbs: 25.0)
  let dinner = Macros(protein: 30.0, fat: 10.0, carbs: 25.0)
  let snack = Macros(protein: 10.0, fat: 2.0, carbs: 10.0)

  let daily = types.macros_sum([breakfast, lunch, dinner, snack])

  let expected = Macros(protein: 100.0, fat: 30.0, carbs: 80.0)

  let result = test_helper.assert_macros_equal(daily, expected, 0.01)
  should.be_ok(result)

  // Verify calories
  let calories = types.macros_calories(daily)
  should.equal(calories, 990.0)
}
