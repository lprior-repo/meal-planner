/// Tests for constraint validation logic
///
/// GREEN PHASE: Test now uses the real implementation from constraint_validator module.
import birl
import gleeunit
import gleeunit/should
import meal_planner/meal_plan/constraint_validator

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Constraint Validation Tests - RED PHASE
// ============================================================================

/// Test that constraint validation rejects non-consecutive travel dates
///
/// Requirement: Travel dates must be consecutive and in future.
/// This test validates that:
/// 1. Travel dates like ["2020-01-01", "2025-12-22"] should be rejected
/// 2. Reason: "2020-01-01" is in the past AND not consecutive with "2025-12-22"
///
/// Expected: Error("Travel dates must be consecutive")
///
/// NOTE: This test will FAIL in RED phase because validate_travel_dates()
/// returns Ok(Nil) instead of checking for consecutive dates.
pub fn constraint_validation_rejects_invalid_travel_dates_test() {
  // Test data: Non-consecutive travel dates
  // - "2020-01-01" is in the past and 5 years before "2025-12-22"
  // - These dates are NOT consecutive
  let assert Ok(date1) = birl.from_naive("2020-01-01 00:00:00")
  let assert Ok(date2) = birl.from_naive("2025-12-22 00:00:00")
  let invalid_dates = [date1, date2]

  // Call validation function from constraint_validator module
  let result = constraint_validator.validate_travel_dates(invalid_dates)

  // Assert: Should return Error with message about consecutive dates
  result
  |> should.be_error()

  // Verify exact error message
  let assert Error(error_msg) = result
  error_msg
  |> should.equal("Travel dates must be consecutive")
}
// ============================================================================
// GREEN PHASE: Helper function removed
// ============================================================================
//
// The validate_travel_dates function is now implemented in
// src/meal_planner/meal_plan/constraint_validator.gleam
// and imported at the top of this file.
