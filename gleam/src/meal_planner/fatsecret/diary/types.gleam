/// FatSecret Food Diary types
///
/// These types represent food entries logged in the user's food diary,
/// along with daily and monthly summaries. The FatSecret API uses
/// date_int (days since Unix epoch) for all date operations.
import gleam/int
import gleam/option.{type Option}
import gleam/result
import gleam/string

// ============================================================================
// MealType (re-exported from client for consistency)
// ============================================================================

/// Meal type for diary entries
pub type MealType {
  Breakfast
  Lunch
  Dinner
  Snack
}

/// Convert MealType to API string
pub fn meal_type_to_string(meal: MealType) -> String {
  case meal {
    Breakfast -> "breakfast"
    Lunch -> "lunch"
    Dinner -> "dinner"
    Snack -> "other"
  }
}

/// Parse MealType from API string
pub fn meal_type_from_string(s: String) -> Result(MealType, Nil) {
  case s {
    "breakfast" -> Ok(Breakfast)
    "lunch" -> Ok(Lunch)
    "dinner" -> Ok(Dinner)
    "other" | "snack" -> Ok(Snack)
    _ -> Error(Nil)
  }
}

// ============================================================================
// Food Entry ID (opaque type for type safety)
// ============================================================================

/// Opaque food entry ID from FatSecret API
pub opaque type FoodEntryId {
  FoodEntryId(String)
}

/// Create a FoodEntryId from a string
pub fn food_entry_id(id: String) -> FoodEntryId {
  FoodEntryId(id)
}

/// Convert FoodEntryId to string for API calls
pub fn food_entry_id_to_string(id: FoodEntryId) -> String {
  let FoodEntryId(s) = id
  s
}

// ============================================================================
// Food Entry Types
// ============================================================================

/// Complete food diary entry
///
/// Represents a single food logged to the user's diary. All nutrition
/// values are stored in the units they come from the API (grams, milligrams).
pub type FoodEntry {
  FoodEntry(
    /// Unique entry ID from FatSecret
    food_entry_id: FoodEntryId,
    /// Entry display name
    food_entry_name: String,
    /// Full description (includes serving size info)
    food_entry_description: String,
    /// Food ID (if from FatSecret database, empty for custom)
    food_id: String,
    /// Serving ID (if from FatSecret database, empty for custom)
    serving_id: String,
    /// Number of servings consumed
    number_of_units: Float,
    /// Which meal this entry belongs to
    meal: MealType,
    /// Date as days since Unix epoch (0 = 1970-01-01)
    date_int: Int,
    /// Macros and micronutrients
    calories: Float,
    carbohydrate: Float,
    // grams
    protein: Float,
    // grams
    fat: Float,
    // grams
    saturated_fat: Option(Float),
    // grams
    polyunsaturated_fat: Option(Float),
    // grams
    monounsaturated_fat: Option(Float),
    // grams
    cholesterol: Option(Float),
    // milligrams
    sodium: Option(Float),
    // milligrams
    potassium: Option(Float),
    // milligrams
    fiber: Option(Float),
    // grams
    sugar: Option(Float),
  )
}

// grams
/// Input for creating a new food entry
///
/// Two ways to create entries:
/// 1. FromFood: Reference an existing FatSecret food with serving
/// 2. Custom: Manually enter all nutrition values
pub type FoodEntryInput {
  /// Create entry from FatSecret database food
  FromFood(
    food_id: String,
    serving_id: String,
    number_of_units: Float,
    meal: MealType,
    date_int: Int,
  )
  /// Create custom entry with manual nutrition values
  Custom(
    food_entry_name: String,
    serving_description: String,
    number_of_units: Float,
    meal: MealType,
    date_int: Int,
    calories: Float,
    carbohydrate: Float,
    protein: Float,
    fat: Float,
  )
}

/// Update for an existing food entry
///
/// Only allows updating serving size and meal type.
/// To change nutrition values, delete and recreate the entry.
pub type FoodEntryUpdate {
  FoodEntryUpdate(number_of_units: Option(Float), meal: Option(MealType))
}

// ============================================================================
// Summary Types
// ============================================================================

/// Daily nutrition summary
///
/// Aggregated totals for a single day's diary entries.
pub type DaySummary {
  DaySummary(
    date_int: Int,
    calories: Float,
    carbohydrate: Float,
    protein: Float,
    fat: Float,
  )
}

/// Monthly nutrition summary
///
/// Contains a summary for each day in the month.
pub type MonthSummary {
  MonthSummary(days: List(DaySummary), month: Int, year: Int)
}

// ============================================================================
// Date Conversion Functions
// ============================================================================

