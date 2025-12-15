/// Tandoor Shopping List web handlers
///
/// This module provides HTTP endpoints for managing shopping lists:
/// - List shopping list entries with filtering and pagination
/// - Create new shopping list entries
/// - Add recipes to shopping lists
/// - Get single shopping list entry details
/// - Update shopping list entry (mark as checked, etc.)
/// - Delete shopping list entry

import gleam/int
import gleam/json
import gleam/option
import gleam/result
import meal_planner/env
import meal_planner/tandoor/api/shopping_list
import meal_planner/tandoor/client
import meal_planner/tandoor/handlers/helpers
import meal_planner/tandoor/types/shopping/shopping_list_entry.{
  type ShoppingListEntryCreate, ShoppingListEntryCreate,
}
import wisp

/// Get Tandoor client config with authentication
fn get_authenticated_client() -> Result(client.ClientConfig, wisp.Response) {
  case env.load_tandoor_config() {
    option.Some(tandoor_cfg) -> {
      let config = client.session_config(
        tandoor_cfg.base_url,
        tandoor_cfg.username,
        tandoor_cfg.password,
      )
      case client.login(config) {
        Ok(auth_config) -> Ok(auth_config)
        Error(e) -> {
          let #(status, message) = case e {
            client.AuthenticationError(msg) -> #(401, msg)
            client.AuthorizationError(msg) -> #(403, msg)
            client.NotFoundError(resource) -> #(404, resource)
            client.BadRequestError(msg) -> #(400, msg)
            client.ServerError(s, msg) -> #(s, msg)
            client.NetworkError(msg) -> #(502, msg)
            client.TimeoutError -> #(504, "Request timed out")
            client.ParseError(msg) -> #(500, msg)
            client.UnknownError(msg) -> #(500, msg)
          }
          Error(helpers.error_response(status, message))
        }
      }
    }
    option.None -> Error(helpers.error_response(502, "Tandoor not configured"))
  }
}

/// Extract query parameters for list endpoint
fn extract_list_params(
  params: List(#(String, String)),
) -> #(option.Option(Bool), option.Option(Int), option.Option(Int)) {
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
    |> option.map(fn(s) { case s {
      0 -> 1
      n -> n
    }})
    |> option.unwrap(1)

  case recipe_id {
    option.Some(id) -> Ok(#(id, servings))
    option.None ->
      Error(helpers.error_response(400, "Missing required parameter: recipe_id"))
  }
}

/// List shopping list entries - GET /api/tandoor/shopping-list-entries
pub fn handle_list(req: wisp.Request) -> wisp.Response {
  case get_authenticated_client() {
    Ok(config) -> {
      let params = wisp.query_parameters(req)
      let #(checked, limit, offset) = extract_list_params(params)

      case shopping_list.list(config, checked, limit, offset) {
        Ok(response) -> {
          let results_json =
            json.array(
              response.results,
              fn(entry) {
                json.object([
                  #("id", json.int(entry.id)),
                  #("amount", json.float(entry.amount)),
                  #("order", json.int(entry.order)),
                  #("checked", json.bool(entry.checked)),
                  #("food", helpers.encode_optional_int(option.map(entry.food, fn(f) { f }))),
                  #("unit", helpers.encode_optional_int(option.map(entry.unit, fn(u) { u }))),
                  #(
                    "list_recipe",
                    helpers.encode_optional_int(
                      option.map(entry.list_recipe, fn(lr) { lr }),
                    ),
                  ),
                  #(
                    "ingredient",
                    helpers.encode_optional_int(
                      option.map(entry.ingredient, fn(i) { i }),
                    ),
                  ),
                  #("completed_at", helpers.encode_optional_string(entry.completed_at)),
                  #("delay_until", helpers.encode_optional_string(entry.delay_until)),
                ])
              },
            )

          let response_json = helpers.paginated_response(
            results_json,
            response.count,
            response.next,
            response.previous,
          )

          json.to_string(response_json)
          |> wisp.json_response(200)
        }
        Error(_) -> helpers.error_response(502, "Failed to fetch shopping list entries")
      }
    }
    Error(resp) -> resp
  }
}

