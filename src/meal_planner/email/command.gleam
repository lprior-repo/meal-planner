/// Email command types for meal plan feedback
///
/// Represents commands that Lewis can send via email to adjust meal plans,
/// preferences, and trigger regenerations.

import gleam/option.{type Option}

/// Day of the week for meal plan adjustments
pub type Day {
  Monday
  Tuesday
  Wednesday
  Thursday
  Friday
  Saturday
  Sunday
}

/// Meal type within a day
pub type MealType {
  Breakfast
  Lunch
  Dinner
}

/// User preference update (e.g., foods to avoid, eating style preferences)
pub type Preference {
  Dislike(food: String)
  Prefer(preference: String)
  Variety(flag: String)
}

/// Scope of regeneration
pub type RegenerationScope {
  SingleMeal(day: Day, meal: MealType)
  SingleDay(day: Day)
  FullWeek
}

/// Email command that Lewis sends to Claude
pub type EmailCommand {
  /// Adjust a single meal: "adjust Friday dinner to pasta"
  AdjustMeal(day: Day, meal: MealType, recipe: Option(String))

  /// Rotate out a food: "I didn't like the tacos"
  RotateFood(food: String)

  /// Update preferences: "add more vegetables"
  UpdatePreference(preference: Preference)

  /// Regenerate meal plan or portion: "regenerate week with high protein"
  Regenerate(scope: RegenerationScope, constraint: Option(String))

  /// Skip a meal due to travel or circumstances: "skip breakfast Tuesday"
  SkipMeal(day: Day, meal: MealType)

  /// Unknown or malformed command
  Unknown(raw_text: String)
}

/// Result of parsing an email
pub type ParseResult {
  CommandFound(command: EmailCommand)
  NoCommand(reason: String)
  ParseError(error: String)
}
