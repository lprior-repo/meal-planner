/// Constraint validation functions for meal planning
///
/// Provides validation for user-supplied constraints like travel dates,
/// locked meals, macro adjustments, and recipe IDs.

import gleam/int
import gleam/list
import gleam/result
import gleam/string
import meal_planner/types

// ============================================================================
// Type Definitions
// ============================================================================

pub type MealType {
  Breakfast
  Lunch
  Dinner
  Snack
}

pub type DayOfWeek {
  Monday
  Tuesday
  Wednesday
  Thursday
  Friday
  Saturday
  Sunday
}

pub type MacroAdjustment {
  HighProtein
  LowCarb
  Balanced
}

pub type LockedMeal {
  LockedMeal(day: DayOfWeek, meal_type: MealType, recipe_id: Int)
}

pub type Constraints {
  Constraints(
    week_of: String,
    travel_dates: List(String),
    locked_meals: List(LockedMeal),
    macro_adjustment: MacroAdjustment,
    meal_skips: List(String),
    preferences: List(String),
  )
}

// ============================================================================
// Validation Functions
// ============================================================================

/// Validate a date string in ISO 8601 format (YYYY-MM-DD)
pub fn validate_date(date_string: String) -> Result(String, String) {
  use parts <- result.try(case string.split(date_string, "-") {
    [y, m, d] -> Ok(#(y, m, d))
    _ -> Error("Invalid date format: expected YYYY-MM-DD")
  })

  let #(year_str, month_str, day_str) = parts
  use year <- result.try(parse_int(year_str, "Invalid year"))
  use month <- result.try(parse_int(month_str, "Invalid month"))
  use day <- result.try(parse_int(day_str, "Invalid day"))

  case month >= 1 && month <= 12 && day >= 1 {
    False -> Error("Invalid date: month must be 1-12, day must be > 0")
    True -> {
      let max_day = max_day_in_month(month, year)
      case day <= max_day {
        True -> Ok(date_string)
        False ->
          Error(
            "Invalid date: day must be 1-"
            <> int.to_string(max_day)
            <> " for month "
            <> int.to_string(month),
          )
      }
    }
  }
}

/// Get the maximum day in a given month (accounting for leap years)
fn max_day_in_month(month: Int, year: Int) -> Int {
  case month {
    1 | 3 | 5 | 7 | 8 | 10 | 12 -> 31
    4 | 6 | 9 | 11 -> 30
    2 -> case is_leap_year(year) {
      True -> 29
      False -> 28
    }
    _ -> 31
  }
}

/// Check if a year is a leap year
fn is_leap_year(year: Int) -> Bool {
  case year % 400 {
    0 -> True
    _ ->
      case year % 100 {
        0 -> False
        _ -> year % 4 == 0
      }
  }
}

/// Validate that a recipe ID is positive (> 0)
pub fn validate_recipe_id_positive(recipe_id: Int) -> Result(Int, String) {
  case recipe_id > 0 {
    True -> Ok(recipe_id)
    False -> Error("Recipe ID must be positive (> 0)")
  }
}

/// Validate that travel dates are consecutive
pub fn validate_travel_dates(dates: List(String)) -> Result(List(String), String) {
  case dates {
    [] -> Ok([])
    [single] -> {
      // Single date must be valid
      use _ <- result.try(validate_date(single))
      Ok(dates)
    }
    _ -> {
      // Multiple dates: validate all are valid format, then check consecutiveness
      let all_valid = list.all(dates, fn(d) {
        case validate_date(d) {
          Ok(_) -> True
          Error(_) -> False
        }
      })
      case all_valid {
        False -> Error("Invalid travel dates: some dates have invalid format")
        True -> {
          // Check if dates are consecutive
          let sorted_dates = list.sort(dates, string.compare)
          case are_dates_consecutive(sorted_dates) {
            True -> Ok(dates)
            False ->
              Error("Invalid travel dates: dates must be consecutive")
          }
        }
      }
    }
  }
}

/// Check if a list of date strings in ISO format are consecutive
fn are_dates_consecutive(dates: List(String)) -> Bool {
  case dates {
    [] -> True
    [_] -> True
    [first, second, ..rest] -> {
      case is_next_day(first, second) {
        False -> False
        True -> are_dates_consecutive([second, ..rest])
      }
    }
  }
}

/// Check if second date is exactly one day after first date
fn is_next_day(date1: String, date2: String) -> Bool {
  // Parse both dates into components
  case date_to_day_number(date1), date_to_day_number(date2) {
    Ok(day1), Ok(day2) -> day2 == day1 + 1
    _, _ -> False
  }
}

/// Convert ISO 8601 date string to a simple day number for comparison
/// Uses a simple epoch calculation for dates (simplified, works for recent years)
fn date_to_day_number(date_string: String) -> Result(Int, String) {
  case string.split(date_string, "-") {
    [year_str, month_str, day_str] -> {
      use year <- result.try(parse_int(year_str, "Invalid year"))
      use month <- result.try(parse_int(month_str, "Invalid month"))
      use day <- result.try(parse_int(day_str, "Invalid day"))

      // Simple calculation: days since year 2000
      let years_diff = year - 2000
      let days_in_years = years_diff * 365
      let leap_days = years_diff / 4
      let days_in_months = month_days_total(month)
      let total_days = days_in_years + leap_days + days_in_months + day
      Ok(total_days)
    }
    _ -> Error("Invalid date format")
  }
}

/// Get total days from January 1st to start of given month (non-leap year)
fn month_days_total(month: Int) -> Int {
  case month {
    1 -> 0
    2 -> 31
    3 -> 59
    4 -> 90
    5 -> 120
    6 -> 151
    7 -> 181
    8 -> 212
    9 -> 243
    10 -> 273
    11 -> 304
    12 -> 334
    _ -> 0
  }
}

// ============================================================================
// String Parsing Functions
// ============================================================================

/// Parse MealType from string
pub fn meal_type_from_string(s: String) -> Result(MealType, String) {
  case string.lowercase(s) {
    "breakfast" -> Ok(Breakfast)
    "lunch" -> Ok(Lunch)
    "dinner" -> Ok(Dinner)
    "snack" -> Ok(Snack)
    _ -> Error("Invalid meal type: " <> s)
  }
}

/// Parse DayOfWeek from string
pub fn day_of_week_from_string(s: String) -> Result(DayOfWeek, String) {
  case s {
    "Monday" -> Ok(Monday)
    "Tuesday" -> Ok(Tuesday)
    "Wednesday" -> Ok(Wednesday)
    "Thursday" -> Ok(Thursday)
    "Friday" -> Ok(Friday)
    "Saturday" -> Ok(Saturday)
    "Sunday" -> Ok(Sunday)
    _ -> Error("Invalid day of week: " <> s)
  }
}

/// Parse MacroAdjustment from string
pub fn macro_adjustment_from_string(s: String) -> Result(MacroAdjustment, String) {
  case s {
    "high_protein" -> Ok(HighProtein)
    "low_carb" -> Ok(LowCarb)
    "balanced" -> Ok(Balanced)
    _ -> Error("Invalid macro adjustment: " <> s)
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

fn parse_int(s: String, error_msg: String) -> Result(Int, String) {
  case string.trim(s) {
    "" -> Error(error_msg)
    trimmed ->
      case int.parse(trimmed) {
        Ok(n) -> Ok(n)
        Error(_) -> Error(error_msg)
      }
  }
}
