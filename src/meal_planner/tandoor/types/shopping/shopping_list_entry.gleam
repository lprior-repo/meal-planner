/// ShoppingListEntry types for Tandoor SDK
///
/// This module defines types for shopping list entry functionality.
/// Shopping list entries represent individual items on a shopping list.
///
/// Based on Tandoor API 2.3.6 specification.
import gleam/option.{type Option}
import meal_planner/tandoor/core/ids.{
  type IngredientId, type ShoppingListEntryId, type ShoppingListId, type UserId,
}
import meal_planner/tandoor/types/food/food.{type Food}
import meal_planner/tandoor/types/shopping/shopping_list_recipe.{
  type ShoppingListRecipe,
}
import meal_planner/tandoor/types/unit/unit.{type Unit}
import meal_planner/tandoor/types/user/user.{type User}

/// Represents a single item on a shopping list
///
/// ShoppingListEntry contains full object references (not just IDs) for:
/// - food: Full Food object (not just FoodId)
/// - unit: Full Unit object (not just UnitId)
/// - created_by: Full User object (not just UserId)
/// - list_recipe_data: Related ShoppingListRecipe data (readonly)
pub type ShoppingListEntry {
  ShoppingListEntry(
    /// Entry ID
    id: ShoppingListEntryId,
    /// Associated shopping list recipe ID (optional)
    list_recipe: Option(ShoppingListId),
    /// Food item - full object (optional)
    food: Option(Food),
    /// Unit of measurement - full object (optional)
    unit: Option(Unit),
    /// Amount/quantity
    amount: Float,
    /// Display order in the list
    order: Int,
    /// Whether this item has been checked off
    checked: Bool,
    /// Associated ingredient ID (optional)
    ingredient: Option(IngredientId),
    /// User who created this entry - full object
    created_by: User,
    /// Associated recipe data (readonly)
    list_recipe_data: Option(ShoppingListRecipe),
    /// Creation timestamp (ISO 8601)
    created_at: String,
    /// Last update timestamp (ISO 8601)
    updated_at: String,
    /// When the item was checked/completed (optional)
    completed_at: Option(String),
    /// Delay display until this date (optional)
    delay_until: Option(String),
  )
}

/// Request to create a shopping list entry
pub type ShoppingListEntryCreate {
  ShoppingListEntryCreate(
    list_recipe: Option(ShoppingListId),
    food: Option(Int),
    unit: Option(Int),
    amount: Float,
    order: Int,
    checked: Bool,
    ingredient: Option(IngredientId),
    completed_at: Option(String),
    delay_until: Option(String),
    /// Mealplan ID for auto-linking
    mealplan_id: Option(Int),
  )
}

/// Request to update a shopping list entry
pub type ShoppingListEntryUpdate {
  ShoppingListEntryUpdate(
    list_recipe: Option(ShoppingListId),
    food: Option(Int),
    unit: Option(Int),
    amount: Float,
    order: Int,
    checked: Bool,
    ingredient: Option(IngredientId),
    completed_at: Option(String),
    delay_until: Option(String),
  )
}
