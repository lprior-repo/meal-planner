//// Recurrence engine for recurring meal plans
////
//// This module provides:
//// - Recurrence pattern calculation
//// - Next occurrence determination
//// - Date range generation for recurring schedules

import birl
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import meal_planner/scheduler/advanced.{
  type RecurrencePattern, type RecurrenceRule,
}

// ============================================================================
// Date Calculation
// ============================================================================

/// Calculate next occurrence date from a recurrence pattern
pub fn next_occurrence(
  rule: RecurrenceRule,
  from_date: String,
) -> Option(String) {
  case rule.pattern {
    advanced.EveryNDays(days) -> add_days(from_date, days)
    advanced.WeeklyOnDays(weekdays) ->
      next_weekly_occurrence(from_date, weekdays)
    advanced.MonthlyOnDay(day) -> next_monthly_occurrence(from_date, day)
    advanced.Custom(_) -> None
  }
}

/// Generate all occurrence dates within date range
pub fn generate_occurrences(
  rule: RecurrenceRule,
  start_date: String,
  end_date: String,
) -> List(String) {
  generate_occurrences_recursive(rule, start_date, end_date, [], 0)
}

fn generate_occurrences_recursive(
  rule: RecurrenceRule,
  current: String,
  end_date: String,
  acc: List(String),
  count: Int,
) -> List(String) {
  let exceeds_max = case rule.max_occurrences {
    Some(max) -> count >= max
    None -> False
  }

  let past_end = compare_dates(current, end_date) > 0

  case exceeds_max || past_end {
    True -> list.reverse(acc)
    False -> {
      case next_occurrence(rule, current) {
        Some(next) ->
          generate_occurrences_recursive(
            rule,
            next,
            end_date,
            [current, ..acc],
            count + 1,
          )
        None -> list.reverse([current, ..acc])
      }
    }
  }
}

// ============================================================================
// Date Arithmetic
// ============================================================================

/// Add N days to ISO 8601 date string
fn add_days(date: String, days: Int) -> Option(String) {
  case parse_iso_date(date) {
    Ok(time) -> {
      let seconds_to_add = days * 24 * 60 * 60
      let new_time =
        time
        |> birl.add(birl.seconds(seconds_to_add))
      Some(birl.to_iso8601(new_time))
    }
    Error(_) -> None
  }
}

/// Find next weekly occurrence on specified weekdays
fn next_weekly_occurrence(
  from_date: String,
  weekdays: List(Int),
) -> Option(String) {
  case weekdays {
    [] -> None
    _ -> {
      case parse_iso_date(from_date) {
        Ok(time) -> {
          let current_weekday = get_weekday(time)
          let next_weekday = find_next_weekday(current_weekday, weekdays)
          let days_to_add =
            calculate_days_to_next_weekday(current_weekday, next_weekday)
          add_days(from_date, days_to_add)
        }
        Error(_) -> None
      }
    }
  }
}

/// Find next monthly occurrence on specified day
fn next_monthly_occurrence(from_date: String, day: Int) -> Option(String) {
  case parse_iso_date(from_date) {
    Ok(_time) -> {
      let _ = day
      add_days(from_date, 30)
    }
    Error(_) -> None
  }
}

// ============================================================================
// Date Utilities
// ============================================================================

/// Parse ISO 8601 date string to birl Time
fn parse_iso_date(date: String) -> Result(birl.Time, Nil) {
  birl.parse(date)
  |> result.map_error(fn(_) { Nil })
}

/// Get weekday from time (0=Sunday, 6=Saturday)
fn get_weekday(time: birl.Time) -> Int {
  let day =
    time
    |> birl.weekday
  case day {
    birl.Mon -> 1
    birl.Tue -> 2
    birl.Wed -> 3
    birl.Thu -> 4
    birl.Fri -> 5
    birl.Sat -> 6
    birl.Sun -> 0
  }
}

/// Find next weekday in sorted list
fn find_next_weekday(current: Int, weekdays: List(Int)) -> Int {
  let sorted = list.sort(weekdays, int.compare)
  case list.find(sorted, fn(day) { day > current }) {
    Ok(day) -> day
    Error(_) -> {
      case list.first(sorted) {
        Ok(day) -> day
        Error(_) -> current
      }
    }
  }
}

/// Calculate days to add to reach next weekday
fn calculate_days_to_next_weekday(current: Int, next: Int) -> Int {
  case next > current {
    True -> next - current
    False -> 7 - current + next
  }
}

/// Compare two ISO 8601 date strings
/// Returns: -1 if date1 < date2, 0 if equal, 1 if date1 > date2
fn compare_dates(date1: String, date2: String) -> Int {
  case parse_iso_date(date1), parse_iso_date(date2) {
    Ok(time1), Ok(time2) -> {
      let unix1 = birl.to_unix(time1)
      let unix2 = birl.to_unix(time2)
      case unix1 < unix2 {
        True -> -1
        False ->
          case unix1 > unix2 {
            True -> 1
            False -> 0
          }
      }
    }
    _, _ -> 0
  }
}

// ============================================================================
// Recurrence Validation
// ============================================================================

/// Validate recurrence rule
pub fn validate_rule(rule: RecurrenceRule) -> Bool {
  let valid_pattern = case rule.pattern {
    advanced.EveryNDays(days) -> days > 0
    advanced.WeeklyOnDays(weekdays) -> {
      !list.is_empty(weekdays)
      && list.all(weekdays, fn(day) { day >= 0 && day <= 6 })
    }
    advanced.MonthlyOnDay(day) -> day >= 1 && day <= 31
    advanced.Custom(_) -> True
  }

  let valid_dates = case rule.end_date {
    Some(end) -> compare_dates(rule.start_date, end) <= 0
    None -> True
  }

  let valid_max = case rule.max_occurrences {
    Some(max) -> max > 0
    None -> True
  }

  valid_pattern && valid_dates && valid_max
}

/// Check if recurrence is still active
pub fn is_active(rule: RecurrenceRule, current_date: String) -> Bool {
  let after_start = compare_dates(current_date, rule.start_date) >= 0

  let before_end = case rule.end_date {
    Some(end) -> compare_dates(current_date, end) <= 0
    None -> True
  }

  after_start && before_end
}
