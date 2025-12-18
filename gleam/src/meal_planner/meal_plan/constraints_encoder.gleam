/// Constraint encoder for meal planning
///
/// This module encodes Constraint types to JSON for storage and API consumption.
/// Follows the established encoder patterns from the Tandoor SDK modules.
import birl
import gleam/json.{type Json}
import gleam/list
import meal_planner/meal_plan/constraints.{
  type Constraint, type DayOfWeek, type LockedMeal, type MacroAdjustment,
  type MealSkip, type MealType, type Preference, Constraint, LockedMeal,
  MealSkip,
}

/// Encode complete Constraint to JSON
///
/// # Example Output
/// ```json
/// {
///   "week_of": "2025-12-22",
///   "travel_dates": ["2025-12-23", "2025-12-24"],
///   "locked_meals": [{
///     "day": "Friday",
///     "meal_type": "dinner",
///     "recipe_id": 42
///   }],
///   "macro_adjustment": "high_protein",
///   "preferences": [
///     {"type": "avoid", "value": "seafood"}
///   ],
///   "meal_skips": [{
///     "day": "Saturday",
///     "meal_type": "breakfast"
///   }]
/// }
/// ```
pub fn encode_constraint(constraint: Constraint) -> Json {
  let Constraint(
    week_of,
    travel_dates,
    locked_meals,
    macro_adjustment,
    preferences,
    meal_skips,
  ) = constraint

  json.object([
    #("week_of", encode_date(week_of)),
    #("travel_dates", json.array(travel_dates, encode_date)),
    #("locked_meals", json.array(locked_meals, encode_locked_meal)),
    #("macro_adjustment", encode_macro_adjustment(macro_adjustment)),
    #("preferences", json.array(preferences, encode_preference)),
    #("meal_skips", json.array(meal_skips, encode_meal_skip)),
  ])
}

/// Encode LockedMeal to JSON
///
/// # Example Output
/// ```json
/// {
///   "day": "Friday",
///   "meal_type": "dinner",
///   "recipe_id": 42
/// }
/// ```
pub fn encode_locked_meal(locked_meal: LockedMeal) -> Json {
  let LockedMeal(day, meal_type, recipe_id) = locked_meal

  json.object([
    #("day", encode_day_of_week(day)),
    #("meal_type", encode_meal_type(meal_type)),
    #("recipe_id", json.int(recipe_id)),
  ])
}

/// Encode MealSkip to JSON
///
/// # Example Output
/// ```json
/// {
///   "day": "Saturday",
///   "meal_type": "breakfast"
/// }
/// ```
pub fn encode_meal_skip(meal_skip: MealSkip) -> Json {
  let MealSkip(day, meal_type) = meal_skip

  json.object([
    #("day", encode_day_of_week(day)),
    #("meal_type", encode_meal_type(meal_type)),
  ])
}

/// Encode Preference to JSON
///
/// # Example Output
/// ```json
/// {
///   "type": "avoid",
///   "value": "seafood"
/// }
/// ```
pub fn encode_preference(pref: Preference) -> Json {
  let #(type_str, value) = constraints.preference_to_tuple(pref)

  json.object([#("type", json.string(type_str)), #("value", json.string(value))])
}

/// Encode MealType to JSON string
fn encode_meal_type(meal_type: MealType) -> Json {
  meal_type
  |> constraints.meal_type_to_string
  |> json.string
}

/// Encode DayOfWeek to JSON string
fn encode_day_of_week(day: DayOfWeek) -> Json {
  day
  |> constraints.day_of_week_to_string
  |> json.string
}

/// Encode MacroAdjustment to JSON string
fn encode_macro_adjustment(adjustment: MacroAdjustment) -> Json {
  adjustment
  |> constraints.macro_adjustment_to_string
  |> json.string
}

/// Encode Time to ISO 8601 date string (YYYY-MM-DD)
///
/// Converts birl.Time to date-only string for JSON serialization.
fn encode_date(time: birl.Time) -> Json {
  time
  |> birl.to_iso8601
  |> json.string
}
