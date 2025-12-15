/// Tandoor Cuisines CRUD handlers
///
/// This module provides all CRUD operations for Tandoor cuisines.
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http
import gleam/int
import gleam/json
import gleam/option
import gleam/result

import meal_planner/tandoor/api/cuisine/create as cuisine_create
import meal_planner/tandoor/api/cuisine/delete as cuisine_delete
import meal_planner/tandoor/api/cuisine/get as cuisine_get
import meal_planner/tandoor/api/cuisine/list as cuisine_list
import meal_planner/tandoor/api/cuisine/update as cuisine_update
import meal_planner/tandoor/handlers/helpers
import meal_planner/tandoor/types/cuisine/cuisine

import wisp

/// Handle GET /api/tandoor/cuisines (list cuisines)
/// and POST /api/tandoor/cuisines (create cuisine)
pub fn handle_cuisines_collection(req: wisp.Request) -> wisp.Response {
  case req.method {
    http.Get -> handle_list_cuisines(req)
    http.Post -> handle_create_cuisine(req)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

/// Handle GET /api/tandoor/cuisines/:id (get cuisine)
/// PUT /api/tandoor/cuisines/:id (update cuisine)
/// DELETE /api/tandoor/cuisines/:id (delete cuisine)
pub fn handle_cuisine_by_id(
  req: wisp.Request,
  cuisine_id: String,
) -> wisp.Response {
  case int.parse(cuisine_id) {
    Ok(_id) -> {
      case req.method {
        http.Get -> handle_get_cuisine(req, cuisine_id)
        http.Put -> handle_update_cuisine(req, cuisine_id)
        http.Delete -> handle_delete_cuisine(req, cuisine_id)
        _ -> wisp.method_not_allowed([http.Get, http.Put, http.Delete])
      }
    }
    Error(_) -> helpers.error_response(400, "Invalid cuisine ID")
  }
}

/// List all cuisines with optional parent filtering
pub fn handle_list_cuisines(req: wisp.Request) -> wisp.Response {
  let query = wisp.get_query(req)
  let parent_filter = helpers.parse_int_param(query, "parent")

  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case cuisine_list.list_cuisines_by_parent(config, parent_filter) {
        Ok(cuisines) -> {
          json.array(cuisines, fn(cuisine) {
            json.object([
              #("id", json.int(cuisine.id)),
              #("name", json.string(cuisine.name)),
              #(
                "description",
                helpers.encode_optional_string(cuisine.description),
              ),
              #("icon", helpers.encode_optional_string(cuisine.icon)),
              #("parent", case cuisine.parent {
                option.Some(parent_id) -> json.int(parent_id)
                option.None -> json.null()
              }),
              #("num_recipes", json.int(cuisine.num_recipes)),
              #("created_at", json.string(cuisine.created_at)),
              #("updated_at", json.string(cuisine.updated_at)),
            ])
          })
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> helpers.error_response(500, "Failed to list cuisines")
      }
    }
    Error(resp) -> resp
  }
}

