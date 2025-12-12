import gleeunit
import gleeunit/should
import meal_planner/types.{type Macros, Macros}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Data Fixtures
// ============================================================================

fn test_macros() -> Macros {
  Macros(protein: 30.0, fat: 20.0, carbs: 50.0)
}

fn test_macros_2() -> Macros {
  Macros(protein: 10.0, fat: 5.0, carbs: 15.0)
}

fn test_macros_negative() -> Macros {
  Macros(protein: -10.0, fat: -5.0, carbs: -15.0)
}

// ============================================================================
// New Helper Functions Tests
// ============================================================================

pub fn macros_subtract_test() {
  let a = test_macros()
  let b = test_macros_2()
  let result = types.macros_subtract(a, b)

  result.protein |> should.equal(20.0)
  result.fat |> should.equal(15.0)
  result.carbs |> should.equal(35.0)
}

pub fn macros_subtract_self_test() {
  let a = test_macros()
  let result = types.macros_subtract(a, a)

  result |> should.equal(types.macros_zero())
}

pub fn macros_average_test() {
  let macros = [test_macros(), test_macros_2()]
  let result = types.macros_average(macros)

  result.protein |> should.equal(20.0)
  result.fat |> should.equal(12.5)
  result.carbs |> should.equal(32.5)
}

pub fn macros_average_empty_test() {
  let result = types.macros_average([])

  result |> should.equal(types.macros_zero())
}

pub fn macros_negate_test() {
  let m = test_macros()
  let result = types.macros_negate(m)

  result.protein |> should.equal(-30.0)
  result.fat |> should.equal(-20.0)
  result.carbs |> should.equal(-50.0)
}

pub fn macros_negate_twice_test() {
  let m = test_macros()
  let result = types.macros_negate(types.macros_negate(m))

  result |> should.equal(m)
}

pub fn macros_abs_test() {
  let m = test_macros_negative()
  let result = types.macros_abs(m)

  result.protein |> should.equal(10.0)
  result.fat |> should.equal(5.0)
  result.carbs |> should.equal(15.0)
}

pub fn macros_abs_positive_test() {
  let m = test_macros()
  let result = types.macros_abs(m)

  result |> should.equal(m)
}

pub fn macros_min_test() {
  let a = test_macros()
  let b = test_macros_2()
  let result = types.macros_min(a, b)

  result.protein |> should.equal(10.0)
  result.fat |> should.equal(5.0)
  result.carbs |> should.equal(15.0)
}

pub fn macros_max_test() {
  let a = test_macros()
  let b = test_macros_2()
  let result = types.macros_max(a, b)

  result.protein |> should.equal(30.0)
  result.fat |> should.equal(20.0)
  result.carbs |> should.equal(50.0)
}

pub fn macros_clamp_no_change_test() {
  let m = test_macros()
  let result = types.macros_clamp(m, 0.0, 100.0)

  result |> should.equal(m)
}

pub fn macros_clamp_lower_bound_test() {
  let m = test_macros_2()
  let result = types.macros_clamp(m, 20.0, 100.0)

  result.protein |> should.equal(20.0)
  result.fat |> should.equal(20.0)
  result.carbs |> should.equal(20.0)
}

pub fn macros_clamp_upper_bound_test() {
  let m = test_macros()
  let result = types.macros_clamp(m, 0.0, 25.0)

  result.protein |> should.equal(25.0)
  result.fat |> should.equal(20.0)
  result.carbs |> should.equal(25.0)
}

// ============================================================================
// Property-Based Tests (algebraic properties)
// ============================================================================

pub fn subtract_inverse_test() {
  let a = test_macros()
  let b = test_macros_2()

  let diff = types.macros_subtract(a, b)
  let restored = types.macros_add(diff, b)

  restored |> should.equal(a)
}
