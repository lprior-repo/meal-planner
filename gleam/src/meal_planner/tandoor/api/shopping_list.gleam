/// Shopping List API - Complete CRUD operations
///
/// This module provides all shopping list operations using CRUD helpers.
/// Consolidates: get, list, create, update, delete, and recipe operations.
///
/// **Refactored**: Uses crud_helpers for 60%+ line reduction
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option}
import gleam/result
import meal_planner/tandoor/api/crud_helpers
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/core/http.{type PaginatedResponse}
import meal_planner/tandoor/decoders/shopping/shopping_list_entry_decoder
import meal_planner/tandoor/encoders/shopping/shopping_list_encoder
import meal_planner/tandoor/types/shopping/shopping_list_entry.{
  type ShoppingListEntry, type ShoppingListEntryCreate,
  type ShoppingListEntryUpdate,
}

// ============================================================================
// Get Single Entry
// ============================================================================

/// Get a single shopping list entry by ID
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = get(config, 42)
/// ```
pub fn get(
  config: ClientConfig,
  id: Int,
) -> Result(ShoppingListEntry, TandoorError) {
  let path = "/api/shopping-list-entry/" <> int.to_string(id) <> "/"
  use resp <- result.try(crud_helpers.execute_get(config, path, []))
  crud_helpers.parse_json_single(resp, shopping_list_entry_decoder.decoder())
}

// ============================================================================
// List Entries with Filtering
// ============================================================================

/// List shopping list entries with optional filtering and pagination
///
/// # Arguments
/// * `checked` - Filter by checked status (true/false)
/// * `limit` - Number of results per page
/// * `offset` - Offset for pagination
///
/// # Example
/// ```gleam
/// // Get unchecked items
/// let result = list(config, Some(False), Some(20), Some(0))
/// // Get all items
/// let all = list(config, None, None, None)
/// ```
pub fn list(
  config: ClientConfig,
  checked: Option(Bool),
  limit: Option(Int),
  offset: Option(Int),
) -> Result(PaginatedResponse(ShoppingListEntry), TandoorError) {
  let params = build_query_params(checked, limit, offset)
  use resp <- result.try(crud_helpers.execute_get(
    config,
    "/api/shopping-list-entry/",
    params,
  ))
  crud_helpers.parse_json_paginated(
    resp,
    shopping_list_entry_decoder.decode_entry(),
  )
}

// ============================================================================
// Create Entry
// ============================================================================

/// Create a new shopping list entry
///
/// # Example
/// ```gleam
/// let entry = ShoppingListEntryCreate(
///   list_recipe: None,
///   food: Some(food_id(42)),
///   unit: Some(unit_id(1)),
///   amount: 2.5,
///   order: 0,
///   checked: False,
///   ingredient: None,
///   completed_at: None,
///   delay_until: None,
///   mealplan_id: None,
/// )
/// let result = create(config, entry)
/// ```
pub fn create(
  config: ClientConfig,
  data: ShoppingListEntryCreate,
) -> Result(ShoppingListEntry, TandoorError) {
  let body =
    shopping_list_encoder.encode_entry_create(data)
    |> json.to_string

  use resp <- result.try(crud_helpers.execute_post(
    config,
    "/api/shopping-list-entry/",
    body,
  ))
  crud_helpers.parse_json_single(resp, shopping_list_entry_decoder.decoder())
}

// ============================================================================
// Update Entry
// ============================================================================

/// Update an existing shopping list entry
///
/// # Example
/// ```gleam
/// let updates = ShoppingListEntryUpdate(
///   amount: 3.0,
///   checked: True,
///   completed_at: Some("2025-12-14T10:30:00Z"),
///   ..
/// )
/// let result = update(config, 42, updates)
/// ```
pub fn update(
  config: ClientConfig,
  id: Int,
  data: ShoppingListEntryUpdate,
) -> Result(ShoppingListEntry, TandoorError) {
  let path = "/api/shopping-list-entry/" <> int.to_string(id) <> "/"
  let body =
    shopping_list_encoder.encode_entry_update(data)
    |> json.to_string

  use resp <- result.try(crud_helpers.execute_patch(config, path, body))
  crud_helpers.parse_json_single(resp, shopping_list_entry_decoder.decoder())
}

// ============================================================================
// Delete Entry
// ============================================================================

/// Delete a shopping list entry
///
/// # Example
/// ```gleam
/// let result = delete(config, 42)
/// ```
pub fn delete(config: ClientConfig, id: Int) -> Result(Nil, TandoorError) {
  let path = "/api/shopping-list-entry/" <> int.to_string(id) <> "/"
  use resp <- result.try(crud_helpers.execute_delete(config, path))
  crud_helpers.parse_empty_response(resp)
}

// ============================================================================
// Add Recipe to Shopping List
// ============================================================================

/// Add a recipe to the shopping list
///
/// Creates shopping list entries for all ingredients in the specified recipe.
///
/// # Example
/// ```gleam
/// let result = add_recipe(config, recipe_id: 123, servings: 4)
/// ```
pub fn add_recipe(
  config: ClientConfig,
  recipe_id: Int,
  servings: Int,
) -> Result(List(ShoppingListEntry), TandoorError) {
  let body =
    json.object([
      #("recipe", json.int(recipe_id)),
      #("servings", json.int(servings)),
    ])
    |> json.to_string

  use resp <- result.try(crud_helpers.execute_post(
    config,
    "/api/shopping-list-recipe/",
    body,
  ))
  crud_helpers.parse_json_list(resp, shopping_list_entry_decoder.decoder())
}

// ============================================================================
// Private Helpers
// ============================================================================

/// Build query parameters from optional filters
fn build_query_params(
  checked: Option(Bool),
  limit: Option(Int),
  offset: Option(Int),
) -> List(#(String, String)) {
  let checked_param = case checked {
    option.Some(True) -> [#("checked", "true")]
    option.Some(False) -> [#("checked", "false")]
    option.None -> []
  }

  let limit_param = case limit {
    option.Some(l) -> [#("page_size", int.to_string(l))]
    option.None -> []
  }

  let offset_param = case offset {
    option.Some(o) -> [#("offset", int.to_string(o))]
    option.None -> []
  }

  // Concatenate all non-empty parameter lists
  list.concat([checked_param, limit_param, offset_param])
}