/// Get a single cuisine by ID
pub fn handle_get_cuisine(
  _req: wisp.Request,
  cuisine_id: String,
) -> wisp.Response {
  case int.parse(cuisine_id) {
    Ok(id) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case cuisine_get.get_cuisine(config, cuisine_id: id) {
            Ok(cuisine) -> {
              json.object([
                #("id", json.int(cuisine.id)),
                #("name", json.string(cuisine.name)),
                #(
                  "description",
                  helpers.encode_optional_string(cuisine.description),
                ),
                #("icon", helpers.encode_optional_string(cuisine.icon)),
                #("parent", case cuisine.parent {
                  option.Some(parent_id) -> json.int(parent_id)
                  option.None -> json.null()
                }),
                #("num_recipes", json.int(cuisine.num_recipes)),
                #("created_at", json.string(cuisine.created_at)),
                #("updated_at", json.string(cuisine.updated_at)),
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
    Error(_) -> helpers.error_response(400, "Invalid cuisine ID")
  }
}

/// Create a new cuisine
pub fn handle_create_cuisine(req: wisp.Request) -> wisp.Response {
  use json_body <- wisp.require_json(req)

  case parse_cuisine_create_request(json_body) {
    Ok(cuisine_request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case cuisine_create.create_cuisine(config, cuisine_request) {
            Ok(cuisine) -> {
              json.object([
                #("id", json.int(cuisine.id)),
                #("name", json.string(cuisine.name)),
                #(
                  "description",
                  helpers.encode_optional_string(cuisine.description),
                ),
                #("icon", helpers.encode_optional_string(cuisine.icon)),
                #("parent", case cuisine.parent {
                  option.Some(parent_id) -> json.int(parent_id)
                  option.None -> json.null()
                }),
                #("num_recipes", json.int(cuisine.num_recipes)),
                #("created_at", json.string(cuisine.created_at)),
                #("updated_at", json.string(cuisine.updated_at)),
              ])
              |> json.to_string
              |> wisp.json_response(201)
            }
            Error(_) -> helpers.error_response(500, "Failed to create cuisine")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

/// Update an existing cuisine
pub fn handle_update_cuisine(
  req: wisp.Request,
  cuisine_id: String,
) -> wisp.Response {
  use json_body <- wisp.require_json(req)

  case int.parse(cuisine_id) {
    Ok(id) -> {
      case parse_cuisine_update_request(json_body) {
        Ok(cuisine_request) -> {
          case helpers.get_authenticated_client() {
            Ok(config) -> {
              case
                cuisine_update.update_cuisine(
                  config,
                  cuisine_id: id,
                  data: cuisine_request,
                )
              {
                Ok(cuisine) -> {
                  json.object([
                    #("id", json.int(cuisine.id)),
                    #("name", json.string(cuisine.name)),
                    #(
                      "description",
                      helpers.encode_optional_string(cuisine.description),
                    ),
                    #("icon", helpers.encode_optional_string(cuisine.icon)),
                    #("parent", case cuisine.parent {
                      option.Some(parent_id) -> json.int(parent_id)
                      option.None -> json.null()
                    }),
                    #("num_recipes", json.int(cuisine.num_recipes)),
                    #("created_at", json.string(cuisine.created_at)),
                    #("updated_at", json.string(cuisine.updated_at)),
                  ])
                  |> json.to_string
                  |> wisp.json_response(200)
                }
                Error(_) ->
                  helpers.error_response(500, "Failed to update cuisine")
              }
            }
            Error(resp) -> resp
          }
        }
        Error(msg) -> helpers.error_response(400, msg)
      }
    }
    Error(_) -> helpers.error_response(400, "Invalid cuisine ID")
  }
}

/// Delete a cuisine
pub fn handle_delete_cuisine(
  _req: wisp.Request,
  cuisine_id: String,
) -> wisp.Response {
  case int.parse(cuisine_id) {
    Ok(id) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case cuisine_delete.delete_cuisine(config, cuisine_id: id) {
            Ok(_) -> wisp.no_content()
            Error(_) -> helpers.error_response(500, "Failed to delete cuisine")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(_) -> helpers.error_response(400, "Invalid cuisine ID")
  }
}

// =============================================================================
// JSON Decoders for Cuisine Requests
// =============================================================================

/// Decoder for cuisine create request
fn cuisine_create_decoder() -> decode.Decoder(cuisine.CuisineCreateRequest) {
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  use icon <- decode.field("icon", decode.optional(decode.string))
  use parent <- decode.field("parent", decode.optional(decode.int))
  decode.success(cuisine.CuisineCreateRequest(
    name: name,
    description: description,
    icon: icon,
    parent: parent,
  ))
}

/// Decoder for cuisine update request
fn cuisine_update_decoder() -> decode.Decoder(cuisine.CuisineUpdateRequest) {
  use name <- decode.field("name", decode.optional(decode.string))
  use description <- decode.field(
    "description",
    decode.optional(decode.optional(decode.string)),
  )
  use icon <- decode.field(
    "icon",
    decode.optional(decode.optional(decode.string)),
  )
  use parent <- decode.field(
    "parent",
    decode.optional(decode.optional(decode.int)),
  )
  decode.success(cuisine.CuisineUpdateRequest(
    name: name,
    description: description,
    icon: icon,
    parent: parent,
  ))
}

/// Parse JSON body into CuisineCreateRequest
fn parse_cuisine_create_request(
  json_data: dynamic.Dynamic,
) -> Result(cuisine.CuisineCreateRequest, String) {
  decode.run(json_data, cuisine_create_decoder())
  |> result.map_error(fn(_) { "Invalid cuisine create request" })
}

/// Parse JSON body into CuisineUpdateRequest
fn parse_cuisine_update_request(
  json_data: dynamic.Dynamic,
) -> Result(cuisine.CuisineUpdateRequest, String) {
  decode.run(json_data, cuisine_update_decoder())
  |> result.map_error(fn(_) { "Invalid cuisine update request" })
}
