//// TDD Tests for Date Navigation (Capability 4)
//// Following BDD Red-Green-Refactor with fractal loop discipline

import gleam/int
import gleam/string
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Capability 4: Date Navigation
// ============================================================================

// Behavior: GIVEN dashboard WHEN user clicks previous THEN navigate to previous day
pub fn calculate_previous_date_test() {
  // Given current date
  let current = "2024-12-01"

  // When calculating previous date
  let previous = calculate_date_offset(current, -1)

  // Then should be previous day
  previous
  |> should.equal("2024-11-30")
}

// Behavior: GIVEN dashboard WHEN user clicks next THEN navigate to next day
pub fn calculate_next_date_test() {
  // Given current date
  let current = "2024-12-01"

  // When calculating next date
  let next = calculate_date_offset(current, 1)

  // Then should be next day
  next
  |> should.equal("2024-12-02")
}

// Edge case: month boundary backwards
pub fn previous_date_crosses_month_boundary_test() {
  // Given first day of month
  let current = "2024-12-01"

  // When calculating previous date
  let previous = calculate_date_offset(current, -1)

  // Then should be last day of previous month
  previous
  |> should.equal("2024-11-30")
}

// Edge case: month boundary forwards
pub fn next_date_crosses_month_boundary_test() {
  // Given last day of month
  let current = "2024-11-30"

  // When calculating next date
  let next = calculate_date_offset(current, 1)

  // Then should be first day of next month
  next
  |> should.equal("2024-12-01")
}

// Edge case: year boundary backwards
pub fn previous_date_crosses_year_boundary_test() {
  // Given first day of year
  let current = "2024-01-01"

  // When calculating previous date
  let previous = calculate_date_offset(current, -1)

  // Then should be last day of previous year
  previous
  |> should.equal("2023-12-31")
}

// Edge case: year boundary forwards
pub fn next_date_crosses_year_boundary_test() {
  // Given last day of year
  let current = "2024-12-31"

  // When calculating next date
  let next = calculate_date_offset(current, 1)

  // Then should be first day of next year
  next
  |> should.equal("2025-01-01")
}

// Leap year edge case
pub fn leap_year_feb_29_test() {
  // Given Feb 28 in leap year
  let current = "2024-02-28"

  // When calculating next date
  let next = calculate_date_offset(current, 1)

  // Then should be Feb 29 (2024 is a leap year)
  next
  |> should.equal("2024-02-29")

  // And next day after that
  let day_after = calculate_date_offset(next, 1)
  day_after
  |> should.equal("2024-03-01")
}

// Non-leap year Feb
pub fn non_leap_year_feb_test() {
  // Given Feb 28 in non-leap year
  let current = "2023-02-28"

  // When calculating next date
  let next = calculate_date_offset(current, 1)

  // Then should be March 1 (2023 is not a leap year)
  next
  |> should.equal("2023-03-01")
}

// ============================================================================
// Helper Functions (to be implemented in web.gleam or date_utils.gleam)
// ============================================================================

/// Calculate date with offset (positive = future, negative = past)
/// This is a simplified implementation for testing date logic
/// Production code should use a proper date library
fn calculate_date_offset(date_str: String, days: Int) -> String {
  // Parse date string "YYYY-MM-DD"
  let assert Ok(#(year, month, day)) = parse_date(date_str)

  // Add/subtract days
  let new_date = add_days_to_date(year, month, day, days)

  // Format back to string
  format_date(new_date.0, new_date.1, new_date.2)
}

/// Parse ISO date string
fn parse_date(date_str: String) -> Result(#(Int, Int, Int), Nil) {
  case string.split(date_str, "-") {
    [y, m, d] -> {
      case int.parse(y), int.parse(m), int.parse(d) {
        Ok(year), Ok(month), Ok(day) -> Ok(#(year, month, day))
        _, _, _ -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

/// Add days to a date (handles month/year boundaries)
fn add_days_to_date(
  year: Int,
  month: Int,
  day: Int,
  offset: Int,
) -> #(Int, Int, Int) {
  let new_day = day + offset
  let days_in_current = days_in_month(year, month)

  // Check if day is within current month
  case new_day >= 1 && new_day <= days_in_current {
    True -> #(year, month, new_day)
    False ->
      case new_day < 1 {
        // Need to go to previous month
        True -> {
          case month {
            1 -> {
              // Go to previous year
              let prev_year = year - 1
              let prev_month = 12
              let days_in_prev = days_in_month(prev_year, prev_month)
              add_days_to_date(prev_year, prev_month, days_in_prev, new_day)
            }
            _ -> {
              let prev_month = month - 1
              let days_in_prev = days_in_month(year, prev_month)
              add_days_to_date(year, prev_month, days_in_prev, new_day)
            }
          }
        }
        // Need to go to next month
        False -> {
          let overflow = new_day - days_in_current

          case month {
            12 -> add_days_to_date(year + 1, 1, 0, overflow)
            _ -> add_days_to_date(year, month + 1, 0, overflow)
          }
        }
      }
  }
}

/// Get number of days in a month
fn days_in_month(year: Int, month: Int) -> Int {
  case month {
    1 | 3 | 5 | 7 | 8 | 10 | 12 -> 31
    4 | 6 | 9 | 11 -> 30
    2 ->
      case is_leap_year(year) {
        True -> 29
        False -> 28
      }
    _ -> 30
    // fallback
  }
}

/// Check if year is a leap year
fn is_leap_year(year: Int) -> Bool {
  case year % 400 == 0 {
    True -> True
    False ->
      case year % 100 == 0 {
        True -> False
        False -> year % 4 == 0
      }
  }
}

/// Format date as ISO string
fn format_date(year: Int, month: Int, day: Int) -> String {
  int.to_string(year) <> "-" <> pad_zero(month) <> "-" <> pad_zero(day)
}

/// Pad single digit with zero
fn pad_zero(n: Int) -> String {
  case n < 10 {
    True -> "0" <> int.to_string(n)
    False -> int.to_string(n)
  }
}
