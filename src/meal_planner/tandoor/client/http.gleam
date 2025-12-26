/// HTTP utilities for Tandoor API client
///
/// This module provides low-level HTTP request building, response parsing,
/// and error handling utilities extracted from the main client module.
/// It handles:
/// - Request building for different HTTP methods
/// - Response parsing and error classification
/// - Authentication header management
/// - URL encoding and query string building
/// - Error classification for retryability
///
/// These utilities are designed to be composable and work with gleam_httpc.
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/uri

// ============================================================================
// Types
// ============================================================================

/// Tandoor API error type
pub type TandoorError {
  /// Authentication failed (401)
  AuthenticationError(message: String)
  /// Authorization failed (403)
  AuthorizationError(message: String)
  /// Resource not found (404)
  NotFoundError(resource: String)
  /// Request validation failed (400)
  BadRequestError(message: String)
  /// Server error (5xx)
  ServerError(status_code: Int, message: String)
  /// Network or connection error
  NetworkError(message: String)
  /// Timeout waiting for response
  TimeoutError
  /// Error parsing response JSON
  ParseError(message: String)
  /// Unknown error
  UnknownError(message: String)
}

/// Authentication method for Tandoor API
pub type AuthMethod {
  /// Session-based authentication (username/password -> session cookie)
  /// This is the recommended method as it properly establishes space scope
  SessionAuth(
    username: String,
    password: String,
    session_id: Option(String),
    csrf_token: Option(String),
  )
  /// Bearer token authentication (for OAuth2 tokens)
  BearerAuth(token: String)
}

