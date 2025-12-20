//// Generic CRUD operation helpers
////
//// Consolidates repeated CRUD patterns across Tandoor API handlers.
//// Implements type contracts for list, create, get, update, delete operations.
////
//// GLEAM 7 COMMANDMENTS COMPLIANCE:
//// - RULE 1: Immutability - no var, all data immutable
//// - RULE 2: No nulls - use Option(T) or Result(T, E)
//// - RULE 3: Pipe everything - |> data transformation
//// - RULE 4: Exhaustive matching - all case branches
//// - RULE 5: Labeled arguments - >2 params use labels
//// - RULE 6: Type safety - no dynamic, custom types
//// - RULE 7: FORMAT_OR_DEATH - gleam format --check passes

import gleam/dynamic/decode
import gleam/http
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, ParseError,
}
import meal_planner/tandoor/core/http as core_http
import wisp.{type Request, type Response}

// =============================================================================
// Type Contracts for Generic CRUD
// =============================================================================

/// Generic response envelope for list operations
pub type ListResponse(item) {
  ListResponse(
    count: Int,
    next: Option(String),
    previous: Option(String),
    results: List(item),
  )
}

/// Generic CRUD operation result (either success or error)
pub type CrudResult(item, error) {
  CrudOk(item)
  CrudError(error)
}

// =============================================================================
// Generic CRUD Handler Type
// =============================================================================

/// Generic handler for CRUD operations on a resource
///
/// Type parameters:
/// - `item`: The resource type (e.g., Supermarket, Unit)
/// - `create_req`: Request type for creation
/// - `update_req`: Request type for updates
/// - `error`: Error type from API operations
pub type CrudHandler(item, create_req, update_req, error) {
  CrudHandler(
    /// List: GET /resource with pagination
    list: fn() -> Result(ListResponse(item), error),
    /// Create: POST /resource with request body
    create: fn(create_req) -> Result(item, error),
    /// Get: GET /resource/:id
    get: fn(Int) -> Result(item, error),
    /// Update: PATCH /resource/:id with request body
    update: fn(Int, update_req) -> Result(item, error),
    /// Delete: DELETE /resource/:id
    delete: fn(Int) -> Result(Nil, error),
    /// JSON encoding: item → json.Json
    encode_item: fn(item) -> json.Json,
    /// Error response: error → HTTP response
    error_to_response: fn(error) -> Response,
  )
}

// =============================================================================
// Generic CRUD HTTP Handler Functions
// =============================================================================

