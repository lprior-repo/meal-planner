/// MealPlan Create API
///
/// This module provides functions to create meal plan entries in the Tandoor API.
import gleam/option
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/types/mealplan/meal_plan_entry.{type MealPlanEntry}
import meal_planner/tandoor/types/mealplan/meal_type as client_meal_type
import meal_planner/tandoor/types/mealplan/mealplan.{
  type MealPlanCreate, type MealType, Breakfast, Dinner, Lunch, Other, Snack,
}

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
    client.CreateMealPlanRequest(
      title: data.recipe_name,
      recipe: data.recipe |> option.map(ids.recipe_id_to_int),
      servings: data.servings,
      note: data.note,
      from_date: data.from_date,
      to_date: data.to_date,
      meal_type: convert_meal_type_for_client(data.meal_type),
    )

  // Use the existing client method - delegate to it
  // This provides a cleaner API surface while reusing existing implementation
  client.create_meal_plan_entry(config, request)
}

/// Convert SDK MealType enum to client's MealType record
fn convert_meal_type_for_client(
  mt: MealType,
) -> client_meal_type.MealType {
  // The client uses meal_type.MealType which is a record type
  // We need to convert from the enum to a suitable record
  client_meal_type.meal_type_from_string(case mt {
    Breakfast -> "BREAKFAST"
    Lunch -> "LUNCH"
    Dinner -> "DINNER"
    Snack -> "SNACK"
    Other -> "OTHER"
  })
}
