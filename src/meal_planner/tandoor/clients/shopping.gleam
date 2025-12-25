/// Tandoor Shopping API Client
///
/// This module provides functions for interacting with the Tandoor Shopping API.
/// It handles shopping list operations: creation, retrieval, deletion, and item management.
///
/// Focus: API operations only
/// - CRUD operations on shopping lists and entries
/// - Query parameter building
/// - JSON encoding/decoding for requests and responses
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/logger
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, ParseError, build_delete_request,
  build_get_request, build_patch_request, build_post_request, execute_and_parse,
}
import meal_planner/tandoor/shopping.{
  type ShoppingListEntry, type ShoppingListEntryCreate,
  type ShoppingListEntryResponse, type ShoppingListEntryUpdate,
  shopping_list_entry_decoder, shopping_list_entry_response_decoder,
}

// ============================================================================
// Encoding Helpers
// ============================================================================

/// Encode optional ShoppingListId
fn encode_optional_shopping_list_id(id: Option(Int)) -> json.Json {
  case id {
    Some(id) -> json.int(id)
    None -> json.null()
  }
}

/// Encode optional FoodId
fn encode_optional_food_id(id: Option(Int)) -> json.Json {
  case id {
    Some(id) -> json.int(id)
    None -> json.null()
  }
}

/// Encode optional UnitId
fn encode_optional_unit_id(id: Option(Int)) -> json.Json {
  case id {
    Some(id) -> json.int(id)
    None -> json.null()
  }
}

/// Encode optional IngredientId
fn encode_optional_ingredient_id(id: Option(Int)) -> json.Json {
  case id {
    Some(id) -> json.int(id)
    None -> json.null()
  }
}

/// Encode optional String
fn encode_optional_string(value: Option(String)) -> json.Json {
  case value {
    Some(s) -> json.string(s)
    None -> json.null()
  }
}

/// Encode optional Int
fn encode_optional_int(value: Option(Int)) -> json.Json {
  case value {
    Some(i) -> json.int(i)
    None -> json.null()
  }
}

// ============================================================================
// Query Parameter Builders
// ============================================================================

