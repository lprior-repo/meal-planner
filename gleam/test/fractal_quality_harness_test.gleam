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
// TEST RESULT AGGREGATOR
// ===================================================================

/// Aggregate test results from multiple test passes
/// Combines unit, integration, and E2E test results
pub fn aggregate_test_results(
  unit: TestResults,
  integration: TestResults,
  e2e: TestResults,
) -> TestResults {
  TestResults(
    passed: unit.passed + integration.passed + e2e.passed,
    failed: unit.failed + integration.failed + e2e.failed,
  )
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
// AGGREGATE TEST RESULTS TESTS
// ===================================================================

pub fn aggregate_all_passed_test() {
  // All three test types passed
  let unit = TestResults(passed: 10, failed: 0)
  let integration = TestResults(passed: 5, failed: 0)
  let e2e = TestResults(passed: 3, failed: 0)

  aggregate_test_results(unit, integration, e2e)
  |> should.equal(TestResults(passed: 18, failed: 0))
}

pub fn aggregate_all_failed_test() {
  // All three test types failed
  let unit = TestResults(passed: 0, failed: 10)
  let integration = TestResults(passed: 0, failed: 5)
  let e2e = TestResults(passed: 0, failed: 3)

  aggregate_test_results(unit, integration, e2e)
  |> should.equal(TestResults(passed: 0, failed: 18))
}

pub fn aggregate_mixed_results_test() {
  // Mix of passed and failed across test types
  let unit = TestResults(passed: 8, failed: 2)
  let integration = TestResults(passed: 4, failed: 1)
  let e2e = TestResults(passed: 2, failed: 1)

  aggregate_test_results(unit, integration, e2e)
  |> should.equal(TestResults(passed: 14, failed: 4))
}

pub fn aggregate_zero_tests_test() {
  // Edge case: no tests in any category
  let unit = TestResults(passed: 0, failed: 0)
  let integration = TestResults(passed: 0, failed: 0)
  let e2e = TestResults(passed: 0, failed: 0)

  aggregate_test_results(unit, integration, e2e)
  |> should.equal(TestResults(passed: 0, failed: 0))
}

pub fn aggregate_only_unit_tests_test() {
  // Only unit tests ran (Pass 1 of fractal loop)
  let unit = TestResults(passed: 10, failed: 1)
  let integration = TestResults(passed: 0, failed: 0)
  let e2e = TestResults(passed: 0, failed: 0)

  aggregate_test_results(unit, integration, e2e)
  |> should.equal(TestResults(passed: 10, failed: 1))
}

pub fn aggregate_unit_and_integration_test() {
  // Unit and integration tests ran (Pass 1 and 2)
  let unit = TestResults(passed: 10, failed: 1)
  let integration = TestResults(passed: 5, failed: 0)
  let e2e = TestResults(passed: 0, failed: 0)

  aggregate_test_results(unit, integration, e2e)
  |> should.equal(TestResults(passed: 15, failed: 1))
}

pub fn aggregate_complete_fractal_loop_test() {
  // All four passes complete (unit, integration, e2e, review)
  // Review would be captured in unit/integration/e2e
  let unit = TestResults(passed: 20, failed: 1)
  let integration = TestResults(passed: 10, failed: 0)
  let e2e = TestResults(passed: 5, failed: 0)

  let aggregated = aggregate_test_results(unit, integration, e2e)

  aggregated |> should.equal(TestResults(passed: 35, failed: 1))

  // Verify truth score is high (should be 35/36 ≈ 0.972)
  let score = truth_score(aggregated)
  { score >. 0.95 } |> should.be_true
}

pub fn aggregate_preserves_individual_results_test() {
  // Aggregation shouldn't modify original results
  let unit = TestResults(passed: 5, failed: 1)
  let integration = TestResults(passed: 3, failed: 0)
  let e2e = TestResults(passed: 2, failed: 0)

  let _aggregated = aggregate_test_results(unit, integration, e2e)

  // Original results should be unchanged
  unit |> should.equal(TestResults(passed: 5, failed: 1))
  integration |> should.equal(TestResults(passed: 3, failed: 0))
  e2e |> should.equal(TestResults(passed: 2, failed: 0))
}

pub fn aggregate_large_test_suites_test() {
  // Handle large numbers
  let unit = TestResults(passed: 1000, failed: 50)
  let integration = TestResults(passed: 500, failed: 25)
  let e2e = TestResults(passed: 100, failed: 5)

  aggregate_test_results(unit, integration, e2e)
  |> should.equal(TestResults(passed: 1600, failed: 80))
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
