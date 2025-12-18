/// ShoppingListRecipe types for Tandoor SDK
///
/// This module defines types for recipe-based shopping lists.
/// A ShoppingListRecipe represents a collection of ingredients from a recipe or meal plan.
import gleam/option.{type Option}
import meal_planner/tandoor/core/ids.{
  type MealPlanId, type RecipeId, type ShoppingListId, type UserId,
}

/// Represents a recipe-based shopping list
pub type ShoppingListRecipe {
  ShoppingListRecipe(
    /// Shopping list ID
    id: ShoppingListId,
    /// Name of the shopping list
    name: String,
    /// Associated recipe ID (optional)
    recipe: Option(RecipeId),
    /// Associated meal plan ID (optional)
    mealplan: Option(MealPlanId),
    /// Number of servings this list is for
    servings: Float,
    /// User who created this shopping list
    created_by: UserId,
  )
}

/// Request to create a shopping list from a recipe
pub type ShoppingListRecipeCreate {
  ShoppingListRecipeCreate(
    name: String,
    recipe: Option(RecipeId),
    mealplan: Option(MealPlanId),
    servings: Float,
  )
}

/// Request to update a shopping list
pub type ShoppingListRecipeUpdate {
  ShoppingListRecipeUpdate(
    name: String,
    recipe: Option(RecipeId),
    mealplan: Option(MealPlanId),
    servings: Float,
  )
}
