/// MealPlan encoder for Tandoor SDK
///
/// This module encodes MealPlan types to JSON for the Tandoor API.
import gleam/json.{type Json}
import gleam/option.{type Option}
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/types/mealplan/mealplan.{
  type MealPlanCreate, type MealPlanUpdate, MealPlanCreate, MealPlanUpdate,
}

/// Encode MealPlanCreate to JSON
pub fn encode_meal_plan_create(create: MealPlanCreate) -> Json {
  let MealPlanCreate(
    recipe,
    recipe_name,
    servings,
    note,
    from_date,
    to_date,
    meal_type,
  ) = create

  json.object([
    #("recipe", encode_optional_recipe_id(recipe)),
    #("recipe_name", json.string(recipe_name)),
    #("servings", json.float(servings)),
    #("note", json.string(note)),
    #("from_date", json.string(from_date)),
    #("to_date", json.string(to_date)),
    #("meal_type", json.string(mealplan.meal_type_to_string(meal_type))),
  ])
}

/// Encode MealPlanUpdate to JSON
pub fn encode_meal_plan_update(update: MealPlanUpdate) -> Json {
  let MealPlanUpdate(
    recipe,
    recipe_name,
    servings,
    note,
    from_date,
    to_date,
    meal_type,
  ) = update

  json.object([
    #("recipe", encode_optional_recipe_id(recipe)),
    #("recipe_name", json.string(recipe_name)),
    #("servings", json.float(servings)),
    #("note", json.string(note)),
    #("from_date", json.string(from_date)),
    #("to_date", json.string(to_date)),
    #("meal_type", json.string(mealplan.meal_type_to_string(meal_type))),
  ])
}

/// Helper to encode optional recipe ID
fn encode_optional_recipe_id(recipe: Option(ids.RecipeId)) -> Json {
  case recipe {
    option.Some(id) -> json.int(ids.recipe_id_to_int(id))
    option.None -> json.null()
  }
}
