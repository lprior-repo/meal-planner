/// Unit Tests: Macro Calculation Functions
///
/// Tests the macro calculation functionality:
/// 1. Macro scaling with servings
/// 2. Calorie calculations
/// 3. Macro addition and summation
/// 4. Precision and rounding behavior
///
/// This is a critical calculation path that must remain accurate.
import gleam/float
import gleeunit
import gleeunit/should
import meal_planner/types

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Helper to compare macros with tolerance for floating point precision
fn assert_macros_equal(
  actual: types.Macros,
  expected: types.Macros,
  tolerance: Float,
) -> Result(Nil, String) {
  let protein_ok =
    float.absolute_value(actual.protein -. expected.protein) <. tolerance
  let fat_ok = float.absolute_value(actual.fat -. expected.fat) <. tolerance
  let carbs_ok =
    float.absolute_value(actual.carbs -. expected.carbs) <. tolerance

  case protein_ok && fat_ok && carbs_ok {
    True -> Ok(Nil)
    False ->
      Error(
        "Macros mismatch: expected "
        <> types.macros_to_string(expected)
        <> " got "
        <> types.macros_to_string(actual),
      )
  }
}

// ============================================================================
// Serving Size Scaling Tests
// ============================================================================

/// Test: Double servings double the macros
pub fn double_servings_double_macros_test() {
  let base_macros = types.Macros(protein: 20.0, fat: 10.0, carbs: 30.0)
  let scaled = types.macros_scale(base_macros, 2.0)
  let expected = types.Macros(protein: 40.0, fat: 20.0, carbs: 60.0)

  let result = assert_macros_equal(scaled, expected, 0.01)
  should.be_ok(result)
}

/// Test: Half serving halves the macros
pub fn half_serving_halves_macros_test() {
  let base_macros = types.Macros(protein: 30.0, fat: 20.0, carbs: 40.0)
  let scaled = types.macros_scale(base_macros, 0.5)
  let expected = types.Macros(protein: 15.0, fat: 10.0, carbs: 20.0)

  let result = assert_macros_equal(scaled, expected, 0.01)
  should.be_ok(result)
}

/// Test: Zero servings result in zero macros
pub fn zero_servings_zero_macros_test() {
  let base_macros = types.Macros(protein: 30.0, fat: 20.0, carbs: 40.0)
  let scaled = types.macros_scale(base_macros, 0.0)
  let zero = types.macros_zero()

  let result = assert_macros_equal(scaled, zero, 0.01)
  should.be_ok(result)
}

/// Test: Fractional servings scale precisely
pub fn fractional_servings_scale_test() {
  let base_macros = types.Macros(protein: 20.0, fat: 10.0, carbs: 30.0)
  let scaled = types.macros_scale(base_macros, 1.5)
  let expected = types.Macros(protein: 30.0, fat: 15.0, carbs: 45.0)

  let result = assert_macros_equal(scaled, expected, 0.01)
  should.be_ok(result)
}

// ============================================================================
// Calorie Calculation Tests
// ============================================================================

/// Test: Calories calculated using 4/9/4 rule
/// Protein: 4 cal/g, Fat: 9 cal/g, Carbs: 4 cal/g
pub fn calories_4_9_4_rule_test() {
  let macros = types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0)
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
pub fn high_protein_calories_test() {
  let macros = types.Macros(protein: 100.0, fat: 0.0, carbs: 0.0)
  let calories = types.macros_calories(macros)

  should.equal(calories, 400.0)
}

/// Test: High fat macros calculate correctly
pub fn high_fat_calories_test() {
  let macros = types.Macros(protein: 0.0, fat: 50.0, carbs: 0.0)
  let calories = types.macros_calories(macros)

  should.equal(calories, 450.0)
}

/// Test: High carb macros calculate correctly
pub fn high_carb_calories_test() {
  let macros = types.Macros(protein: 0.0, fat: 0.0, carbs: 100.0)
  let calories = types.macros_calories(macros)

  should.equal(calories, 400.0)
}

/// Test: Realistic daily macros
pub fn realistic_daily_macros_test() {
  let macros = types.Macros(protein: 150.0, fat: 60.0, carbs: 200.0)
  // 150*4 + 60*9 + 200*4 = 600 + 540 + 800 = 1940
  let calories = types.macros_calories(macros)

  should.equal(calories, 1940.0)
}

// ============================================================================
// Macro Addition Tests
// ============================================================================

/// Test: Adding two macros sums each component
pub fn add_two_macros_test() {
  let m1 = types.Macros(protein: 20.0, fat: 10.0, carbs: 30.0)
  let m2 = types.Macros(protein: 15.0, fat: 5.0, carbs: 25.0)
  let sum = types.macros_add(m1, m2)
  let expected = types.Macros(protein: 35.0, fat: 15.0, carbs: 55.0)

  let result = assert_macros_equal(sum, expected, 0.01)
  should.be_ok(result)
}

/// Test: Adding zero macros is identity
pub fn add_zero_is_identity_test() {
  let macros = types.Macros(protein: 25.0, fat: 12.0, carbs: 35.0)
  let zero = types.macros_zero()
  let sum = types.macros_add(macros, zero)

  let result = assert_macros_equal(sum, macros, 0.01)
  should.be_ok(result)
}

