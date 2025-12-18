/// MealPlan Update/Delete API
///
/// This module provides functions to update and delete meal plan entries in the Tandoor API.
import gleam/int
import gleam/json
import gleam/result
import meal_planner/tandoor/api/crud_helpers
import meal_planner/tandoor/api/generic_crud
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/core/ids.{type MealPlanId}
import meal_planner/tandoor/decoders/mealplan/meal_plan_decoder
import meal_planner/tandoor/encoders/mealplan/mealplan_encoder
import meal_planner/tandoor/types/mealplan/meal_plan_entry.{type MealPlanEntry}
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
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let data = MealPlanUpdate(
///   recipe: Some(recipe_id),
///   recipe_name: "Updated Dinner",
///   servings: 6.0,
///   note: "More guests",
///   from_date: "2024-01-15",
///   to_date: "2024-01-15",
///   meal_type: Dinner,
/// )
/// let result = update_meal_plan(config, id: meal_plan_id, data: data)
/// ```
pub fn update_meal_plan(
  config: ClientConfig,
  id: MealPlanId,
  data: MealPlanUpdate,
) -> Result(MealPlanEntry, TandoorError) {
  let body =
    mealplan_encoder.encode_meal_plan_update(data)
    |> json.to_string

  generic_crud.update(
    config,
    "/api/meal-plan/",
    ids.meal_plan_id_to_int(id),
    body,
    meal_plan_decoder.meal_plan_entry_decoder(),
  )
}

/// Delete a meal plan entry from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `id` - Meal plan entry ID to delete
///
/// # Returns
/// Result with unit or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = delete_meal_plan(config, id: meal_plan_id)
/// ```
pub fn delete_meal_plan(
  config: ClientConfig,
  id: MealPlanId,
) -> Result(Nil, TandoorError) {
  let path =
    "/api/meal-plan/" <> int.to_string(ids.meal_plan_id_to_int(id)) <> "/"

  // Execute DELETE request using CRUD helpers
  use _resp <- result.try(crud_helpers.execute_delete(config, path))

  // DELETE returns 204 No Content on success
  Ok(Nil)
}
