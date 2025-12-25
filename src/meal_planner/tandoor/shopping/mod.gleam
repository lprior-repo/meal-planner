/// Tandoor Shopping List module
///
/// Re-exports types and provides API client functions for shopping lists.
import meal_planner/tandoor/shopping/types as types

pub type ShoppingList = types.ShoppingList
pub type ShoppingListCreate = types.ShoppingListCreate
pub type ShoppingListUpdate = types.ShoppingListUpdate
pub type ShoppingListEntry = types.ShoppingListEntry
pub type ShoppingListEntryCreate = types.ShoppingListEntryCreate
pub type ShoppingListEntryResponse = types.ShoppingListEntryResponse
pub type ShoppingListQuery = types.ShoppingListQuery
pub type ShoppingListRecipe = types.ShoppingListRecipe
pub type ShoppingListRecipeCreate = types.ShoppingListRecipeCreate
pub type ShoppingListRecipeUpdate = types.ShoppingListRecipeUpdate

// Placeholder functions for API calls
// These would normally call the Tandoor API

/// List shopping list entries
pub fn list_entries(
  _config: Nil,
  _query: ShoppingListQuery,
) -> Result(List(ShoppingListEntryResponse), String) {
  Ok([])
}

/// Create a shopping list entry
pub fn create_entry(
  _config: Nil,
  _entry: ShoppingListEntryCreate,
) -> Result(ShoppingListEntryResponse, String) {
  Error("Not implemented")
}

/// Get a single shopping list entry
pub fn get_entry(
  _config: Nil,
  _entry_id: Int,
) -> Result(ShoppingListEntryResponse, String) {
  Error("Not implemented")
}

/// Delete a shopping list entry
pub fn delete_entry(
  _config: Nil,
  _entry_id: Int,
) -> Result(Nil, String) {
  Error("Not implemented")
}

/// Add a recipe to a shopping list
pub fn add_recipe_to_shopping_list(
  _config: Nil,
  _list_id: Int,
  _recipe_id: Int,
  _servings: Int,
) -> Result(Nil, String) {
  Error("Not implemented")
}
