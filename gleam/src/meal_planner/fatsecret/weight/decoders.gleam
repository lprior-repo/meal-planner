/// FatSecret Weight decoders
///
/// JSON decoders for weight types from the FatSecret API.
/// Follows the gleam/dynamic decode pattern for type-safe parsing.
import gleam/dynamic/decode
import gleam/option.{None}
import meal_planner/fatsecret/weight/types.{
  type WeightDaySummary, type WeightEntry, type WeightMonthSummary,
  WeightDaySummary, WeightEntry, WeightMonthSummary,
}

// ============================================================================
// WeightEntry Decoders
// ============================================================================

/// Decode WeightEntry from API response
///
/// Example JSON structure from FatSecret API:
/// ```json
/// {
///   "date_int": "19723",
///   "weight_kg": "75.5",
///   "weight_comment": "Morning weight"
/// }
/// ```
pub fn weight_entry_decoder() -> decode.Decoder(WeightEntry) {
  use date_int <- decode.field("date_int", int_string_decoder())
  use weight_kg <- decode.field("weight_kg", float_string_decoder())
  use weight_comment <- decode.optional_field(
    "weight_comment",
    None,
    decode.optional(decode.string),
  )

  decode.success(WeightEntry(
    date_int: date_int,
    weight_kg: weight_kg,
    weight_comment: weight_comment,
  ))
}

// ============================================================================
// Summary Decoders
// ============================================================================

/// Decode WeightDaySummary from API response
///
/// Example JSON:
/// ```json
/// {
///   "date_int": "19723",
///   "weight_kg": "75.5"
/// }
/// ```
pub fn weight_day_summary_decoder() -> decode.Decoder(WeightDaySummary) {
  use date_int <- decode.field("date_int", int_string_decoder())
  use weight_kg <- decode.field("weight_kg", float_string_decoder())

  decode.success(WeightDaySummary(date_int: date_int, weight_kg: weight_kg))
}

/// Decode WeightMonthSummary from API response
///
/// Example JSON:
/// ```json
/// {
///   "month": "1",
///   "year": "2024",
///   "days": {
///     "day": [
///       { "date_int": "19723", "weight_kg": "75.5" },
///       { "date_int": "19724", "weight_kg": "75.3" }
///     ]
///   }
/// }
/// ```
pub fn weight_month_summary_decoder() -> decode.Decoder(WeightMonthSummary) {
  use month <- decode.field("month", int_string_decoder())
  use year <- decode.field("year", int_string_decoder())

  // Days can be a single object or array
  use days <- decode.field(
    "days",
    decode.one_of(
      decode.at(["day"], decode.list(weight_day_summary_decoder())),
      [
        decode.at(["day"], single_day_to_list_decoder()),
      ],
    ),
  )

  decode.success(WeightMonthSummary(days: days, month: month, year: year))
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

/// Decode single WeightDaySummary and wrap in list
fn single_day_to_list_decoder() -> decode.Decoder(List(WeightDaySummary)) {
  use day <- decode.then(weight_day_summary_decoder())
  decode.success([day])
}

// ============================================================================
// String Parsing Helpers
// ============================================================================

/// Parse float from string with error handling
@external(erlang, "erlang", "binary_to_float")
fn erlang_binary_to_float(s: String) -> Float

/// Parse int from string
@external(erlang, "erlang", "binary_to_integer")
fn erlang_binary_to_integer(s: String) -> Int

/// Parse float from string, handling both "1.5" and "1" formats
fn parse_float(s: String) -> Result(Float, Nil) {
  // Try as float first
  case try_parse_float(s) {
    Ok(f) -> Ok(f)
    Error(_) -> {
      // If that fails, try parsing as int then convert
      case parse_int(s) {
        Ok(i) -> Ok(int_to_float(i))
        Error(_) -> Error(Nil)
      }
    }
  }
}

/// Try to parse string as float
fn try_parse_float(s: String) -> Result(Float, Nil) {
  case erlang_binary_to_float(s) {
    f -> Ok(f)
  }
}

/// Parse int from string
fn parse_int(s: String) -> Result(Int, Nil) {
  case erlang_binary_to_integer(s) {
    i -> Ok(i)
  }
}

/// Convert int to float
@external(erlang, "erlang", "float")
fn int_to_float(i: Int) -> Float
