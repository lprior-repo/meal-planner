/// Constraint decoder for meal planning
///
/// This module decodes JSON to Constraint types for processing user input.
/// Follows the established decoder patterns from the Tandoor SDK modules.
import birl
import gleam/dynamic
import gleam/dynamic/decode
import gleam/result
import gleam/string
import meal_planner/meal_plan/constraints.{
  type Constraint, type DayOfWeek, type LockedMeal, type MacroAdjustment,
  type MealSkip, type MealType, type Preference, Constraint, LockedMeal,
  MealSkip,
}

/// Decode complete Constraint from JSON
///
/// # Example Input
/// ```json
/// {
///   "week_of": "2025-12-22T00:00:00Z",
///   "travel_dates": ["2025-12-23T00:00:00Z"],
///   "locked_meals": [{
///     "day": "Friday",
///     "meal_type": "dinner",
///     "recipe_id": 42
///   }],
///   "macro_adjustment": "high_protein",
///   "preferences": [
///     {"type": "avoid", "value": "seafood"}
///   ],
///   "meal_skips": []
/// }
/// ```
pub fn constraint_decoder() -> decode.Decoder(Constraint) {
  use week_of <- decode.field("week_of", decode_date())
  use travel_dates <- decode.field("travel_dates", decode.list(decode_date()))
  use locked_meals <- decode.field(
    "locked_meals",
    decode.list(locked_meal_decoder()),
  )
  use macro_adjustment <- decode.field(
    "macro_adjustment",
    decode_macro_adjustment(),
  )
  use preferences <- decode.field(
    "preferences",
    decode.list(preference_decoder()),
  )
  use meal_skips <- decode.field("meal_skips", decode.list(meal_skip_decoder()))

  decode.success(Constraint(
    week_of: week_of,
    travel_dates: travel_dates,
    locked_meals: locked_meals,
    macro_adjustment: macro_adjustment,
    preferences: preferences,
    meal_skips: meal_skips,
  ))
}

/// Decode LockedMeal from JSON
///
/// # Example Input
/// ```json
/// {
///   "day": "Friday",
///   "meal_type": "dinner",
///   "recipe_id": 42
/// }
/// ```
pub fn locked_meal_decoder() -> decode.Decoder(LockedMeal) {
  use day <- decode.field("day", decode_day_of_week())
  use meal_type <- decode.field("meal_type", decode_meal_type())
  use recipe_id <- decode.field("recipe_id", decode.int)

  decode.success(LockedMeal(
    day: day,
    meal_type: meal_type,
    recipe_id: recipe_id,
  ))
}

/// Decode MealSkip from JSON
///
/// # Example Input
/// ```json
/// {
///   "day": "Saturday",
///   "meal_type": "breakfast"
/// }
/// ```
pub fn meal_skip_decoder() -> decode.Decoder(MealSkip) {
  use day <- decode.field("day", decode_day_of_week())
  use meal_type <- decode.field("meal_type", decode_meal_type())

  decode.success(MealSkip(day: day, meal_type: meal_type))
}

/// Decode Preference from JSON
///
/// # Example Input
/// ```json
/// {
///   "type": "avoid",
///   "value": "seafood"
/// }
/// ```
pub fn preference_decoder() -> decode.Decoder(Preference) {
  use type_str <- decode.field("type", decode.string)
  use value <- decode.field("value", decode.string)

  let tuple = #(type_str, value)
  decode.success(constraints.preference_from_tuple(tuple))
}

/// Decode MealType from JSON string
fn decode_meal_type() -> decode.Decoder(MealType) {
  use s <- decode.then(decode.string)
  decode.success(constraints.meal_type_from_string(s))
}

/// Decode DayOfWeek from JSON string
fn decode_day_of_week() -> decode.Decoder(DayOfWeek) {
  use s <- decode.then(decode.string)
  decode.success(constraints.day_of_week_from_string(s))
}

/// Decode MacroAdjustment from JSON string
fn decode_macro_adjustment() -> decode.Decoder(MacroAdjustment) {
  use s <- decode.then(decode.string)
  decode.success(constraints.macro_adjustment_from_string(s))
}

/// Decode ISO 8601 date string to birl.Time
///
/// Accepts both date-only (YYYY-MM-DD) and full datetime (ISO 8601) formats.
fn decode_date() -> decode.Decoder(birl.Time) {
  use s <- decode.then(decode.string)
  case birl.parse(s) {
    Ok(time) -> decode.success(time)
    Error(_) -> decode.failure(time: birl.now(), "Invalid ISO 8601 date: " <> s)
  }
}

/// Run constraint decoder on dynamic value
///
/// Returns Result with descriptive error message on failure.
pub fn decode_constraint(
  json_value: dynamic.Dynamic,
) -> Result(Constraint, String) {
  case decode.run(json_value, constraint_decoder()) {
    Ok(constraint) -> Ok(constraint)
    Error(errors) -> {
      let error_msg =
        errors
        |> dynamic.format_errors("Failed to decode constraint")
      Error(error_msg)
    }
  }
}
