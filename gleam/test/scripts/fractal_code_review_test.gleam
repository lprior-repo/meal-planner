import gleeunit
import gleeunit/should
import scripts/fractal_code_review

pub fn main() {
  gleeunit.main()
}

// Test: check_type_safety should return True for fully typed function
pub fn check_type_safety_fully_typed_test() {
  let code = "
pub fn calculate(x: Int, y: Int) -> Int {
  x + y
}
"

  fractal_code_review.check_type_safety(code)
  |> should.be_true()
}

// Test: check_type_safety should return False for untyped parameter
pub fn check_type_safety_untyped_parameter_test() {
  let code = "
pub fn calculate(x, y: Int) -> Int {
  x + y
}
"

  fractal_code_review.check_type_safety(code)
  |> should.be_false()
}

// Test: check_type_safety should return False for missing return type
pub fn check_type_safety_missing_return_type_test() {
  let code = "
pub fn calculate(x: Int, y: Int) {
  x + y
}
"

  fractal_code_review.check_type_safety(code)
  |> should.be_false()
}

// Test: check_type_safety should handle multiple functions correctly
pub fn check_type_safety_multiple_functions_test() {
  let code = "
pub fn add(x: Int, y: Int) -> Int {
  x + y
}

pub fn multiply(a: Float, b: Float) -> Float {
  a *. b
}
"

  fractal_code_review.check_type_safety(code)
  |> should.be_true()
}

// Test: check_type_safety should return False if any function is untyped
pub fn check_type_safety_mixed_functions_test() {
  let code = "
pub fn add(x: Int, y: Int) -> Int {
  x + y
}

pub fn multiply(a, b) {
  a *. b
}
"

  fractal_code_review.check_type_safety(code)
  |> should.be_false()
}

// Test: check_type_safety should handle external functions
pub fn check_type_safety_external_function_test() {
  let code = "
@external(erlang, \"erlang\", \"float\")
pub fn int_to_float(n: Int) -> Float
"

  fractal_code_review.check_type_safety(code)
  |> should.be_true()
}

// Test: check_type_safety should handle empty code
pub fn check_type_safety_empty_code_test() {
  let code = ""

  fractal_code_review.check_type_safety(code)
  |> should.be_true()
}

// Test: check_type_safety should handle code with only comments
pub fn check_type_safety_only_comments_test() {
  let code = "
/// This is a comment
// Another comment
"

  fractal_code_review.check_type_safety(code)
  |> should.be_true()
}

// Test: check_coverage should return 1.0 for 100% coverage
pub fn check_coverage_full_coverage_test() {
  let file = "gleam/test/meal_planner/web_test.gleam"

  fractal_code_review.check_coverage(file)
  |> should.equal(1.0)
}

// Test: check_coverage should return 0.0 for no test file
pub fn check_coverage_no_test_file_test() {
  let file = "gleam/src/meal_planner/web.gleam"

  fractal_code_review.check_coverage(file)
  |> should.equal(0.0)
}

// Test: check_coverage should calculate partial coverage correctly
pub fn check_coverage_partial_coverage_test() {
  let file = "gleam/src/meal_planner/storage.gleam"

  let coverage = fractal_code_review.check_coverage(file)

  // Should be between 0.0 and 1.0
  case coverage >=. 0.0 && coverage <=. 1.0 {
    True -> should.be_true(True)
    False -> should.be_true(False)
  }
}

// Test: check_coverage should handle non-existent files
pub fn check_coverage_non_existent_file_test() {
  let file = "gleam/src/does_not_exist.gleam"

  fractal_code_review.check_coverage(file)
  |> should.equal(0.0)
}
