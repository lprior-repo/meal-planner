/// Tandoor Shopping List handlers
///
/// This module provides HTTP handler functions for Tandoor shopping list operations:
/// - Listing shopping list entries
/// - Creating shopping list entries
/// - Getting a shopping list entry by ID
/// - Updating shopping list entries
/// - Deleting shopping list entries
/// - JSON encoding/decoding for shopping lists
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http
import gleam/int
import gleam/json
import gleam/option.{type Option, None}
import gleam/result

import meal_planner/tandoor/core/ids
import meal_planner/tandoor/food.{type Food}
import meal_planner/tandoor/handlers/helpers
import meal_planner/tandoor/shopping/mod as shopping
import meal_planner/tandoor/shopping/types.{
  type ShoppingListEntry, type ShoppingListEntryCreate,
  type ShoppingListEntryResponse, type ShoppingListEntryUpdate,
  ShoppingListEntryCreate, ShoppingListEntryUpdate, ShoppingListQuery,
}
import meal_planner/tandoor/unit.{type Unit}

import wisp

// =============================================================================
// Shopping List Entry Collection Handler
// =============================================================================

pub fn handle_shopping_list_collection(req: wisp.Request) -> wisp.Response {
  case req.method {
    http.Get -> handle_list_entries(req)
    http.Post -> handle_create_entry(req)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn handle_list_entries(req: wisp.Request) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      let query_params = wisp.get_query(req)
      let checked = parse_checked_param(query_params)
      let limit = helpers.parse_int_param(query_params, "limit")
      let offset = helpers.parse_int_param(query_params, "offset")

      let query =
        ShoppingListQuery(
          checked: checked,
          mealplan: None,
          updated_after: None,
          limit: limit,
          offset: offset,
        )

      case shopping.list_entries(config, query) {
        Ok(response) -> {
          let results_json =
            json.array(response.results, encode_shopping_list_entry_response)

          helpers.paginated_response(
            results_json,
            response.count,
            response.next,
            response.previous,
          )
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> helpers.error_response(500, "Failed to fetch shopping list")
      }
    }
    Error(resp) -> resp
  }
}

