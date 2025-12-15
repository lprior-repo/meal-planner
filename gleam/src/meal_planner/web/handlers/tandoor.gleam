/// Tandoor Recipe Manager web handlers
///
/// This module provides basic endpoints for checking Tandoor connection.
/// Full CRUD operations are available via the Tandoor API functions
/// in meal_planner/tandoor/api/* modules.

import gleam/json
import gleam/option

import meal_planner/env
import meal_planner/tandoor/client
import meal_planner/tandoor/api/unit/list as unit_list
import meal_planner/tandoor/api/keyword/keyword_api
import meal_planner/tandoor/handlers/helpers

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

/// Main router for Tandoor API requests
pub fn handle_tandoor_routes(req: wisp.Request) -> wisp.Response {
  let path = wisp.path_segments(req)

  case path {
    // Status endpoint
    ["tandoor", "status"] -> {
      case get_authenticated_client() {
        Ok(_) -> {
          json.object([
            #("status", json.string("connected")),
            #("service", json.string("tandoor")),
          ])
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(resp) -> resp
      }
    }

    // Units (GET only)
    ["api", "tandoor", "units"] -> {
      case get_authenticated_client() {
        Ok(config) -> {
          case unit_list.list_units(config, limit: option.None, page: option.None) {
            Ok(response) -> {
              let results_json =
                json.array(
                  response.results,
                  fn(unit) {
                    json.object([
                      #("id", json.int(unit.id)),
                      #("name", json.string(unit.name)),
                      #("plural_name", helpers.encode_optional_string(unit.plural_name)),
                    ])
                  },
                )

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

    // Keywords (GET only)
    ["api", "tandoor", "keywords"] -> {
      case get_authenticated_client() {
        Ok(config) -> {
          case keyword_api.list_keywords(config) {
            Ok(keywords) -> {
              json.array(
                keywords,
                fn(keyword) {
                  json.object([
                    #("id", json.int(keyword.id)),
                    #("name", json.string(keyword.name)),
                  ])
                },
              )
              |> json.to_string
              |> wisp.json_response(200)
            }
            Error(_) -> wisp.not_found()
          }
        }
        Error(resp) -> resp
      }
    }

    _ -> wisp.not_found()
  }
}
