/// MealPlan Create API
///
/// This module provides functions to create meal plan entries in the Tandoor API.
import gleam/json
import gleam/result
import meal_planner/tandoor/api/crud_helpers
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/decoders/mealplan/meal_plan_decoder
import meal_planner/tandoor/encoders/mealplan/mealplan_encoder
import meal_planner/tandoor/types/mealplan/meal_plan_entry.{type MealPlanEntry}
import meal_planner/tandoor/types/mealplan/mealplan.{type MealPlanCreate}

/// Create a new meal plan entry in Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `data` - Meal plan data to create
///
/// # Returns
/// Result with created meal plan entry or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let data = MealPlanCreate(
///   recipe: Some(recipe_id),
///   recipe_name: "Dinner",
///   servings: 4.0,
///   note: "Family dinner",
///   from_date: "2024-01-15",
///   to_date: "2024-01-15",
///   meal_type: Dinner,
/// )
/// let result = create_meal_plan(config, data)
/// ```
pub fn create_meal_plan(
  config: ClientConfig,
  data: MealPlanCreate,
) -> Result(MealPlanEntry, TandoorError) {
  let path = "/api/meal-plan/"

  // Encode meal plan data to JSON
  let request_body =
    mealplan_encoder.encode_meal_plan_create(data)
    |> json.to_string

  // Execute POST request using CRUD helpers
  use resp <- result.try(crud_helpers.execute_post(config, path, request_body))

  // Parse JSON response using meal plan entry decoder
  crud_helpers.parse_json_single(
    resp,
    meal_plan_decoder.meal_plan_entry_decoder(),
  )
}
