/// MealPlan Update/Delete API
///
/// This module provides functions to update and delete meal plan entries in the Tandoor API.
import meal_planner/tandoor/client.{
  type ClientConfig, type MealPlanEntry, type TandoorError,
}
import meal_planner/tandoor/core/ids.{type MealPlanId}
import meal_planner/tandoor/types/mealplan/mealplan.{type MealPlanUpdate}

/// Update a meal plan entry in Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `id` - Meal plan entry ID to update
/// * `data` - Updated meal plan data
///
/// # Returns
/// Result with updated meal plan entry or error
///
/// # Note
/// The Tandoor API may not support PATCH updates for meal plans.
/// This function is a placeholder for when the API supports it.
pub fn update_meal_plan(
  _config: ClientConfig,
  _id: MealPlanId,
  _data: MealPlanUpdate,
) -> Result(MealPlanEntry, TandoorError) {
  // TODO: Implement when Tandoor API provides a PATCH endpoint for meal plans
  Error(client.BadRequestError(
    "update_meal_plan not yet supported - delete and recreate instead",
  ))
}

/// Delete a meal plan entry from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `id` - Meal plan entry ID to delete
///
/// # Returns
/// Result with unit or error
pub fn delete_meal_plan(
  config: ClientConfig,
  id: MealPlanId,
) -> Result(Nil, TandoorError) {
  // Convert SDK type to raw int for client
  let entry_id = ids.meal_plan_id_to_int(id)

  // Use the existing client method - delegate to it
  client.delete_meal_plan_entry(config, entry_id)
}
