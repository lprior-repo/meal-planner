/// Property-based tests for macro percentage calculations
/// Tests mathematical properties of macro ratio/percentage calculations
///
/// This test suite validates:
/// - Protein% + fat% + carbs% = 100% (within tolerance)
/// - All percentages are between 0% and 100%
/// - Percentages scale correctly with macro changes
/// - Zero macros give zero percentages
/// - Single macro gives 100% for that macro
/// - Ratios are independent of scaling
///
/// Note: These are property tests written as traditional unit tests.
/// Each test verifies a mathematical property that should hold for all inputs.
///
import gleam/list
import gleeunit/should
import meal_planner/types.{type Macros, Macros}

// ============================================================================
// Test Data - Various Macro Distributions
// ============================================================================

fn balanced_macros() -> Macros {
  // Roughly 30% protein, 30% fat, 40% carbs
  Macros(protein: 30.0, fat: 20.0, carbs: 50.0)
}

fn high_protein() -> Macros {
  // High protein, low fat, moderate carbs
  Macros(protein: 50.0, fat: 10.0, carbs: 30.0)
}

fn high_fat() -> Macros {
  // Low protein, high fat, low carbs (keto-style)
  Macros(protein: 20.0, fat: 70.0, carbs: 10.0)
}

fn high_carb() -> Macros {
  // Low protein, low fat, high carbs
  Macros(protein: 15.0, fat: 5.0, carbs: 80.0)
}

fn protein_only() -> Macros {
  Macros(protein: 100.0, fat: 0.0, carbs: 0.0)
}

fn fat_only() -> Macros {
  Macros(protein: 0.0, fat: 50.0, carbs: 0.0)
}

fn carbs_only() -> Macros {
  Macros(protein: 0.0, fat: 0.0, carbs: 100.0)
}

fn very_small_macros() -> Macros {
  Macros(protein: 0.5, fat: 0.25, carbs: 1.0)
}

fn very_large_macros() -> Macros {
  Macros(protein: 500.0, fat: 250.0, carbs: 1000.0)
}

fn all_test_macros() -> List(Macros) {
  [
    balanced_macros(),
    high_protein(),
    high_fat(),
    high_carb(),
    protein_only(),
    fat_only(),
    carbs_only(),
    very_small_macros(),
    very_large_macros(),
  ]
}

// ============================================================================
// PROPERTY: Percentages Sum to 100% (Within Tolerance)
// ============================================================================

pub fn percentages_sum_to_one_balanced_test() {
  // Property: protein% + fat% + carbs% = 1.0 (100%)
  let macros = balanced_macros()
  let p_ratio = types.protein_ratio(macros)
  let f_ratio = types.fat_ratio(macros)
  let c_ratio = types.carb_ratio(macros)
  let sum = p_ratio +. f_ratio +. c_ratio

  float_approximately_equal(sum, 1.0, 0.001) |> should.be_true
}

pub fn percentages_sum_to_one_high_protein_test() {
  let macros = high_protein()
  let sum =
    types.protein_ratio(macros)
    +. types.fat_ratio(macros)
    +. types.carb_ratio(macros)

  float_approximately_equal(sum, 1.0, 0.001) |> should.be_true
}

pub fn percentages_sum_to_one_high_fat_test() {
  let macros = high_fat()
  let sum =
    types.protein_ratio(macros)
    +. types.fat_ratio(macros)
    +. types.carb_ratio(macros)

  float_approximately_equal(sum, 1.0, 0.001) |> should.be_true
}

pub fn percentages_sum_to_one_high_carb_test() {
  let macros = high_carb()
  let sum =
    types.protein_ratio(macros)
    +. types.fat_ratio(macros)
    +. types.carb_ratio(macros)

  float_approximately_equal(sum, 1.0, 0.001) |> should.be_true
}

pub fn percentages_sum_to_one_all_distributions_test() {
  // Property: For all macro distributions, percentages sum to 100%
  all_test_macros()
  |> list.each(fn(macros) {
    let sum =
      types.protein_ratio(macros)
      +. types.fat_ratio(macros)
      +. types.carb_ratio(macros)
    float_approximately_equal(sum, 1.0, 0.001) |> should.be_true
  })
}

// ============================================================================
// PROPERTY: Percentages are Between 0% and 100%
// ============================================================================

