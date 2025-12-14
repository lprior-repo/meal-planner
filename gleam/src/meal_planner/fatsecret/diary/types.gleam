/// FatSecret Food Diary types
///
/// These types represent food entries logged in the user's food diary,
/// along with daily and monthly summaries. The FatSecret API uses
/// date_int (days since Unix epoch) for all date operations.
import birl
import gleam/option.{type Option}
import gleam/result

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
  // Use birl to parse the date string (assumes UTC at midnight)
  use time <- result.try(birl.from_naive(date <> "T00:00:00"))

  // Convert to days since Unix epoch
  // birl.to_unix returns seconds, divide by 86400 to get days
  let seconds = birl.to_unix(time)
  Ok(seconds / 86_400)
}

/// Convert days since epoch to YYYY-MM-DD
///
/// Inverse of date_to_int. Always returns a valid date string.
/// Examples:
/// - 0 -> "1970-01-01"
/// - 1 -> "1970-01-02"
/// - 19723 -> "2024-01-01"
pub fn int_to_date(date_int: Int) -> String {
  // Convert days to seconds (Unix timestamp)
  let unix_seconds = date_int * 86_400

  // Create a birl Time from Unix seconds
  let time = birl.from_unix(unix_seconds)

  // Extract the date string (YYYY-MM-DD)
  birl.to_naive_date_string(time)
}
