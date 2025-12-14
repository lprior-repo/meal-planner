/// ShoppingListEntry types for Tandoor SDK
///
/// This module defines types for shopping list entry functionality.
/// Shopping list entries represent individual items on a shopping list.
import gleam/option.{type Option}
import meal_planner/tandoor/core/ids.{
  type FoodId, type IngredientId, type ShoppingListEntryId, type ShoppingListId,
  type UnitId, type UserId,
}

/// Represents a single item on a shopping list
pub type ShoppingListEntry {
  ShoppingListEntry(
    /// Entry ID
    id: ShoppingListEntryId,
    /// Associated shopping list recipe ID (optional)
    list_recipe: Option(ShoppingListId),
    /// Food item (optional)
    food: Option(FoodId),
    /// Unit of measurement (optional)
    unit: Option(UnitId),
    /// Amount/quantity
    amount: Float,
    /// Display order in the list
    order: Int,
    /// Whether this item has been checked off
    checked: Bool,
    /// Associated ingredient ID (optional)
    ingredient: Option(IngredientId),
    /// User who created this entry
    created_by: UserId,
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
    food: Option(FoodId),
    unit: Option(UnitId),
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
    food: Option(FoodId),
    unit: Option(UnitId),
    amount: Float,
    order: Int,
    checked: Bool,
    ingredient: Option(IngredientId),
    completed_at: Option(String),
    delay_until: Option(String),
  )
}