/// Build query parameters for listing shopping list entries
///
/// # Arguments
/// * `checked` - Filter by checked status (true/false)
/// * `limit` - Number of results per page
/// * `offset` - Offset for pagination
///
/// # Returns
/// List of query parameter tuples
fn build_entry_query_params(
  checked: Option(Bool),
  limit: Option(Int),
  offset: Option(Int),
) -> List(#(String, String)) {
  let checked_param = case checked {
    Some(True) -> [#("checked", "true")]
    Some(False) -> [#("checked", "false")]
    None -> []
  }

  let limit_param = case limit {
    Some(l) -> [#("page_size", int.to_string(l))]
    None -> []
  }

  let offset_param = case offset {
    Some(o) -> [#("offset", int.to_string(o))]
    None -> []
  }

  list.flatten([checked_param, limit_param, offset_param])
}

// ============================================================================
// Entry Creation/Encoding
// ============================================================================

/// Encode a ShoppingListEntryCreate request to JSON
fn encode_shopping_list_entry_create(
  entry: ShoppingListEntryCreate,
) -> json.Json {
  let ShoppingListEntryCreate(
    list_recipe,
    food,
    unit,
    amount,
    order,
    checked,
    ingredient,
    completed_at,
    delay_until,
    mealplan_id,
  ) = entry

  json.object([
    #("list_recipe", encode_optional_shopping_list_id(list_recipe)),
    #("food", encode_optional_food_id(food)),
    #("unit", encode_optional_unit_id(unit)),
    #("amount", json.float(amount)),
    #("order", json.int(order)),
    #("checked", json.bool(checked)),
    #("ingredient", encode_optional_ingredient_id(ingredient)),
    #("completed_at", encode_optional_string(completed_at)),
    #("delay_until", encode_optional_string(delay_until)),
    #("mealplan_id", encode_optional_int(mealplan_id)),
  ])
}

/// Encode a ShoppingListEntryUpdate request to JSON
fn encode_shopping_list_entry_update(
  entry: ShoppingListEntryUpdate,
) -> json.Json {
  let ShoppingListEntryUpdate(
    list_recipe,
    food,
    unit,
    amount,
    order,
    checked,
    ingredient,
    completed_at,
    delay_until,
  ) = entry

  json.object([
    #("list_recipe", encode_optional_shopping_list_id(list_recipe)),
    #("food", encode_optional_food_id(food)),
    #("unit", encode_optional_unit_id(unit)),
    #("amount", json.float(amount)),
    #("order", json.int(order)),
    #("checked", json.bool(checked)),
    #("ingredient", encode_optional_ingredient_id(ingredient)),
    #("completed_at", encode_optional_string(completed_at)),
    #("delay_until", encode_optional_string(delay_until)),
  ])
}

// ============================================================================
// GET Operations
// ============================================================================

/// Get a single shopping list entry by ID
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `entry_id` - The ID of the entry to retrieve
///
/// # Returns
/// Result with shopping list entry or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// get_entry(config, entry_id: 42)
/// ```
pub fn get_entry(
  config: ClientConfig,
  entry_id entry_id: Int,
) -> Result(ShoppingListEntry, TandoorError) {
  let path = "/api/shopping-list-entry/" <> int.to_string(entry_id) <> "/"

  use req <- result.try(build_get_request(config, path, []))
  logger.debug("Tandoor GET " <> path)

  use resp <- result.try(execute_and_parse(req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, shopping_list_entry_decoder()) {
        Ok(entry) -> Ok(entry)
        Error(errors) -> {
          let error_msg =
            "Failed to decode entry: "
            <> string.join(
              list.map(errors, fn(e) {
                case e {
                  decode.DecodeError(expected, _found, path) ->
                    expected <> " at " <> string.join(path, ".")
                }
              }),
              ", ",
            )
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Invalid JSON response"))
  }
}

/// List shopping list entries with optional filtering and pagination
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `checked` - Filter by checked status (true/false)
/// * `limit` - Number of results per page
/// * `offset` - Offset for pagination
///
/// # Returns
/// Result with paginated response or error
///
/// # Example
/// ```gleam
/// // Get unchecked items
/// list_entries(config, checked: Some(False), limit: Some(20), offset: Some(0))
/// // Get all items
/// list_entries(config, checked: None, limit: None, offset: None)
/// ```
pub fn list_entries(
  config: ClientConfig,
  checked checked: Option(Bool),
  limit limit: Option(Int),
  offset offset: Option(Int),
) -> Result(
  #(List(ShoppingListEntryResponse), Int, Option(Int), Option(Int)),
  TandoorError,
) {
  let params = build_entry_query_params(checked, limit, offset)
  use req <- result.try(build_get_request(
    config,
    "/api/shopping-list-entry/",
    params,
  ))
  logger.debug("Tandoor GET /api/shopping-list-entry/")

  use resp <- result.try(execute_and_parse(req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case
        decode.run(json_data, fn(dyn) {
          use results <- decode.field(
            "results",
            decode.list(fn(d) {
              decode.run(d, shopping_list_entry_response_decoder())
            }),
          )
          use count <- decode.field("count", decode.int)
          use next <- decode.field("next", decode.optional(decode.string))
          use previous <- decode.field(
            "previous",
            decode.optional(decode.string),
          )
          decode.success(#(results, count, next, previous))
        })
      {
        Ok(#(items, count, next, previous)) ->
          Ok(#(items, count, next, previous))
        Error(errors) -> {
          let error_msg =
            "Failed to decode entries: "
            <> string.join(
              list.map(errors, fn(e) {
                case e {
                  decode.DecodeError(expected, _found, path) ->
                    expected <> " at " <> string.join(path, ".")
                }
              }),
              ", ",
            )
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Invalid JSON response"))
  }
}

// ============================================================================
// POST Operations (Create)
// ============================================================================

/// Create a new shopping list entry
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `data` - ShoppingListEntryCreate request object
///
/// # Returns
/// Result with created shopping list entry or error
///
/// # Example
/// ```gleam
/// let entry = ShoppingListEntryCreate(
///   list_recipe: None,
///   food: Some(42),
///   unit: Some(1),
///   amount: 2.5,
///   order: 0,
///   checked: False,
///   ingredient: None,
///   completed_at: None,
///   delay_until: None,
///   mealplan_id: None,
/// )
/// create_entry(config, entry)
/// ```
pub fn create_entry(
  config: ClientConfig,
  data: ShoppingListEntryCreate,
) -> Result(ShoppingListEntry, TandoorError) {
  let body =
    encode_shopping_list_entry_create(data)
    |> json.to_string

  use req <- result.try(build_post_request(
    config,
    "/api/shopping-list-entry/",
    body,
  ))
  logger.debug("Tandoor POST /api/shopping-list-entry/")

  use resp <- result.try(execute_and_parse(req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, shopping_list_entry_decoder()) {
        Ok(entry) -> Ok(entry)
        Error(errors) -> {
          let error_msg =
            "Failed to decode created entry: "
            <> string.join(
              list.map(errors, fn(e) {
                case e {
                  decode.DecodeError(expected, _found, path) ->
                    expected <> " at " <> string.join(path, ".")
                }
              }),
              ", ",
            )
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Invalid JSON response"))
  }
}

/// Add a recipe to the shopping list (creates entries for all ingredients)
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `recipe_id` - The ID of the recipe to add
/// * `servings` - Number of servings
///
/// # Returns
/// Result with list of created shopping list entries or error
///
/// # Example
/// ```gleam
/// add_recipe(config, recipe_id: 123, servings: 4)
/// ```
pub fn add_recipe(
  config: ClientConfig,
  recipe_id recipe_id: Int,
  servings servings: Int,
) -> Result(List(ShoppingListEntry), TandoorError) {
  let body =
    json.object([
      #("recipe", json.int(recipe_id)),
      #("servings", json.int(servings)),
    ])
    |> json.to_string

  use req <- result.try(build_post_request(
    config,
    "/api/shopping-list-recipe/",
    body,
  ))
  logger.debug("Tandoor POST /api/shopping-list-recipe/")

  use resp <- result.try(execute_and_parse(req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, decode.list(shopping_list_entry_decoder())) {
        Ok(entries) -> Ok(entries)
        Error(errors) -> {
          let error_msg =
            "Failed to decode recipe entries: "
            <> string.join(
              list.map(errors, fn(e) {
                case e {
                  decode.DecodeError(expected, _found, path) ->
                    expected <> " at " <> string.join(path, ".")
                }
              }),
              ", ",
            )
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Invalid JSON response"))
  }
}

// ============================================================================
// PATCH Operations (Update)
// ============================================================================

/// Update an existing shopping list entry
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `entry_id` - The ID of the entry to update
/// * `data` - ShoppingListEntryUpdate request object
///
/// # Returns
/// Result with updated shopping list entry or error
///
/// # Example
/// ```gleam
/// let updates = ShoppingListEntryUpdate(
///   list_recipe: None,
///   food: Some(42),
///   unit: Some(1),
///   amount: 3.0,
///   order: 1,
///   checked: True,
///   ingredient: None,
///   completed_at: Some("2025-12-14T10:30:00Z"),
///   delay_until: None,
/// )
/// update_entry(config, entry_id: 42, data: updates)
/// ```
pub fn update_entry(
  config: ClientConfig,
  entry_id entry_id: Int,
  data data: ShoppingListEntryUpdate,
) -> Result(ShoppingListEntry, TandoorError) {
  let path = "/api/shopping-list-entry/" <> int.to_string(entry_id) <> "/"
  let body =
    encode_shopping_list_entry_update(data)
    |> json.to_string

  use req <- result.try(build_patch_request(config, path, body))
  logger.debug("Tandoor PATCH " <> path)

  use resp <- result.try(execute_and_parse(req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, shopping_list_entry_decoder()) {
        Ok(entry) -> Ok(entry)
        Error(errors) -> {
          let error_msg =
            "Failed to decode updated entry: "
            <> string.join(
              list.map(errors, fn(e) {
                case e {
                  decode.DecodeError(expected, _found, path) ->
                    expected <> " at " <> string.join(path, ".")
                }
              }),
              ", ",
            )
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Invalid JSON response"))
  }
}

/// Mark a shopping list entry as completed
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `entry_id` - The ID of the entry to mark as complete
///
/// # Returns
/// Result with updated shopping list entry or error
///
/// # Example
/// ```gleam
/// complete_item(config, entry_id: 42)
/// ```
pub fn complete_item(
  config: ClientConfig,
  entry_id entry_id: Int,
) -> Result(ShoppingListEntry, TandoorError) {
  let update =
    ShoppingListEntryUpdate(
      list_recipe: None,
      food: None,
      unit: None,
      amount: 0.0,
      order: 0,
      checked: True,
      ingredient: None,
      completed_at: None,
      delay_until: None,
    )
  update_entry(config, entry_id, update)
}

// ============================================================================
// DELETE Operations
// ============================================================================

/// Delete a shopping list entry
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `entry_id` - The ID of the entry to delete
///
/// # Returns
/// Result with unit or error
///
/// # Example
/// ```gleam
/// remove_item(config, entry_id: 42)
/// ```
pub fn remove_item(
  config: ClientConfig,
  entry_id entry_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/shopping-list-entry/" <> int.to_string(entry_id) <> "/"

  use req <- result.try(build_delete_request(config, path))
  logger.debug("Tandoor DELETE " <> path)

  use _resp <- result.try(execute_and_parse(req))
  Ok(Nil)
}
