import birl
import gleam/json
import gleam/list
import gleeunit
import gleeunit/should
import meal_planner/meal_plan/constraints.{type Constraint, Constraint}
import meal_planner/meal_plan/constraints_decoder
import simplifile

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Constraint Validation Tests
// ============================================================================

/// Test that constraint validation rejects non-consecutive travel dates
///
/// Requirement: Travel dates must be consecutive and in future.
/// This test creates a constraint with travel dates that are NOT consecutive:
/// - 2020-01-01 (past date, not consecutive with 2025-12-22)
/// - 2025-12-22 (week start date)
///
/// Expected: Validation should return Error("Travel dates must be consecutive")
pub fn constraint_validation_rejects_invalid_travel_dates_test() {
  // Load base fixture
  let assert Ok(fixture_content) =
    simplifile.read(from: "test/fixtures/meal_plan/constraint_full.json")

  // Parse the JSON
  let assert Ok(fixture_json) =
    json.decode(from: fixture_content, using: json.dynamic)

  // Decode to Constraint type
  let assert Ok(constraint) =
    constraints_decoder.decode_constraint(fixture_json)

  // Test data: Non-consecutive travel dates
  // - "2020-01-01" is in the past and NOT consecutive with "2025-12-22"
  let invalid_dates = [
    birl.from_naive("2020-01-01 00:00:00"),
    birl.from_naive("2025-12-22 00:00:00"),
  ]

  // Create constraint with invalid travel dates
  let invalid_constraint =
    Constraint(
      week_of: constraint.week_of,
      travel_dates: invalid_dates,
      locked_meals: constraint.locked_meals,
      macro_adjustment: constraint.macro_adjustment,
      preferences: constraint.preferences,
      meal_skips: constraint.meal_skips,
    )

  // Validate constraint (this function doesn't exist yet - will be implemented in GREEN phase)
  let result = validate_travel_dates(invalid_constraint)

  // This should fail with an error message about consecutive dates
  result
  |> should.be_error()

  // Verify error message contains "consecutive"
  let assert Error(error_msg) = result
  error_msg
  |> should.equal("Travel dates must be consecutive")
}

// ============================================================================
// Helper Functions (Placeholders - will be implemented in GREEN phase)
// ============================================================================

/// Validate that travel dates are consecutive
///
/// This is a placeholder function that will be implemented in the GREEN phase.
/// For RED phase, it always returns Ok to make the test fail.
fn validate_travel_dates(constraint: Constraint) -> Result(Nil, String) {
  // RED phase: Always return Ok to make test fail
  Ok(Nil)
}
