/// Tandoor Recipe Manager web handlers
///
/// This module provides endpoints for Tandoor Recipe Manager integration,
/// including:
/// - Status checking
/// - Units listing
/// - Keywords listing
/// - Supermarkets CRUD operations
/// - Supermarket Categories CRUD operations

import gleam/dynamic
import gleam/dynamic/decode
import gleam/http
import gleam/int
import gleam/json
import gleam/option
import gleam/result

import meal_planner/env
import meal_planner/tandoor/client
import meal_planner/tandoor/api/unit/list as unit_list
import meal_planner/tandoor/api/keyword/keyword_api
import meal_planner/tandoor/api/supermarket/category as supermarket_category
import meal_planner/tandoor/api/supermarket/create as supermarket_create_api
import meal_planner/tandoor/api/supermarket/delete as supermarket_delete
import meal_planner/tandoor/api/supermarket/get as supermarket_get
import meal_planner/tandoor/api/supermarket/list as supermarket_list
import meal_planner/tandoor/api/supermarket/update as supermarket_update
import meal_planner/tandoor/handlers/helpers
import meal_planner/tandoor/types/supermarket/supermarket_category_create.{
  type SupermarketCategoryCreateRequest, SupermarketCategoryCreateRequest,
}
import meal_planner/tandoor/types/supermarket/supermarket_create.{
  type SupermarketCreateRequest, SupermarketCreateRequest,
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

    // Supermarkets (GET list, POST create)
    ["api", "tandoor", "supermarkets"] ->
      handle_supermarkets_collection(req)

    // Supermarket by ID (GET, PATCH, DELETE)
    ["api", "tandoor", "supermarkets", supermarket_id] ->
      handle_supermarket_by_id(req, supermarket_id)

    // Supermarket Categories (GET list, POST create)
    ["api", "tandoor", "supermarket-categories"] ->
      handle_categories_collection(req)

    // Supermarket Category by ID (GET, PATCH, DELETE)
    ["api", "tandoor", "supermarket-categories", category_id] ->
      handle_category_by_id(req, category_id)

    _ -> wisp.not_found()
  }
}

// =============================================================================
// Supermarket Collection Handler
// =============================================================================

fn handle_supermarkets_collection(req: wisp.Request) -> wisp.Response {
  case req.method {
    http.Get -> handle_list_supermarkets(req)
    http.Post -> handle_create_supermarket(req)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn handle_list_supermarkets(_req: wisp.Request) -> wisp.Response {
  case get_authenticated_client() {
    Ok(config) -> {
      case supermarket_list.list_supermarkets(
        config,
        limit: option.None,
        page: option.None,
      ) {
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
      case get_authenticated_client() {
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
            Error(_) -> helpers.error_response(500, "Failed to create supermarket")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

// =============================================================================
// Supermarket Item Handler
// =============================================================================

fn handle_supermarket_by_id(
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

fn handle_get_supermarket(_req: wisp.Request, id: Int) -> wisp.Response {
  case get_authenticated_client() {
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
      case get_authenticated_client() {
        Ok(config) -> {
          case supermarket_update.update_supermarket(
            config,
            id: id,
            supermarket_data: request,
          ) {
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
            Error(_) -> helpers.error_response(500, "Failed to update supermarket")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

fn handle_delete_supermarket(_req: wisp.Request, id: Int) -> wisp.Response {
  case get_authenticated_client() {
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
// Supermarket Category Collection Handler
// =============================================================================

fn handle_categories_collection(req: wisp.Request) -> wisp.Response {
  case req.method {
    http.Get -> handle_list_categories(req)
    http.Post -> handle_create_category(req)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn handle_list_categories(_req: wisp.Request) -> wisp.Response {
  case get_authenticated_client() {
    Ok(config) -> {
      case supermarket_category.list_categories(
        config,
        limit: option.None,
        offset: option.None,
      ) {
        Ok(response) -> {
          let results_json =
            json.array(response.results, fn(category) {
              json.object([
                #("id", json.int(category.id)),
                #("name", json.string(category.name)),
                #(
                  "description",
                  helpers.encode_optional_string(category.description),
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

fn handle_create_category(req: wisp.Request) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_supermarket_category_create_request(body) {
    Ok(request) -> {
      case get_authenticated_client() {
        Ok(config) -> {
          case supermarket_category.create_category(config, request) {
            Ok(category) -> {
              json.object([
                #("id", json.int(category.id)),
                #("name", json.string(category.name)),
                #(
                  "description",
                  helpers.encode_optional_string(category.description),
                ),
              ])
              |> json.to_string
              |> wisp.json_response(201)
            }
            Error(_) -> helpers.error_response(500, "Failed to create category")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

// =============================================================================
// Supermarket Category Item Handler
// =============================================================================

fn handle_category_by_id(req: wisp.Request, category_id: String) -> wisp.Response {
  case int.parse(category_id) {
    Ok(id) -> {
      case req.method {
        http.Get -> handle_get_category(req, id)
        http.Patch -> handle_update_category(req, id)
        http.Delete -> handle_delete_category(req, id)
        _ -> wisp.method_not_allowed([http.Get, http.Patch, http.Delete])
      }
    }
    Error(_) -> helpers.error_response(400, "Invalid category ID")
  }
}

fn handle_get_category(_req: wisp.Request, id: Int) -> wisp.Response {
  case get_authenticated_client() {
    Ok(config) -> {
      case supermarket_category.get_category(config, category_id: id) {
        Ok(category) -> {
          json.object([
            #("id", json.int(category.id)),
            #("name", json.string(category.name)),
            #(
              "description",
              helpers.encode_optional_string(category.description),
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

fn handle_update_category(req: wisp.Request, id: Int) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_supermarket_category_create_request(body) {
    Ok(request) -> {
      case get_authenticated_client() {
        Ok(config) -> {
          case supermarket_category.update_category(
            config,
            category_id: id,
            category_data: request,
          ) {
            Ok(category) -> {
              json.object([
                #("id", json.int(category.id)),
                #("name", json.string(category.name)),
                #(
                  "description",
                  helpers.encode_optional_string(category.description),
                ),
              ])
              |> json.to_string
              |> wisp.json_response(200)
            }
            Error(_) -> helpers.error_response(500, "Failed to update category")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

fn handle_delete_category(_req: wisp.Request, id: Int) -> wisp.Response {
  case get_authenticated_client() {
    Ok(config) -> {
      case supermarket_category.delete_category(config, id) {
        Ok(Nil) -> wisp.response(204)
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

// =============================================================================
// JSON Decoders
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

fn parse_supermarket_category_create_request(
  json_data: dynamic.Dynamic,
) -> Result(SupermarketCategoryCreateRequest, String) {
  decode.run(json_data, supermarket_category_create_decoder())
  |> result.map_error(fn(_) { "Invalid category create request" })
}

fn supermarket_category_create_decoder() -> decode.Decoder(
  SupermarketCategoryCreateRequest,
) {
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  decode.success(SupermarketCategoryCreateRequest(
    name: name,
    description: description,
  ))
}
