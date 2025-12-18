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
import meal_planner/tandoor/shopping.{
  type ShoppingListEntry, type ShoppingListEntryResponse,
  ShoppingListEntryCreate,
  list_entries, create_entry, get_entry, delete_entry, add_recipe_to_shopping_list,
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
      helpers.encode_optional_int(option.map(entry.food, fn(f) {
        ids.food_id_to_int(f.id)
      })),
    ),
    #(
      "unit",
      helpers.encode_optional_int(option.map(entry.unit, fn(u) { u.id })),
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
pub fn handle_list(req: wisp.Request) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      let params = wisp.get_query(req)
      let #(checked, limit, offset) = extract_list_params(params)

      case list_entries(config, checked: checked, limit: limit, offset: offset) {
        Ok(response) -> {
          let results_json =
            json.array(response.results, entry_response_to_json)

          let response_json =
            helpers.paginated_response(
              results_json,
              response.count,
              response.next,
              response.previous,
            )

          json.to_string(response_json)
          |> wisp.json_response(200)
        }
        Error(_) ->
          helpers.error_response(502, "Failed to fetch shopping list entries")
      }
    }
    Error(resp) -> resp
  }
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
pub fn handle_create(req: wisp.Request) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      use body <- wisp.require_json(req)

      case decode.run(body, decode_create_request()) {
        Ok(#(food, unit, amount, order, checked)) -> {
          let entry =
            ShoppingListEntryCreate(
              list_recipe: None,
              food: Some(food),
              unit: Some(unit),
              amount: amount,
              order: order,
              checked: checked,
              ingredient: None,
              completed_at: None,
              delay_until: None,
              mealplan_id: None,
            )

          case create_entry(config, entry) {
            Ok(created) -> {
              let response_json = entry_to_json(created)
              json.to_string(response_json)
              |> wisp.json_response(201)
            }
            Error(_) ->
              helpers.error_response(
                502,
                "Failed to create shopping list entry",
              )
          }
        }
        Error(_) ->
          helpers.error_response(
            400,
            "Missing or invalid required fields: food, unit, amount, order, checked",
          )
      }
    }
    Error(resp) -> resp
  }
}

/// Add recipe to shopping list - POST /api/tandoor/shopping-list-recipe
pub fn handle_add_recipe(req: wisp.Request) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      let params = wisp.get_query(req)

      case extract_add_recipe_params(params) {
        Ok(#(recipe_id, servings)) -> {
          case add_recipe_to_shopping_list(config, recipe_id: recipe_id, servings: servings) {
            Ok(entries) -> {
              let results_json = json.array(entries, entry_to_json)

              json.to_string(results_json)
              |> wisp.json_response(201)
            }
            Error(_) ->
              helpers.error_response(
                502,
                "Failed to add recipe to shopping list",
              )
          }
        }
        Error(resp) -> resp
      }
    }
    Error(resp) -> resp
  }
}

/// Get single shopping list entry - GET /api/tandoor/shopping-list-entries/{id}
pub fn handle_get(_req: wisp.Request, id_str: String) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case int.parse(id_str) {
        Ok(id) -> {
          case get_entry(config, entry_id: id) {
            Ok(entry) -> {
              let response_json = entry_to_json(entry)
              json.to_string(response_json)
              |> wisp.json_response(200)
            }
            Error(_) ->
              helpers.error_response(404, "Shopping list entry not found")
          }
        }
        Error(_) ->
          helpers.error_response(400, "Invalid shopping list entry ID")
      }
    }
    Error(resp) -> resp
  }
}

/// Delete shopping list entry - DELETE /api/tandoor/shopping-list-entries/{id}
pub fn handle_delete(_req: wisp.Request, id_str: String) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case int.parse(id_str) {
        Ok(id) -> {
          case delete_entry(config, entry_id: id) {
            Ok(Nil) ->
              json.object([#("success", json.bool(True))])
              |> json.to_string
              |> wisp.json_response(204)
            Error(_) ->
              helpers.error_response(
                502,
                "Failed to delete shopping list entry",
              )
          }
        }
        Error(_) ->
          helpers.error_response(400, "Invalid shopping list entry ID")
      }
    }
    Error(resp) -> resp
  }
}
