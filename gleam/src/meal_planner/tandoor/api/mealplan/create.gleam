/// MealPlan Create API
///
/// This module provides functions to create meal plan entries in the Tandoor API.
import gleam/option
import meal_planner/tandoor/client.{
  type ClientConfig, type CreateMealPlanRequest, type MealPlanEntry,
  type TandoorError, CreateMealPlanRequest,
}
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/types/mealplan/mealplan.{type MealPlanCreate}

/// Create a new meal plan entry in Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `data` - Meal plan data to create
///
/// # Returns
/// Result with created meal plan entry or error
pub fn create_meal_plan(
  config: ClientConfig,
  data: MealPlanCreate,
) -> Result(MealPlanEntry, TandoorError) {
  // Convert SDK type to client type
  let request =
    CreateMealPlanRequest(
      recipe: data.recipe |> option.map(ids.recipe_id_to_int),
      recipe_name: data.recipe_name,
      servings: data.servings,
      note: data.note,
      from_date: data.from_date,
      to_date: data.to_date,
      meal_type: data.meal_type,
    )

  // Use the existing client method - delegate to it
  // This provides a cleaner API surface while reusing existing implementation
  client.create_meal_plan_entry(config, request)
}
