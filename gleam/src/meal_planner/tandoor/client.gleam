/// HTTP client for Tandoor API with Bearer token authentication
///
/// This module provides a simple, type-safe HTTP client for communicating
/// with the Tandoor API. It handles:
/// - Bearer token authentication
/// - Request/response building
/// - Error handling for common scenarios
/// - URL construction with proper encoding
///
/// The client is designed to work with gleam_httpc and follows functional
/// programming principles with immutable state.

import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/logger

// ============================================================================
// Types
// ============================================================================

/// HTTP request method
pub type HttpMethod {
  Get
  Post
  Put
  Patch
  Delete
}

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

/// HTTP client configuration
pub type ClientConfig {
  ClientConfig(
    /// Base URL for Tandoor API (e.g., "http://localhost:8000")
    base_url: String,
    /// Bearer token for authentication
    api_token: String,
    /// Request timeout in milliseconds
    timeout_ms: Int,
    /// Retry on transient failures
    retry_on_transient: Bool,
    /// Maximum retries for transient failures
    max_retries: Int,
  )
}

/// HTTP response from Tandoor API
pub type ApiResponse {
  ApiResponse(
    status: Int,
    headers: List(#(String, String)),
    body: String,
  )
}

// ============================================================================
// Client Configuration
// ============================================================================

/// Create a default client configuration
///
/// # Arguments
/// * `base_url` - Base URL for Tandoor (e.g., "http://localhost:8000")
/// * `api_token` - Bearer token for authentication
///
/// # Returns
/// ClientConfig with sensible defaults:
/// - timeout: 10 seconds
/// - retry_on_transient: true
/// - max_retries: 3
pub fn default_config(base_url: String, api_token: String) -> ClientConfig {
  ClientConfig(
    base_url: base_url,
    api_token: api_token,
    timeout_ms: 10_000,
    retry_on_transient: True,
    max_retries: 3,
  )
}

/// Create a client configuration with custom timeout
pub fn with_timeout(
  config: ClientConfig,
  timeout_ms: Int,
) -> ClientConfig {
  ClientConfig(
    base_url: config.base_url,
    api_token: config.api_token,
    timeout_ms: timeout_ms,
    retry_on_transient: config.retry_on_transient,
    max_retries: config.max_retries,
  )
}

/// Create a client configuration with retry settings
pub fn with_retry_config(
  config: ClientConfig,
  retry_on_transient: Bool,
  max_retries: Int,
) -> ClientConfig {
  ClientConfig(
    base_url: config.base_url,
    api_token: config.api_token,
    timeout_ms: config.timeout_ms,
    retry_on_transient: retry_on_transient,
    max_retries: max_retries,
  )
}

// ============================================================================
// Request Building
// ============================================================================

/// Build a GET request to the Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with auth token
/// * `path` - API path (e.g., "/api/recipe/")
/// * `query_params` - Optional query parameters
///
/// # Returns
/// Result with HTTP request or error
pub fn build_get_request(
  config: ClientConfig,
  path: String,
  query_params: List(#(String, String)),
) -> Result(request.Request(String), TandoorError) {
  let url = build_url(config.base_url, path, query_params)

  case url {
    Error(e) -> Error(NetworkError(e))
    Ok(url_str) -> {
      let req =
        request.new()
        |> request.set_method(http.Get)
        |> request.set_path(url_str)
        |> add_auth_header(config.api_token)
        |> add_json_headers()

      Ok(req)
    }
  }
}

/// Build a POST request to the Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with auth token
/// * `path` - API path (e.g., "/api/recipe/")
/// * `body` - JSON body as string
///
/// # Returns
/// Result with HTTP request or error
pub fn build_post_request(
  config: ClientConfig,
  path: String,
  body: String,
) -> Result(request.Request(String), TandoorError) {
  let url = build_url(config.base_url, path, [])

  case url {
    Error(e) -> Error(NetworkError(e))
    Ok(url_str) -> {
      let req =
        request.new()
        |> request.set_method(http.Post)
        |> request.set_path(url_str)
        |> request.set_body(body)
        |> add_auth_header(config.api_token)
        |> add_json_headers()

      Ok(req)
    }
  }
}

/// Build a PUT request to the Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with auth token
/// * `path` - API path (e.g., "/api/recipe/123/")
/// * `body` - JSON body as string
///
/// # Returns
/// Result with HTTP request or error
pub fn build_put_request(
  config: ClientConfig,
  path: String,
  body: String,
) -> Result(request.Request(String), TandoorError) {
  let url = build_url(config.base_url, path, [])

  case url {
    Error(e) -> Error(NetworkError(e))
    Ok(url_str) -> {
      let req =
        request.new()
        |> request.set_method(http.Put)
        |> request.set_path(url_str)
        |> request.set_body(body)
        |> add_auth_header(config.api_token)
        |> add_json_headers()

      Ok(req)
    }
  }
}

/// Build a PATCH request to the Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with auth token
/// * `path` - API path (e.g., "/api/recipe/123/")
/// * `body` - JSON body as string
///
/// # Returns
/// Result with HTTP request or error
pub fn build_patch_request(
  config: ClientConfig,
  path: String,
  body: String,
) -> Result(request.Request(String), TandoorError) {
  let url = build_url(config.base_url, path, [])

  case url {
    Error(e) -> Error(NetworkError(e))
    Ok(url_str) -> {
      let req =
        request.new()
        |> request.set_method(http.Patch)
        |> request.set_path(url_str)
        |> request.set_body(body)
        |> add_auth_header(config.api_token)
        |> add_json_headers()

      Ok(req)
    }
  }
}

/// Build a DELETE request to the Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with auth token
/// * `path` - API path (e.g., "/api/recipe/123/")
///
/// # Returns
/// Result with HTTP request or error
pub fn build_delete_request(
  config: ClientConfig,
  path: String,
) -> Result(request.Request(String), TandoorError) {
  let url = build_url(config.base_url, path, [])

  case url {
    Error(e) -> Error(NetworkError(e))
    Ok(url_str) -> {
      let req =
        request.new()
        |> request.set_method(http.Delete)
        |> request.set_path(url_str)
        |> add_auth_header(config.api_token)
        |> add_json_headers()

      Ok(req)
    }
  }
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
  decoder: fn(json.Json) -> Result(a, String),
) -> Result(a, TandoorError) {
  case json.parse(response.body) {
    Ok(parsed_json) -> {
      case decoder(parsed_json) {
        Ok(value) -> Ok(value)
        Error(error_msg) -> Error(ParseError(error_msg))
      }
    }
    Error(parse_error) -> {
      let error_msg = "Failed to parse JSON: " <> parse_error
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

/// Add Bearer token authentication header to request
fn add_auth_header(
  request: request.Request(String),
  api_token: String,
) -> request.Request(String) {
  let auth_header = "Bearer " <> api_token
  request.prepend_header(request, "Authorization", auth_header)
}

/// Add JSON content-type headers to request
fn add_json_headers(
  request: request.Request(String),
) -> request.Request(String) {
  request
  |> request.prepend_header("Content-Type", "application/json")
  |> request.prepend_header("Accept", "application/json")
}

/// Build a complete URL from base URL, path, and query parameters
///
/// # Arguments
/// * `base_url` - Base URL (e.g., "http://localhost:8000")
/// * `path` - API path (e.g., "/api/recipe/")
/// * `query_params` - List of query parameters
///
/// # Returns
/// Result with complete URL or error message
fn build_url(
  base_url: String,
  path: String,
  query_params: List(#(String, String)),
) -> Result(String, String) {
  // Remove trailing slashes from base URL
  let base = string.trim_end(base_url, "/")

  // Ensure path starts with /
  let normalized_path = case string.starts_with(path, "/") {
    True -> path
    False -> "/" <> path
  }

  // Combine base URL and path
  let url = base <> normalized_path

  // Add query parameters if present
  case list.is_empty(query_params) {
    True -> Ok(url)
    False -> {
      let query_string = build_query_string(query_params)
      Ok(url <> "?" <> query_string)
    }
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

/// Log a request for debugging
fn log_request(method: String, url: String) -> Nil {
  logger.debug("Tandoor API request: " <> method <> " " <> url)
}

/// Log a response for debugging
fn log_response(status: Int, body_length: Int) -> Nil {
  logger.debug(
    "Tandoor API response: "
    <> int.to_string(status)
    <> " ("
    <> int.to_string(body_length)
    <> " bytes)"
  )
}
