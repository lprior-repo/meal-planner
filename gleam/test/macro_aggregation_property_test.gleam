/// Property-based tests for macro aggregation
/// Tests mathematical properties of macro aggregation operations
///
/// This test suite validates:
/// - Total macros >= sum of individual macros (accumulation property)
/// - Aggregation is commutative (order doesn't matter)
/// - Aggregation is associative (grouping doesn't matter)
/// - Empty list aggregation returns zero
/// - Single item aggregation returns that item
/// - Aggregation scales correctly with list size
///
/// Note: These are property tests written as traditional unit tests.
/// Each test verifies a mathematical property that should hold for all inputs.
///
import gleam/list
import gleeunit/should
import meal_planner/types.{type Macros, Macros}

// ============================================================================
// Test Data - Sample Macros for Aggregation
// ============================================================================

fn sample_macro_1() -> Macros {
  Macros(protein: 25.0, fat: 10.0, carbs: 30.0)
}

fn sample_macro_2() -> Macros {
  Macros(protein: 30.0, fat: 15.0, carbs: 40.0)
}

fn sample_macro_3() -> Macros {
  Macros(protein: 20.0, fat: 5.0, carbs: 50.0)
}

fn sample_macro_4() -> Macros {
  Macros(protein: 15.0, fat: 8.0, carbs: 25.0)
}

fn sample_macro_5() -> Macros {
  Macros(protein: 35.0, fat: 12.0, carbs: 45.0)
}

// Create lists of varying sizes for testing
fn macro_list_size_1() -> List(Macros) {
  [sample_macro_1()]
}

fn macro_list_size_2() -> List(Macros) {
  [sample_macro_1(), sample_macro_2()]
}

fn macro_list_size_3() -> List(Macros) {
  [sample_macro_1(), sample_macro_2(), sample_macro_3()]
}

fn macro_list_size_5() -> List(Macros) {
  [
    sample_macro_1(),
    sample_macro_2(),
    sample_macro_3(),
    sample_macro_4(),
    sample_macro_5(),
  ]
}

fn macro_list_size_10() -> List(Macros) {
  [
    sample_macro_1(),
    sample_macro_2(),
    sample_macro_3(),
    sample_macro_4(),
    sample_macro_5(),
    sample_macro_1(),
    sample_macro_2(),
    sample_macro_3(),
    sample_macro_4(),
    sample_macro_5(),
  ]
}

fn macro_list_size_20() -> List(Macros) {
  list.flatten([macro_list_size_10(), macro_list_size_10()])
}

// ============================================================================
// PROPERTY: Total Macros >= Sum of Individual Macros
// ============================================================================

pub fn total_macros_gte_individual_sum_size_1_test() {
  // Property: For 1 recipe, total macros should equal that recipe's macros
  let macros_list = macro_list_size_1()
  let total = types.macros_sum(macros_list)
  let individual = sample_macro_1()

  types.macros_approximately_equal(total, individual) |> should.be_true
}

pub fn total_macros_gte_individual_sum_size_2_test() {
  // Property: Total >= each individual macro
  let macros_list = macro_list_size_2()
  let total = types.macros_sum(macros_list)

  // Total protein should be >= any individual protein
  { total.protein >=. sample_macro_1().protein } |> should.be_true
  { total.protein >=. sample_macro_2().protein } |> should.be_true

  // Total fat should be >= any individual fat
  { total.fat >=. sample_macro_1().fat } |> should.be_true
  { total.fat >=. sample_macro_2().fat } |> should.be_true

  // Total carbs should be >= any individual carbs
  { total.carbs >=. sample_macro_1().carbs } |> should.be_true
  { total.carbs >=. sample_macro_2().carbs } |> should.be_true
}

pub fn total_macros_gte_individual_sum_size_5_test() {
  // Property: Total >= each individual macro for 5 recipes
  let macros_list = macro_list_size_5()
  let total = types.macros_sum(macros_list)

  // Check each recipe
  macros_list
  |> list.each(fn(m) {
    { total.protein >=. m.protein } |> should.be_true
    { total.fat >=. m.fat } |> should.be_true
    { total.carbs >=. m.carbs } |> should.be_true
  })
}

pub fn total_macros_gte_individual_sum_size_10_test() {
  // Property: Total >= each individual macro for 10 recipes
  let macros_list = macro_list_size_10()
  let total = types.macros_sum(macros_list)

  macros_list
  |> list.each(fn(m) {
    { total.protein >=. m.protein } |> should.be_true
    { total.fat >=. m.fat } |> should.be_true
    { total.carbs >=. m.carbs } |> should.be_true
  })
}

pub fn total_macros_gte_individual_sum_size_20_test() {
  // Property: Total >= each individual macro for 20 recipes
  let macros_list = macro_list_size_20()
  let total = types.macros_sum(macros_list)

  macros_list
  |> list.each(fn(m) {
    { total.protein >=. m.protein } |> should.be_true
    { total.fat >=. m.fat } |> should.be_true
    { total.carbs >=. m.carbs } |> should.be_true
  })
}

// ============================================================================
// PROPERTY: Aggregation Equals Manual Sum
// ============================================================================

