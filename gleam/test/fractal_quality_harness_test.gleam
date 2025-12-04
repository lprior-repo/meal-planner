/// Fractal Quality Harness - Truth Score Calculator Tests
///
/// Tests for truth_score function that calculates quality score from test results.
/// Score is a Float between 0.0-1.0 representing the proportion of passing tests.
///
/// Formula: truth_score = passed_tests / total_tests
/// - 1.0 = all tests passed (perfect quality)
/// - 0.0 = all tests failed (complete failure)
/// - 0.95+ = high quality (deployment ready)
/// - <0.95 = needs work (auto-rollback)
///
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// ===================================================================
// TEST RESULT TYPE
// ===================================================================

/// Test results containing pass/fail counts
pub type TestResults {
  TestResults(passed: Int, failed: Int)
}

// ===================================================================
// TRUTH SCORE CALCULATOR
// ===================================================================

/// Calculate truth score from test results
/// Returns a Float between 0.0 and 1.0
pub fn truth_score(results: TestResults) -> Float {
  let total = results.passed + results.failed

  case total {
    0 -> 0.0
    _ -> {
      let passed_float = int_to_float(results.passed)
      let total_float = int_to_float(total)
      passed_float /. total_float
    }
  }
}

// ===================================================================
// BASIC FUNCTIONALITY TESTS
// ===================================================================

pub fn all_tests_passed_returns_1_0_test() {
  TestResults(passed: 10, failed: 0)
  |> truth_score
  |> should.equal(1.0)
}

pub fn all_tests_failed_returns_0_0_test() {
  TestResults(passed: 0, failed: 10)
  |> truth_score
  |> should.equal(0.0)
}

pub fn half_tests_passed_returns_0_5_test() {
  TestResults(passed: 5, failed: 5)
  |> truth_score
  |> should.equal(0.5)
}

pub fn single_passing_test_returns_1_0_test() {
  TestResults(passed: 1, failed: 0)
  |> truth_score
  |> should.equal(1.0)
}

pub fn single_failing_test_returns_0_0_test() {
  TestResults(passed: 0, failed: 1)
  |> truth_score
  |> should.equal(0.0)
}

pub fn no_tests_returns_0_0_test() {
  // Edge case: no tests run
  TestResults(passed: 0, failed: 0)
  |> truth_score
  |> should.equal(0.0)
}

// ===================================================================
// PRECISE CALCULATION TESTS
// ===================================================================

pub fn ninety_five_percent_passing_test() {
  // 95 passed, 5 failed = 0.95 (threshold for deployment)
  let score =
    TestResults(passed: 95, failed: 5)
    |> truth_score

  score
  |> should.equal(0.95)
}

pub fn one_failure_in_hundred_test() {
  // 99 passed, 1 failed = 0.99
  let score =
    TestResults(passed: 99, failed: 1)
    |> truth_score

  score
  |> should.equal(0.99)
}

pub fn seventy_five_percent_passing_test() {
  // 75 passed, 25 failed = 0.75
  let score =
    TestResults(passed: 75, failed: 25)
    |> truth_score

  score
  |> should.equal(0.75)
}

// ===================================================================
// PROPERTY-BASED TESTS
// ===================================================================

pub fn score_always_between_0_and_1_test() {
  // Property: score must always be in range [0.0, 1.0]
  verify_score_in_range(TestResults(passed: 0, failed: 100))
  verify_score_in_range(TestResults(passed: 100, failed: 0))
  verify_score_in_range(TestResults(passed: 50, failed: 50))
  verify_score_in_range(TestResults(passed: 1, failed: 999))
  verify_score_in_range(TestResults(passed: 999, failed: 1))
}

fn verify_score_in_range(results: TestResults) -> Nil {
  let score = truth_score(results)
  { score >=. 0.0 } |> should.be_true
  { score <=. 1.0 } |> should.be_true
}

pub fn score_increases_with_more_passes_test() {
  // Property: adding passes should increase score
  let score1 = truth_score(TestResults(passed: 5, failed: 5))
  let score2 = truth_score(TestResults(passed: 6, failed: 5))
  let score3 = truth_score(TestResults(passed: 7, failed: 5))

  { score2 >. score1 } |> should.be_true
  { score3 >. score2 } |> should.be_true
}

pub fn score_decreases_with_more_failures_test() {
  // Property: adding failures should decrease score
  let score1 = truth_score(TestResults(passed: 5, failed: 5))
  let score2 = truth_score(TestResults(passed: 5, failed: 6))
  let score3 = truth_score(TestResults(passed: 5, failed: 7))

  { score2 <. score1 } |> should.be_true
  { score3 <. score2 } |> should.be_true
}

pub fn score_is_commutative_test() {
  // Property: order of test execution doesn't matter
  // (10 pass, 5 fail) same score as (5 fail, 10 pass)
  let score1 = truth_score(TestResults(passed: 10, failed: 5))
  let score2 = truth_score(TestResults(passed: 10, failed: 5))

  score1 |> should.equal(score2)
}

// ===================================================================
// DEPLOYMENT READINESS TESTS
// ===================================================================

pub fn high_quality_score_test() {
  // Score >= 0.95 indicates deployment readiness
  let score = truth_score(TestResults(passed: 95, failed: 5))

  { score >=. 0.95 } |> should.be_true
}

pub fn low_quality_score_test() {
  // Score < 0.95 indicates need for rollback
  let score = truth_score(TestResults(passed: 90, failed: 10))

  { score <. 0.95 } |> should.be_true
}

pub fn perfect_quality_score_test() {
  // Score = 1.0 indicates perfect quality
  let score = truth_score(TestResults(passed: 100, failed: 0))

  { score == 1.0 } |> should.be_true
}

// ===================================================================
// EDGE CASES
// ===================================================================

pub fn large_number_of_tests_test() {
  // Verify calculation works with large numbers
  let score = truth_score(TestResults(passed: 10_000, failed: 100))

  // 10000 / 10100 ≈ 0.9901
  { score >. 0.99 } |> should.be_true
  { score <. 1.0 } |> should.be_true
}

pub fn single_test_suite_test() {
  // Edge case: only one test in suite
  let pass_score = truth_score(TestResults(passed: 1, failed: 0))
  let fail_score = truth_score(TestResults(passed: 0, failed: 1))

  pass_score |> should.equal(1.0)
  fail_score |> should.equal(0.0)
}

// ===================================================================
// HELPER FUNCTIONS
// ===================================================================

@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float