/// Convert YYYY-MM-DD to days since epoch (date_int)
///
/// FatSecret API uses date_int which is the number of days since 1970-01-01.
/// Examples:
/// - "1970-01-01" -> 0
/// - "1970-01-02" -> 1
/// - "2024-01-01" -> 19723
///
/// Returns Error if date format is invalid.
pub fn date_to_int(date: String) -> Result(Int, Nil) {
  case string.split(date, "-") {
    [year_str, month_str, day_str] -> {
      use year <- result.try(int.parse(year_str))
      use month <- result.try(int.parse(month_str))
      use day <- result.try(int.parse(day_str))

      // Validate ranges
      case
        year >= 1970
        && year <= 2100
        && month >= 1
        && month <= 12
        && day >= 1
        && day <= 31
      {
        True -> Ok(days_since_epoch(year, month, day))
        False -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

/// Convert days since epoch to YYYY-MM-DD
///
/// Inverse of date_to_int. Always returns a valid date string.
/// Examples:
/// - 0 -> "1970-01-01"
/// - 1 -> "1970-01-02"
/// - 19723 -> "2024-01-01"
pub fn int_to_date(date_int: Int) -> String {
  let #(year, month, day) = epoch_to_date(date_int)

  // Format with zero padding
  let year_str = int.to_string(year)
  let month_str = pad_zero(month)
  let day_str = pad_zero(day)

  year_str <> "-" <> month_str <> "-" <> day_str
}

// ============================================================================
// Internal Date Calculation Helpers
// ============================================================================

/// Calculate days since 1970-01-01
///
/// Uses a simplified calculation that doesn't account for leap years
/// but is good enough for the FatSecret API date range.
/// For a production implementation, use a proper date library.
fn days_since_epoch(year: Int, month: Int, day: Int) -> Int {
  let years_since_epoch = year - 1970
  let days_from_years = years_since_epoch * 365

  // Account for leap years (simplified)
  let leap_days = years_since_epoch / 4

  // Days from months (simplified - assumes 30.4 days per month average)
  let days_from_months = case month {
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

  // Add leap day if after Feb in a leap year
  let leap_day_adjustment = case is_leap_year(year) && month > 2 {
    True -> 1
    False -> 0
  }

  days_from_years + leap_days + days_from_months + leap_day_adjustment + day - 1
}

/// Convert days since epoch back to (year, month, day)
///
/// Simplified reverse calculation. For production, use a proper date library.
fn epoch_to_date(days: Int) -> #(Int, Int, Int) {
  // Estimate year (365.25 days per year average)
  let year_estimate = 1970 + days / 365
  let year = find_year(days, year_estimate)

  // Calculate days into the year
  let days_at_year_start = days_since_epoch(year, 1, 1)
  let day_of_year = days - days_at_year_start + 1

  // Find month and day
  let #(month, day) = day_of_year_to_month_day(day_of_year, year)

  #(year, month, day)
}

/// Find the correct year for a given number of days
fn find_year(days: Int, estimate: Int) -> Int {
  let days_at_estimate = days_since_epoch(estimate, 1, 1)
  case days >= days_at_estimate {
    True -> {
      let next_year_days = days_since_epoch(estimate + 1, 1, 1)
      case days < next_year_days {
        True -> estimate
        False -> find_year(days, estimate + 1)
      }
    }
    False -> find_year(days, estimate - 1)
  }
}

/// Convert day of year to (month, day)
fn day_of_year_to_month_day(day_of_year: Int, year: Int) -> #(Int, Int) {
  let days_in_month = case is_leap_year(year) {
    True -> [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    False -> [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  }

  find_month_day(day_of_year, days_in_month, 1, 0)
}

/// Recursively find month and day from day of year
fn find_month_day(
  remaining: Int,
  days_in_months: List(Int),
  current_month: Int,
  accumulated: Int,
) -> #(Int, Int) {
  case days_in_months {
    [] -> #(12, 31)
    // Fallback
    [days_in_month, ..rest] -> {
      case remaining <= accumulated + days_in_month {
        True -> #(current_month, remaining - accumulated)
        False ->
          find_month_day(
            remaining,
            rest,
            current_month + 1,
            accumulated + days_in_month,
          )
      }
    }
  }
}

/// Check if a year is a leap year
fn is_leap_year(year: Int) -> Bool {
  case year % 4 {
    0 ->
      case year % 100 {
        0 ->
          case year % 400 {
            0 -> True
            _ -> False
          }
        _ -> True
      }
    _ -> False
  }
}

/// Pad single digit numbers with leading zero
fn pad_zero(n: Int) -> String {
  case n < 10 {
    True -> "0" <> int.to_string(n)
    False -> int.to_string(n)
  }
}
