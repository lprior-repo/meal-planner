import gleam/list
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

// Test: detect_long_functions should find functions over 50 lines
pub fn detect_long_functions_finds_long_function_test() {
  let code = "
pub fn short_function() -> Int {
  1 + 1
}

pub fn long_function() -> Int {
  let x = 1
  let y = 2
  let z = 3
  let a = 4
  let b = 5
  let c = 6
  let d = 7
  let e = 8
  let f = 9
  let g = 10
  let h = 11
  let i = 12
  let j = 13
  let k = 14
  let l = 15
  let m = 16
  let n = 17
  let o = 18
  let p = 19
  let q = 20
  let r = 21
  let s = 22
  let t = 23
  let u = 24
  let v = 25
  let w = 26
  let x2 = 27
  let y2 = 28
  let z2 = 29
  let a2 = 30
  let b2 = 31
  let c2 = 32
  let d2 = 33
  let e2 = 34
  let f2 = 35
  let g2 = 36
  let h2 = 37
  let i2 = 38
  let j2 = 39
  let k2 = 40
  let l2 = 41
  let m2 = 42
  let n2 = 43
  let o2 = 44
  let p2 = 45
  x + y + z
}
"

  let long_funcs = fractal_code_review.detect_long_functions(code)

  list.length(long_funcs)
  |> should.equal(1)

  case list.first(long_funcs) {
    Ok(func) -> {
      func.name
      |> should.equal("long_function")

      // Should have more than 50 lines
      func.line_count
      |> should.be_true(fn(count) { count > 50 })
    }
    Error(_) -> should.fail()
  }
}

// Test: detect_long_functions should ignore short functions
pub fn detect_long_functions_ignores_short_functions_test() {
  let code = "
pub fn func1() -> Int { 1 }
pub fn func2() -> String { \"hello\" }
pub fn func3() -> Bool { True }
"

  let long_funcs = fractal_code_review.detect_long_functions(code)

  list.length(long_funcs)
  |> should.equal(0)
}

// Test: detect_long_functions should handle empty code
pub fn detect_long_functions_empty_code_test() {
  let code = ""

  let long_funcs = fractal_code_review.detect_long_functions(code)

  list.length(long_funcs)
  |> should.equal(0)
}

// Test: calculate_review_score should return 1.0 for all passing checks
pub fn calculate_review_score_all_passing_test() {
  let checks = [
    #("type_safety", True),
    #("test_coverage", True),
    #("no_long_functions", True),
  ]

  fractal_code_review.calculate_review_score(checks)
  |> should.equal(1.0)
}

// Test: calculate_review_score should return 0.0 for all failing checks
pub fn calculate_review_score_all_failing_test() {
  let checks = [
    #("type_safety", False),
    #("test_coverage", False),
    #("no_long_functions", False),
  ]

  fractal_code_review.calculate_review_score(checks)
  |> should.equal(0.0)
}

// Test: calculate_review_score should calculate partial score correctly
pub fn calculate_review_score_partial_test() {
  let checks = [
    #("type_safety", True),
    #("test_coverage", False),
    #("no_long_functions", True),
  ]

  let score = fractal_code_review.calculate_review_score(checks)

  // Should be 2/3 = 0.666...
  case score >=. 0.66 && score <=. 0.67 {
    True -> should.be_true(True)
    False -> should.be_true(False)
  }
}

// Test: calculate_review_score should handle empty checklist
pub fn calculate_review_score_empty_test() {
  let checks = []

  fractal_code_review.calculate_review_score(checks)
  |> should.equal(1.0)
}

// Test: calculate_review_score should handle single check
pub fn calculate_review_score_single_passing_test() {
  let checks = [#("type_safety", True)]

  fractal_code_review.calculate_review_score(checks)
  |> should.equal(1.0)
}

pub fn calculate_review_score_single_failing_test() {
  let checks = [#("type_safety", False)]

  fractal_code_review.calculate_review_score(checks)
  |> should.equal(0.0)
}
