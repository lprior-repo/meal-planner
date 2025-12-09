//// Property-based tests for macro aggregation operations
//// Verifies: macros_add is associative and commutative
//// Verifies: macros_sum produces consistent results regardless of order
//// Bead: meal-planner-n0s7

import gleam/float
import gleam/list
import gleeunit
import gleeunit/should
import meal_planner/types.{
  type Macros, Macros, macros_add, macros_approximately_equal, macros_sum,
  macros_zero,
}
import qcheck

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Generators
// ============================================================================

/// Generator for non-negative floats representing macro values (0-500g)
fn non_negative_float() -> qcheck.Generator(Float) {
  qcheck.bounded_float(0.0, 500.0)
}

/// Generator for Macros with independent protein, fat, and carbs values
fn gen_macros() -> qcheck.Generator(Macros) {
  use protein <- qcheck.map(non_negative_float())
  use fat <- qcheck.map(non_negative_float())
  use carbs <- qcheck.map(non_negative_float())
  Macros(protein: protein, fat: fat, carbs: carbs)
}

/// Generator for a pair of Macros
fn gen_macros_pair() -> qcheck.Generator(#(Macros, Macros)) {
  use a <- qcheck.map(gen_macros())
  use b <- qcheck.map(gen_macros())
  #(a, b)
}

/// Generator for a triple of Macros
fn gen_macros_triple() -> qcheck.Generator(#(Macros, Macros, Macros)) {
  use a <- qcheck.map(gen_macros())
  use b <- qcheck.map(gen_macros())
  use c <- qcheck.map(gen_macros())
  #(a, b, c)
}

/// Generator for a list of Macros (2-10 items)
fn gen_macros_list() -> qcheck.Generator(List(Macros)) {
  qcheck.list_generic(gen_macros(), qcheck.int_uniform_inclusive(2, 10))
}

// ============================================================================
// Property Test: Commutativity
// ============================================================================

/// GIVEN two random Macros WHEN adding them in either order
/// THEN the result should be the same (commutative property)
///
/// Mathematical property: a + b = b + a
///
/// This test verifies that macros_add(a, b) = macros_add(b, a)
/// for all possible combinations of macros.
pub fn macros_add_commutative_test() {
  use pair <- qcheck.given(gen_macros_pair())
  let #(a, b) = pair

  // Add in both orders
  let ab = macros_add(a, b)
  let ba = macros_add(b, a)

  // Verify they are approximately equal
  macros_approximately_equal(ab, ba)
  |> should.be_true
}

// ============================================================================
// Property Test: Associativity
// ============================================================================

/// GIVEN three random Macros WHEN adding them with different groupings
/// THEN the result should be the same (associative property)
///
/// Mathematical property: (a + b) + c = a + (b + c)
///
/// This test verifies that the order of operations doesn't matter
/// when adding multiple macros together.
pub fn macros_add_associative_test() {
  use triple <- qcheck.given(gen_macros_triple())
  let #(a, b, c) = triple

  // Add with left grouping: (a + b) + c
  let ab = macros_add(a, b)
  let ab_c = macros_add(ab, c)

  // Add with right grouping: a + (b + c)
  let bc = macros_add(b, c)
  let a_bc = macros_add(a, bc)

  // Verify they are approximately equal
  macros_approximately_equal(ab_c, a_bc)
  |> should.be_true
}

// ============================================================================
// Property Test: Identity Element
// ============================================================================

/// GIVEN any Macros WHEN adding zero macros
/// THEN the result should be unchanged (identity property)
///
/// Mathematical property: a + 0 = a
///
/// This verifies that macros_zero() acts as the identity element
/// for macros addition.
pub fn macros_add_identity_test() {
  use macros <- qcheck.given(gen_macros())

  let zero = macros_zero()
  let result = macros_add(macros, zero)

  // Verify adding zero doesn't change the macros
  macros_approximately_equal(result, macros)
  |> should.be_true
}

// ============================================================================
// Property Test: Sum Consistency
// ============================================================================

/// GIVEN a list of Macros WHEN summing them with macros_sum
/// THEN the result should equal manually folding with macros_add
///
/// This test verifies that macros_sum is implemented correctly
/// and produces consistent results.
pub fn macros_sum_consistency_test() {
  use macros_list <- qcheck.given(gen_macros_list())

  // Sum using the dedicated function
  let sum_result = macros_sum(macros_list)

  // Sum using manual fold
  let fold_result = list.fold(macros_list, macros_zero(), macros_add)

  // Verify they are approximately equal
  macros_approximately_equal(sum_result, fold_result)
  |> should.be_true
}

// ============================================================================
// Property Test: Sum Order Independence
// ============================================================================

/// GIVEN a list of Macros WHEN summing them in different orders
/// THEN the result should be the same (order independence)
///
/// This test combines commutativity and associativity to verify
/// that the order of elements doesn't matter when summing.
pub fn macros_sum_order_independent_test() {
  use macros_list <- qcheck.given(gen_macros_list())

  // Sum in original order
  let sum_original = macros_sum(macros_list)

  // Sum in reversed order
  let reversed = list.reverse(macros_list)
  let sum_reversed = macros_sum(reversed)

  // Verify they are approximately equal
  macros_approximately_equal(sum_original, sum_reversed)
  |> should.be_true
}

// ============================================================================
// Property Test: Sum Non-Negativity
// ============================================================================

/// GIVEN a list of non-negative Macros WHEN summing them
/// THEN all components of the result should be non-negative
///
/// This property ensures that summing non-negative values
/// produces non-negative results.
pub fn macros_sum_non_negative_test() {
  use macros_list <- qcheck.given(gen_macros_list())

  let sum = macros_sum(macros_list)

  // Verify all components are non-negative
  let protein_ok = sum.protein >=. 0.0
  let fat_ok = sum.fat >=. 0.0
  let carbs_ok = sum.carbs >=. 0.0

  { protein_ok && fat_ok && carbs_ok }
  |> should.be_true
}

// ============================================================================
// Property Test: Sum Empty List
// ============================================================================

/// GIVEN an empty list WHEN summing macros
/// THEN the result should be zero macros
///
/// This verifies the base case of the summation.
pub fn macros_sum_empty_list_test() {
  use _ <- qcheck.given(qcheck.int())

  let empty_list = []
  let sum = macros_sum(empty_list)
  let zero = macros_zero()

  macros_approximately_equal(sum, zero)
  |> should.be_true
}

// ============================================================================
// Property Test: Component-Wise Addition
// ============================================================================

/// GIVEN two Macros WHEN adding them
/// THEN each component should be the sum of individual components
///
/// This verifies that macros_add correctly sums each field independently.
pub fn macros_add_component_wise_test() {
  use pair <- qcheck.given(gen_macros_pair())
  let #(a, b) = pair

  let result = macros_add(a, b)

  // Verify each component is summed correctly
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

  { protein_correct && fat_correct && carbs_correct }
  |> should.be_true
}
