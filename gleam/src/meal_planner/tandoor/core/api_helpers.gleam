/// Tandoor API Helper Functions
///
/// This module provides DRY helper functions for common API patterns:
/// - Sending requests and decoding JSON responses
/// - Sending requests that expect no response body (DELETE operations)
///
/// These helpers eliminate repetitive error handling code across API modules.
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import meal_planner/tandoor/client.{
  type ApiResponse, type TandoorError, ApiResponse, NetworkError, ParseError,
}

// ============================================================================
// Core API Helpers
// ============================================================================

/// Send an HTTP request and decode the JSON response
///
/// This helper combines three common steps:
/// 1. Execute the HTTP request
/// 2. Parse the JSON response
/// 3. Decode the JSON data using the provided decoder
///
/// # Arguments
/// * `request` - The HTTP request to send
/// * `decoder` - Decoder to parse JSON into desired type
///
/// # Returns
/// Result with decoded value or TandoorError
///
/// # Example
/// ```gleam
/// let req = build_get_request(config, "/api/recipe/123/", [])
/// use recipe <- result.try(send_and_decode(req, recipe_decoder()))
/// ```
pub fn send_and_decode(
  request: request.Request(String),
  decoder: decode.Decoder(a),
) -> Result(a, TandoorError) {
  // Execute request and get parsed response
  use resp <- result.try(execute_and_parse(request))

  // Parse and decode JSON body
  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, decoder) {
        Ok(value) -> Ok(value)
        Error(errors) -> {
          // Format decode errors into human-readable message
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

/// Send an HTTP request expecting no response body
///
/// This helper is designed for DELETE operations and other requests
/// that return 204 No Content or similar status codes.
///
/// # Arguments
/// * `request` - The HTTP request to send
///
/// # Returns
/// Result with Nil on success or TandoorError
///
/// # Example
/// ```gleam
/// let req = build_delete_request(config, "/api/recipe/123/")
/// use _ <- result.try(send_no_content(req))
/// ```
pub fn send_no_content(
  request: request.Request(String),
) -> Result(Nil, TandoorError) {
  use _resp <- result.try(
    httpc.send(request)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )
  Ok(Nil)
}

// ============================================================================
// Internal Helpers
// ============================================================================

/// Execute request and parse HTTP response
///
/// Internal helper that combines execute_request and parse_response
/// from the client module.
fn execute_and_parse(
  req: request.Request(String),
) -> Result(ApiResponse, TandoorError) {
  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Convert httpc Response to our ApiResponse type
  Ok(ApiResponse(status: resp.status, headers: resp.headers, body: resp.body))
}