/// Test: Addition is commutative (A + B = B + A)
pub fn addition_is_commutative_test() {
  let m1 = types.Macros(protein: 20.0, fat: 10.0, carbs: 30.0)
  let m2 = types.Macros(protein: 15.0, fat: 5.0, carbs: 25.0)
  let sum1 = types.macros_add(m1, m2)
  let sum2 = types.macros_add(m2, m1)

  let result = assert_macros_equal(sum1, sum2, 0.01)
  should.be_ok(result)
}

/// Test: Sum a list of macros
pub fn sum_list_of_macros_test() {
  let macros_list = [
    types.Macros(protein: 10.0, fat: 5.0, carbs: 15.0),
    types.Macros(protein: 20.0, fat: 10.0, carbs: 25.0),
    types.Macros(protein: 15.0, fat: 8.0, carbs: 20.0),
  ]
  let sum = types.macros_sum(macros_list)
  let expected = types.Macros(protein: 45.0, fat: 23.0, carbs: 60.0)

  let result = assert_macros_equal(sum, expected, 0.01)
  should.be_ok(result)
}

/// Test: Sum empty list gives zero
pub fn sum_empty_list_zero_test() {
  let sum = types.macros_sum([])
  let zero = types.macros_zero()

  let result = assert_macros_equal(sum, zero, 0.01)
  should.be_ok(result)
}

// ============================================================================
// Precision and Rounding Tests
// ============================================================================

/// Test: Floating point precision maintained
pub fn floating_point_precision_test() {
  let macros = types.Macros(protein: 20.5, fat: 10.25, carbs: 30.75)

  should.equal(macros.protein, 20.5)
  should.equal(macros.fat, 10.25)
  should.equal(macros.carbs, 30.75)
}

/// Test: Very small servings preserve precision
pub fn tiny_servings_precision_test() {
  let base = types.Macros(protein: 30.0, fat: 20.0, carbs: 40.0)
  let scaled = types.macros_scale(base, 0.1)
  let expected = types.Macros(protein: 3.0, fat: 2.0, carbs: 4.0)

  let result = assert_macros_equal(scaled, expected, 0.01)
  should.be_ok(result)
}

/// Test: Large servings scale correctly
pub fn large_servings_scale_test() {
  let base = types.Macros(protein: 15.0, fat: 8.0, carbs: 25.0)
  let scaled = types.macros_scale(base, 10.0)
  let expected = types.Macros(protein: 150.0, fat: 80.0, carbs: 250.0)

  let result = assert_macros_equal(scaled, expected, 0.01)
  should.be_ok(result)
}

// ============================================================================
// Integration Tests with Real-World Scenarios
// ============================================================================

/// Test: Typical bodybuilder day (high protein)
pub fn bodybuilder_day_macros_test() {
  let breakfast = types.Macros(protein: 40.0, fat: 15.0, carbs: 50.0)
  let lunch = types.Macros(protein: 50.0, fat: 20.0, carbs: 60.0)
  let pre_workout = types.Macros(protein: 10.0, fat: 5.0, carbs: 40.0)
  let dinner = types.Macros(protein: 60.0, fat: 20.0, carbs: 50.0)
  let evening_snack = types.Macros(protein: 40.0, fat: 10.0, carbs: 50.0)

  let daily =
    types.macros_sum([breakfast, lunch, pre_workout, dinner, evening_snack])
  let expected = types.Macros(protein: 200.0, fat: 70.0, carbs: 250.0)

  let result = assert_macros_equal(daily, expected, 0.01)
  should.be_ok(result)

  let calories = types.macros_calories(daily)
  // 200*4 + 70*9 + 250*4 = 800 + 630 + 1000 = 2430
  should.equal(calories, 2430.0)
}

/// Test: Keto diet day (high fat, low carb)
pub fn keto_day_macros_test() {
  let breakfast = types.Macros(protein: 25.0, fat: 30.0, carbs: 5.0)
  let lunch = types.Macros(protein: 35.0, fat: 45.0, carbs: 8.0)
  let dinner = types.Macros(protein: 40.0, fat: 50.0, carbs: 10.0)
  let snack = types.Macros(protein: 20.0, fat: 25.0, carbs: 7.0)

  let daily = types.macros_sum([breakfast, lunch, dinner, snack])
  let expected = types.Macros(protein: 120.0, fat: 150.0, carbs: 30.0)

  let result = assert_macros_equal(daily, expected, 0.01)
  should.be_ok(result)

  let calories = types.macros_calories(daily)
  // 120*4 + 150*9 + 30*4 = 480 + 1350 + 120 = 1950
  should.equal(calories, 1950.0)
}

/// Test: Low-calorie diet day
pub fn low_calorie_day_test() {
  let breakfast = types.Macros(protein: 25.0, fat: 8.0, carbs: 20.0)
  let lunch = types.Macros(protein: 35.0, fat: 10.0, carbs: 25.0)
  let dinner = types.Macros(protein: 30.0, fat: 10.0, carbs: 25.0)
  let snack = types.Macros(protein: 10.0, fat: 2.0, carbs: 10.0)

  let daily = types.macros_sum([breakfast, lunch, dinner, snack])
  let expected = types.Macros(protein: 100.0, fat: 30.0, carbs: 80.0)

  let result = assert_macros_equal(daily, expected, 0.01)
  should.be_ok(result)

  let calories = types.macros_calories(daily)
  // 100*4 + 30*9 + 80*4 = 400 + 270 + 320 = 990
  should.equal(calories, 990.0)
}
