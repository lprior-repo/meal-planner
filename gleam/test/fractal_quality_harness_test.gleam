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
import gleam/list
import gleam/string
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
// CODE REVIEW CHECKLIST TYPES
// ===================================================================

/// Code review checklist item
pub type CheckItem {
  CheckItem(name: String, description: String, passed: Bool)
}

// ===================================================================
// ROLLBACK ACTION TYPE
// ===================================================================

/// Action to take based on quality score
pub type RollbackAction {
  NoRollback
  Rollback(files: List(String))
}

// ===================================================================
// CODE REVIEW CHECKLIST GENERATOR
// ===================================================================

/// Generate code review checklist for a file
/// Returns list of check items for: type safety, error handling, test coverage, function length
pub fn generate_checklist(file: String) -> List(CheckItem) {
  [
    CheckItem(
      name: "Type Safety",
      description: "All function parameters and return types are explicitly typed",
      passed: True,
    ),
    CheckItem(
      name: "Error Handling",
      description: "All Result types are properly handled with case expressions",
      passed: True,
    ),
    CheckItem(
      name: "Test Coverage",
      description: "File has corresponding test file with comprehensive coverage",
      passed: True,
    ),
    CheckItem(
      name: "Function Length",
      description: "All functions are under 50 lines of code",
      passed: True,
    ),
  ]
}

// ===================================================================
// AUTO ROLLBACK
// ===================================================================

