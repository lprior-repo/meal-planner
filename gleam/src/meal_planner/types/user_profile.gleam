/// User profile types and operations
///
/// Handles user fitness goals, activity levels, and personalized nutrition targets.

import gleam/dynamic/decode.{type Decoder}
import gleam/float
import gleam/int
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import meal_planner/id.{type UserId, user_id_decoder, user_id_to_json}
import meal_planner/types/macros.{type Macros}
import meal_planner/types/micronutrients.{
  type MicronutrientGoals, decoder as micronutrients_decoder,
  to_json as micronutrients_to_json,
}

/// Activity level for calorie/macro calculations
pub type ActivityLevel {
  Sedentary
  Moderate
  Active
}

/// Fitness goal for calorie adjustments
pub type Goal {
  Gain
  Maintain
  Lose
}

/// User profile for personalized nutrition targets
pub type UserProfile {
  UserProfile(
    id: UserId,
    bodyweight: Float,
    activity_level: ActivityLevel,
    goal: Goal,
    meals_per_day: Int,
    micronutrient_goals: Option(MicronutrientGoals),
  )
}

/// Calculate daily protein target (0.8-1g per lb bodyweight)
/// Higher end for active/gain, lower for sedentary/lose
pub fn daily_protein_target(u: UserProfile) -> Float {
  let multiplier = case u.activity_level, u.goal {
    Active, _ -> 1.0
    _, Gain -> 1.0
    Sedentary, _ -> 0.8
    _, Lose -> 0.8
    _, _ -> 0.9
  }
  u.bodyweight *. multiplier
}

/// Calculate daily fat target (0.3g per lb bodyweight)
pub fn daily_fat_target(u: UserProfile) -> Float {
  u.bodyweight *. 0.3
}

/// Calculate daily calorie target based on activity and goal
pub fn daily_calorie_target(u: UserProfile) -> Float {
  let base_multiplier = case u.activity_level {
    Sedentary -> 12.0
    Moderate -> 15.0
    Active -> 18.0
  }
  let base = u.bodyweight *. base_multiplier
  case u.goal {
    Gain -> base *. 1.15
    Lose -> base *. 0.85
    Maintain -> base
  }
}

/// Calculate daily carb target based on remaining calories
/// After protein (4cal/g) and fat (9cal/g), fill rest with carbs (4cal/g)
pub fn daily_carb_target(u: UserProfile) -> Float {
  let total_calories = daily_calorie_target(u)
  let protein_calories = daily_protein_target(u) *. 4.0
  let fat_calories = daily_fat_target(u) *. 9.0
  let remaining = total_calories -. protein_calories -. fat_calories
  case remaining <. 0.0 {
    True -> 0.0
    False -> remaining /. 4.0
  }
}

/// Calculate complete daily macro targets
pub fn daily_macro_targets(u: UserProfile) -> Macros {
  macros.Macros(
    protein: daily_protein_target(u),
    fat: daily_fat_target(u),
    carbs: daily_carb_target(u),
  )
}

// ============================================================================
// JSON Serialization
// ============================================================================

fn activity_level_to_string(a: ActivityLevel) -> String {
  case a {
    Sedentary -> "sedentary"
    Moderate -> "moderate"
    Active -> "active"
  }
}

fn goal_to_string(g: Goal) -> String {
  case g {
    Gain -> "gain"
    Maintain -> "maintain"
    Lose -> "lose"
  }
}

pub fn to_json(u: UserProfile) -> Json {
  let targets = daily_macro_targets(u)
  let base_fields = [
    #("id", user_id_to_json(u.id)),
    #("bodyweight", json.float(u.bodyweight)),
    #(
      "activity_level",
      json.string(activity_level_to_string(u.activity_level)),
    ),
    #("goal", json.string(goal_to_string(u.goal))),
    #("meals_per_day", json.int(u.meals_per_day)),
    #("daily_targets", macros.to_json(targets)),
  ]

  let fields = case u.micronutrient_goals {
    Some(goals) -> [
      #("micronutrient_goals", micronutrients_to_json(goals)),
      ..base_fields
    ]
    None -> base_fields
  }

  json.object(fields)
}

// ============================================================================
// JSON Deserialization
// ============================================================================

fn activity_level_decoder() -> Decoder(ActivityLevel) {
  use s <- decode.then(decode.string)
  case s {
    "sedentary" -> decode.success(Sedentary)
    "moderate" -> decode.success(Moderate)
    "active" -> decode.success(Active)
    _ -> decode.failure(Sedentary, "ActivityLevel")
  }
}

fn goal_decoder() -> Decoder(Goal) {
  use s <- decode.then(decode.string)
  case s {
    "gain" -> decode.success(Gain)
    "maintain" -> decode.success(Maintain)
    "lose" -> decode.success(Lose)
    _ -> decode.failure(Maintain, "Goal")
  }
}

pub fn decoder() -> Decoder(UserProfile) {
  use user_id <- decode.field("id", user_id_decoder())
  use bodyweight <- decode.field("bodyweight", decode.float)
  use activity_level <- decode.field("activity_level", activity_level_decoder())
  use goal <- decode.field("goal", goal_decoder())
  use meals_per_day <- decode.field("meals_per_day", decode.int)
  use micronutrient_goals <- decode.field(
    "micronutrient_goals",
    decode.optional(micronutrients_decoder()),
  )
  decode.success(UserProfile(
    id: user_id,
    bodyweight: bodyweight,
    activity_level: activity_level,
    goal: goal,
    meals_per_day: meals_per_day,
    micronutrient_goals: micronutrient_goals,
  ))
}

// ============================================================================
// Display Formatting
// ============================================================================

fn float_to_int_rounded(f: Float) -> Int {
  float.round(f)
}

fn float_to_int_rounded_string(f: Float) -> String {
  int.to_string(float_to_int_rounded(f))
}

fn activity_level_to_display_string(level: ActivityLevel) -> String {
  case level {
    Sedentary -> "Sedentary"
    Moderate -> "Moderate"
    Active -> "Active"
  }
}

fn goal_to_display_string(goal: Goal) -> String {
  case goal {
    Gain -> "Gain"
    Maintain -> "Maintain"
    Lose -> "Lose"
  }
}

/// Format user profile with calculated targets as a comprehensive string
pub fn to_display_string(profile: UserProfile) -> String {
  let protein = float_to_int_rounded(daily_protein_target(profile))
  let fat = float_to_int_rounded(daily_fat_target(profile))
  let carbs = float_to_int_rounded(daily_carb_target(profile))
  let calories = float_to_int_rounded(daily_calorie_target(profile))

  "==== YOUR VERTICAL DIET PROFILE ====\n"
  <> "Bodyweight: "
  <> float_to_int_rounded_string(profile.bodyweight)
  <> " lbs\n"
  <> "Activity Level: "
  <> activity_level_to_display_string(profile.activity_level)
  <> "\n"
  <> "Goal: "
  <> goal_to_display_string(profile.goal)
  <> "\n"
  <> "Meals per Day: "
  <> int.to_string(profile.meals_per_day)
  <> "\n\n"
  <> "--- Daily Macro Targets ---\n"
  <> "Calories: "
  <> int.to_string(calories)
  <> "\n"
  <> "Protein: "
  <> int.to_string(protein)
  <> "g\n"
  <> "Fat: "
  <> int.to_string(fat)
  <> "g\n"
  <> "Carbs: "
  <> int.to_string(carbs)
  <> "g\n"
  <> "======================================"
}
