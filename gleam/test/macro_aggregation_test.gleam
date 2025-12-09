/// Unit Tests for macro aggregation operations
/// Verifies: macros_add is associative and commutative
/// Verifies: macros_sum produces consistent results regardless of order
import gleam/float
import gleam/list
import gleeunit
import gleeunit/should
import meal_planner/types.{
  type Macros, Macros, macros_add, macros_approximately_equal, macros_sum,
  macros_zero,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Helper
// ============================================================================

fn approx_equal(a: Macros, b: Macros, tolerance: Float) -> Bool {
  float.absolute_value(a.protein -. b.protein) <. tolerance
  && float.absolute_value(a.fat -. b.fat) <. tolerance
  && float.absolute_value(a.carbs -. b.carbs) <. tolerance
}

// ============================================================================
// Property Test: Commutativity
// ============================================================================

/// Test: Addition is commutative
/// Given two macros, a + b should equal b + a
pub fn macros_add_commutative_test() {
  let a = Macros(protein: 25.0, fat: 10.0, carbs: 30.0)
  let b = Macros(protein: 15.0, fat: 5.0, carbs: 20.0)

  let ab = macros_add(a, b)
  let ba = macros_add(b, a)

  macros_approximately_equal(ab, ba) |> should.be_true
}

// ============================================================================
// Property Test: Associativity
// ============================================================================

/// Test: Addition is associative
/// Given three macros, (a + b) + c should equal a + (b + c)
pub fn macros_add_associative_test() {
  let a = Macros(protein: 20.0, fat: 8.0, carbs: 25.0)
  let b = Macros(protein: 15.0, fat: 5.0, carbs: 20.0)
  let c = Macros(protein: 10.0, fat: 3.0, carbs: 15.0)

  let ab = macros_add(a, b)
  let ab_c = macros_add(ab, c)

  let bc = macros_add(b, c)
  let a_bc = macros_add(a, bc)

  macros_approximately_equal(ab_c, a_bc) |> should.be_true
}

// ============================================================================
// Property Test: Identity Element
// ============================================================================

/// Test: Zero is the identity element for macro addition
/// Given any macros, a + 0 should equal a
pub fn macros_add_identity_test() {
  let macros = Macros(protein: 30.0, fat: 15.0, carbs: 40.0)
  let zero = macros_zero()
  let result = macros_add(macros, zero)

  macros_approximately_equal(result, macros) |> should.be_true
}

// ============================================================================
// Property Test: Sum Consistency
// ============================================================================

/// Test: macros_sum is consistent with repeated macros_add
pub fn macros_sum_consistency_test() {
  let macros_list = [
    Macros(protein: 10.0, fat: 5.0, carbs: 15.0),
    Macros(protein: 20.0, fat: 10.0, carbs: 25.0),
    Macros(protein: 15.0, fat: 8.0, carbs: 20.0),
  ]

  let sum_result = macros_sum(macros_list)
  let fold_result = list.fold(macros_list, macros_zero(), macros_add)

  macros_approximately_equal(sum_result, fold_result) |> should.be_true
}

// ============================================================================
// Property Test: Sum Order Independence
// ============================================================================

/// Test: macros_sum is order independent
/// Summing in different orders should give the same result
pub fn macros_sum_order_independent_test() {
  let macros_list = [
    Macros(protein: 10.0, fat: 5.0, carbs: 15.0),
    Macros(protein: 20.0, fat: 10.0, carbs: 25.0),
    Macros(protein: 15.0, fat: 8.0, carbs: 20.0),
  ]

  let sum_original = macros_sum(macros_list)
  let reversed = list.reverse(macros_list)
  let sum_reversed = macros_sum(reversed)

  macros_approximately_equal(sum_original, sum_reversed) |> should.be_true
}

// ============================================================================
// Property Test: Sum Non-Negativity
// ============================================================================

/// Test: Summing non-negative values produces non-negative result
pub fn macros_sum_non_negative_test() {
  let macros_list = [
    Macros(protein: 10.0, fat: 5.0, carbs: 15.0),
    Macros(protein: 20.0, fat: 10.0, carbs: 25.0),
    Macros(protein: 15.0, fat: 8.0, carbs: 20.0),
  ]

  let sum = macros_sum(macros_list)

  { sum.protein >=. 0.0 && sum.fat >=. 0.0 && sum.carbs >=. 0.0 }
  |> should.be_true
}

// ============================================================================
// Property Test: Sum Empty List
// ============================================================================

/// Test: Summing an empty list gives zero macros
pub fn macros_sum_empty_list_test() {
  let empty_list: List(Macros) = []
  let sum = macros_sum(empty_list)
  let zero = macros_zero()

  macros_approximately_equal(sum, zero) |> should.be_true
}

// ============================================================================
// Property Test: Component-Wise Addition
// ============================================================================

/// Test: Addition operates component-wise
/// Each component of (a + b) should be sum of individual components
pub fn macros_add_component_wise_test() {
  let a = Macros(protein: 25.0, fat: 10.0, carbs: 30.0)
  let b = Macros(protein: 15.0, fat: 5.0, carbs: 20.0)

  let result = macros_add(a, b)

  let protein_correct = {
    let diff =
      float.absolute_value(result.protein -. { a.protein +. b.protein })
    diff <. 0.1
  }

  let fat_correct = {
    let diff = float.absolute_value(result.fat -. { a.fat +. b.fat })
    diff <. 0.1
  }

  let carbs_correct = {
    let diff = float.absolute_value(result.carbs -. { a.carbs +. b.carbs })
    diff <. 0.1
  }

  { protein_correct && fat_correct && carbs_correct } |> should.be_true
}
