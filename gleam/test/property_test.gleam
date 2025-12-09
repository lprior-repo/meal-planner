//// Property-based tests for Macros type using Gleam qcheck
////
//// BDD Spec: specs/features/property-tests-qcheck.spec.md
//// Bead: meal-planner-386
////
//// This module demonstrates property-based testing patterns using qcheck:
////
//// ## Key Patterns
////
//// 1. **Generators**: Create random test data with `qcheck.Generator(a)`
////    - Use `bounded_float(min, max)` for numeric ranges
////    - Combine generators with `map`, `map2`, `map3`, etc.
////    - Use `tuple2`, `tuple3` for generating multiple values
////
//// 2. **Property Tests**: Use `qcheck.given(generator, property_fn)`
////    - The `use` syntax creates clean property test functions
////    - Property functions receive generated values and assert invariants
////    - Tests run multiple iterations (default 100) with different values
////
//// 3. **Mathematical Properties**: Test algebraic laws
////    - Commutative: `a + b == b + a`
////    - Associative: `(a + b) + c == a + (b + c)`
////    - Identity: `a + 0 == a` and `a * 1 == a`
////    - Zero: `a * 0 == 0`
////
//// 4. **Approximate Equality**: Use epsilon for float comparisons
////    - Floating point arithmetic isn't exact
////    - Define `float_equal_approx` helper with small epsilon (0.0001)
////
//// ## Usage
////
//// Run with: `gleam test`
//// Each property test runs 100 times by default with randomized inputs.
//// If a test fails, qcheck will shrink the input to find the minimal failing case.

import gleam/float
import gleeunit/should
import meal_planner/types.{
  type Macros, Macros, macros_add, macros_calories, macros_scale, macros_zero,
}
import qcheck

// ============================================================================
// Generators
// ============================================================================

/// Generator for non-negative floats (valid macro values 0-500g)
///
/// Pattern: Use `bounded_float` for numeric ranges
fn non_negative_float() -> qcheck.Generator(Float) {
  qcheck.bounded_float(0.0, 500.0)
}

/// Simple generator for Macros using map2
///
/// Pattern: Combine multiple generators with `map2`, `map3`, etc.
fn gen_macros() -> qcheck.Generator(Macros) {
  use protein, fat <- qcheck.map2(non_negative_float(), non_negative_float())
  // For simplicity, use protein value for carbs too (scaled)
  Macros(protein: protein, fat: fat, carbs: protein *. 1.5)
}

/// Alternative: Generate Macros from tuple
///
/// Pattern: Generate tuples then map to custom types
fn gen_macros_from_tuple() -> qcheck.Generator(Macros) {
  use pf <- qcheck.map(qcheck.tuple2(non_negative_float(), non_negative_float()))
  let #(protein, fat) = pf
  Macros(protein: protein, fat: fat, carbs: protein +. fat)
}

// ============================================================================
// Property Tests: Macros Addition
// ============================================================================

/// GIVEN macros_add(a, b) WHEN testing THEN verify commutative: add(a,b) == add(b,a)
pub fn macros_add_commutative_test() {
  use ab <- qcheck.given(qcheck.tuple2(gen_macros(), gen_macros_from_tuple()))
  let #(a, b) = ab

  let result_ab = macros_add(a, b)
  let result_ba = macros_add(b, a)

  // Commutative property: a + b == b + a
  should.be_true(macros_equal(result_ab, result_ba))
}

/// GIVEN macros_add(a, b, c) WHEN testing THEN verify associative
/// Note: Using single generator with derived values to avoid timeout
pub fn macros_add_associative_test() {
  use a <- qcheck.given(gen_macros())
  // Derive b and c from a to avoid nested given timeouts
  let b = macros_scale(a, 0.5)
  let c = macros_scale(a, 0.3)

  let result_left = macros_add(macros_add(a, b), c)
  let result_right = macros_add(a, macros_add(b, c))

  // Associative property: (a + b) + c == a + (b + c)
  should.be_true(macros_equal_approx(result_left, result_right))
}

/// GIVEN macros_add(a, zero) WHEN testing THEN verify identity
pub fn macros_add_identity_test() {
  use a <- qcheck.given(gen_macros())

  let result = macros_add(a, macros_zero())

  // Identity property: a + 0 == a
  should.be_true(macros_equal(result, a))
}

// ============================================================================
// Property Tests: Macros Scaling
// ============================================================================

/// GIVEN macros_scale(m, 1.0) WHEN testing THEN verify identity: result == m
pub fn macros_scale_identity_test() {
  use m <- qcheck.given(gen_macros())

  let result = macros_scale(m, 1.0)

  // Identity property: m * 1.0 == m
  should.be_true(macros_equal(result, m))
}

/// GIVEN macros_scale(m, 0.0) WHEN testing THEN verify zero: result == macros_zero()
pub fn macros_scale_zero_test() {
  use m <- qcheck.given(gen_macros())

  let result = macros_scale(m, 0.0)

  // Zero property: m * 0.0 == zero
  should.be_true(macros_equal(result, macros_zero()))
}

/// GIVEN macros_scale(m, 2.0) WHEN testing THEN verify doubling
pub fn macros_scale_double_test() {
  use m <- qcheck.given(gen_macros())

  let scaled = macros_scale(m, 2.0)
  let added = macros_add(m, m)

  // m * 2 == m + m
  should.be_true(macros_equal_approx(scaled, added))
}

// ============================================================================
// Property Tests: Macros Calories
// ============================================================================

/// GIVEN macros_calories(m) WHEN testing THEN verify non-negative for non-negative inputs
pub fn macros_calories_non_negative_test() {
  use m <- qcheck.given(gen_macros())

  let calories = macros_calories(m)

  // Non-negative inputs should produce non-negative calories
  should.be_true(calories >=. 0.0)
}

/// GIVEN macros WHEN calories calculated THEN verify formula
pub fn macros_calories_formula_test() {
  use m <- qcheck.given(gen_macros())

  let calories = macros_calories(m)
  let expected = { m.protein *. 4.0 } +. { m.fat *. 9.0 } +. { m.carbs *. 4.0 }

  // Verify formula: (protein * 4) + (fat * 9) + (carbs * 4)
  should.be_true(float_equal_approx(calories, expected))
}

/// GIVEN macros_calories WHEN adding two macros THEN calories are additive
pub fn macros_calories_additive_test() {
  use ab <- qcheck.given(qcheck.tuple2(gen_macros(), gen_macros_from_tuple()))
  let #(a, b) = ab

  let sum_then_calories = macros_calories(macros_add(a, b))
  let calories_then_sum = macros_calories(a) +. macros_calories(b)

  // Calories of sum == sum of calories
  should.be_true(float_equal_approx(sum_then_calories, calories_then_sum))
}

// ============================================================================
// Helpers
// ============================================================================

/// Check if two Macros are exactly equal
fn macros_equal(a: Macros, b: Macros) -> Bool {
  a.protein == b.protein && a.fat == b.fat && a.carbs == b.carbs
}

/// Check if two Macros are approximately equal (for floating point comparison)
fn macros_equal_approx(a: Macros, b: Macros) -> Bool {
  let Macros(protein: ap, fat: af, carbs: ac) = a
  let Macros(protein: bp, fat: bf, carbs: bc) = b
  float_equal_approx(ap, bp)
  && float_equal_approx(af, bf)
  && float_equal_approx(ac, bc)
}

/// Approximate float equality with epsilon
fn float_equal_approx(a: Float, b: Float) -> Bool {
  let epsilon = 0.0001
  float.absolute_value(a -. b) <. epsilon
}
