/// MealPlan Create API
///
/// This module provides functions to create meal plan entries in the Tandoor API.
import gleam/option
import meal_planner/tandoor/client.{
  type ClientConfig, type MealPlanEntry, type TandoorError, Breakfast as ClientBreakfast,
  CreateMealPlanRequest, Dinner as ClientDinner, Lunch as ClientLunch,
  Other as ClientOther, Snack as ClientSnack,
}
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/types/mealplan/mealplan.{
  type MealPlanCreate, type MealType, Breakfast, Dinner, Lunch, Other, Snack,
}

/// Convert SDK MealType to client MealType
fn convert_meal_type(mt: MealType) -> client.MealType {
  case mt {
    Breakfast -> ClientBreakfast
    Lunch -> ClientLunch
    Dinner -> ClientDinner
    Snack -> ClientSnack
    Other -> ClientOther
  }
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
    CreateMealPlanRequest(
      recipe: data.recipe |> option.map(ids.recipe_id_to_int),
      recipe_name: data.recipe_name,
      servings: data.servings,
      note: data.note,
      from_date: data.from_date,
      to_date: data.to_date,
      meal_type: convert_meal_type(data.meal_type),
    )

  // Use the existing client method - delegate to it
  // This provides a cleaner API surface while reusing existing implementation
  client.create_meal_plan_entry(config, request)
}
