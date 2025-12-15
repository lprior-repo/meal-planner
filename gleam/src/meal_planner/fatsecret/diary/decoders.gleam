/// FatSecret Food Diary decoders
///
/// JSON decoders for food diary types from the FatSecret API.
/// Follows the gleam/dynamic decode pattern for type-safe parsing.
import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/option.{None}
import meal_planner/fatsecret/diary/types.{
  type DaySummary, type FoodEntry, type FoodEntryId, type MealType,
  type MonthSummary, DaySummary, FoodEntry, MonthSummary,
}

// ============================================================================
// MealType Decoder
// ============================================================================

/// Decode MealType from API string
pub fn meal_type_decoder() -> decode.Decoder(MealType) {
  use s <- decode.then(decode.string)
  case types.meal_type_from_string(s) {
    Ok(meal) -> decode.success(meal)
    Error(_) -> decode.failure(types.Snack, "MealType")
  }
}

// ============================================================================
// FoodEntry Decoders
// ============================================================================

/// Decode FoodEntryId from JSON string
fn food_entry_id_decoder() -> decode.Decoder(FoodEntryId) {
  use id_str <- decode.then(decode.string)
  decode.success(types.food_entry_id(id_str))
}

/// Decode complete FoodEntry from API response
///
/// Example JSON structure from FatSecret API:
/// ```json
/// {
///   "food_entry_id": "123456",
///   "food_entry_name": "Chicken Breast",
///   "food_entry_description": "Per 100g - Calories: 165kcal | Fat: 3.6g | Carbs: 0g | Protein: 31g",
///   "food_id": "4142",
///   "serving_id": "12345",
///   "number_of_units": "1.5",
///   "meal": "dinner",
///   "date_int": "19723",
///   "calories": "248",
///   "carbohydrate": "0",
///   "protein": "46.5",
///   "fat": "5.4",
///   "saturated_fat": "1.2",
///   "polyunsaturated_fat": "0.8",
///   "monounsaturated_fat": "1.5",
///   "cholesterol": "110",
///   "sodium": "95",
///   "potassium": "420",
///   "fiber": "0",
///   "sugar": "0"
/// }
/// ```
pub fn food_entry_decoder() -> decode.Decoder(FoodEntry) {
  use food_entry_id <- decode.field("food_entry_id", food_entry_id_decoder())
  use food_entry_name <- decode.field("food_entry_name", decode.string)
  use food_entry_description <- decode.field(
    "food_entry_description",
    decode.string,
  )
  use food_id <- decode.field("food_id", decode.string)
  use serving_id <- decode.field("serving_id", decode.string)

  // Number of units comes as string, need to parse to float
  use number_of_units <- decode.field("number_of_units", float_string_decoder())

  use meal <- decode.field("meal", meal_type_decoder())

  // date_int comes as string, need to parse to int
  use date_int <- decode.field("date_int", int_string_decoder())

  // All nutrition values come as strings from API
  use calories <- decode.field("calories", float_string_decoder())
  use carbohydrate <- decode.field("carbohydrate", float_string_decoder())
  use protein <- decode.field("protein", float_string_decoder())
  use fat <- decode.field("fat", float_string_decoder())

  // Optional micronutrients (may not always be present)
  use saturated_fat <- decode.optional_field(
    "saturated_fat",
    None,
    decode.optional(float_string_decoder()),
  )
  use polyunsaturated_fat <- decode.optional_field(
    "polyunsaturated_fat",
    None,
    decode.optional(float_string_decoder()),
  )
  use monounsaturated_fat <- decode.optional_field(
    "monounsaturated_fat",
    None,
    decode.optional(float_string_decoder()),
  )
  use cholesterol <- decode.optional_field(
    "cholesterol",
    None,
    decode.optional(float_string_decoder()),
  )
  use sodium <- decode.optional_field(
    "sodium",
    None,
    decode.optional(float_string_decoder()),
  )
  use potassium <- decode.optional_field(
    "potassium",
    None,
    decode.optional(float_string_decoder()),
  )
  use fiber <- decode.optional_field(
    "fiber",
    None,
    decode.optional(float_string_decoder()),
  )
  use sugar <- decode.optional_field(
    "sugar",
    None,
    decode.optional(float_string_decoder()),
  )

  decode.success(FoodEntry(
    food_entry_id: food_entry_id,
    food_entry_name: food_entry_name,
    food_entry_description: food_entry_description,
    food_id: food_id,
    serving_id: serving_id,
    number_of_units: number_of_units,
    meal: meal,
    date_int: date_int,
    calories: calories,
    carbohydrate: carbohydrate,
    protein: protein,
    fat: fat,
    saturated_fat: saturated_fat,
    polyunsaturated_fat: polyunsaturated_fat,
    monounsaturated_fat: monounsaturated_fat,
    cholesterol: cholesterol,
    sodium: sodium,
    potassium: potassium,
    fiber: fiber,
    sugar: sugar,
  ))
}

