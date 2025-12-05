//// Property-based tests for calorie calculations
//// Verifies: calories = 4*protein + 4*carbs + 9*fat (within 0.01 tolerance)
//// Bead: meal-planner-0qot

import gleam/float
import gleeunit
import gleeunit/should
import meal_planner/types.{type Macros, Macros, macros_calories}
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

// ============================================================================
// Property Test: Calorie Calculation Formula
// ============================================================================

/// GIVEN random macro combinations WHEN calculating calories
/// THEN verify: calories = 4*protein + 4*carbs + 9*fat (within 0.01 tolerance)
///
/// This property test generates 100 random combinations of protein, fat, and carbs
/// and verifies that the macros_calories function correctly implements the formula:
///   calories = (protein * 4) + (fat * 9) + (carbs * 4)
///
/// The test uses a tolerance of 0.01 calories to account for floating-point
/// arithmetic precision.
pub fn calories_formula_property_test() {
  use macros <- qcheck.given(gen_macros())

  // Calculate calories using the function under test
  let actual_calories = macros_calories(macros)

  // Calculate expected calories using the formula directly
  let expected_calories =
    { macros.protein *. 4.0 }
    +. { macros.fat *. 9.0 }
    +. { macros.carbs *. 4.0 }

  // Verify the formula is correct within tolerance
  let difference = float.absolute_value(actual_calories -. expected_calories)
  let tolerance = 0.01

  difference
  |> should.be_true(fn(diff) { diff <. tolerance })
}

/// GIVEN zero macros WHEN calculating calories THEN result should be zero
pub fn calories_zero_macros_test() {
  use _ <- qcheck.given(qcheck.int())

  let zero_macros = Macros(protein: 0.0, fat: 0.0, carbs: 0.0)
  let calories = macros_calories(zero_macros)

  calories
  |> should.equal(0.0)
}

/// GIVEN macros with only protein WHEN calculating calories
/// THEN result should be protein * 4
pub fn calories_protein_only_test() {
  use protein <- qcheck.given(non_negative_float())

  let macros = Macros(protein: protein, fat: 0.0, carbs: 0.0)
  let calories = macros_calories(macros)
  let expected = protein *. 4.0

  let difference = float.absolute_value(calories -. expected)
  let tolerance = 0.01

  difference
  |> should.be_true(fn(diff) { diff <. tolerance })
}

/// GIVEN macros with only fat WHEN calculating calories
/// THEN result should be fat * 9
pub fn calories_fat_only_test() {
  use fat <- qcheck.given(non_negative_float())

  let macros = Macros(protein: 0.0, fat: fat, carbs: 0.0)
  let calories = macros_calories(macros)
  let expected = fat *. 9.0

  let difference = float.absolute_value(calories -. expected)
  let tolerance = 0.01

  difference
  |> should.be_true(fn(diff) { diff <. tolerance })
}

/// GIVEN macros with only carbs WHEN calculating calories
/// THEN result should be carbs * 4
pub fn calories_carbs_only_test() {
  use carbs <- qcheck.given(non_negative_float())

  let macros = Macros(protein: 0.0, fat: 0.0, carbs: carbs)
  let calories = macros_calories(macros)
  let expected = carbs *. 4.0

  let difference = float.absolute_value(calories -. expected)
  let tolerance = 0.01

  difference
  |> should.be_true(fn(diff) { diff <. tolerance })
}

/// GIVEN non-negative macros WHEN calculating calories
/// THEN result should always be non-negative
pub fn calories_non_negative_test() {
  use macros <- qcheck.given(gen_macros())

  let calories = macros_calories(macros)

  calories
  |> should.be_true(fn(cal) { cal >=. 0.0 })
}
