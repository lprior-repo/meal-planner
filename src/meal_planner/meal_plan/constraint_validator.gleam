/// Constraint validation logic for meal planning
///
/// This module provides validation functions for meal plan constraints
/// such as travel date consecutiveness and future date requirements.
import birl
import birl/duration
import gleam/list
import gleam/order

/// Validate that travel dates are consecutive (exactly 1 day apart)
///
/// Takes a list of birl.Time values and checks that:
/// 1. Each date is exactly 1 day after the previous date
/// 2. No gaps exist between dates
///
/// ## Examples
///
/// ```gleam
/// let assert Ok(date1) = birl.from_naive("2025-12-20 00:00:00")
/// let assert Ok(date2) = birl.from_naive("2025-12-21 00:00:00")
/// validate_travel_dates([date1, date2])
/// // -> Ok(Nil)
/// ```
///
/// ```gleam
/// let assert Ok(date1) = birl.from_naive("2025-12-20 00:00:00")
/// let assert Ok(date2) = birl.from_naive("2025-12-25 00:00:00")
/// validate_travel_dates([date1, date2])
/// // -> Error("Travel dates must be consecutive")
/// ```
pub fn validate_travel_dates(dates: List(birl.Time)) -> Result(Nil, String) {
  // Sort dates chronologically to ensure proper ordering
  let sorted_dates =
    dates
    |> list.sort(birl.compare)

  // Check if all consecutive pairs are exactly 1 day apart
  sorted_dates
  |> check_consecutive_pairs
}

/// Check that each pair of consecutive dates is exactly 1 day apart
///
/// Uses tail recursion with pattern matching to iterate through the list.
/// Returns Error as soon as a non-consecutive pair is found.
fn check_consecutive_pairs(dates: List(birl.Time)) -> Result(Nil, String) {
  case dates {
    // Empty list or single date is valid
    [] | [_] -> Ok(Nil)

    // At least two dates - check if first two are consecutive
    [first, second, ..rest] -> {
      let diff = birl.difference(second, first)
      let one_day = duration.days(1)

      case duration.compare(diff, one_day) {
        order.Eq -> {
          // Exactly 1 day apart - continue checking remaining pairs
          check_consecutive_pairs([second, ..rest])
        }
        _ -> {
          // Not exactly 1 day apart - return error
          Error("Travel dates must be consecutive")
        }
      }
    }
  }
}