pub fn aggregation_equals_manual_sum_test() {
  // Property: macros_sum should equal manual addition
  let macros_list = macro_list_size_3()
  let total = types.macros_sum(macros_list)

  let manual_protein =
    sample_macro_1().protein
    +. sample_macro_2().protein
    +. sample_macro_3().protein
  let manual_fat =
    sample_macro_1().fat +. sample_macro_2().fat +. sample_macro_3().fat
  let manual_carbs =
    sample_macro_1().carbs +. sample_macro_2().carbs +. sample_macro_3().carbs

  float_approximately_equal(total.protein, manual_protein, 0.001)
  |> should.be_true
  float_approximately_equal(total.fat, manual_fat, 0.001) |> should.be_true
  float_approximately_equal(total.carbs, manual_carbs, 0.001) |> should.be_true
}

// ============================================================================
// PROPERTY: Empty List Returns Zero
// ============================================================================

pub fn empty_list_returns_zero_test() {
  // Property: Sum of empty list should be zero
  let total = types.macros_sum([])
  types.macros_approximately_equal(total, types.macros_zero()) |> should.be_true
}

// ============================================================================
// PROPERTY: Single Item Returns That Item
// ============================================================================

pub fn single_item_returns_item_test() {
  // Property: Sum of single item should equal that item
  let item = sample_macro_1()
  let total = types.macros_sum([item])
  types.macros_approximately_equal(total, item) |> should.be_true
}

// ============================================================================
// PROPERTY: Aggregation is Commutative (Order Doesn't Matter)
// ============================================================================

pub fn aggregation_commutative_two_items_test() {
  // Property: sum([a, b]) = sum([b, a])
  let forward = types.macros_sum([sample_macro_1(), sample_macro_2()])
  let reverse = types.macros_sum([sample_macro_2(), sample_macro_1()])
  types.macros_approximately_equal(forward, reverse) |> should.be_true
}

pub fn aggregation_commutative_three_items_test() {
  // Property: Different orderings give same result
  let order1 =
    types.macros_sum([sample_macro_1(), sample_macro_2(), sample_macro_3()])
  let order2 =
    types.macros_sum([sample_macro_3(), sample_macro_1(), sample_macro_2()])
  let order3 =
    types.macros_sum([sample_macro_2(), sample_macro_3(), sample_macro_1()])

  types.macros_approximately_equal(order1, order2) |> should.be_true
  types.macros_approximately_equal(order2, order3) |> should.be_true
}

// ============================================================================
// PROPERTY: Aggregation is Associative (Grouping Doesn't Matter)
// ============================================================================

pub fn aggregation_associative_test() {
  // Property: (a + b) + c = a + (b + c)
  let a = sample_macro_1()
  let b = sample_macro_2()
  let c = sample_macro_3()

  let left = types.macros_add(types.macros_add(a, b), c)
  let right = types.macros_add(a, types.macros_add(b, c))

  types.macros_approximately_equal(left, right) |> should.be_true
}

pub fn aggregation_associative_with_sum_test() {
  // Property: sum([a, b, c]) = add(a, sum([b, c]))
  let a = sample_macro_1()
  let b = sample_macro_2()
  let c = sample_macro_3()

  let total_sum = types.macros_sum([a, b, c])
  let partial_sum = types.macros_add(a, types.macros_sum([b, c]))

  types.macros_approximately_equal(total_sum, partial_sum) |> should.be_true
}

// ============================================================================
// PROPERTY: Scaling Property
// ============================================================================

pub fn sum_scales_linearly_test() {
  // Property: sum(list) * 2 = sum(list ++ list)
  let original_list = macro_list_size_3()
  let doubled_list = list.flatten([original_list, original_list])

  let original_sum = types.macros_sum(original_list)
  let doubled_sum = types.macros_sum(doubled_list)
  let scaled_sum = types.macros_scale(original_sum, 2.0)

  types.macros_approximately_equal(doubled_sum, scaled_sum) |> should.be_true
}

// ============================================================================
// PROPERTY: Calorie Aggregation
// ============================================================================

pub fn aggregated_calories_equal_sum_of_individual_calories_test() {
  // Property: calories(sum(list)) = sum(map(list, calories))
  let macros_list = macro_list_size_5()
  let total_macros = types.macros_sum(macros_list)
  let total_calories = types.macros_calories(total_macros)

  let individual_calories =
    macros_list
    |> list.map(types.macros_calories)
    |> list.fold(0.0, fn(acc, cal) { acc +. cal })

  float_approximately_equal(total_calories, individual_calories, 0.01)
  |> should.be_true
}

// ============================================================================
// PROPERTY: Non-Negative Aggregation
// ============================================================================

pub fn aggregated_macros_non_negative_test() {
  // Property: If all inputs are non-negative, output is non-negative
  let macros_list = macro_list_size_10()
  let total = types.macros_sum(macros_list)

  { total.protein >=. 0.0 } |> should.be_true
  { total.fat >=. 0.0 } |> should.be_true
  { total.carbs >=. 0.0 } |> should.be_true
}

// ============================================================================
// PROPERTY: Identity Element
// ============================================================================

pub fn zero_is_identity_element_test() {
  // Property: sum([a, zero]) = a
  let a = sample_macro_1()
  let zero = types.macros_zero()
  let result = types.macros_sum([a, zero])

  types.macros_approximately_equal(result, a) |> should.be_true
}

pub fn multiple_zeros_are_identity_test() {
  // Property: sum([a, zero, zero, zero]) = a
  let a = sample_macro_1()
  let zeros = [types.macros_zero(), types.macros_zero(), types.macros_zero()]
  let result = types.macros_sum([a, ..zeros])

  types.macros_approximately_equal(result, a) |> should.be_true
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
