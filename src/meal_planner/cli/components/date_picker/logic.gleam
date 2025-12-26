/// Date Picker Logic - Date Calculations and Validation
///
/// Contains helper functions for date manipulation, validation, and formatting.
import birl
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/cli/components/date_picker/model.{
  type DateFormat, type DatePickerModel, DatePickerModel, EuFormat, IsoFormat,
  LongFormat, UsFormat,
}

// ============================================================================
// Date Validation
// ============================================================================

/// Check if date is within valid range
pub fn is_date_valid(
  date_int: Int,
  min_date: Option(Int),
  max_date: Option(Int),
) -> Bool {
  let min_ok = case min_date {
    Some(min) -> date_int >= min
    None -> True
  }
  let max_ok = case max_date {
    Some(max) -> date_int <= max
    None -> True
  }
  min_ok && max_ok
}

// ============================================================================
// Date Conversion
// ============================================================================

/// Get today's date as days since epoch
pub fn get_today_date_int() -> Int {
  let now = birl.now()
  let today_seconds = birl.to_unix(now)
  today_seconds / 86_400
}

/// Convert date_int to year, month, day
pub fn date_int_to_ymd(date_int: Int) -> #(Int, Int, Int) {
  let seconds = date_int * 86_400
  let date = birl.from_unix(seconds)
  let iso = birl.to_iso8601(date)
  // Parse YYYY-MM-DD from ISO string
  let parts = string.slice(iso, 0, 10) |> string.split("-")
  case parts {
    [y_str, m_str, d_str] -> {
      let year = result.unwrap(int.parse(y_str), 2000)
      let month = result.unwrap(int.parse(m_str), 1)
      let day = result.unwrap(int.parse(d_str), 1)
      #(year, month, day)
    }
    _ -> #(2000, 1, 1)
  }
}

/// Convert year, month, day to date_int
pub fn ymd_to_date_int(year: Int, month: Int, day: Int) -> Result(Int, String) {
  let date_str =
    string.pad_start(int.to_string(year), 4, "0")
    <> "-"
    <> string.pad_start(int.to_string(month), 2, "0")
    <> "-"
    <> string.pad_start(int.to_string(day), 2, "0")
    <> "T00:00:00"

  case birl.from_naive(date_str) {
    Ok(dt) -> {
      let seconds = birl.to_unix(dt)
      Ok(seconds / 86_400)
    }
    Error(_) -> Error("Invalid date")
  }
}

// ============================================================================
// Date Formatting
// ============================================================================

/// Convert date_int to display string
pub fn date_int_to_string(date_int: Int, format: DateFormat) -> String {
  let #(year, month, day) = date_int_to_ymd(date_int)
  case format {
    IsoFormat ->
      string.pad_start(int.to_string(year), 4, "0")
      <> "-"
      <> string.pad_start(int.to_string(month), 2, "0")
      <> "-"
      <> string.pad_start(int.to_string(day), 2, "0")
    UsFormat ->
      string.pad_start(int.to_string(month), 2, "0")
      <> "/"
      <> string.pad_start(int.to_string(day), 2, "0")
      <> "/"
      <> int.to_string(year)
    EuFormat ->
      string.pad_start(int.to_string(day), 2, "0")
      <> "/"
      <> string.pad_start(int.to_string(month), 2, "0")
      <> "/"
      <> int.to_string(year)
    LongFormat ->
      month_name(month)
      <> " "
      <> int.to_string(day)
      <> ", "
      <> int.to_string(year)
  }
}

/// Parse date input string
pub fn parse_date_input(
  input: String,
  format: DateFormat,
) -> Result(Int, String) {
  case format {
    IsoFormat -> {
      case string.split(input, "-") {
        [y, m, d] -> {
          case int.parse(y), int.parse(m), int.parse(d) {
            Ok(year), Ok(month), Ok(day) -> ymd_to_date_int(year, month, day)
            _, _, _ -> Error("Invalid date format (YYYY-MM-DD)")
          }
        }
        _ -> Error("Invalid date format (YYYY-MM-DD)")
      }
    }
    UsFormat -> {
      case string.split(input, "/") {
        [m, d, y] -> {
          case int.parse(m), int.parse(d), int.parse(y) {
            Ok(month), Ok(day), Ok(year) -> ymd_to_date_int(year, month, day)
            _, _, _ -> Error("Invalid date format (MM/DD/YYYY)")
          }
        }
        _ -> Error("Invalid date format (MM/DD/YYYY)")
      }
    }
    EuFormat -> {
      case string.split(input, "/") {
        [d, m, y] -> {
          case int.parse(d), int.parse(m), int.parse(y) {
            Ok(day), Ok(month), Ok(year) -> ymd_to_date_int(year, month, day)
            _, _, _ -> Error("Invalid date format (DD/MM/YYYY)")
          }
        }
        _ -> Error("Invalid date format (DD/MM/YYYY)")
      }
    }
    LongFormat -> Error("Long format input not supported")
  }
}

// ============================================================================
// Calendar Calculations
// ============================================================================

/// Get month name
pub fn month_name(month: Int) -> String {
  case month {
    1 -> "January"
    2 -> "February"
    3 -> "March"
    4 -> "April"
    5 -> "May"
    6 -> "June"
    7 -> "July"
    8 -> "August"
    9 -> "September"
    10 -> "October"
    11 -> "November"
    12 -> "December"
    _ -> "Unknown"
  }
}

/// Get day of week (0 = Sunday, 6 = Saturday)
pub fn day_of_week(date_int: Int) -> Int {
  // Unix epoch (Jan 1, 1970) was a Thursday (4)
  { date_int + 4 } % 7
}

/// Get number of days in month
pub fn days_in_month(year: Int, month: Int) -> Int {
  case month {
    1 | 3 | 5 | 7 | 8 | 10 | 12 -> 31
    4 | 6 | 9 | 11 -> 30
    2 -> {
      case is_leap_year(year) {
        True -> 29
        False -> 28
      }
    }
    _ -> 30
  }
}

/// Check if year is leap year
pub fn is_leap_year(year: Int) -> Bool {
  case year % 400 == 0 {
    True -> True
    False ->
      case year % 100 == 0 {
        True -> False
        False -> year % 4 == 0
      }
  }
}

// ============================================================================
// Model Helpers
// ============================================================================

/// Set selected date and update view
pub fn set_selected_date(
  model: DatePickerModel,
  date_int: Int,
) -> DatePickerModel {
  let #(year, month, _day) = date_int_to_ymd(date_int)
  DatePickerModel(
    ..model,
    selected_date: date_int,
    view_year: year,
    view_month: month,
    error: None,
  )
}

// ============================================================================
// List Utilities
// ============================================================================

/// Chunk a list into sublists of given size
pub fn chunk_list(items: List(a), size: Int) -> List(List(a)) {
  case items {
    [] -> []
    _ -> {
      let chunk = list.take(items, size)
      let rest = list.drop(items, size)
      [chunk, ..chunk_list(rest, size)]
    }
  }
}
