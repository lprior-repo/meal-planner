/// JSON decoders for meal planning constraints
///
/// Provides decoders that parse JSON constraint data into Gleam types.
import gleam/dynamic/decode
import meal_planner/meal_plan/constraints

// ============================================================================
// Type Decoders
// ============================================================================

/// Decode a Constraint from JSON
pub fn constraint_decoder() -> decode.Decoder(constraints.Constraints) {
  use week_of <- decode.field("week_of", decode.string)
  use constraints_inner <- decode.field(
    "constraints",
    constraints_inner_decoder(),
  )
  decode.success(constraints.Constraints(
    week_of: week_of,
    travel_dates: constraints_inner.0,
    locked_meals: constraints_inner.1,
    macro_adjustment: constraints_inner.2,
    meal_skips: constraints_inner.3,
    preferences: constraints_inner.4,
  ))
}

/// Decode the inner constraints object
fn constraints_inner_decoder() -> decode.Decoder(
  #(
    List(String),
    List(constraints.LockedMeal),
    constraints.MacroAdjustment,
    List(String),
    List(String),
  ),
) {
  use travel_dates <- decode.field("travel_dates", decode.list(decode.string))
  use locked_meals <- decode.field(
    "locked_meals",
    decode.list(locked_meal_decoder()),
  )
  use macro_adj <- decode.field("macro_adjustment", macro_adjustment_decoder())
  use meal_skips <- decode.field("meal_skips", decode.list(decode.string))
  use prefs <- decode.field("preferences", decode.list(decode.string))
  decode.success(#(travel_dates, locked_meals, macro_adj, meal_skips, prefs))
}

/// Decode a LockedMeal from JSON
fn locked_meal_decoder() -> decode.Decoder(constraints.LockedMeal) {
  use day <- decode.field("day", day_of_week_decoder())
  use meal_type <- decode.field("meal_type", meal_type_decoder())
  use recipe_id <- decode.field("recipe_id", decode.int)
  decode.success(constraints.LockedMeal(day, meal_type, recipe_id))
}

/// Decode MealType from JSON
fn meal_type_decoder() -> decode.Decoder(constraints.MealType) {
  use s <- decode.then(decode.string)
  case constraints.meal_type_from_string(s) {
    Ok(meal) -> decode.success(meal)
    Error(_) -> decode.failure(constraints.Breakfast, "MealType")
  }
}

/// Decode DayOfWeek from JSON
fn day_of_week_decoder() -> decode.Decoder(constraints.DayOfWeek) {
  use s <- decode.then(decode.string)
  case constraints.day_of_week_from_string(s) {
    Ok(day) -> decode.success(day)
    Error(_) -> decode.failure(constraints.Monday, "DayOfWeek")
  }
}

/// Decode MacroAdjustment from JSON
fn macro_adjustment_decoder() -> decode.Decoder(constraints.MacroAdjustment) {
  use s <- decode.then(decode.string)
  case constraints.macro_adjustment_from_string(s) {
    Ok(adj) -> decode.success(adj)
    Error(_) -> decode.failure(constraints.Balanced, "MacroAdjustment")
  }
}
