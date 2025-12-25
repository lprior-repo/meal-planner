/// Tandoor Shopping List web handlers
///
/// This module provides HTTP endpoints for managing shopping lists:
/// - List shopping list entries with filtering and pagination
/// - Create new shopping list entries
/// - Add recipes to shopping lists
/// - Get single shopping list entry details
/// - Update shopping list entry (mark as checked, etc.)
/// - Delete shopping list entry
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/option.{type Option, None, Some}
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/handlers/helpers

// Import types directly from types module for field access
import meal_planner/tandoor/shopping/types.{
  type ShoppingListEntry, type ShoppingListEntryResponse, ShoppingListEntry,
  ShoppingListEntryCreate,
}
import wisp

/// Extract query parameters for list endpoint
fn extract_list_params(
  params: List(#(String, String)),
) -> #(Option(Bool), Option(Int), Option(Int)) {
  let checked =
    helpers.get_query_param(params, "checked")
    |> option.map(fn(s) { s == "true" })

  let limit = helpers.parse_int_param(params, "page_size")
  let offset = helpers.parse_int_param(params, "offset")

  #(checked, limit, offset)
}

/// Extract query parameters for add recipe endpoint
fn extract_add_recipe_params(
  params: List(#(String, String)),
) -> Result(#(Int, Int), wisp.Response) {
  let recipe_id = helpers.parse_int_param(params, "recipe_id")
  let servings =
    helpers.parse_int_param(params, "servings")
    |> option.map(fn(s) {
      case s {
        0 -> 1
        n -> n
      }
    })
    |> option.unwrap(1)

  case recipe_id {
    Some(id) -> Ok(#(id, servings))
    None ->
      Error(helpers.error_response(400, "Missing required parameter: recipe_id"))
  }
}

/// Encode a shopping list entry response to JSON
fn entry_response_to_json(entry: ShoppingListEntryResponse) -> json.Json {
  json.object([
    #("id", json.int(entry.id)),
    #("amount", json.float(entry.amount)),
    #("order", json.int(entry.order)),
    #("checked", json.bool(entry.checked)),
    #("food", case entry.food {
      Some(food) ->
        json.object([
          #("id", json.int(ids.food_id_to_int(food.id))),
          #("name", json.string(food.name)),
        ])
      None -> json.null()
    }),
    #("unit", case entry.unit {
      Some(unit) ->
        json.object([
          #("id", json.int(unit.id)),
          #("name", json.string(unit.name)),
        ])
      None -> json.null()
    }),
    #("list_recipe", helpers.encode_optional_int(entry.list_recipe)),
    #("completed_at", helpers.encode_optional_string(entry.completed_at)),
  ])
}

/// Encode a shopping list entry to JSON
fn entry_to_json(entry: ShoppingListEntry) -> json.Json {
  json.object([
    #("id", json.int(ids.shopping_list_entry_id_to_int(entry.id))),
    #("amount", json.float(entry.amount)),
    #("order", json.int(entry.order)),
    #("checked", json.bool(entry.checked)),
    #(
      "food",
      helpers.encode_optional_int(option.map(entry.food, ids.food_id_to_int)),
    ),
    #(
      "unit",
      helpers.encode_optional_int(option.map(entry.unit, ids.unit_id_to_int)),
    ),
    #(
      "list_recipe",
      helpers.encode_optional_int(option.map(
        entry.list_recipe,
        ids.shopping_list_id_to_int,
      )),
    ),
    #(
      "ingredient",
      helpers.encode_optional_int(option.map(
        entry.ingredient,
        ids.ingredient_id_to_int,
      )),
    ),
    #("completed_at", helpers.encode_optional_string(entry.completed_at)),
    #("delay_until", helpers.encode_optional_string(entry.delay_until)),
  ])
}

/// List shopping list entries - GET /api/tandoor/shopping-list-entries
pub fn handle_list(_req: wisp.Request) -> wisp.Response {
  // TODO: Implement shopping list API integration
  helpers.error_response(501, "Shopping list API not yet implemented")
}

/// Decoder for create request body
fn decode_create_request() -> decode.Decoder(#(Int, Int, Float, Int, Bool)) {
  use food <- decode.field("food", decode.int)
  use unit <- decode.field("unit", decode.int)
  use amount <- decode.field("amount", decode.float)
  use order <- decode.field("order", decode.int)
  use checked <- decode.field("checked", decode.bool)
  decode.success(#(food, unit, amount, order, checked))
}

/// Create shopping list entry - POST /api/tandoor/shopping-list-entries
pub fn handle_create(_req: wisp.Request) -> wisp.Response {
  // TODO: Implement shopping list API integration
  helpers.error_response(501, "Shopping list API not yet implemented")
}

/// Add recipe to shopping list - POST /api/tandoor/shopping-list-recipe
pub fn handle_add_recipe(_req: wisp.Request) -> wisp.Response {
  // TODO: Implement shopping list API integration
  helpers.error_response(501, "Shopping list API not yet implemented")
}

/// Get single shopping list entry - GET /api/tandoor/shopping-list-entries/{id}
pub fn handle_get(_req: wisp.Request, _id_str: String) -> wisp.Response {
  // TODO: Implement shopping list API integration
  helpers.error_response(501, "Shopping list API not yet implemented")
}

/// Delete shopping list entry - DELETE /api/tandoor/shopping-list-entries/{id}
pub fn handle_delete(_req: wisp.Request, _id_str: String) -> wisp.Response {
  // TODO: Implement shopping list API integration
  helpers.error_response(501, "Shopping list API not yet implemented")
}