pub fn percentages_in_valid_range_test() {
  // Property: All percentages should be in [0.0, 1.0]
  all_test_macros()
  |> list.each(fn(macros) {
    let p_ratio = types.protein_ratio(macros)
    let f_ratio = types.fat_ratio(macros)
    let c_ratio = types.carb_ratio(macros)

    { p_ratio >=. 0.0 && p_ratio <=. 1.0 } |> should.be_true
    { f_ratio >=. 0.0 && f_ratio <=. 1.0 } |> should.be_true
    { c_ratio >=. 0.0 && c_ratio <=. 1.0 } |> should.be_true
  })
}

// ============================================================================
// PROPERTY: Zero Macros Give Zero Percentages
// ============================================================================

pub fn zero_macros_give_zero_percentages_test() {
  // Property: Zero macros should give 0% for all ratios
  let zero = types.macros_zero()
  types.protein_ratio(zero) |> should.equal(0.0)
  types.fat_ratio(zero) |> should.equal(0.0)
  types.carb_ratio(zero) |> should.equal(0.0)
}

// ============================================================================
// PROPERTY: Single Macro Gives 100% for That Macro
// ============================================================================

pub fn protein_only_gives_100_percent_protein_test() {
  // Property: Protein-only macros should give 100% protein
  let macros = protein_only()
  types.protein_ratio(macros) |> should.equal(1.0)
  types.fat_ratio(macros) |> should.equal(0.0)
  types.carb_ratio(macros) |> should.equal(0.0)
}

pub fn fat_only_gives_100_percent_fat_test() {
  // Property: Fat-only macros should give 100% fat
  let macros = fat_only()
  types.protein_ratio(macros) |> should.equal(0.0)
  types.fat_ratio(macros) |> should.equal(1.0)
  types.carb_ratio(macros) |> should.equal(0.0)
}

pub fn carbs_only_gives_100_percent_carbs_test() {
  // Property: Carbs-only macros should give 100% carbs
  let macros = carbs_only()
  types.protein_ratio(macros) |> should.equal(0.0)
  types.fat_ratio(macros) |> should.equal(0.0)
  types.carb_ratio(macros) |> should.equal(1.0)
}

// ============================================================================
// PROPERTY: Ratios are Scale-Invariant
// ============================================================================

pub fn ratios_unchanged_by_scaling_test() {
  // Property: Scaling macros doesn't change ratios
  let original = balanced_macros()
  let scaled = types.macros_scale(original, 2.5)

  let p_ratio_original = types.protein_ratio(original)
  let f_ratio_original = types.fat_ratio(original)
  let c_ratio_original = types.carb_ratio(original)

  let p_ratio_scaled = types.protein_ratio(scaled)
  let f_ratio_scaled = types.fat_ratio(scaled)
  let c_ratio_scaled = types.carb_ratio(scaled)

  float_approximately_equal(p_ratio_original, p_ratio_scaled, 0.0001)
  |> should.be_true
  float_approximately_equal(f_ratio_original, f_ratio_scaled, 0.0001)
  |> should.be_true
  float_approximately_equal(c_ratio_original, c_ratio_scaled, 0.0001)
  |> should.be_true
}

pub fn ratios_unchanged_by_various_scales_test() {
  // Property: Ratios remain constant across different scaling factors
  let original = high_protein()
  let scales = [0.5, 1.0, 2.0, 5.0, 10.0]

  let original_p = types.protein_ratio(original)
  let original_f = types.fat_ratio(original)
  let original_c = types.carb_ratio(original)

  scales
  |> list.each(fn(scale) {
    let scaled = types.macros_scale(original, scale)
    float_approximately_equal(types.protein_ratio(scaled), original_p, 0.0001)
    |> should.be_true
    float_approximately_equal(types.fat_ratio(scaled), original_f, 0.0001)
    |> should.be_true
    float_approximately_equal(types.carb_ratio(scaled), original_c, 0.0001)
    |> should.be_true
  })
}

// ============================================================================
// PROPERTY: Percentage Calculation Formula Correctness
// ============================================================================

pub fn protein_percentage_formula_test() {
  // Property: protein% = (protein * 4) / total_calories
  let macros = balanced_macros()
  let total_cals = types.macros_calories(macros)
  let protein_cals = macros.protein *. 4.0
  let expected_ratio = protein_cals /. total_cals
  let actual_ratio = types.protein_ratio(macros)

  float_approximately_equal(actual_ratio, expected_ratio, 0.0001)
  |> should.be_true
}

pub fn fat_percentage_formula_test() {
  // Property: fat% = (fat * 9) / total_calories
  let macros = balanced_macros()
  let total_cals = types.macros_calories(macros)
  let fat_cals = macros.fat *. 9.0
  let expected_ratio = fat_cals /. total_cals
  let actual_ratio = types.fat_ratio(macros)

  float_approximately_equal(actual_ratio, expected_ratio, 0.0001)
  |> should.be_true
}

