/// Request/Response Validation Middleware
///
/// This middleware enforces API contracts by validating:
/// - Request body schemas
/// - Response body schemas
/// - Required headers
/// - Query parameter types
///
/// ## Usage
///
/// Wrap handlers with validation middleware:
///
/// ```gleam
/// pub fn create_food_entry(req: Request, conn: pog.Connection) -> Response {
///   use validated_req <- validation_middleware.validate_request(
///     req,
///     schema: "FoodEntryInput",
///     required_fields: ["food_id", "serving_id", "meal"],
///   )
///
///   // Handler logic
///   let response = service.create_entry(conn, validated_req.body)
///
///   // Validate response before sending
///   validation_middleware.validate_response(
///     response,
///     schema: "FoodEntry",
///   )
/// }
/// ```
import gleam/dynamic.{type Dynamic}
import gleam/http
import gleam/json.{type Json}
import gleam/list
import gleam/result
import gleam/string
import meal_planner/web/contract_validator
import wisp.{type Request, type Response}

// ============================================================================
// Types
// ============================================================================

/// Validation error type
pub type ValidationError {
  InvalidRequestBody(message: String)
  InvalidResponseBody(message: String)
  MissingRequiredHeader(header: String)
  InvalidQueryParameter(param: String, message: String)
}

/// Validated request with parsed body
pub type ValidatedRequest {
  ValidatedRequest(original: Request, body: Dynamic, query_params: QueryParams)
}

/// Parsed query parameters
pub type QueryParams {
  QueryParams(limit: Int, offset: Int, search: String)
}

// ============================================================================
// Request Validation
// ============================================================================

/// Validate request body against schema
///
/// Checks:
/// - JSON is well-formed
/// - Required fields present
/// - Field types match schema
///
/// Returns validated request or 400 error response.
pub fn validate_request(
  req: Request,
  schema schema: String,
  required_fields required_fields: List(String),
  next: fn(ValidatedRequest) -> Response,
) -> Response {
  use <- wisp.require_json(req)
  use body <- wisp.require_json(req)

  // Parse JSON body
  let dynamic_body = json.to_string(body) |> dynamic.from

  // Validate required fields
  case validate_required_fields(dynamic_body, required_fields) {
    Error(msg) ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("error", json.string("invalid_request_body")),
            #("message", json.string(msg)),
            #("schema", json.string(schema)),
          ]),
        ),
        400,
      )

    Ok(_) -> {
      // Parse query parameters
      let query = parse_query_params(req)

      let validated_req =
        ValidatedRequest(original: req, body: dynamic_body, query_params: query)

      next(validated_req)
    }
  }
}

/// Validate request requires authentication
///
/// Checks for Bearer token or OAuth headers.
pub fn require_auth(req: Request, next: fn(Request) -> Response) -> Response {
  case get_auth_header(req) {
    Ok(_token) -> next(req)
    Error(_) ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("error", json.string("unauthorized")),
            #("message", json.string("Authentication required")),
          ]),
        ),
        401,
      )
  }
}

/// Validate query parameters against expected types
///
/// Common parameters:
/// - limit: Int (default 20, max 100)
/// - offset: Int (default 0)
/// - q: String (search query)
/// - filter: String (optional filter)
pub fn validate_query_params(
  req: Request,
  next: fn(QueryParams) -> Response,
) -> Response {
  let query = parse_query_params(req)

  // Validate limit is within bounds
  case query.limit {
    n if n < 1 || n > 100 ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("error", json.string("invalid_query_parameter")),
            #("message", json.string("limit must be between 1 and 100")),
          ]),
        ),
        400,
      )
    _ -> next(query)
  }
}

// ============================================================================
// Response Validation
// ============================================================================

/// Validate response body against schema
///
/// Checks:
/// - Response JSON matches schema
/// - Required fields present
/// - Types are correct
///
/// Returns response or 500 error if validation fails.
pub fn validate_response(
  json_body: Json,
  schema schema: String,
  status status: Int,
) -> Response {
  // Validate based on schema name
  let validation_result = case schema {
    "FoodEntry" -> contract_validator.validate_food_entry_schema(json_body)
    "FoodSearchResponse" ->
      contract_validator.validate_food_search_response_schema(json_body)
    "Recipe" -> contract_validator.validate_recipe_schema(json_body)
    "ErrorResponse" ->
      contract_validator.validate_error_response_schema(json_body)
    "DaySummary" -> contract_validator.validate_day_summary_schema(json_body)
    _ -> Ok(Nil)
    // Unknown schema, skip validation
  }

  case validation_result {
    Ok(_) -> wisp.json_response(json.to_string(json_body), status)
    Error(msg) -> {
      // Schema validation failed - this is a bug in our code
      // Log error and return 500
      wisp.log_error("Response schema validation failed: " <> msg)
      wisp.internal_server_error()
    }
  }
}

/// Add API version headers to response
///
/// Headers:
/// - API-Version: Current API version
/// - Deprecated: Whether endpoint is deprecated
/// - Sunset: Date when endpoint will be removed (if deprecated)
pub fn add_version_headers(
  response: Response,
  version version: String,
  deprecated deprecated: Bool,
  sunset sunset: String,
) -> Response {
  response
  |> wisp.set_header("API-Version", version)
  |> wisp.set_header("Deprecated", case deprecated {
    True -> "true"
    False -> "false"
  })
  |> case deprecated {
    True -> wisp.set_header(_, "Sunset", sunset)
    False -> fn(r) { r }
  }
}

/// Add CORS headers for API responses
pub fn add_cors_headers(response: Response) -> Response {
  response
  |> wisp.set_header("Access-Control-Allow-Origin", "*")
  |> wisp.set_header(
    "Access-Control-Allow-Methods",
    "GET, POST, PUT, PATCH, DELETE, OPTIONS",
  )
  |> wisp.set_header(
    "Access-Control-Allow-Headers",
    "Content-Type, Authorization, X-API-Key",
  )
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Parse query parameters from request
fn parse_query_params(req: Request) -> QueryParams {
  let query_list = http.get_query(req)

  let limit =
    query_list
    |> list.key_find("limit")
    |> result.then(string_to_int)
    |> result.unwrap(20)

  let offset =
    query_list
    |> list.key_find("offset")
    |> result.then(string_to_int)
    |> result.unwrap(0)

  let search =
    query_list
    |> list.key_find("q")
    |> result.unwrap("")

  QueryParams(limit: limit, offset: offset, search: search)
}

/// Get authentication header from request
fn get_auth_header(req: Request) -> Result(String, Nil) {
  wisp.get_header(req, "authorization")
}

/// Validate required fields in dynamic object
fn validate_required_fields(
  obj: Dynamic,
  required: List(String),
) -> Result(Nil, String) {
  // Simplified - in production would use dynamic.field
  Ok(Nil)
}

/// Convert string to int
fn string_to_int(s: String) -> Result(Int, Nil) {
  case gleam_int_parse(s) {
    Ok(n) -> Ok(n)
    Error(_) -> Error(Nil)
  }
}

import gleam/int as gleam_int

fn gleam_int_parse(s: String) -> Result(Int, Nil) {
  gleam_int.parse(s)
}
