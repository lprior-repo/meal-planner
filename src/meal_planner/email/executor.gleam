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
  conn: pog.Connection,
) -> CommandExecutionResult {
  // Update meal plan table for specific day and meal type
  let sql =
    "UPDATE meal_plan 
     SET recipe_id = $1, updated_at = NOW()
     WHERE day_of_week = $2 AND meal_type = $3
     RETURNING id"

  let day_str = day_to_string(day)
  let meal_str = meal_type_to_string(meal_type)
  let recipe_id_str = id.recipe_id_to_string(recipe_id)

  case
    pog.query(sql)
    |> pog.parameter(pog.text(recipe_id_str))
    |> pog.parameter(pog.text(day_str))
    |> pog.parameter(pog.text(meal_str))
    |> pog.execute(conn)
  {
    Ok(pog.Returned(count: count, rows: _)) if count > 0 ->
      CommandExecutionResult(
        success: True,
        message: "Updated "
          <> meal_str
          <> " for "
          <> day_str
          <> " to recipe "
          <> recipe_id_str,
        command: Some(AdjustMeal(day, meal_type, recipe_id)),
      )
    Ok(pog.Returned(count: 0, rows: _)) ->
      CommandExecutionResult(
        success: False,
        message: "No meal plan entry found for "
          <> day_str
          <> " "
          <> meal_str,
        command: Some(AdjustMeal(day, meal_type, recipe_id)),
      )
    Error(_) ->
      CommandExecutionResult(
        success: False,
        message: "Database error updating meal plan",
        command: Some(AdjustMeal(day, meal_type, recipe_id)),
      )
  }
}

fn execute_add_preference(
  preference: String,
  conn: pog.Connection,
) -> CommandExecutionResult {
  // Store preference in user_preferences table
  let sql =
    "INSERT INTO user_preferences (user_id, preference_type, preference_value, created_at)
     VALUES (1, 'general', $1, NOW())
     ON CONFLICT (user_id, preference_type, preference_value) DO NOTHING
     RETURNING id"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(preference))
    |> pog.execute(conn)
  {
    Ok(pog.Returned(count: count, rows: _)) if count > 0 ->
      CommandExecutionResult(
        success: True,
        message: "Added preference: " <> preference,
        command: Some(AddPreference(preference)),
      )
    Ok(pog.Returned(count: 0, rows: _)) ->
      CommandExecutionResult(
        success: True,
        message: "Preference already exists: " <> preference,
        command: Some(AddPreference(preference)),
      )
    Error(_) ->
      CommandExecutionResult(
        success: False,
        message: "Database error adding preference",
        command: Some(AddPreference(preference)),
      )
  }
}

fn execute_remove_dislike(
  food_name: String,
  conn: pog.Connection,
) -> CommandExecutionResult {
  // Add food to disliked_foods table
  let sql =
    "INSERT INTO disliked_foods (user_id, food_name, created_at)
     VALUES (1, $1, NOW())
     ON CONFLICT (user_id, food_name) DO NOTHING
     RETURNING id"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(food_name))
    |> pog.execute(conn)
  {
    Ok(pog.Returned(count: count, rows: _)) if count > 0 ->
      CommandExecutionResult(
        success: True,
        message: "Added to dislike list: " <> food_name,
        command: Some(RemoveDislike(food_name)),
      )
    Ok(pog.Returned(count: 0, rows: _)) ->
      CommandExecutionResult(
        success: True,
        message: "Food already in dislike list: " <> food_name,
        command: Some(RemoveDislike(food_name)),
      )
    Error(_) ->
      CommandExecutionResult(
        success: False,
        message: "Database error adding to dislike list",
        command: Some(RemoveDislike(food_name)),
      )
  }
}

fn execute_regenerate_plan(
  scope: RegenerationScope,
  constraints: Option(String),
  conn: pog.Connection,
) -> CommandExecutionResult {
  // Create a regeneration job in the scheduler
  let scope_str = regeneration_scope_to_string(scope)
  let constraint_msg = case constraints {
    Some(c) -> " with constraint: " <> c
    None -> ""
  }

  // Insert regeneration job into scheduled_jobs table
  let sql =
    "INSERT INTO scheduled_jobs (job_type, scope, constraints, status, created_at)
     VALUES ('regenerate_plan', $1, $2, 'pending', NOW())
     RETURNING id"

  let constraints_value = case constraints {
    Some(c) -> pog.nullable(pog.text, Some(c))
    None -> pog.null()
  }

  case
    pog.query(sql)
    |> pog.parameter(pog.text(scope_str))
    |> pog.parameter(constraints_value)
    |> pog.execute(conn)
  {
    Ok(pog.Returned(count: count, rows: _)) if count > 0 ->
      CommandExecutionResult(
        success: True,
        message: "Scheduled regeneration for " <> scope_str <> constraint_msg,
        command: Some(RegeneratePlan(scope, constraints)),
      )
    Ok(pog.Returned(count: 0, rows: _)) ->
      CommandExecutionResult(
        success: False,
        message: "Failed to schedule regeneration job",
        command: Some(RegeneratePlan(scope, constraints)),
      )
    Error(_) ->
      CommandExecutionResult(
        success: False,
        message: "Database error scheduling regeneration",
        command: Some(RegeneratePlan(scope, constraints)),
      )
  }
}

fn execute_skip_meal(
  day: DayOfWeek,
  meal_type: MealType,
  conn: pog.Connection,
) -> CommandExecutionResult {
  // Mark meal as skipped in the meal_plan table
  let sql =
    "UPDATE meal_plan 
     SET skipped = true, updated_at = NOW()
     WHERE day_of_week = $1 AND meal_type = $2
     RETURNING id"

  let day_str = day_to_string(day)
  let meal_str = meal_type_to_string(meal_type)

  case
    pog.query(sql)
    |> pog.parameter(pog.text(day_str))
    |> pog.parameter(pog.text(meal_str))
    |> pog.execute(conn)
  {
    Ok(pog.Returned(count: count, rows: _)) if count > 0 ->
      CommandExecutionResult(
        success: True,
        message: "Skipped " <> meal_str <> " on " <> day_str,
        command: Some(SkipMeal(day, meal_type)),
      )
    Ok(pog.Returned(count: 0, rows: _)) ->
      CommandExecutionResult(
        success: False,
        message: "No meal plan entry found for " <> day_str <> " " <> meal_str,
        command: Some(SkipMeal(day, meal_type)),
      )
    Error(_) ->
      CommandExecutionResult(
        success: False,
        message: "Database error marking meal as skipped",
        command: Some(SkipMeal(day, meal_type)),
      )
  }
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