/// Handle collection endpoint (GET list or POST create)
///
/// Routes:
/// - GET /resource → list all items with pagination
/// - POST /resource → create new item (not yet implemented)
///
/// ## Example
/// ```gleam
/// let handler = CrudHandler(
///   list: fn() { supermarkets_api.list(config) },
///   // ... other handlers
/// )
/// handle_collection(request, handler)
/// ```
///
/// ## Returns
/// - 200 with JSON list on successful GET
/// - 404 for POST (pending implementation)
/// - 405 for unsupported methods
pub fn handle_collection(
  req: Request,
  handler: CrudHandler(item, create_req, update_req, error),
) -> Response {
  case req.method {
    http.Get -> handle_list(handler)
    http.Post -> wisp.not_found()
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

/// Handle item endpoint (GET, PATCH, DELETE)
///
/// Routes:
/// - GET /resource/:id → get item by ID
/// - PATCH /resource/:id → update item (not yet implemented)
/// - DELETE /resource/:id → delete item by ID
///
/// ## Example
/// ```gleam
/// let handler = CrudHandler(
///   get: fn(id) { supermarkets_api.get(config, id) },
///   delete: fn(id) { supermarkets_api.delete(config, id) },
///   // ... other handlers
/// )
/// handle_item(request, handler, "42")
/// ```
///
/// ## Returns
/// - 200 with JSON item on successful GET
/// - 204 on successful DELETE
/// - 400 if ID is not a valid integer
/// - 404 for PATCH (pending implementation)
/// - 405 for unsupported methods
pub fn handle_item(
  req: Request,
  handler: CrudHandler(item, create_req, update_req, error),
  item_id_str: String,
) -> Response {
  case int.parse(item_id_str) {
    Ok(id) ->
      case req.method {
        http.Get -> handle_get(handler, id)
        http.Patch -> wisp.not_found()
        http.Delete -> handle_delete(handler, id)
        _ -> wisp.method_not_allowed([http.Get, http.Patch, http.Delete])
      }
    Error(_) ->
      wisp.json_response(
        json.to_string(json.object([#("error", json.string("Invalid ID"))])),
        400,
      )
  }
}

// =============================================================================
// Internal Handler Functions
// =============================================================================

fn handle_list(
  handler: CrudHandler(item, create_req, update_req, error),
) -> Response {
  case handler.list() {
    Ok(ListResponse(count, next, previous, results)) -> {
      let results_json = json.array(results, handler.encode_item)
      json.object([
        #("count", json.int(count)),
        #("next", encode_optional_string(next)),
        #("previous", encode_optional_string(previous)),
        #("results", results_json),
      ])
      |> json.to_string
      |> wisp.json_response(200)
    }
    Error(err) -> handler.error_to_response(err)
  }
}

fn handle_get(
  handler: CrudHandler(item, create_req, update_req, error),
  id: Int,
) -> Response {
  case handler.get(id) {
    Ok(item) ->
      handler.encode_item(item)
      |> json.to_string
      |> wisp.json_response(200)
    Error(err) -> handler.error_to_response(err)
  }
}

fn handle_delete(
  handler: CrudHandler(item, create_req, update_req, error),
  id: Int,
) -> Response {
  case handler.delete(id) {
    Ok(Nil) -> wisp.response(204)
    Error(err) -> handler.error_to_response(err)
  }
}

// =============================================================================
// Helper Functions
// =============================================================================

/// Encode optional string to JSON (null if None)
///
/// Used for pagination links (next/previous) which may be null.
///
/// ## Examples
/// ```gleam
/// encode_optional_string(Some("https://api.com/page2"))
/// // => json.string("https://api.com/page2")
///
/// encode_optional_string(None)
/// // => json.null()
/// ```
fn encode_optional_string(opt: Option(String)) -> json.Json {
  case opt {
    option.Some(s) -> json.string(s)
    option.None -> json.null()
  }
}

/// Parse JSON response body using a decoder
fn parse_json_response(
  body: String,
  decoder: decode.Decoder(item),
) -> Result(item, TandoorError) {
  case json.parse(body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, decoder) {
        Ok(item) -> Ok(item)
        Error(errors) -> {
          let error_msg =
            "Failed to decode response: "
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

// =============================================================================
// Generic CRUD API Operations (GREEN PHASE - Minimal Implementation)
// =============================================================================

/// Generic CREATE operation for Tandoor API
///
/// Makes POST request to create a new resource.
///
/// ## Parameters
/// - `config`: Tandoor client configuration (base URL, auth token)
/// - `path`: API endpoint path (e.g., "/api/supermarket/")
/// - `body`: JSON request body as string
/// - `decoder`: Dynamic decoder for parsing response
///
/// ## Example
/// ```gleam
/// let body = json.object([#("name", json.string("Whole Foods"))])
/// create(config, "/api/supermarket/", json.to_string(body), supermarket_decoder)
/// ```
///
/// ## Implementation Notes
/// Use `core_http.post_json` for HTTP POST with authentication.
pub fn create(
  config: ClientConfig,
  path: String,
  body: String,
  decoder: decode.Decoder(item),
) -> Result(item, TandoorError) {
  use req <- result.try(client.build_post_request(config, path, body))
  use resp <- result.try(client.execute_and_parse(req))
  parse_json_response(resp.body, decoder)
}

/// Generic GET operation for Tandoor API
///
/// Makes GET request for a specific resource by ID.
///
/// ## Parameters
/// - `config`: Tandoor client configuration (base URL, auth token)
/// - `path`: API endpoint path without ID (e.g., "/api/supermarket/")
/// - `id`: Resource ID to fetch
/// - `decoder`: Dynamic decoder for parsing response
///
/// ## Example
/// ```gleam
/// get(config, "/api/supermarket/", 42, supermarket_decoder)
/// ```
///
/// ## Implementation Notes
/// Append ID to path and use `core_http.get_json` for authenticated request.
pub fn get(
  config: ClientConfig,
  path: String,
  id: Int,
  decoder: decode.Decoder(item),
) -> Result(item, TandoorError) {
  let full_path = path <> int.to_string(id) <> "/"
  use req <- result.try(client.build_get_request(config, full_path, []))
  use resp <- result.try(client.execute_and_parse(req))
  parse_json_response(resp.body, decoder)
}

/// Generic UPDATE operation for Tandoor API
///
/// Makes PATCH request to update a resource.
///
/// ## Parameters
/// - `config`: Tandoor client configuration (base URL, auth token)
/// - `path`: API endpoint path without ID (e.g., "/api/supermarket/")
/// - `id`: Resource ID to update
/// - `body`: JSON request body with fields to update
/// - `decoder`: Dynamic decoder for parsing updated response
///
/// ## Example
/// ```gleam
/// let body = json.object([#("name", json.string("Whole Foods Market"))])
/// update(config, "/api/supermarket/", 42, json.to_string(body), supermarket_decoder)
/// ```
///
/// ## Implementation Notes
/// Use `core_http.patch_json` for HTTP PATCH with authentication.
pub fn update(
  config: ClientConfig,
  path: String,
  id: Int,
  body: String,
  decoder: decode.Decoder(item),
) -> Result(item, TandoorError) {
  let full_path = path <> int.to_string(id) <> "/"
  use req <- result.try(client.build_patch_request(config, full_path, body))
  use resp <- result.try(client.execute_and_parse(req))
  parse_json_response(resp.body, decoder)
}

/// Generic DELETE operation for Tandoor API
///
/// Makes DELETE request to remove a resource.
///
/// ## Parameters
/// - `config`: Tandoor client configuration (base URL, auth token)
/// - `path`: API endpoint path without ID (e.g., "/api/supermarket/")
/// - `id`: Resource ID to delete
///
/// ## Example
/// ```gleam
/// delete(config, "/api/supermarket/", 42)
/// ```
///
/// ## Implementation Notes
/// Use `core_http.delete` for HTTP DELETE with authentication.
/// Typically returns 204 No Content on success.
pub fn delete(
  config: ClientConfig,
  path: String,
  id: Int,
) -> Result(Nil, TandoorError) {
  let full_path = path <> int.to_string(id) <> "/"
  use req <- result.try(client.build_delete_request(config, full_path))
  use _resp <- result.try(client.execute_and_parse(req))
  Ok(Nil)
}

/// Generic LIST operation for Tandoor API (simple list without pagination)
///
/// Makes GET request to list all resources.
///
/// ## Parameters
/// - `config`: Tandoor client configuration (base URL, auth token)
/// - `path`: API endpoint path (e.g., "/api/supermarket/")
/// - `params`: Query parameters as key-value pairs (e.g., [#("query", "organic")])
/// - `decoder`: Dynamic decoder for parsing individual items
///
/// ## Example
/// ```gleam
/// list(config, "/api/supermarket/", [#("limit", "100")], supermarket_decoder)
/// ```
///
/// ## Implementation Notes
/// Use `core_http.get_json_list` for simple list fetching.
/// For pagination support, use `list_paginated` instead.
pub fn list(
  config: ClientConfig,
  path: String,
  params: List(#(String, String)),
  decoder: decode.Decoder(item),
) -> Result(List(item), TandoorError) {
  use req <- result.try(client.build_get_request(config, path, params))
  use resp <- result.try(client.execute_and_parse(req))
  parse_json_response(resp.body, decode.list(decoder))
}

/// Generic PAGINATED LIST operation for Tandoor API
///
/// Makes GET request to list resources with pagination support.
///
/// ## Parameters
/// - `config`: Tandoor client configuration (base URL, auth token)
/// - `path`: API endpoint path (e.g., "/api/supermarket/")
/// - `params`: Query parameters including pagination (e.g., [#("page", "2"), #("limit", "25")])
/// - `decoder`: Dynamic decoder for parsing individual items
///
/// ## Example
/// ```gleam
/// list_paginated(
///   config,
///   "/api/supermarket/",
///   [#("page", "1"), #("limit", "50")],
///   supermarket_decoder
/// )
/// ```
///
/// ## Returns
/// `PaginatedResponse` with count, next/previous URLs, and results list.
///
/// ## Implementation Notes
/// Use `core_http.get_paginated_json` for paginated list fetching.
/// Response includes next/previous links for navigation.
pub fn list_paginated(
  config: ClientConfig,
  path: String,
  params: List(#(String, String)),
  decoder: decode.Decoder(item),
) -> Result(core_http.PaginatedResponse(item), TandoorError) {
  use req <- result.try(client.build_get_request(config, path, params))
  use resp <- result.try(client.execute_and_parse(req))
  parse_json_response(resp.body, core_http.paginated_decoder(decoder))
}