/// Create shopping list entry - POST /api/tandoor/shopping-list-entries
pub fn handle_create(req: wisp.Request) -> wisp.Response {
  case get_authenticated_client() {
    Ok(config) -> {
      use body <- wisp.require_json(req)

      // Parse JSON body to ShoppingListEntryCreate
      let food_id = json.field(body, "food", json.int)
      let unit_id = json.field(body, "unit", json.int)
      let amount = json.field(body, "amount", json.float)
      let order = json.field(body, "order", json.int)
      let checked = json.field(body, "checked", json.bool)

      case #(food_id, unit_id, amount, order, checked) {
        #(Ok(food), Ok(unit), Ok(amt), Ok(ord), Ok(chk)) -> {
          let entry = ShoppingListEntryCreate(
            list_recipe: None,
            food: option.Some(food),
            unit: option.Some(unit),
            amount: amt,
            order: ord,
            checked: chk,
            ingredient: None,
            completed_at: None,
            delay_until: None,
            mealplan_id: None,
          )

          case shopping_list.create(config, entry) {
            Ok(created) -> {
              let response_json = json.object([
                #("id", json.int(created.id)),
                #("amount", json.float(created.amount)),
                #("order", json.int(created.order)),
                #("checked", json.bool(created.checked)),
                #("food", helpers.encode_optional_int(created.food)),
                #("unit", helpers.encode_optional_int(created.unit)),
                #(
                  "list_recipe",
                  helpers.encode_optional_int(created.list_recipe),
                ),
                #("ingredient", helpers.encode_optional_int(created.ingredient)),
                #("completed_at", helpers.encode_optional_string(created.completed_at)),
                #("delay_until", helpers.encode_optional_string(created.delay_until)),
              ])

              json.to_string(response_json)
              |> wisp.json_response(201)
            }
            Error(_) ->
              helpers.error_response(502, "Failed to create shopping list entry")
          }
        }
        _ ->
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
  case get_authenticated_client() {
    Ok(config) -> {
      let params = wisp.query_parameters(req)

      case extract_add_recipe_params(params) {
        Ok(#(recipe_id, servings)) -> {
          case shopping_list.add_recipe(config, recipe_id, servings) {
            Ok(entries) -> {
              let results_json =
                json.array(
                  entries,
                  fn(entry) {
                    json.object([
                      #("id", json.int(entry.id)),
                      #("amount", json.float(entry.amount)),
                      #("order", json.int(entry.order)),
                      #("checked", json.bool(entry.checked)),
                      #("food", helpers.encode_optional_int(entry.food)),
                      #("unit", helpers.encode_optional_int(entry.unit)),
                      #(
                        "list_recipe",
                        helpers.encode_optional_int(entry.list_recipe),
                      ),
                      #("ingredient", helpers.encode_optional_int(entry.ingredient)),
                      #("completed_at", helpers.encode_optional_string(entry.completed_at)),
                      #("delay_until", helpers.encode_optional_string(entry.delay_until)),
                    ])
                  },
                )

              json.to_string(results_json)
              |> wisp.json_response(201)
            }
            Error(_) ->
              helpers.error_response(502, "Failed to add recipe to shopping list")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(resp) -> resp
  }
}

/// Get single shopping list entry - GET /api/tandoor/shopping-list-entries/{id}
pub fn handle_get(req: wisp.Request, id_str: String) -> wisp.Response {
  case get_authenticated_client() {
    Ok(config) -> {
      case int.parse(id_str) {
        Ok(id) -> {
          case shopping_list.get(config, id) {
            Ok(entry) -> {
              let response_json = json.object([
                #("id", json.int(entry.id)),
                #("amount", json.float(entry.amount)),
                #("order", json.int(entry.order)),
                #("checked", json.bool(entry.checked)),
                #("food", helpers.encode_optional_int(entry.food)),
                #("unit", helpers.encode_optional_int(entry.unit)),
                #("list_recipe", helpers.encode_optional_int(entry.list_recipe)),
                #("ingredient", helpers.encode_optional_int(entry.ingredient)),
                #("completed_at", helpers.encode_optional_string(entry.completed_at)),
                #("delay_until", helpers.encode_optional_string(entry.delay_until)),
              ])

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
pub fn handle_delete(req: wisp.Request, id_str: String) -> wisp.Response {
  case get_authenticated_client() {
    Ok(config) -> {
      case int.parse(id_str) {
        Ok(id) -> {
          case shopping_list.delete(config, id) {
            Ok(Nil) ->
              json.object([#("success", json.bool(True))])
              |> json.to_string
              |> wisp.json_response(204)
            Error(_) ->
              helpers.error_response(502, "Failed to delete shopping list entry")
          }
        }
        Error(_) ->
          helpers.error_response(400, "Invalid shopping list entry ID")
      }
    }
    Error(resp) -> resp
  }
}
