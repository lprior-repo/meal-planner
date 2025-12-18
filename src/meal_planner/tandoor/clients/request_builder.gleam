/// Request building functions for Tandoor API client
///
/// This module provides functions to build HTTP requests for the Tandoor API
/// with proper authentication headers, JSON content-type, and URL encoding.
import gleam/http
import gleam/http/request
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import gleam/uri
import meal_planner/tandoor/client.{
  type AuthMethod, type ClientConfig, type TandoorError, BearerAuth,
  NetworkError, SessionAuth,
}

// ============================================================================
// Request Building Functions
// ============================================================================

/// Build a GET request to the Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with auth
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
  case build_request_from_url(config.base_url, path, query_params) {
    Error(e) -> Error(NetworkError(e))
    Ok(req) -> {
      let final_req =
        req
        |> request.set_method(http.Get)
        |> add_auth_headers(config.auth, False)
        |> add_json_headers()
      Ok(final_req)
    }
  }
}

/// Build a POST request to the Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with auth
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
  case build_request_from_url(config.base_url, path, []) {
    Error(e) -> Error(NetworkError(e))
    Ok(req) -> {
      let final_req =
        req
        |> request.set_method(http.Post)
        |> request.set_body(body)
        |> add_auth_headers(config.auth, True)
        |> add_json_headers()
      Ok(final_req)
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
  case build_request_from_url(config.base_url, path, []) {
    Error(e) -> Error(NetworkError(e))
    Ok(req) -> {
      let final_req =
        req
        |> request.set_method(http.Put)
        |> request.set_body(body)
        |> add_auth_headers(config.auth, True)
        |> add_json_headers()
      Ok(final_req)
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
  case build_request_from_url(config.base_url, path, []) {
    Error(e) -> Error(NetworkError(e))
    Ok(req) -> {
      let final_req =
        req
        |> request.set_method(http.Patch)
        |> request.set_body(body)
        |> add_auth_headers(config.auth, True)
        |> add_json_headers()
      Ok(final_req)
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
  case build_request_from_url(config.base_url, path, []) {
    Error(e) -> Error(NetworkError(e))
    Ok(req) -> {
      let final_req =
        req
        |> request.set_method(http.Delete)
        |> add_auth_headers(config.auth, True)
        |> add_json_headers()
      Ok(final_req)
    }
  }
}

// ============================================================================
// Internal Helper Functions
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
      request.prepend_header(req, "authorization", auth_header)
    }
    SessionAuth(username, password, session_id, csrf_token) -> {
      case session_id {
        Some(sid) -> {
          // Add session cookie
          let req_with_session =
            request.prepend_header(req, "cookie", "sessionid=" <> sid)

          // Add CSRF token for mutating requests
          case include_csrf, csrf_token {
            True, Some(csrf) ->
              request.prepend_header(req_with_session, "x-csrftoken", csrf)
            _, _ -> req_with_session
          }
        }
        None -> {
          // No session yet - use basic auth for login
          let credentials = base64_encode(username <> ":" <> password)
          request.prepend_header(req, "authorization", "Basic " <> credentials)
        }
      }
    }
  }
}

/// Simple base64 encoding (for basic auth)
fn base64_encode(input: String) -> String {
  do_base64_encode(input)
}

@external(erlang, "base64", "encode")
fn do_base64_encode(input: String) -> String

/// Add JSON content-type headers to request
fn add_json_headers(request: request.Request(String)) -> request.Request(String) {
  request
  |> request.prepend_header("content-type", "application/json")
  |> request.prepend_header("accept", "application/json")
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
