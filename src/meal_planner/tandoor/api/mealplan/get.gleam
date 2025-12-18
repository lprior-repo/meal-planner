/// MealPlan Get API
///
/// This module provides functions to get a single meal plan entry from the Tandoor API.
import meal_planner/tandoor/api/generic_crud
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/core/ids.{type MealPlanId}
import meal_planner/tandoor/decoders/mealplan/meal_plan_decoder
import meal_planner/tandoor/types/mealplan/meal_plan_entry.{type MealPlanEntry}

/// Get a single meal plan entry by ID from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `id` - Meal plan entry ID
///
/// # Returns
/// Result with meal plan entry or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = get_meal_plan(config, id: meal_plan_id)
/// ```
pub fn get_meal_plan(
  config: ClientConfig,
  id: MealPlanId,
) -> Result(MealPlanEntry, TandoorError) {
  generic_crud.get(
    config,
    "/api/meal-plan/",
    ids.meal_plan_id_to_int(id),
    meal_plan_decoder.meal_plan_entry_decoder(),
  )
}
