/// Supermarkets web handlers for Tandoor Recipe Manager
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http
import gleam/int
import gleam/json
import gleam/option
import gleam/result

import meal_planner/tandoor/api/supermarket/create as supermarket_create_api
import meal_planner/tandoor/api/supermarket/delete as supermarket_delete
import meal_planner/tandoor/api/supermarket/get as supermarket_get
import meal_planner/tandoor/api/supermarket/list as supermarket_list
import meal_planner/tandoor/api/supermarket/update as supermarket_update
import meal_planner/tandoor/handlers/helpers
import meal_planner/tandoor/types/supermarket/supermarket_create.{
  type SupermarketCreateRequest, SupermarketCreateRequest,
}

import wisp

/// Handle supermarkets collection (GET list, POST create)
pub fn handle_supermarkets_collection(req: wisp.Request) -> wisp.Response {
  case req.method {
    http.Get -> handle_list_supermarkets(req)
    http.Post -> handle_create_supermarket(req)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

/// Handle supermarket by ID (GET, PATCH, DELETE)
pub fn handle_supermarket_by_id(
  req: wisp.Request,
  supermarket_id: String,
) -> wisp.Response {
  case int.parse(supermarket_id) {
    Ok(id) -> {
      case req.method {
        http.Get -> handle_get_supermarket(req, id)
        http.Patch -> handle_update_supermarket(req, id)
        http.Delete -> handle_delete_supermarket(req, id)
        _ -> wisp.method_not_allowed([http.Get, http.Patch, http.Delete])
      }
    }
    Error(_) -> helpers.error_response(400, "Invalid supermarket ID")
  }
}

// =============================================================================
// Private Handler Functions
// =============================================================================

fn handle_list_supermarkets(_req: wisp.Request) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case
        supermarket_list.list_supermarkets(
          config,
          limit: option.None,
          page: option.None,
        )
      {
        Ok(response) -> {
          let results_json =
            json.array(response.results, fn(supermarket) {
              json.object([
                #("id", json.int(supermarket.id)),
                #("name", json.string(supermarket.name)),
                #(
                  "description",
                  helpers.encode_optional_string(supermarket.description),
                ),
              ])
            })

          json.object([
            #("count", json.int(response.count)),
            #("next", helpers.encode_optional_string(response.next)),
            #("previous", helpers.encode_optional_string(response.previous)),
            #("results", results_json),
          ])
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

fn handle_create_supermarket(req: wisp.Request) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_supermarket_create_request(body) {
    Ok(request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case supermarket_create_api.create_supermarket(config, request) {
            Ok(supermarket) -> {
              json.object([
                #("id", json.int(supermarket.id)),
                #("name", json.string(supermarket.name)),
                #(
                  "description",
                  helpers.encode_optional_string(supermarket.description),
                ),
              ])
              |> json.to_string
              |> wisp.json_response(201)
            }
            Error(_) ->
              helpers.error_response(500, "Failed to create supermarket")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

fn handle_get_supermarket(_req: wisp.Request, id: Int) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case supermarket_get.get_supermarket(config, id: id) {
        Ok(supermarket) -> {
          json.object([
            #("id", json.int(supermarket.id)),
            #("name", json.string(supermarket.name)),
            #(
              "description",
              helpers.encode_optional_string(supermarket.description),
            ),
          ])
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

fn handle_update_supermarket(req: wisp.Request, id: Int) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_supermarket_create_request(body) {
    Ok(request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case
            supermarket_update.update_supermarket(
              config,
              id: id,
              supermarket_data: request,
            )
          {
            Ok(supermarket) -> {
              json.object([
                #("id", json.int(supermarket.id)),
                #("name", json.string(supermarket.name)),
                #(
                  "description",
                  helpers.encode_optional_string(supermarket.description),
                ),
              ])
              |> json.to_string
              |> wisp.json_response(200)
            }
            Error(_) ->
              helpers.error_response(500, "Failed to update supermarket")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

fn handle_delete_supermarket(_req: wisp.Request, id: Int) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case supermarket_delete.delete_supermarket(config, id) {
        Ok(Nil) -> wisp.response(204)
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

// =============================================================================
// JSON Decoding
// =============================================================================

fn parse_supermarket_create_request(
  json_data: dynamic.Dynamic,
) -> Result(SupermarketCreateRequest, String) {
  decode.run(json_data, supermarket_create_decoder())
  |> result.map_error(fn(_) { "Invalid supermarket create request" })
}

fn supermarket_create_decoder() -> decode.Decoder(SupermarketCreateRequest) {
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  decode.success(SupermarketCreateRequest(name: name, description: description))
}
