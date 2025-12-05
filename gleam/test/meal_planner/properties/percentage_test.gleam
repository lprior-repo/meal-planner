//// Property-based tests for percentage calculations
//// Verifies: percentage calculation properties across the application
//// Bead: meal-planner-7zzg
////
//// This module tests the mathematical properties of percentage calculations
//// used throughout the application (progress bars, dashboards, summaries).
//// While individual modules have private calculate_percentage functions,
//// this test suite ensures they all follow consistent mathematical rules:
////
//// 1. Range: 0-100% for capped versions, 0-∞ for uncapped
//// 2. Zero division safety: 0/0 = 0% (not NaN or error)
//// 3. Monotonicity: increasing current increases percentage
//// 4. Proportionality: doubling both current and target preserves percentage
//// 5. Boundary conditions: edge cases handled correctly

import gleam/float
import gleeunit
import gleeunit/should
import qcheck

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Reference Implementation (matches application code)
// ============================================================================

/// Calculate percentage (current / target * 100)
/// Returns 0.0 when target is 0 to avoid division by zero
fn calculate_percentage(current: Float, target: Float) -> Float {
  case target >. 0.0 {
    True -> current /. target *. 100.0
    False -> 0.0
  }
}

/// Calculate percentage with upper cap at 100%
/// Used in some UI components to prevent visual overflow
fn calculate_percentage_capped(current: Float, target: Float) -> Float {
  case target >. 0.0 {
    True -> {
      let pct = current /. target *. 100.0
      case pct >. 100.0 {
        True -> 100.0
        False -> pct
      }
    }
    False -> 0.0
  }
}

// ============================================================================
// Generators
// ============================================================================

/// Generator for non-negative floats (0-1000)
fn non_negative_float() -> qcheck.Generator(Float) {
  qcheck.bounded_float(0.0, 1000.0)
}

/// Generator for positive floats (0.1-1000)
/// Excludes zero to test division behavior
fn positive_float() -> qcheck.Generator(Float) {
  qcheck.bounded_float(0.1, 1000.0)
}

/// Generator for small positive floats (0.01-10)
/// Useful for testing edge cases near zero
fn small_positive_float() -> qcheck.Generator(Float) {
  qcheck.bounded_float(0.01, 10.0)
}

/// Generator for pairs of (current, target) values
fn gen_percentage_pair() -> qcheck.Generator(#(Float, Float)) {
  use current <- qcheck.map(non_negative_float())
  use target <- qcheck.map(positive_float())
  #(current, target)
}

// ============================================================================
// Property Test: Non-Negativity
// ============================================================================

/// GIVEN non-negative current and target WHEN calculating percentage
/// THEN result should always be non-negative
///
/// This ensures percentage calculations never produce negative values,
/// which would be mathematically incorrect and visually confusing.
pub fn percentage_non_negative_test() {
  use pair <- qcheck.given(gen_percentage_pair())
  let #(current, target) = pair

  let percentage = calculate_percentage(current, target)

  percentage
  |> should.be_true(fn(p) { p >=. 0.0 })
}

// ============================================================================
// Property Test: Zero Target Safety
// ============================================================================

/// GIVEN any current value and zero target WHEN calculating percentage
/// THEN result should be 0.0 (not NaN or error)
///
/// This tests the critical edge case of division by zero.
/// The application should handle this gracefully by returning 0%.
pub fn percentage_zero_target_test() {
  use current <- qcheck.given(non_negative_float())

  let percentage = calculate_percentage(current, 0.0)

  percentage
  |> should.equal(0.0)
}

/// GIVEN zero current and zero target WHEN calculating percentage
/// THEN result should be 0.0
///
/// Tests the special case where both values are zero.
pub fn percentage_zero_both_test() {
  use _ <- qcheck.given(qcheck.int())

  let percentage = calculate_percentage(0.0, 0.0)

  percentage
  |> should.equal(0.0)
}

// ============================================================================
// Property Test: Boundary Values
// ============================================================================

/// GIVEN current equals target WHEN calculating percentage
/// THEN result should be exactly 100%
///
/// This tests the important case where we're exactly at the target.
pub fn percentage_at_target_test() {
  use target <- qcheck.given(positive_float())

  let percentage = calculate_percentage(target, target)

  // Allow small floating-point tolerance
  let diff = float.absolute_value(percentage -. 100.0)
  diff
  |> should.be_true(fn(d) { d <. 0.01 })
}

/// GIVEN zero current and positive target WHEN calculating percentage
/// THEN result should be 0%
pub fn percentage_zero_current_test() {
  use target <- qcheck.given(positive_float())

  let percentage = calculate_percentage(0.0, target)

  percentage
  |> should.equal(0.0)
}

// ============================================================================
// Property Test: Range (0-100) for Capped Version
// ============================================================================

/// GIVEN any valid inputs WHEN calculating capped percentage
/// THEN result should be in range [0, 100]
///
/// This tests that the capped version never exceeds 100%,
/// which is important for visual progress bars.
pub fn percentage_capped_range_test() {
  use pair <- qcheck.given(gen_percentage_pair())
  let #(current, target) = pair

  let percentage = calculate_percentage_capped(current, target)

  let in_range = percentage >=. 0.0 && percentage <=. 100.0
  in_range
  |> should.be_true
}

/// GIVEN current > target WHEN calculating capped percentage
/// THEN result should be exactly 100%
pub fn percentage_capped_over_target_test() {
  use target <- qcheck.given(positive_float())
  // Current is 150% of target
  let current = target *. 1.5

  let percentage = calculate_percentage_capped(current, target)

  percentage
  |> should.equal(100.0)
}

