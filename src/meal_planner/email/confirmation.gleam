/// Email confirmation generator
///
/// Generates confirmation emails for executed email commands.
/// Templates include:
/// - Command summary (what was changed)
/// - Updated meal plan (if modified)
/// - Macro verification (still on track)
/// - Next steps or additional information
import gleam/option.{type Option, None, Some}
import gleam/string

import meal_planner/types.{
  type CommandExecutionResult, type EmailCommand, type Macros,
  type RegenerationScope, AddPreference, AdjustMeal, Breakfast,
  CommandExecutionResult, Dinner, Lunch, RegeneratePlan, RemoveDislike, SkipMeal,
  Snack,
}

// =============================================================================
// Email Confirmation Types
// =============================================================================

/// Confirmation email structure
pub type ConfirmationEmail {
  ConfirmationEmail(
    to_email: String,
    subject: String,
    body: String,
    html_body: String,
  )
}

/// Meal plan snapshot for confirmation
pub type MealPlanSnapshot {
  MealPlanSnapshot(
    day: String,
    breakfast: Option(String),
    lunch: Option(String),
    dinner: Option(String),
    snack: Option(String),
  )
}

// =============================================================================
// Confirmation Email Generator
// =============================================================================

/// Generate confirmation email from execution result
///
/// Returns email object with subject, plain text, and HTML body.
/// Tailored to command type with relevant information.
pub fn generate_confirmation(
  result: CommandExecutionResult,
  user_email: String,
) -> ConfirmationEmail {
  case result.command {
    Some(cmd) -> {
      let #(subject, body, html) =
        generate_email_content(cmd, result.success, result.message)
      ConfirmationEmail(
        to_email: user_email,
        subject: subject,
        body: body,
        html_body: html,
      )
    }
    None -> {
      // Fallback for commands without details
      ConfirmationEmail(
        to_email: user_email,
        subject: "Command Processed",
        body: result.message,
        html_body: "<p>" <> result.message <> "</p>",
      )
    }
  }
}

// =============================================================================
// Email Content Generators (Per Command Type)
// =============================================================================

fn generate_email_content(
  command: EmailCommand,
  success: Bool,
  message: String,
) -> #(String, String, String) {
  case command {
    AdjustMeal(day, meal_type, _recipe_id) ->
      generate_adjust_meal_email(day, meal_type, success, message)
    AddPreference(preference) ->
      generate_add_preference_email(preference, success, message)
    RemoveDislike(food_name) ->
      generate_remove_dislike_email(food_name, success, message)
    RegeneratePlan(scope, constraints) ->
      generate_regenerate_plan_email(scope, constraints, success, message)
    SkipMeal(day, meal_type) ->
      generate_skip_meal_email(day, meal_type, success, message)
  }
}

fn generate_adjust_meal_email(
  _day: types.DayOfWeek,
  _meal_type: types.MealType,
  _success: Bool,
  message: String,
) -> #(String, String, String) {
  #(
    "Meal Updated! 🍽️",
    "Your meal has been updated: " <> message,
    "<h2>Meal Updated! 🍽️</h2><p>" <> message <> "</p>",
  )
}

fn generate_add_preference_email(
  preference: String,
  _success: Bool,
  message: String,
) -> #(String, String, String) {
  #(
    "Preference Added ✓",
    "Added preference: " <> preference <> ". " <> message,
    "<h2>Preference Added ✓</h2><p>Added preference: " <> preference <> "</p>",
  )
}

fn generate_remove_dislike_email(
  food: String,
  _success: Bool,
  message: String,
) -> #(String, String, String) {
  #(
    "Dislike Noted ✓",
    "Added " <> food <> " to dislikes. " <> message,
    "<h2>Dislike Noted ✓</h2><p>Added " <> food <> " to dislikes.</p>",
  )
}

fn generate_regenerate_plan_email(
  _scope: RegenerationScope,
  _constraints: Option(String),
  _success: Bool,
  message: String,
) -> #(String, String, String) {
  #(
    "Plan Regeneration Started 🔄",
    "Regeneration started: " <> message,
    "<h2>Plan Regeneration Started 🔄</h2><p>" <> message <> "</p>",
  )
}

fn generate_skip_meal_email(
  _day: types.DayOfWeek,
  _meal_type: types.MealType,
  _success: Bool,
  message: String,
) -> #(String, String, String) {
  #(
    "Meal Skipped ✓",
    "Meal marked as skipped: " <> message,
    "<h2>Meal Skipped ✓</h2><p>" <> message <> "</p>",
  )
}

// =============================================================================
// Helper Functions
// =============================================================================

fn meal_type_to_string(meal: types.MealType) -> String {
  case meal {
    Breakfast -> "Breakfast"
    Lunch -> "Lunch"
    Dinner -> "Dinner"
    Snack -> "Snack"
  }
}

fn day_to_string(day: types.DayOfWeek) -> String {
  case day {
    types.Monday -> "Monday"
    types.Tuesday -> "Tuesday"
    types.Wednesday -> "Wednesday"
    types.Thursday -> "Thursday"
    types.Friday -> "Friday"
    types.Saturday -> "Saturday"
    types.Sunday -> "Sunday"
  }
}