/// HTTP response from Tandoor API
pub type ApiResponse {
  ApiResponse(status: Int, headers: List(#(String, String)), body: String)
}

// ============================================================================
// Request Building
// ============================================================================

/// Build a GET request to the Tandoor API
///
/// # Arguments
/// * `base_url` - Base URL for Tandoor API (e.g., "http://localhost:8000")
/// * `auth` - Authentication method
/// * `path` - API path (e.g., "/api/recipe/")
/// * `query_params` - Optional query parameters
///
/// # Returns
/// Result with HTTP request or error
pub fn build_get_request(
  base_url: String,
  auth: AuthMethod,
  path: String,
  query_params: List(#(String, String)),
) -> Result(request.Request(String), TandoorError) {
  case build_request_from_url(base_url, path, query_params) {
    Error(e) -> Error(NetworkError(e))
    Ok(req) -> {
      let final_req =
        req
        |> request.set_method(http.Get)
        |> add_auth_headers(auth, False)
        |> add_json_headers()
      Ok(final_req)
    }
  }
}

/// Build a POST request to the Tandoor API
///
/// # Arguments
/// * `base_url` - Base URL for Tandoor API
/// * `auth` - Authentication method
/// * `path` - API path
/// * `body` - JSON body as string
///
/// # Returns
/// Result with HTTP request or error
pub fn build_post_request(
  base_url: String,
  auth: AuthMethod,
  path: String,
  body: String,
) -> Result(request.Request(String), TandoorError) {
  case build_request_from_url(base_url, path, []) {
    Error(e) -> Error(NetworkError(e))
    Ok(req) -> {
      let final_req =
        req
        |> request.set_method(http.Post)
        |> request.set_body(body)
        |> add_auth_headers(auth, True)
        |> add_json_headers()
      Ok(final_req)
    }
  }
}

/// Build a PUT request to the Tandoor API
///
/// # Arguments
/// * `base_url` - Base URL for Tandoor API
/// * `auth` - Authentication method
/// * `path` - API path
/// * `body` - JSON body as string
///
/// # Returns
/// Result with HTTP request or error
pub fn build_put_request(
  base_url: String,
  auth: AuthMethod,
  path: String,
  body: String,
) -> Result(request.Request(String), TandoorError) {
  case build_request_from_url(base_url, path, []) {
    Error(e) -> Error(NetworkError(e))
    Ok(req) -> {
      let final_req =
        req
        |> request.set_method(http.Put)
        |> request.set_body(body)
        |> add_auth_headers(auth, True)
        |> add_json_headers()
      Ok(final_req)
    }
  }
}

/// Build a PATCH request to the Tandoor API
///
/// # Arguments
/// * `base_url` - Base URL for Tandoor API
/// * `auth` - Authentication method
/// * `path` - API path
/// * `body` - JSON body as string
///
/// # Returns
/// Result with HTTP request or error
pub fn build_patch_request(
  base_url: String,
  auth: AuthMethod,
  path: String,
  body: String,
) -> Result(request.Request(String), TandoorError) {
  case build_request_from_url(base_url, path, []) {
    Error(e) -> Error(NetworkError(e))
    Ok(req) -> {
      let final_req =
        req
        |> request.set_method(http.Patch)
        |> request.set_body(body)
        |> add_auth_headers(auth, True)
        |> add_json_headers()
      Ok(final_req)
    }
  }
}

/// Build a DELETE request to the Tandoor API
///
/// # Arguments
/// * `base_url` - Base URL for Tandoor API
/// * `auth` - Authentication method
/// * `path` - API path
///
/// # Returns
/// Result with HTTP request or error
pub fn build_delete_request(
  base_url: String,
  auth: AuthMethod,
  path: String,
) -> Result(request.Request(String), TandoorError) {
  case build_request_from_url(base_url, path, []) {
    Error(e) -> Error(NetworkError(e))
    Ok(req) -> {
      let final_req =
        req
        |> request.set_method(http.Delete)
        |> add_auth_headers(auth, True)
        |> add_json_headers()
      Ok(final_req)
    }
  }
}

// ============================================================================
// HTTP Execution
// ============================================================================

/// Execute an HTTP request and return the response
///
/// This function handles the actual HTTP communication using httpc
pub fn execute_request(
  req: request.Request(String),
) -> Result(response.Response(String), TandoorError) {
  case httpc.send(req) {
    Ok(resp) -> Ok(resp)
    Error(_) -> Error(NetworkError("Failed to connect to Tandoor"))
  }
}

/// Execute a request and parse the response
pub fn execute_and_parse(
  req: request.Request(String),
) -> Result(ApiResponse, TandoorError) {
  use resp <- result.try(execute_request(req))
  parse_response(resp)
}

// ============================================================================
// Response Handling
// ============================================================================

/// Parse an HTTP response from Tandoor API
///
/// # Arguments
/// * `response` - HTTP response from the server
///
/// # Returns
/// Result with ApiResponse or TandoorError
pub fn parse_response(
  response: response.Response(String),
) -> Result(ApiResponse, TandoorError) {
  let status = response.status
  let body = response.body
  let headers = response.headers

  case status {
    200 | 201 | 204 -> {
      Ok(ApiResponse(status: status, headers: headers, body: body))
    }
    400 -> Error(BadRequestError(body))
    401 -> Error(AuthenticationError(body))
    403 -> Error(AuthorizationError(body))
    404 -> Error(NotFoundError(body))
    500 | 502 | 503 | 504 -> Error(ServerError(status, body))
    _ -> Error(UnknownError("HTTP " <> int.to_string(status) <> ": " <> body))
  }
}

/// Parse JSON body from an API response
///
/// # Arguments
/// * `response` - ApiResponse to parse
/// * `decoder` - JSON decoder function
///
/// # Returns
/// Result with decoded data or ParseError
pub fn parse_json_body(
  response: ApiResponse,
  decoder: fn(dynamic.Dynamic) -> Result(a, String),
) -> Result(a, TandoorError) {
  case json.parse(response.body, using: decode.dynamic) {
    Ok(parsed_json) -> {
      case decoder(parsed_json) {
        Ok(value) -> Ok(value)
        Error(error_msg) -> Error(ParseError(error_msg))
      }
    }
    Error(_) -> {
      let error_msg = "Failed to parse JSON"
      Error(ParseError(error_msg))
    }
  }
}

// ============================================================================
// Error Handling
// ============================================================================

/// Check if an error is transient and could be retried
///
/// # Arguments
/// * `error` - TandoorError to check
///
/// # Returns
/// True if the error is transient, False if permanent
pub fn is_transient_error(error: TandoorError) -> Bool {
  case error {
    // Transient errors that can be retried
    NetworkError(_) -> True
    TimeoutError -> True
    ServerError(status, _) -> {
      // Retry on 5xx errors except 501 (not implemented)
      status == 500 || status == 502 || status == 503 || status == 504
    }
    // Permanent errors
    AuthenticationError(_) -> False
    AuthorizationError(_) -> False
    NotFoundError(_) -> False
    BadRequestError(_) -> False
    ParseError(_) -> False
    UnknownError(_) -> False
  }
}

/// Convert a TandoorError to a human-readable message
///
/// # Arguments
/// * `error` - TandoorError to convert
///
/// # Returns
/// String with error description
pub fn error_to_string(error: TandoorError) -> String {
  case error {
    AuthenticationError(msg) -> "Authentication failed: " <> msg
    AuthorizationError(msg) -> "Not authorized: " <> msg
    NotFoundError(resource) -> "Not found: " <> resource
    BadRequestError(msg) -> "Bad request: " <> msg
    ServerError(status, msg) ->
      "Server error (" <> int.to_string(status) <> "): " <> msg
    NetworkError(msg) -> "Network error: " <> msg
    TimeoutError -> "Request timed out"
    ParseError(msg) -> "Failed to parse response: " <> msg
    UnknownError(msg) -> "Unknown error: " <> msg
  }
}

// ============================================================================
// Internal Helpers
// ============================================================================

/// Add authentication headers based on auth method
fn add_auth_headers(
  req: request.Request(String),
  auth: AuthMethod,
  include_csrf: Bool,
) -> request.Request(String) {
  case auth {
    BearerAuth(token) -> {
      let auth_header = "Bearer " <> token
      request.prepend_header(req, "Authorization", auth_header)
    }
    SessionAuth(username, password, session_id, csrf_token) -> {
      case session_id {
        Some(sid) -> {
          // Add session cookie
          let req_with_session =
            request.prepend_header(req, "Cookie", "sessionid=" <> sid)

          // Add CSRF token for mutating requests
          case include_csrf, csrf_token {
            True, Some(csrf) ->
              request.prepend_header(req_with_session, "X-CSRFToken", csrf)
            _, _ -> req_with_session
          }
        }
        None -> {
          // No session yet - use basic auth for login
          let credentials = base64_encode(username <> ":" <> password)
          request.prepend_header(req, "Authorization", "Basic " <> credentials)
        }
      }
    }
  }
}

/// Simple base64 encoding (for basic auth)
fn base64_encode(input: String) -> String {
  // Use Erlang's base64 module for encoding
  do_base64_encode(input)
}

@external(erlang, "base64", "encode")
fn do_base64_encode(input: String) -> String

/// Add JSON content-type headers to request
fn add_json_headers(request: request.Request(String)) -> request.Request(String) {
  request
  |> request.prepend_header("Content-Type", "application/json")
  |> request.prepend_header("Accept", "application/json")
}

/// Build a request from base URL and path
///
/// # Arguments
/// * `base_url` - Base URL (e.g., "http://localhost:8000")
/// * `path` - API path (e.g., "/api/recipe/")
/// * `query_params` - List of query parameters
///
/// # Returns
/// Result with HTTP request or error message
fn build_request_from_url(
  base_url: String,
  path: String,
  query_params: List(#(String, String)),
) -> Result(request.Request(String), String) {
  // Remove trailing slashes from base URL
  let base = case string.ends_with(base_url, "/") {
    True -> string.drop_end(base_url, 1)
    False -> base_url
  }

  // Ensure path starts with /
  let normalized_path = case string.starts_with(path, "/") {
    True -> path
    False -> "/" <> path
  }

  // Combine base URL and path
  let full_url = base <> normalized_path

  // Add query parameters if present
  let url_with_query = case list.is_empty(query_params) {
    True -> full_url
    False -> {
      let query_string = build_query_string(query_params)
      full_url <> "?" <> query_string
    }
  }

  // Parse the URL and create a request
  case uri.parse(url_with_query) {
    Ok(parsed_uri) -> {
      let scheme = case parsed_uri.scheme {
        Some("https") -> http.Https
        _ -> http.Http
      }
      let host = option.unwrap(parsed_uri.host, "localhost")
      let port = parsed_uri.port
      let path_with_query = case parsed_uri.query {
        Some(q) -> parsed_uri.path <> "?" <> q
        None -> parsed_uri.path
      }

      let req =
        request.new()
        |> request.set_scheme(scheme)
        |> request.set_host(host)
        |> request.set_path(path_with_query)
        |> request.set_body("")

      let req_with_port = case port {
        Some(p) -> request.set_port(req, p)
        None -> req
      }

      Ok(req_with_port)
    }
    Error(_) -> Error("Failed to parse URL: " <> url_with_query)
  }
}

/// Build a query string from parameters
///
/// # Arguments
/// * `params` - List of parameter tuples
///
/// # Returns
/// URL-encoded query string
fn build_query_string(params: List(#(String, String))) -> String {
  params
  |> list.map(fn(param) {
    let #(key, value) = param
    key <> "=" <> uri_encode(value)
  })
  |> string.join("&")
}

/// URL encode a string for query parameters
///
/// Note: This is a simple implementation. In production, use a proper
/// URL encoding library.
fn uri_encode(value: String) -> String {
  value
  |> string.replace(" ", "%20")
  |> string.replace("\n", "%0A")
  |> string.replace("\r", "%0D")
  |> string.replace("=", "%3D")
  |> string.replace("&", "%26")
  |> string.replace("#", "%23")
  |> string.replace("%", "%25")
}