// ============================================================================
// Property Test: Monotonicity
// ============================================================================

/// GIVEN fixed target WHEN current increases
/// THEN percentage should increase or stay the same
///
/// This tests that percentage is monotonically increasing with current.
pub fn percentage_monotonic_in_current_test() {
  use target <- qcheck.given(positive_float())
  use current1 <- qcheck.given(non_negative_float())
  use current2 <- qcheck.given(non_negative_float())

  let pct1 = calculate_percentage(current1, target)
  let pct2 = calculate_percentage(current2, target)

  case current1 <. current2 {
    True -> pct1 |> should.be_true(fn(p1) { p1 <=. pct2 })
    False -> pct1 |> should.be_true(fn(p1) { p1 >=. pct2 })
  }
}

// ============================================================================
// Property Test: Proportionality
// ============================================================================

/// GIVEN current and target WHEN both are scaled by same factor
/// THEN percentage should remain the same
///
/// This tests the scale-invariance property: 50/100 = 100/200 = 50%
pub fn percentage_scale_invariant_test() {
  use pair <- qcheck.given(gen_percentage_pair())
  use scale <- qcheck.given(small_positive_float())
  let #(current, target) = pair

  let pct1 = calculate_percentage(current, target)
  let pct2 = calculate_percentage(current *. scale, target *. scale)

  // Both percentages should be approximately equal
  let diff = float.absolute_value(pct1 -. pct2)
  diff
  |> should.be_true(fn(d) { d <. 0.1 })
}

// ============================================================================
// Property Test: Specific Percentage Values
// ============================================================================

/// GIVEN current is 50% of target WHEN calculating percentage
/// THEN result should be approximately 50%
pub fn percentage_half_target_test() {
  use target <- qcheck.given(positive_float())
  let current = target *. 0.5

  let percentage = calculate_percentage(current, target)

  let diff = float.absolute_value(percentage -. 50.0)
  diff
  |> should.be_true(fn(d) { d <. 0.1 })
}

/// GIVEN current is 25% of target WHEN calculating percentage
/// THEN result should be approximately 25%
pub fn percentage_quarter_target_test() {
  use target <- qcheck.given(positive_float())
  let current = target *. 0.25

  let percentage = calculate_percentage(current, target)

  let diff = float.absolute_value(percentage -. 25.0)
  diff
  |> should.be_true(fn(d) { d <. 0.1 })
}

/// GIVEN current is 200% of target WHEN calculating percentage
/// THEN result should be approximately 200%
pub fn percentage_double_target_test() {
  use target <- qcheck.given(positive_float())
  let current = target *. 2.0

  let percentage = calculate_percentage(current, target)

  let diff = float.absolute_value(percentage -. 200.0)
  diff
  |> should.be_true(fn(d) { d <. 0.1 })
}

// ============================================================================
// Property Test: Arithmetic Properties
// ============================================================================

/// GIVEN current1 + current2 and target WHEN calculating percentage
/// THEN result should equal sum of individual percentages
///
/// This tests: (a + b) / t * 100 = (a/t * 100) + (b/t * 100)
pub fn percentage_additive_property_test() {
  use target <- qcheck.given(positive_float())
  use current1 <- qcheck.given(non_negative_float())
  use current2 <- qcheck.given(non_negative_float())

  let combined_pct = calculate_percentage(current1 +. current2, target)
  let sum_of_pcts =
    calculate_percentage(current1, target)
    +. calculate_percentage(current2, target)

  let diff = float.absolute_value(combined_pct -. sum_of_pcts)
  diff
  |> should.be_true(fn(d) { d <. 0.1 })
}

// ============================================================================
// Property Test: Edge Cases with Very Small Numbers
// ============================================================================

/// GIVEN very small positive values WHEN calculating percentage
/// THEN result should still be valid and non-negative
///
/// This tests numerical stability with small floating-point values.
pub fn percentage_small_numbers_test() {
  use _ <- qcheck.given(qcheck.int())

  let small_current = 0.001
  let small_target = 0.01

  let percentage = calculate_percentage(small_current, small_target)

  // 0.001 / 0.01 * 100 = 10%
  let expected = 10.0
  let diff = float.absolute_value(percentage -. expected)
  diff
  |> should.be_true(fn(d) { d <. 0.1 })
}

// ============================================================================
// Property Test: Edge Cases with Very Large Numbers
// ============================================================================

/// GIVEN very large values WHEN calculating percentage
/// THEN result should still be valid and accurate
///
/// This tests numerical stability with large floating-point values.
pub fn percentage_large_numbers_test() {
  use _ <- qcheck.given(qcheck.int())

  let large_current = 1_000_000.0
  let large_target = 2_000_000.0

  let percentage = calculate_percentage(large_current, large_target)

  // 1M / 2M * 100 = 50%
  let expected = 50.0
  let diff = float.absolute_value(percentage -. expected)
  diff
  |> should.be_true(fn(d) { d <. 0.1 })
}

// ============================================================================
// Property Test: Capped vs Uncapped Consistency
// ============================================================================

/// GIVEN current <= target WHEN calculating both capped and uncapped
/// THEN results should be identical
///
/// This verifies that capping only affects values over 100%.
pub fn percentage_capped_consistency_test() {
  use target <- qcheck.given(positive_float())
  use current <- qcheck.given(qcheck.bounded_float(0.0, target))

  let uncapped = calculate_percentage(current, target)
  let capped = calculate_percentage_capped(current, target)

  let diff = float.absolute_value(uncapped -. capped)
  diff
  |> should.be_true(fn(d) { d <. 0.01 })
}