pub fn carb_percentage_formula_test() {
  // Property: carb% = (carbs * 4) / total_calories
  let macros = balanced_macros()
  let total_cals = types.macros_calories(macros)
  let carb_cals = macros.carbs *. 4.0
  let expected_ratio = carb_cals /. total_cals
  let actual_ratio = types.carb_ratio(macros)

  float_approximately_equal(actual_ratio, expected_ratio, 0.0001)
  |> should.be_true
}

// ============================================================================
// PROPERTY: Edge Cases with Very Small Values
// ============================================================================

pub fn percentages_correct_for_very_small_macros_test() {
  // Property: Percentages work correctly even with very small values
  let macros = very_small_macros()
  let sum =
    types.protein_ratio(macros)
    +. types.fat_ratio(macros)
    +. types.carb_ratio(macros)

  float_approximately_equal(sum, 1.0, 0.001) |> should.be_true
}

// ============================================================================
// PROPERTY: Edge Cases with Very Large Values
// ============================================================================

pub fn percentages_correct_for_very_large_macros_test() {
  // Property: Percentages work correctly even with very large values
  let macros = very_large_macros()
  let sum =
    types.protein_ratio(macros)
    +. types.fat_ratio(macros)
    +. types.carb_ratio(macros)

  float_approximately_equal(sum, 1.0, 0.001) |> should.be_true
}

// ============================================================================
// PROPERTY: Percentage Monotonicity
// ============================================================================

pub fn increasing_protein_increases_percentage_test() {
  // Property: Increasing one macro increases its percentage (holding others constant)
  let base = Macros(protein: 10.0, fat: 10.0, carbs: 10.0)
  let more_protein = Macros(protein: 20.0, fat: 10.0, carbs: 10.0)

  let base_ratio = types.protein_ratio(base)
  let more_ratio = types.protein_ratio(more_protein)

  { more_ratio >. base_ratio } |> should.be_true
}

pub fn increasing_fat_increases_percentage_test() {
  let base = Macros(protein: 10.0, fat: 10.0, carbs: 10.0)
  let more_fat = Macros(protein: 10.0, fat: 20.0, carbs: 10.0)

  let base_ratio = types.fat_ratio(base)
  let more_ratio = types.fat_ratio(more_fat)

  { more_ratio >. base_ratio } |> should.be_true
}

pub fn increasing_carbs_increases_percentage_test() {
  let base = Macros(protein: 10.0, fat: 10.0, carbs: 10.0)
  let more_carbs = Macros(protein: 10.0, fat: 10.0, carbs: 20.0)

  let base_ratio = types.carb_ratio(base)
  let more_ratio = types.carb_ratio(more_carbs)

  { more_ratio >. base_ratio } |> should.be_true
}

// ============================================================================
// PROPERTY: Complementary Percentages
// ============================================================================

pub fn increasing_one_decreases_others_test() {
  // Property: Increasing one macro decreases percentages of others
  let base = Macros(protein: 10.0, fat: 10.0, carbs: 10.0)
  let more_protein = Macros(protein: 30.0, fat: 10.0, carbs: 10.0)

  let base_fat_ratio = types.fat_ratio(base)
  let more_fat_ratio = types.fat_ratio(more_protein)

  let base_carb_ratio = types.carb_ratio(base)
  let more_carb_ratio = types.carb_ratio(more_protein)

  // Fat and carb percentages should decrease
  { more_fat_ratio <. base_fat_ratio } |> should.be_true
  { more_carb_ratio <. base_carb_ratio } |> should.be_true
}

// ============================================================================
// PROPERTY: Equal Macros Give Predictable Ratios
// ============================================================================

pub fn equal_protein_carbs_give_equal_ratios_test() {
  // Property: Equal protein and carbs (both 4 cal/g) give equal percentages
  let macros = Macros(protein: 50.0, fat: 0.0, carbs: 50.0)
  let p_ratio = types.protein_ratio(macros)
  let c_ratio = types.carb_ratio(macros)

  float_approximately_equal(p_ratio, c_ratio, 0.0001) |> should.be_true
  float_approximately_equal(p_ratio, 0.5, 0.0001) |> should.be_true
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Compare two floats with tolerance for floating point errors
fn float_approximately_equal(a: Float, b: Float, tolerance: Float) -> Bool {
  let diff = float_abs(a -. b)
  diff <. tolerance
}

/// Absolute value of a float
fn float_abs(x: Float) -> Float {
  case x <. 0.0 {
    True -> 0.0 -. x
    False -> x
  }
}
