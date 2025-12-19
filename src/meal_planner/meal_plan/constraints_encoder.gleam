/// JSON encoders for meal planning constraints
///
/// Provides encoders that convert Gleam constraint types to JSON strings.

import gleam/json
import meal_planner/meal_plan/constraints

// ============================================================================
// Type Encoders
// ============================================================================

/// Encode a Constraint to JSON string
pub fn encode_constraint(constraint: constraints.Constraints) -> String {
  constraint
  |> constraint_to_json
  |> json.to_string
}

/// Convert Constraint to JSON value
fn constraint_to_json(
  constraint: constraints.Constraints,
) -> json.Json {
  json.object([
    #("week_of", json.string(constraint.week_of)),
    #(
      "constraints",
      json.object([
        #("travel_dates", json.array(constraint.travel_dates, json.string)),
        #(
          "locked_meals",
          json.array(constraint.locked_meals, locked_meal_to_json),
        ),
        #("macro_adjustment", macro_adjustment_to_json(constraint.macro_adjustment)),
        #("meal_skips", json.array(constraint.meal_skips, json.string)),
        #("preferences", json.array(constraint.preferences, json.string)),
      ]),
    ),
  ])
}

/// Convert LockedMeal to JSON value
fn locked_meal_to_json(meal: constraints.LockedMeal) -> json.Json {
  let constraints.LockedMeal(day, meal_type, recipe_id) = meal
  json.object([
    #("day", json.string(day_of_week_to_string(day))),
    #("meal_type", json.string(meal_type_to_string(meal_type))),
    #("recipe_id", json.int(recipe_id)),
  ])
}

/// Convert MealType to JSON string
fn meal_type_to_json(meal_type: constraints.MealType) -> json.Json {
  json.string(meal_type_to_string(meal_type))
}

fn meal_type_to_string(meal_type: constraints.MealType) -> String {
  case meal_type {
    constraints.Breakfast -> "breakfast"
    constraints.Lunch -> "lunch"
    constraints.Dinner -> "dinner"
    constraints.Snack -> "snack"
  }
}

/// Convert DayOfWeek to JSON string
fn day_of_week_to_json(day: constraints.DayOfWeek) -> json.Json {
  json.string(day_of_week_to_string(day))
}

fn day_of_week_to_string(day: constraints.DayOfWeek) -> String {
  case day {
    constraints.Monday -> "Monday"
    constraints.Tuesday -> "Tuesday"
    constraints.Wednesday -> "Wednesday"
    constraints.Thursday -> "Thursday"
    constraints.Friday -> "Friday"
    constraints.Saturday -> "Saturday"
    constraints.Sunday -> "Sunday"
  }
}

/// Convert MacroAdjustment to JSON string
fn macro_adjustment_to_json(
  adjustment: constraints.MacroAdjustment,
) -> json.Json {
  json.string(macro_adjustment_to_string(adjustment))
}

fn macro_adjustment_to_string(
  adjustment: constraints.MacroAdjustment,
) -> String {
  case adjustment {
    constraints.HighProtein -> "high_protein"
    constraints.LowCarb -> "low_carb"
    constraints.Balanced -> "balanced"
  }
}
