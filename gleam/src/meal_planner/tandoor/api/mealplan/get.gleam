/// MealPlan Get API
///
/// This module provides functions to get a single meal plan entry from the Tandoor API.
import meal_planner/tandoor/client.{
  type ClientConfig, type MealPlanEntry, type TandoorError,
}
import meal_planner/tandoor/core/ids.{type MealPlanId}

/// Get a single meal plan entry by ID from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `id` - Meal plan entry ID
///
/// # Returns
/// Result with meal plan entry or error
///
/// # Note
/// The Tandoor API uses the list endpoint for filtering, so this function
/// will need to be implemented differently or may require client.gleam updates.
/// For now, this is a placeholder that would need a dedicated endpoint.
pub fn get_meal_plan(
  _config: ClientConfig,
  _id: MealPlanId,
) -> Result(MealPlanEntry, TandoorError) {
  // TODO: Implement when Tandoor API provides a get-by-id endpoint
  // or extend client.gleam to support this pattern
  Error(client.BadRequestError(
    "get_meal_plan by ID not yet supported - use list_meal_plans with filters",
  ))
}
