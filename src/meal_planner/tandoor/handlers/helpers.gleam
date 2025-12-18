/// Common helpers for Tandoor HTTP handlers
///
/// Consolidates duplicate code across multiple handlers:
/// - JSON encoding for optional values
/// - Query parameter parsing
/// - Success/error response builders
/// - Tandoor entity JSON encoders
/// - Authentication client setup
import gleam/float
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/env
import meal_planner/tandoor/client
import wisp

// =============================================================================
// Authentication & Client Setup
// =============================================================================

/// Get Tandoor client config with authentication
///
/// Loads Tandoor configuration from environment variables, creates a session
/// config, and authenticates with the Tandoor server.
///
/// # Returns
/// - Ok(ClientConfig) - Authenticated client configuration ready to use
/// - Error(wisp.Response) - HTTP error response with appropriate status code
pub fn get_authenticated_client() -> Result(client.ClientConfig, wisp.Response) {
  case env.load_tandoor_config() {
    Some(tandoor_cfg) -> {
      let config =
        client.session_config(
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
          Error(error_response(status, message))
        }
      }
    }
    None -> Error(error_response(502, "Tandoor not configured"))
  }
}

// =============================================================================
// Handler Composition - Flattened Pipeline Utilities
// =============================================================================

/// Execute authenticated API call in Result pipeline
///
/// Flattens nested case expressions by combining authentication + API call.
/// Returns Result for use in pipelines, avoiding nested case boilerplate.
///
/// # Example
/// ```gleam
/// use config <- result.try(authenticated_api_call())
/// use results <- result.map(api_function(config))
/// json.to_string(encode_results(results))
/// |> wisp.json_response(200)
/// ```
pub fn authenticated_api_call() -> Result(client.ClientConfig, wisp.Response) {
  get_authenticated_client()
}

/// Flatten Result into wisp.Response with JSON encoding
///
/// Takes a Result containing data to encode and converts it into an HTTP response.
/// Eliminates manual case expressions when combined with authentication pipeline.
///
/// # Arguments
/// * `result` - Result(T, E) from API call
/// * `encode_fn` - Function to encode T into json.Json
/// * `status` - HTTP status code for success
/// * `error_msg` - Error message for failures
///
/// # Returns
/// wisp.Response with encoded data or error
pub fn flatten_api_result(
  result: Result(a, Nil),
  encode_fn: fn(a) -> json.Json,
  status: Int,
  error_msg: String,
) -> wisp.Response {
  case result {
    Ok(data) -> {
      encode_fn(data)
      |> json.to_string
      |> wisp.json_response(status)
    }
    Error(_) -> error_response(500, error_msg)
  }
}

/// Flatten authentication + API call result into response
///
/// Single-step flattening of the 3-level pattern:
/// 1. get_authenticated_client()
/// 2. api_call(config)
/// 3. JSON encode + Response
///
/// Usage:
/// ```gleam
/// let result = api_call(config)
/// flatten_authenticated_result(result, encode_fn, 200, "API failed")
/// ```
pub fn flatten_authenticated_result(
  result: Result(a, Nil),
  encode_fn: fn(a) -> json.Json,
  status: Int,
  error_msg: String,
) -> wisp.Response {
  flatten_api_result(result, encode_fn, status, error_msg)
}

// =============================================================================
// Optional Value JSON Encoders
// =============================================================================

/// Encode an optional String to JSON (null if None)
pub fn encode_optional_string(opt: Option(String)) -> json.Json {
  case opt {
    Some(s) -> json.string(s)
    None -> json.null()
  }
}

/// Encode an optional Int to JSON (null if None)
pub fn encode_optional_int(opt: Option(Int)) -> json.Json {
  case opt {
    Some(i) -> json.int(i)
    None -> json.null()
  }
}

/// Encode an optional Float to JSON (null if None)
pub fn encode_optional_float(opt: Option(Float)) -> json.Json {
  case opt {
    Some(f) -> json.float(f)
    None -> json.null()
  }
}

// =============================================================================
// Query Parameter Parsing
// =============================================================================

/// Get query parameter value by key, returning Option(String)
pub fn get_query_param(
  params: List(#(String, String)),
  key: String,
) -> Option(String) {
  list.find(params, fn(param) { param.0 == key })
  |> result.map(fn(param) { param.1 })
  |> option.from_result
}

/// Parse optional integer query parameter
pub fn parse_int_param(
  params: List(#(String, String)),
  key: String,
) -> Option(Int) {
  params
  |> list.key_find(key)
  |> result.try(fn(s) {
    case string.is_empty(s) {
      True -> Error(Nil)
      False -> int.parse(s)
    }
  })
  |> option.from_result
}

/// Parse optional float query parameter
pub fn parse_float_param(
  params: List(#(String, String)),
  key: String,
) -> Option(Float) {
  params
  |> list.key_find(key)
  |> result.try(fn(s) {
    case string.is_empty(s) {
      True -> Error(Nil)
      False ->
        string.replace(s, ",", ".")
        |> float.parse
    }
  })
  |> option.from_result
}

// =============================================================================
// Response Builders
// =============================================================================

/// Create a JSON error response
pub fn error_response(status: Int, message: String) -> wisp.Response {
  json.object([#("error", json.string(message))])
  |> json.to_string
  |> wisp.json_response(status)
}

/// Create a success response with custom data
pub fn success_response(data: json.Json) -> wisp.Response {
  wisp.json_response(json.to_string(data), 200)
}

/// Create a simple success message response
pub fn success_message(message: String) -> wisp.Response {
  json.object([
    #("success", json.bool(True)),
    #("message", json.string(message)),
  ])
  |> json.to_string
  |> wisp.json_response(200)
}

/// Create a created response (201) with resource data
pub fn created_response(data: json.Json) -> wisp.Response {
  wisp.json_response(json.to_string(data), 201)
}

// =============================================================================
// Validation Helpers
// =============================================================================

/// Clamp an integer to a range
pub fn clamp(value: Int, min: Int, max: Int) -> Int {
  case value {
    _ if value < min -> min
    _ if value > max -> max
    _ -> value
  }
}

/// Clamp pagination limit to valid range (1-100)
pub fn clamp_limit(limit: Int) -> Int {
  clamp(limit, 1, 100)
}

/// Validate that a required string parameter is not empty
pub fn validate_required_string(
  value: Option(String),
  param_name: String,
) -> Result(String, #(Int, String)) {
  case value {
    None -> Error(#(400, "Missing required parameter: " <> param_name))
    Some(s) -> {
      case string.is_empty(s) {
        True ->
          Error(#(400, "Parameter '" <> param_name <> "' cannot be empty"))
        False -> Ok(s)
      }
    }
  }
}

/// Validate that an optional string is not empty if provided
pub fn validate_optional_string(
  value: Option(String),
  param_name: String,
) -> Result(Option(String), #(Int, String)) {
  case value {
    None -> Ok(None)
    Some(s) -> {
      case string.is_empty(s) {
        True ->
          Error(#(400, "Parameter '" <> param_name <> "' cannot be empty"))
        False -> Ok(Some(s))
      }
    }
  }
}

// =============================================================================
// Pagination Response Builder
// =============================================================================

/// Build a paginated response with count and results
pub fn paginated_response(
  results: json.Json,
  count: Int,
  next: Option(String),
  previous: Option(String),
) -> json.Json {
  json.object([
    #("count", json.int(count)),
    #("next", encode_optional_string(next)),
    #("previous", encode_optional_string(previous)),
    #("results", results),
  ])
}
