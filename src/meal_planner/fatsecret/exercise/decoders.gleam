/// FatSecret Exercise JSON decoders
///
/// This module provides type-safe decoders for FatSecret Exercise API responses.
///
/// FatSecret API quirks handled:
/// 1. Single vs array: Returns object for 1 result, array for multiple
/// 2. Numeric strings: Some numbers come as "95" instead of 95
/// 3. Missing optionals: Many fields may be absent
import gleam/dynamic
import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/option.{None, Some}
import meal_planner/fatsecret/exercise/types.{
  type Exercise, type ExerciseDaySummary, type ExerciseEntry,
  type ExerciseEntryId, type ExerciseId, type ExerciseMonthSummary, Exercise,
  ExerciseDaySummary, ExerciseEntry, ExerciseMonthSummary,
}

// ============================================================================
// Helper Decoders for FatSecret Quirks
// ============================================================================

/// Decode a float that might be a string ("95.5" or "95") or number (95.5)
fn flexible_float() -> decode.Decoder(Float) {
  decode.one_of(decode.float, [
    {
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
    },
  ])
}

/// Decode an int that might be a string ("95") or number (95)
fn flexible_int() -> decode.Decoder(Int) {
  decode.one_of(decode.int, [
    {
      use s <- decode.then(decode.string)
      case int.parse(s) {
        Ok(i) -> decode.success(i)
        Error(_) -> decode.failure(0, "Int")
      }
    },
  ])
}

// ============================================================================
// Exercise ID Decoders
// ============================================================================

/// Decode ExerciseId from string
fn exercise_id_decoder() -> decode.Decoder(ExerciseId) {
  use id_str <- decode.then(decode.string)
  decode.success(types.exercise_id(id_str))
}

/// Decode ExerciseEntryId from string
fn exercise_entry_id_decoder() -> decode.Decoder(ExerciseEntryId) {
  use id_str <- decode.then(decode.string)
  decode.success(types.exercise_entry_id(id_str))
}

// ============================================================================
// Exercise Decoder (2-legged - Public Database)
// ============================================================================

/// Decoder for Exercise information from exercises.get.v2
///
/// Example JSON from FatSecret API:
/// ```json
/// {
///   "exercise_id": "1",
///   "exercise_name": "Running",
///   "calories_per_hour": "600"
/// }
/// ```
pub fn exercise_decoder() -> decode.Decoder(Exercise) {
  use exercise_id <- decode.field("exercise_id", exercise_id_decoder())
  use exercise_name <- decode.field("exercise_name", decode.string)
  use calories_per_hour <- decode.field("calories_per_hour", flexible_float())

  decode.success(Exercise(
    exercise_id: exercise_id,
    exercise_name: exercise_name,
    calories_per_hour: calories_per_hour,
  ))
}

/// Decode Exercise from exercises.get.v2 response
///
/// The response wraps the exercise in an "exercise" key:
/// `{"exercise": {...}}`
pub fn decode_exercise_response(
  json: dynamic.Dynamic,
) -> Result(Exercise, List(decode.DecodeError)) {
  decode.run(json, decode.at(["exercise"], exercise_decoder()))
}

// ============================================================================
// ExerciseEntry Decoders (3-legged - User Diary)
// ============================================================================

/// Decoder for complete ExerciseEntry from exercise_entries.get.v2
///
/// Example JSON structure from FatSecret API:
/// ```json
/// {
///   "exercise_entry_id": "123456",
///   "exercise_id": "1",
///   "exercise_name": "Running",
///   "duration_min": "30",
///   "calories": "300",
///   "date_int": "19723"
/// }
/// ```
pub fn exercise_entry_decoder() -> decode.Decoder(ExerciseEntry) {
  use exercise_entry_id <- decode.field(
    "exercise_entry_id",
    exercise_entry_id_decoder(),
  )
  use exercise_id <- decode.field("exercise_id", exercise_id_decoder())
  use exercise_name <- decode.field("exercise_name", decode.string)
  use duration_min <- decode.field("duration_min", flexible_int())
  use calories <- decode.field("calories", flexible_float())
  use date_int <- decode.field("date_int", flexible_int())

  decode.success(ExerciseEntry(
    exercise_entry_id: exercise_entry_id,
    exercise_id: exercise_id,
    exercise_name: exercise_name,
    duration_min: duration_min,
    calories: calories,
    date_int: date_int,
  ))
}

/// Decode list of exercise entries, handling single-vs-array quirk
///
/// FatSecret returns:
/// - `{"exercise_entry": {...}}` for 1 entry
/// - `{"exercise_entry": [{...}, {...}]}` for multiple entries
fn exercise_entries_list_decoder() -> decode.Decoder(List(ExerciseEntry)) {
  decode.one_of(decode.list(exercise_entry_decoder()), [
    {
      use single <- decode.then(exercise_entry_decoder())
      decode.success([single])
    },
  ])
}

/// Decode exercise entries from exercise_entries.get.v2 response
///
/// Example JSON:
/// ```json
/// {
///   "exercise_entries": {
///     "exercise_entry": [
///       {...},
///       {...}
///     ]
///   }
/// }
/// ```
/// When there are no entries, "exercise_entry" field is absent.
pub fn decode_exercise_entries_response() -> decode.Decoder(List(ExerciseEntry)) {
  use entries <- decode.field("exercise_entries", {
    use entry_list <- decode.optional_field(
      "exercise_entry",
      [],
      exercise_entries_list_decoder(),
    )
    decode.success(entry_list)
  })
  decode.success(entries)
}

// ============================================================================
// Summary Decoders
// ============================================================================

/// Decode ExerciseDaySummary from API response
///
/// Example JSON:
/// ```json
/// {
///   "date_int": "19723",
///   "exercise_calories": "450"
/// }
/// ```
pub fn exercise_day_summary_decoder() -> decode.Decoder(ExerciseDaySummary) {
  use date_int <- decode.field("date_int", flexible_int())
  use exercise_calories <- decode.field("exercise_calories", flexible_float())

  decode.success(ExerciseDaySummary(
    date_int: date_int,
    exercise_calories: exercise_calories,
  ))
}

/// Decode single ExerciseDaySummary and wrap in list
fn single_exercise_day_to_list_decoder() -> decode.Decoder(
  List(ExerciseDaySummary),
) {
  use day <- decode.then(exercise_day_summary_decoder())
  decode.success([day])
}

/// Decode ExerciseMonthSummary from exercise_entries.get_month.v2 response
///
/// Example JSON:
/// ```json
/// {
///   "month": "12",
///   "year": "2024",
///   "day": [
///     { "date_int": "19723", "exercise_calories": "450" },
///     { "date_int": "19724", "exercise_calories": "300" }
///   ]
/// }
/// ```
pub fn exercise_month_summary_decoder() -> decode.Decoder(ExerciseMonthSummary) {
  use month <- decode.field("month", flexible_int())
  use year <- decode.field("year", flexible_int())

  // Days can be a single object or array, handle both cases
  use days <- decode.field(
    "day",
    decode.one_of(decode.list(exercise_day_summary_decoder()), [
      {
        use single <- decode.then(exercise_day_summary_decoder())
        decode.success([single])
      },
    ]),
  )

  decode.success(ExerciseMonthSummary(days: days, month: month, year: year))
}

/// Decode ExerciseMonthSummary from exercise_entries.get_month.v2 response
pub fn decode_exercise_month_summary() -> decode.Decoder(ExerciseMonthSummary) {
  decode.at(["month"], exercise_month_summary_decoder())
}