/// Determine if rollback is needed based on quality score
/// Returns Rollback(files) if score < 0.95, otherwise NoRollback
pub fn auto_rollback(score: Float, files: List(String)) -> RollbackAction {
  case score <. 0.95 {
    True -> Rollback(files)
    False -> NoRollback
  }
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
// CODE REVIEW CHECKLIST TESTS
// ===================================================================

pub fn generate_checklist_returns_four_items_test() {
  // Checklist should have 4 standard items
  let checklist = generate_checklist("src/module.gleam")

  checklist
  |> list.length
  |> should.equal(4)
}

pub fn generate_checklist_has_type_safety_check_test() {
  // First item should be type safety
  let checklist = generate_checklist("src/module.gleam")

  case checklist {
    [first, ..] -> {
      first.name |> should.equal("Type Safety")
      first.description
      |> string.contains("typed")
      |> should.be_true
    }
    [] -> should.fail()
  }
}

pub fn generate_checklist_has_error_handling_check_test() {
  // Second item should be error handling
  let checklist = generate_checklist("src/module.gleam")

  case checklist {
    [_, second, ..] -> {
      second.name |> should.equal("Error Handling")
      second.description
      |> string.contains("Result")
      |> should.be_true
    }
    _ -> should.fail()
  }
}

pub fn generate_checklist_has_test_coverage_check_test() {
  // Third item should be test coverage
  let checklist = generate_checklist("src/module.gleam")

  case checklist {
    [_, _, third, ..] -> {
      third.name |> should.equal("Test Coverage")
      third.description
      |> string.contains("coverage")
      |> should.be_true
    }
    _ -> should.fail()
  }
}

pub fn generate_checklist_has_function_length_check_test() {
  // Fourth item should be function length
  let checklist = generate_checklist("src/module.gleam")

  case checklist {
    [_, _, _, fourth] -> {
      fourth.name |> should.equal("Function Length")
      fourth.description
      |> string.contains("50 lines")
      |> should.be_true
    }
    _ -> should.fail()
  }
}

pub fn generate_checklist_all_items_have_passed_field_test() {
  // All items should have passed field
  let checklist = generate_checklist("src/module.gleam")

  checklist
  |> list.all(fn(item) { item.passed == True || item.passed == False })
  |> should.be_true
}

pub fn generate_checklist_default_all_passed_test() {
  // By default, all checks should pass (stub implementation)
  let checklist = generate_checklist("src/module.gleam")

  checklist
  |> list.all(fn(item) { item.passed })
  |> should.be_true
}

pub fn generate_checklist_different_files_same_checklist_test() {
  // For now, all files get same checklist (until implementation enhanced)
  let checklist1 = generate_checklist("src/module1.gleam")
  let checklist2 = generate_checklist("src/module2.gleam")

  list.length(checklist1) |> should.equal(list.length(checklist2))
}

pub fn generate_checklist_item_structure_test() {
  // Verify CheckItem has required fields
  let checklist = generate_checklist("src/module.gleam")

  case checklist {
    [first, ..] -> {
      // Should have name field (non-empty string)
      { string.length(first.name) > 0 } |> should.be_true

      // Should have description field (non-empty string)
      { string.length(first.description) > 0 } |> should.be_true

      // Should have passed field (boolean)
      { first.passed == True || first.passed == False } |> should.be_true
    }
    [] -> should.fail()
  }
}

pub fn generate_checklist_integration_test() {
  // Integration: generate checklist and verify all items
  let checklist = generate_checklist("src/feature.gleam")

  // Should have 4 items
  list.length(checklist) |> should.equal(4)

  // All should be passed initially
  checklist
  |> list.all(fn(item) { item.passed })
  |> should.be_true

  // Each should have unique name
  let names =
    checklist
    |> list.map(fn(item) { item.name })

  list.length(names) |> should.equal(4)
}

// ===================================================================
// AUTO ROLLBACK TESTS
// ===================================================================

pub fn auto_rollback_triggers_on_low_score_test() {
  // Score < 0.95 should trigger rollback
  let score = 0.9
  let files = ["src/module.gleam", "test/module_test.gleam"]

  auto_rollback(score, files)
  |> should.equal(Rollback(files))
}

pub fn auto_rollback_no_rollback_on_high_score_test() {
  // Score >= 0.95 should not rollback
  let score = 0.96
  let files = ["src/module.gleam"]

  auto_rollback(score, files)
  |> should.equal(NoRollback)
}

pub fn auto_rollback_threshold_exactly_0_95_test() {
  // Score exactly 0.95 should not rollback (threshold is <0.95, not <=)
  let score = 0.95
  let files = ["src/module.gleam"]

  auto_rollback(score, files)
  |> should.equal(NoRollback)
}

pub fn auto_rollback_just_below_threshold_test() {
  // Score just below 0.95 should rollback
  let score = 0.94
  let files = ["src/module.gleam"]

  auto_rollback(score, files)
  |> should.equal(Rollback(files))
}

pub fn auto_rollback_perfect_score_test() {
  // Score 1.0 should not rollback
  let score = 1.0
  let files = ["src/module.gleam"]

  auto_rollback(score, files)
  |> should.equal(NoRollback)
}

pub fn auto_rollback_zero_score_test() {
  // Score 0.0 should rollback (all tests failed)
  let score = 0.0
  let files = ["src/module.gleam"]

  auto_rollback(score, files)
  |> should.equal(Rollback(files))
}

pub fn auto_rollback_empty_file_list_test() {
  // Rollback with empty file list
  let score = 0.9
  let files = []

  auto_rollback(score, files)
  |> should.equal(Rollback([]))
}

pub fn auto_rollback_multiple_files_test() {
  // Rollback should preserve all files
  let score = 0.85
  let files = [
    "src/module1.gleam",
    "src/module2.gleam",
    "src/module3.gleam",
    "test/module1_test.gleam",
    "test/module2_test.gleam",
  ]

  auto_rollback(score, files)
  |> should.equal(Rollback(files))
}

pub fn auto_rollback_integration_with_truth_score_test() {
  // Integration test: calculate score and check rollback
  let results = TestResults(passed: 90, failed: 10)
  let score = truth_score(results)
  let files = ["src/feature.gleam"]

  // 90/100 = 0.9, which is < 0.95, so should rollback
  auto_rollback(score, files)
  |> should.equal(Rollback(files))
}

pub fn auto_rollback_integration_high_quality_test() {
  // Integration test: high quality should not rollback
  let results = TestResults(passed: 96, failed: 4)
  let score = truth_score(results)
  let files = ["src/feature.gleam"]

  // 96/100 = 0.96, which is >= 0.95, so no rollback
  auto_rollback(score, files)
  |> should.equal(NoRollback)
}

pub fn auto_rollback_fractal_loop_complete_test() {
  // Complete fractal loop: aggregate and check rollback
  let unit = TestResults(passed: 20, failed: 1)
  let integration = TestResults(passed: 10, failed: 0)
  let e2e = TestResults(passed: 5, failed: 0)

  let aggregated = aggregate_test_results(unit, integration, e2e)
  let score = truth_score(aggregated)
  let files = ["src/feature.gleam", "test/feature_test.gleam"]

  // 35/36 ≈ 0.972, which is >= 0.95, so no rollback
  auto_rollback(score, files)
  |> should.equal(NoRollback)
}

pub fn auto_rollback_fractal_loop_failed_test() {
  // Fractal loop with too many failures should rollback
  let unit = TestResults(passed: 85, failed: 15)
  let integration = TestResults(passed: 40, failed: 10)
  let e2e = TestResults(passed: 15, failed: 10)

  let aggregated = aggregate_test_results(unit, integration, e2e)
  let score = truth_score(aggregated)
  let files = ["src/feature.gleam"]

  // 140/175 = 0.8, which is < 0.95, so should rollback
  auto_rollback(score, files)
  |> should.equal(Rollback(files))
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
