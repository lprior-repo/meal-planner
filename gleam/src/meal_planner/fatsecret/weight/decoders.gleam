/// FatSecret Weight decoders
///
/// JSON decoders for weight types from the FatSecret API.
/// Follows the gleam/dynamic decode pattern for type-safe parsing.
import gleam/dynamic/decode
import gleam/float
import gleam/int
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
/// Example JSON from FatSecret API:
/// ```json
/// {
///   "month": {
///     "from_date_int": "14276",
///     "to_date_int": "14303",
///     "day": [
///       { "date_int": "14276", "weight_kg": "82.000", "weight_comment": "optional" },
///       { "date_int": "14277", "weight_kg": "81.500" }
///     ]
///   }
/// }
/// ```
///
/// Note: The response is wrapped in a "month" object, not at the root level.
pub fn weight_month_summary_decoder() -> decode.Decoder(WeightMonthSummary) {
  // The actual response is wrapped in a "month" object
  decode.at(["month"], {
    use from_date_int <- decode.field("from_date_int", int_string_decoder())
    use to_date_int <- decode.field("to_date_int", int_string_decoder())

    // Days can be a single object or array
    use days <- decode.field(
      "day",
      decode.one_of(decode.list(weight_day_summary_decoder()), [
        single_day_to_list_decoder(),
      ]),
    )

    decode.success(WeightMonthSummary(
      from_date_int: from_date_int,
      to_date_int: to_date_int,
      days: days,
    ))
  })
}

// ============================================================================
// Helper Decoders
// ============================================================================

/// Decode float from string (FatSecret API returns numbers as strings)
/// Handles both "75.5" (float) and "75" (integer as string) formats
fn float_string_decoder() -> decode.Decoder(Float) {
  use s <- decode.then(decode.string)
  // Try parsing as float first
  case float.parse(s) {
    Ok(f) -> decode.success(f)
    Error(_) -> {
      // Fall back to parsing as int then converting to float
      case int.parse(s) {
        Ok(i) -> decode.success(int.to_float(i))
        Error(_) -> decode.failure(0.0, "Float")
      }
    }
  }
}

/// Decode int from string (FatSecret API returns numbers as strings)
fn int_string_decoder() -> decode.Decoder(Int) {
  use s <- decode.then(decode.string)
  case int.parse(s) {
    Ok(i) -> decode.success(i)
    Error(_) -> decode.failure(0, "Int")
  }
}

/// Decode single WeightDaySummary and wrap in list
fn single_day_to_list_decoder() -> decode.Decoder(List(WeightDaySummary)) {
  use day <- decode.then(weight_day_summary_decoder())
  decode.success([day])
}
