/// Email command types for meal plan feedback
///
/// Represents commands that Lewis can send via email to adjust meal plans,
/// preferences, and trigger regenerations.
import gleam/option.{type Option, None, Some}
import gleam/string
import meal_planner/id.{type RecipeId}

/// Day of the week for meal plan adjustments
pub type DayOfWeek {
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
  Snack
}

/// Scope of regeneration
pub type RegenerationScope {
  SingleMeal(day: DayOfWeek, meal: MealType)
  SingleDay(day: DayOfWeek)
  FullWeek
}

/// Email command that Lewis sends to Claude
pub type EmailCommand {
  /// Adjust a single meal: "adjust Friday dinner to pasta"
  AdjustMeal(day: DayOfWeek, meal_type: MealType, recipe_id: RecipeId)

  /// Add a preference: "add more vegetables"
  AddPreference(preference: String)

  /// Remove a dislike: "I didn't like the tacos"
  RemoveDislike(food_name: String)

  /// Regenerate meal plan: "regenerate week with high protein"
  RegeneratePlan(scope: RegenerationScope, constraints: Option(String))

  /// Skip a meal due to travel or circumstances: "skip breakfast Tuesday"
  SkipMeal(day: DayOfWeek, meal_type: MealType)
}

/// Error types for email command parsing
pub type EmailCommandError {
  InvalidCommand(reason: String)
  AmbiguousCommand(message: String)
  MissingContext(required: String)
}

/// Incoming email request
pub type EmailRequest {
  EmailRequest(
    from_email: String,
    subject: String,
    body: String,
    is_reply: Bool,
  )
}

/// Result of parsing an email
pub type ParseResult {
  CommandFound(command: EmailCommand)
  NoCommand(reason: String)
  ParseError(error: String)
}

/// Result of executing an email command
pub type CommandExecutionResult {
  CommandExecutionResult(
    success: Bool,
    message: String,
    command: Option(EmailCommand),
  )
}

// =============================================================================
// Helper Functions
// =============================================================================

/// Convert DayOfWeek to string
pub fn day_of_week_to_string(day: DayOfWeek) -> String {
  case day {
    Monday -> "Monday"
    Tuesday -> "Tuesday"
    Wednesday -> "Wednesday"
    Thursday -> "Thursday"
    Friday -> "Friday"
    Saturday -> "Saturday"
    Sunday -> "Sunday"
  }
}

/// Parse string to DayOfWeek
pub fn day_of_week_from_string(s: String) -> Option(DayOfWeek) {
  case string.lowercase(s) {
    "monday" -> Some(Monday)
    "tuesday" -> Some(Tuesday)
    "wednesday" -> Some(Wednesday)
    "thursday" -> Some(Thursday)
    "friday" -> Some(Friday)
    "saturday" -> Some(Saturday)
    "sunday" -> Some(Sunday)
    _ -> None
  }
}
