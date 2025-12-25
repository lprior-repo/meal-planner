/// Tandoor Shopping List module
///
/// Re-exports types and provides API client functions for shopping lists.
import gleam/option
import meal_planner/tandoor/client
import meal_planner/tandoor/core/pagination.{type PaginatedResponse}
import meal_planner/tandoor/shopping/types.{
  type ShoppingList, type ShoppingListCreate, type ShoppingListEntry,
  type ShoppingListEntryCreate, type ShoppingListEntryResponse,
  type ShoppingListEntryUpdate, type ShoppingListQuery, type ShoppingListRecipe,
  type ShoppingListRecipeCreate, type ShoppingListRecipeUpdate,
  type ShoppingListUpdate, ShoppingList, ShoppingListCreate, ShoppingListEntry,
  ShoppingListEntryCreate, ShoppingListEntryResponse, ShoppingListEntryUpdate,
  ShoppingListQuery, ShoppingListRecipe, ShoppingListRecipeCreate,
  ShoppingListRecipeUpdate, ShoppingListUpdate,
}

// Placeholder functions for API calls
// These would normally call the Tandoor API

/// List shopping list entries
pub fn list_entries(
  _config: client.ClientConfig,
  _query: ShoppingListQuery,
) -> Result(PaginatedResponse(ShoppingListEntryResponse), String) {
  Ok(
    pagination.PaginatedResponse(
      count: 0,
      next: option.None,
      previous: option.None,
      results: [],
    ),
  )
}

/// Create a shopping list entry
pub fn create_entry(
  _config: client.ClientConfig,
  _entry: ShoppingListEntryCreate,
) -> Result(ShoppingListEntryResponse, String) {
  Error("Not implemented")
}

/// Get a single shopping list entry
pub fn get_entry(
  _config: client.ClientConfig,
  _entry_id: Int,
) -> Result(ShoppingListEntryResponse, String) {
  Error("Not implemented")
}

/// Delete a shopping list entry
pub fn delete_entry(
  _config: client.ClientConfig,
  _entry_id: Int,
) -> Result(Nil, String) {
  Error("Not implemented")
}

/// Update a shopping list entry
pub fn update_entry(
  _config: client.ClientConfig,
  _entry_id: Int,
  _data: ShoppingListEntryUpdate,
) -> Result(ShoppingListEntryResponse, String) {
  Error("Not implemented")
}

/// Add a recipe to a shopping list
pub fn add_recipe_to_shopping_list(
  _config: client.ClientConfig,
  _list_id: Int,
  _recipe_id: Int,
  _servings: Int,
) -> Result(Nil, String) {
  Error("Not implemented")
}
