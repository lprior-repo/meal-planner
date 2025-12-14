/// MealPlan types for Tandoor SDK
///
/// This module defines types for meal planning functionality in the Tandoor API.
import gleam/option.{type Option}
import meal_planner/tandoor/core/ids.{type MealPlanId, type RecipeId}
import meal_planner/tandoor/types/recipe/recipe.{type Recipe}

/// Meal type enumeration
pub type MealType {
  Breakfast
  Lunch
  Dinner
  Snack
  Other
}

/// Full meal plan entry with all details
pub type MealPlan {
  MealPlan(
    id: MealPlanId,
    recipe: Option(Recipe),
    recipe_name: String,
    servings: Float,
    note: String,
    from_date: String,
    to_date: String,
    meal_type: MealType,
    created_by: Int,
  )
}

/// Request to create a meal plan entry
pub type MealPlanCreate {
  MealPlanCreate(
    recipe: Option(RecipeId),
    recipe_name: String,
    servings: Float,
    note: String,
    from_date: String,
    to_date: String,
    meal_type: MealType,
  )
}

/// Request to update a meal plan entry
pub type MealPlanUpdate {
  MealPlanUpdate(
    recipe: Option(RecipeId),
    recipe_name: String,
    servings: Float,
    note: String,
    from_date: String,
    to_date: String,
    meal_type: MealType,
  )
}

/// Convert MealType to API string
pub fn meal_type_to_string(meal_type: MealType) -> String {
  case meal_type {
    Breakfast -> "breakfast"
    Lunch -> "lunch"
    Dinner -> "dinner"
    Snack -> "snack"
    Other -> "other"
  }
}

/// Convert API string to MealType
pub fn meal_type_from_string(s: String) -> MealType {
  case s {
    "breakfast" -> Breakfast
    "lunch" -> Lunch
    "dinner" -> Dinner
    "snack" -> Snack
    _ -> Other
  }
}