fn handle_create_entry(req: wisp.Request) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_shopping_list_entry_create(body) {
    Ok(request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case shopping.create_entry(config, request) {
            Ok(entry) -> {
              encode_shopping_list_entry_response(entry)
              |> json.to_string
              |> wisp.json_response(201)
            }
            Error(_) ->
              helpers.error_response(
                500,
                "Failed to create shopping list entry",
              )
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

// =============================================================================
// Shopping List Entry Item Handler
// =============================================================================

pub fn handle_shopping_list_entry_by_id(
  req: wisp.Request,
  entry_id: String,
) -> wisp.Response {
  case int.parse(entry_id) {
    Ok(id) -> {
      case req.method {
        http.Get -> handle_get_entry(req, id)
        http.Patch -> handle_update_entry(req, id)
        http.Delete -> handle_delete_entry(req, id)
        _ -> wisp.method_not_allowed([http.Get, http.Patch, http.Delete])
      }
    }
    Error(_) -> helpers.error_response(400, "Invalid entry ID")
  }
}

fn handle_get_entry(_req: wisp.Request, id: Int) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case shopping.get_entry(config, id) {
        Ok(entry) -> {
          encode_shopping_list_entry_response(entry)
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

fn handle_update_entry(req: wisp.Request, id: Int) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_shopping_list_entry_update(body) {
    Ok(request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case shopping.update_entry(config, id, request) {
            Ok(entry) -> {
              encode_shopping_list_entry_response(entry)
              |> json.to_string
              |> wisp.json_response(200)
            }
            Error(_) ->
              helpers.error_response(
                500,
                "Failed to update shopping list entry",
              )
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

fn handle_delete_entry(_req: wisp.Request, id: Int) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case shopping.delete_entry(config, id) {
        Ok(Nil) -> wisp.response(204)
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

// =============================================================================
// JSON Encoding and Decoding
// =============================================================================

/// Encode a shopping list entry (internal type) to JSON
fn encode_shopping_list_entry(
  entry: ShoppingListEntry,
) -> json.Json {
  json.object([
    #("id", json.int(ids.shopping_list_entry_id_to_int(entry.id))),
    #("list_recipe", encode_optional_shopping_list_id(entry.list_recipe)),
    #("food", encode_optional_food_id(entry.food)),
    #("unit", encode_optional_unit_id(entry.unit)),
    #("amount", json.float(entry.amount)),
    #("order", json.int(entry.order)),
    #("checked", json.bool(entry.checked)),
    #("ingredient", encode_optional_ingredient_id(entry.ingredient)),
    #("created_by", json.int(ids.user_id_to_int(entry.created_by))),
    #("created_at", json.string(entry.created_at)),
    #("updated_at", json.string(entry.updated_at)),
    #("completed_at", helpers.encode_optional_string(entry.completed_at)),
    #("delay_until", helpers.encode_optional_string(entry.delay_until)),
  ])
}

/// Encode a shopping list entry response (from API) to JSON
fn encode_shopping_list_entry_response(
  entry: ShoppingListEntryResponse,
) -> json.Json {
  json.object([
    #("id", json.int(entry.id)),
    #("list_recipe", helpers.encode_optional_int(entry.list_recipe)),
    #("food", case entry.food {
      option.Some(f) -> encode_food(f)
      option.None -> json.null()
    }),
    #("unit", case entry.unit {
      option.Some(u) -> encode_unit(u)
      option.None -> json.null()
    }),
    #("amount", json.float(entry.amount)),
    #("order", json.int(entry.order)),
    #("checked", json.bool(entry.checked)),
    #("created_at", json.string(entry.created_at)),
    #("completed_at", helpers.encode_optional_string(entry.completed_at)),
  ])
}

fn encode_food(food: Food) -> json.Json {
  json.object([
    #("id", json.int(ids.food_id_to_int(food.id))),
    #("name", json.string(food.name)),
  ])
}

fn encode_unit(unit: Unit) -> json.Json {
  json.object([
    #("id", json.int(unit.id)),
    #("name", json.string(unit.name)),
  ])
}

// =============================================================================
// JSON Decoders
// =============================================================================

fn parse_shopping_list_entry_create(
  json_data: dynamic.Dynamic,
) -> Result(ShoppingListEntryCreate, String) {
  decode.run(json_data, shopping_list_entry_create_decoder())
  |> result.map_error(fn(_) { "Invalid shopping list entry create request" })
}

fn shopping_list_entry_create_decoder() -> decode.Decoder(
  ShoppingListEntryCreate,
) {
  use list_recipe <- decode.field(
    "list_recipe",
    decode.optional(ids.shopping_list_id_decoder()),
  )
  use food <- decode.field("food", decode.optional(ids.food_id_decoder()))
  use unit <- decode.field("unit", decode.optional(ids.unit_id_decoder()))
  use amount <- decode.field("amount", decode.float)
  use order <- decode.field("order", decode.int)
  use checked <- decode.field("checked", decode.bool)
  use ingredient <- decode.field(
    "ingredient",
    decode.optional(ids.ingredient_id_decoder()),
  )
  use completed_at <- decode.field(
    "completed_at",
    decode.optional(decode.string),
  )
  use delay_until <- decode.field("delay_until", decode.optional(decode.string))
  use mealplan_id <- decode.field("mealplan_id", decode.optional(decode.int))

  decode.success(ShoppingListEntryCreate(
    list_recipe: list_recipe,
    food: food,
    unit: unit,
    amount: amount,
    order: order,
    checked: checked,
    ingredient: ingredient,
    completed_at: completed_at,
    delay_until: delay_until,
    mealplan_id: mealplan_id,
  ))
}

fn parse_shopping_list_entry_update(
  json_data: dynamic.Dynamic,
) -> Result(ShoppingListEntryUpdate, String) {
  decode.run(json_data, shopping_list_entry_update_decoder())
  |> result.map_error(fn(_) { "Invalid shopping list entry update request" })
}

fn shopping_list_entry_update_decoder() -> decode.Decoder(
  ShoppingListEntryUpdate,
) {
  use list_recipe <- decode.field(
    "list_recipe",
    decode.optional(ids.shopping_list_id_decoder()),
  )
  use food <- decode.field("food", decode.optional(ids.food_id_decoder()))
  use unit <- decode.field("unit", decode.optional(ids.unit_id_decoder()))
  use amount <- decode.field("amount", decode.float)
  use order <- decode.field("order", decode.int)
  use checked <- decode.field("checked", decode.bool)
  use ingredient <- decode.field(
    "ingredient",
    decode.optional(ids.ingredient_id_decoder()),
  )
  use completed_at <- decode.field(
    "completed_at",
    decode.optional(decode.string),
  )
  use delay_until <- decode.field("delay_until", decode.optional(decode.string))

  decode.success(ShoppingListEntryUpdate(
    list_recipe: list_recipe,
    food: food,
    unit: unit,
    amount: amount,
    order: order,
    checked: checked,
    ingredient: ingredient,
    completed_at: completed_at,
    delay_until: delay_until,
  ))
}

// =============================================================================
// Helper Functions
// =============================================================================

fn parse_checked_param(params: List(#(String, String))) -> Option(Bool) {
  case helpers.get_query_param(params, "checked") {
    option.Some("true") -> option.Some(True)
    option.Some("false") -> option.Some(False)
    _ -> option.None
  }
}

fn encode_optional_shopping_list_id(id: Option(ids.ShoppingListId)) -> json.Json {
  case id {
    option.Some(id) -> json.int(ids.shopping_list_id_to_int(id))
    option.None -> json.null()
  }
}

fn encode_optional_food_id(id: Option(ids.FoodId)) -> json.Json {
  case id {
    option.Some(id) -> json.int(ids.food_id_to_int(id))
    option.None -> json.null()
  }
}

fn encode_optional_unit_id(id: Option(ids.UnitId)) -> json.Json {
  case id {
    option.Some(id) -> json.int(ids.unit_id_to_int(id))
    option.None -> json.null()
  }
}

fn encode_optional_ingredient_id(id: Option(ids.IngredientId)) -> json.Json {
  case id {
    option.Some(id) -> json.int(ids.ingredient_id_to_int(id))
    option.None -> json.null()
  }
}
