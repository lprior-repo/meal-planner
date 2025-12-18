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
import gleam/option.{type Option}
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
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
/// - GET /resource → list all items
/// - POST /resource → create new item
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
/// - GET /resource/:id → get item
/// - PATCH /resource/:id → update item
/// - DELETE /resource/:id → delete item
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
fn encode_optional_string(opt: Option(String)) -> json.Json {
  case opt {
    option.Some(s) -> json.string(s)
    option.None -> json.null()
  }
}

// =============================================================================
// Generic CRUD API Operations (GREEN PHASE - Minimal Implementation)
// =============================================================================

/// Generic CREATE operation for Tandoor API
///
/// Makes POST request to create a new resource
pub fn create(
  _config: ClientConfig,
  _path: String,
  _body: String,
  _decoder: decode.Decoder(item),
) -> Result(item, TandoorError) {
  // TODO: Implement HTTP POST request
  todo as "Generic create not yet implemented"
}

/// Generic GET operation for Tandoor API
///
/// Makes GET request for a specific resource by ID
pub fn get(
  _config: ClientConfig,
  _path: String,
  _id: Int,
  _decoder: decode.Decoder(item),
) -> Result(item, TandoorError) {
  // TODO: Implement HTTP GET request
  todo as "Generic get not yet implemented"
}

/// Generic UPDATE operation for Tandoor API
///
/// Makes PATCH request to update a resource
pub fn update(
  _config: ClientConfig,
  _path: String,
  _id: Int,
  _body: String,
  _decoder: decode.Decoder(item),
) -> Result(item, TandoorError) {
  // TODO: Implement HTTP PATCH request
  todo as "Generic update not yet implemented"
}

/// Generic DELETE operation for Tandoor API
///
/// Makes DELETE request to remove a resource
pub fn delete(
  _config: ClientConfig,
  _path: String,
  _id: Int,
) -> Result(Nil, TandoorError) {
  // TODO: Implement HTTP DELETE request
  todo as "Generic delete not yet implemented"
}

/// Generic LIST operation for Tandoor API (simple list without pagination)
///
/// Makes GET request to list all resources
pub fn list(
  _config: ClientConfig,
  _path: String,
  _params: List(#(String, String)),
  _decoder: decode.Decoder(item),
) -> Result(List(item), TandoorError) {
  // TODO: Implement HTTP GET request for list
  todo as "Generic list not yet implemented"
}

/// Generic PAGINATED LIST operation for Tandoor API
///
/// Makes GET request to list resources with pagination support
pub fn list_paginated(
  _config: ClientConfig,
  _path: String,
  _params: List(#(String, String)),
  _decoder: decode.Decoder(item),
) -> Result(core_http.PaginatedResponse(item), TandoorError) {
  // TODO: Implement HTTP GET request with pagination
  todo as "Generic list_paginated not yet implemented"
}
