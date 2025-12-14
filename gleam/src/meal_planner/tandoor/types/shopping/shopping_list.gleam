/// ShoppingList types for Tandoor SDK
///
/// This module defines the main shopping list container type.
/// A shopping list aggregates multiple shopping list entries and provides
/// organization for grocery shopping.
import gleam/option.{type Option}
import meal_planner/tandoor/core/ids.{type ShoppingListId, type UserId}
import meal_planner/tandoor/types/shopping/shopping_list_entry.{
  type ShoppingListEntry,
}

/// Represents a complete shopping list with all entries
///
/// A shopping list is a container for shopping list entries that can be
/// organized by category, checked off, and shared with other users.
pub type ShoppingList {
  ShoppingList(
    /// Shopping list ID
    id: ShoppingListId,
    /// Optional name/title for the shopping list
    name: Option(String),
    /// All entries in this shopping list
    entries: List(ShoppingListEntry),
    /// User who created this shopping list
    created_by: UserId,
    /// Creation timestamp (ISO 8601)
    created_at: String,
    /// Last update timestamp (ISO 8601)
    updated_at: String,
  )
}

/// Request to create a new shopping list
pub type ShoppingListCreate {
  ShoppingListCreate(
    /// Optional name for the shopping list
    name: Option(String),
  )
}

/// Request to update a shopping list
pub type ShoppingListUpdate {
  ShoppingListUpdate(
    /// Optional name for the shopping list
    name: Option(String),
  )
}