// ============================================================================
// Summary Decoders
// ============================================================================

/// Decode DaySummary from API response
///
/// Example JSON:
/// ```json
/// {
///   "date_int": "19723",
///   "calories": "2100",
///   "carbohydrate": "200",
///   "protein": "150",
///   "fat": "70"
/// }
/// ```
pub fn day_summary_decoder() -> decode.Decoder(DaySummary) {
  use date_int <- decode.field("date_int", int_string_decoder())
  use calories <- decode.field("calories", float_string_decoder())
  use carbohydrate <- decode.field("carbohydrate", float_string_decoder())
  use protein <- decode.field("protein", float_string_decoder())
  use fat <- decode.field("fat", float_string_decoder())

  decode.success(DaySummary(
    date_int: date_int,
    calories: calories,
    carbohydrate: carbohydrate,
    protein: protein,
    fat: fat,
  ))
}

/// Decode MonthSummary from API response
///
/// Example JSON:
/// ```json
/// {
///   "month": "1",
///   "year": "2024",
///   "days": {
///     "day": [
///       { "date_int": "19723", "calories": "2100", ... },
///       { "date_int": "19724", "calories": "1950", ... }
///     ]
///   }
/// }
/// ```
pub fn month_summary_decoder() -> decode.Decoder(MonthSummary) {
  use month <- decode.field("month", int_string_decoder())
  use year <- decode.field("year", int_string_decoder())

  // Days can be a single object or array
  use days <- decode.field(
    "days",
    decode.one_of(decode.at(["day"], decode.list(day_summary_decoder())), [
      decode.at(["day"], single_day_to_list_decoder()),
    ]),
  )

  decode.success(MonthSummary(days: days, month: month, year: year))
}

// ============================================================================
// Helper Decoders
// ============================================================================

/// Decode float from string (FatSecret API returns numbers as strings)
fn float_string_decoder() -> decode.Decoder(Float) {
  use s <- decode.then(decode.string)
  case parse_float(s) {
    Ok(f) -> decode.success(f)
    Error(_) -> decode.failure(0.0, "Float")
  }
}

/// Decode int from string (FatSecret API returns numbers as strings)
fn int_string_decoder() -> decode.Decoder(Int) {
  use s <- decode.then(decode.string)
  case parse_int(s) {
    Ok(i) -> decode.success(i)
    Error(_) -> decode.failure(0, "Int")
  }
}

/// Decode single DaySummary and wrap in list
fn single_day_to_list_decoder() -> decode.Decoder(List(DaySummary)) {
  use day <- decode.then(day_summary_decoder())
  decode.success([day])
}

// ============================================================================
// String Parsing Helpers
// ============================================================================

/// Parse float from string, handling both "1.5" and "1" formats
fn parse_float(s: String) -> Result(Float, Nil) {
  // Try parsing as float first using gleam/float
  case float.parse(s) {
    Ok(f) -> Ok(f)
    Error(_) -> {
      // If that fails, try parsing as int then convert to float
      case int.parse(s) {
        Ok(i) -> Ok(int.to_float(i))
        Error(_) -> Error(Nil)
      }
    }
  }
}

/// Parse int from string using gleam/int
fn parse_int(s: String) -> Result(Int, Nil) {
  int.parse(s)
}
