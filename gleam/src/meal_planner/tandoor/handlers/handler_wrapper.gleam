/// Handler wrapper functions for flattening nested case patterns
///
/// Implements GLEAM RULE 3 (PIPE_EVERYTHING) by consolidating the common
/// 3-level nesting pattern found throughout Tandoor handlers:
///
/// 1. Authenticate (get_authenticated_client)
/// 2. API call (list/get/create/update/delete)
/// 3. JSON encode + Response
///
/// This module provides reusable wrappers to flatten this pattern into
/// a single pipeline, reducing boilerplate across ~20+ handler functions.
import gleam/json
import gleam/result
import wisp

// =============================================================================
// Core Handler Wrapper - Flattens Authenticated API Calls
// =============================================================================

/// Flatten authenticated API call into a simple function composition
///
/// Eliminates 3-level nesting by combining:
/// 1. Authentication check
/// 2. API call execution
/// 3. JSON encoding + response
///
/// # Arguments
/// * `auth_fn` - Function that returns Result(Config, Error)
/// * `api_fn` - Function(Config) -> Result(Data, ApiError)
/// * `encode_fn` - Function to encode Data into json.Json
/// * `status_code` - HTTP status code for success
///
/// # Returns
/// Result(#(status, body_string), error_type)
pub fn handle_authenticated_call(
  auth_fn: fn() -> Result(auth_config, auth_error),
  api_fn: fn(auth_config) -> Result(data, api_error),
  encode_fn: fn(data) -> json.Json,
  status_code: Int,
) -> Result(#(Int, String), Nil) {
  // Step 1: Authenticate
  use config <- result.try(
    auth_fn()
    |> result.map_error(fn(_) { Nil }),
  )

  // Step 2: Make API call
  use data <- result.try(
    api_fn(config)
    |> result.map_error(fn(_) { Nil }),
  )

  // Step 3: Encode and build response tuple
  let encoded =
    data
    |> encode_fn
    |> json.to_string

  Ok(#(status_code, encoded))
}

// =============================================================================
// Handler Wrapper - For Request Validation Before Auth
// =============================================================================

/// Flatten pattern: Request validation -> Auth -> API -> Response
///
/// Handles cases where request parsing/validation must occur before
/// authentication (e.g., parsing JSON body).
pub fn handle_validated_authenticated_call(
  validate_fn: fn() -> Result(validated, validation_error),
  auth_fn: fn() -> Result(auth_config, auth_error),
  api_fn: fn(auth_config, validated) -> Result(data, api_error),
  encode_fn: fn(data) -> json.Json,
  status_code: Int,
) -> Result(#(Int, String), Nil) {
  // Step 1: Validate input
  use validated_data <- result.try(
    validate_fn()
    |> result.map_error(fn(_) { Nil }),
  )

  // Step 2: Authenticate
  use config <- result.try(
    auth_fn()
    |> result.map_error(fn(_) { Nil }),
  )

  // Step 3: Make API call with validated data
  use data <- result.try(
    api_fn(config, validated_data)
    |> result.map_error(fn(_) { Nil }),
  )

  // Step 4: Encode and build response
  let encoded =
    data
    |> encode_fn
    |> json.to_string

  Ok(#(status_code, encoded))
}

// =============================================================================
// Handler Wrapper - For ID Validation Before Auth
// =============================================================================

/// Flatten pattern: ID parsing -> Auth -> API -> Response
///
/// Handles common case of parsing integer ID from path parameter before
/// making authenticated API call.
pub fn handle_id_authenticated_call(
  parse_id_fn: fn() -> Result(id, id_error),
  auth_fn: fn() -> Result(auth_config, auth_error),
  api_fn: fn(auth_config, id) -> Result(data, api_error),
  encode_fn: fn(data) -> json.Json,
  status_code: Int,
) -> Result(#(Int, String), Nil) {
  // Step 1: Parse ID
  use id <- result.try(
    parse_id_fn()
    |> result.map_error(fn(_) { Nil }),
  )

  // Step 2: Authenticate
  use config <- result.try(
    auth_fn()
    |> result.map_error(fn(_) { Nil }),
  )

  // Step 3: Make API call with ID
  use data <- result.try(
    api_fn(config, id)
    |> result.map_error(fn(_) { Nil }),
  )

  // Step 4: Encode and respond
  let encoded =
    data
    |> encode_fn
    |> json.to_string

  Ok(#(status_code, encoded))
}

// =============================================================================
// Wisp Response Converters
// =============================================================================

/// Convert handler result to wisp.Response
///
/// Takes a Result containing status code and body, converts it to a
/// wisp.Response for returning from handler functions.
pub fn to_response(
  result: Result(#(Int, String), Nil),
  error_response_fn: fn(Nil) -> wisp.Response,
) -> wisp.Response {
  case result {
    Ok(#(status, body)) -> wisp.json_response(body, status)
    Error(err) -> error_response_fn(err)
  }
}
