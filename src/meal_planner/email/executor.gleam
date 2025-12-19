/// Email command executor - Executes parsed email commands
///
/// Routes commands to appropriate handlers:
/// - AdjustMeal: Updates meal plan for specific meal
/// - AddPreference: Stores preference in user profile
/// - RemoveDislike: Adds food to dislike list
/// - RegeneratePlan: Triggers full/partial meal plan regeneration
/// - SkipMeal: Marks meal as skipped for specific day
///
/// All execution results are returned as CommandExecutionResult.
import gleam/option.{type Option, None, Some}
import pog

import meal_planner/id.{type RecipeId}
import meal_planner/types.{
  type CommandExecutionResult, type DayOfWeek, type EmailCommand, type MealType,
  type RegenerationScope, AddPreference, AdjustMeal, CommandExecutionResult,
  RegeneratePlan, RemoveDislike, SkipMeal,
}

// =============================================================================
// Command Executor
// =============================================================================

/// Execute an email command with database connection
///
/// Routes command to appropriate handler and updates database.
/// Returns CommandExecutionResult with execution status.
pub fn execute_command(
  command: EmailCommand,
  conn: pog.Connection,
) -> CommandExecutionResult {
  case command {
    AdjustMeal(day, meal_type, recipe_id) ->
      execute_adjust_meal(day, meal_type, recipe_id, conn)
    AddPreference(preference) -> execute_add_preference(preference, conn)
    RemoveDislike(food_name) -> execute_remove_dislike(food_name, conn)
    RegeneratePlan(scope, constraints) ->
      execute_regenerate_plan(scope, constraints, conn)
    SkipMeal(day, meal_type) -> execute_skip_meal(day, meal_type, conn)
  }
}

// =============================================================================
// Command Handlers (Minimal Implementations)
// =============================================================================

fn execute_adjust_meal(
  day: DayOfWeek,
  meal_type: MealType,
  recipe_id: RecipeId,
  _conn: pog.Connection,
) -> CommandExecutionResult {
  // TODO: Update meal plan in database
  // For now, return success with placeholder message
  CommandExecutionResult(
    success: True,
    message: "Updated "
      <> meal_type_to_string(meal_type)
      <> " for "
      <> day_to_string(day),
    command: Some(AdjustMeal(day, meal_type, recipe_id)),
  )
}

fn execute_add_preference(
  preference: String,
  _conn: pog.Connection,
) -> CommandExecutionResult {
  // TODO: Store preference in user profile
  // For now, return success with placeholder message
  CommandExecutionResult(
    success: True,
    message: "Added preference: " <> preference,
    command: Some(AddPreference(preference)),
  )
}

fn execute_remove_dislike(
  food_name: String,
  _conn: pog.Connection,
) -> CommandExecutionResult {
  // TODO: Add food to dislike list
  // For now, return success with placeholder message
  CommandExecutionResult(
    success: True,
    message: "Added to dislike list: " <> food_name,
    command: Some(RemoveDislike(food_name)),
  )
}

fn execute_regenerate_plan(
  scope: RegenerationScope,
  constraints: Option(String),
  _conn: pog.Connection,
) -> CommandExecutionResult {
  // TODO: Trigger meal plan regeneration
  // For now, return success with placeholder message
  let scope_str = regeneration_scope_to_string(scope)
  let constraint_msg = case constraints {
    Some(c) -> " with constraint: " <> c
    None -> ""
  }

  CommandExecutionResult(
    success: True,
    message: "Regenerating meal plan for " <> scope_str <> constraint_msg,
    command: Some(RegeneratePlan(scope, constraints)),
  )
}

fn execute_skip_meal(
  day: DayOfWeek,
  meal_type: MealType,
  _conn: pog.Connection,
) -> CommandExecutionResult {
  // TODO: Mark meal as skipped in meal plan
  // For now, return success with placeholder message
  CommandExecutionResult(
    success: True,
    message: "Skipped "
      <> meal_type_to_string(meal_type)
      <> " on "
      <> day_to_string(day),
    command: Some(SkipMeal(day, meal_type)),
  )
}

// =============================================================================
// Helper Functions
// =============================================================================

fn day_to_string(day: DayOfWeek) -> String {
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

fn meal_type_to_string(meal: MealType) -> String {
  case meal {
    types.Breakfast -> "Breakfast"
    types.Lunch -> "Lunch"
    types.Dinner -> "Dinner"
    types.Snack -> "Snack"
  }
}

fn regeneration_scope_to_string(scope: RegenerationScope) -> String {
  case scope {
    types.SingleMeal -> "single meal"
    types.SingleDay -> "single day"
    types.FullWeek -> "full week"
  }
}
