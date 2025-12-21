//// Authentication functions for Tandoor API client
////
//// This module handles session-based authentication and login flow for Tandoor.
//// Extracted from client.gleam for better modularity.

import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/uri
import meal_planner/logger
import meal_planner/tandoor/client.{
  type AuthMethod, type ClientConfig, type TandoorError, AuthenticationError,
  BearerAuth, ClientConfig, NetworkError, SessionAuth,
}

// ============================================================================
// Client Configuration
// ============================================================================

/// Create a client configuration with session-based authentication
///
/// This creates a config object for session-based auth. You must call login()
/// to establish the actual session.
///
/// # Arguments
/// * `base_url` - Base URL for Tandoor (e.g., "http://localhost:8000")
/// * `username` - Tandoor username
/// * `password` - Tandoor password
///
/// # Returns
/// ClientConfig with session auth (not yet authenticated)
pub fn session_config(
  base_url: String,
  username: String,
  password: String,
) -> ClientConfig {
  ClientConfig(
    base_url: base_url,
    auth: SessionAuth(
      username: username,
      password: password,
      session_id: None,
      csrf_token: None,
    ),
    timeout_ms: 10_000,
    retry_on_transient: True,
    max_retries: 3,
  )
}

/// Create a client configuration with Bearer token authentication
///
/// Use this for OAuth2 tokens. Note: Token-based auth may not work with
/// Tandoor's multi-tenant scope system - prefer session_config for full
/// API access.
///
/// # Arguments
/// * `base_url` - Base URL for Tandoor (e.g., "http://localhost:8000")
/// * `token` - Bearer token (OAuth2 access token)
///
/// # Returns
/// ClientConfig with bearer auth
pub fn bearer_config(base_url: String, token: String) -> ClientConfig {
  ClientConfig(
    base_url: base_url,
    auth: BearerAuth(token: token),
    timeout_ms: 10_000,
    retry_on_transient: True,
    max_retries: 3,
  )
}

// ============================================================================
// Session Authentication
// ============================================================================

/// Login to Tandoor and establish a session
///
/// This function handles the Django login flow:
/// 1. GET /accounts/login/ to get initial CSRF token
/// 2. POST credentials to login endpoint
/// 3. Extract session and CSRF cookies from response
///
/// # Arguments
/// * `config` - Client configuration with SessionAuth credentials
///
/// # Returns
/// Result with updated config containing session tokens, or error
pub fn login(config: ClientConfig) -> Result(ClientConfig, TandoorError) {
  case config.auth {
    BearerAuth(_) -> Ok(config)
    SessionAuth(username, password, _, _) -> {
      // Step 1: Get login page to extract CSRF token
      let login_url = config.base_url <> "/accounts/login/"

      use login_req <- result.try(case uri.parse(login_url) {
        Ok(parsed) -> {
          let scheme = case parsed.scheme {
            Some("https") -> http.Https
            _ -> http.Http
          }
          let host = option.unwrap(parsed.host, "localhost")
          let req =
            request.new()
            |> request.set_scheme(scheme)
            |> request.set_host(host)
            |> request.set_path(parsed.path)
            |> request.set_method(http.Get)

          let req_with_port = case parsed.port {
            Some(p) -> request.set_port(req, p)
            None -> req
          }
          Ok(req_with_port)
        }
        Error(_) -> Error(NetworkError("Failed to parse login URL"))
      })

      use login_page <- result.try(execute_request(login_req))

      // Extract CSRF token from response body or cookies
      let initial_csrf =
        extract_csrf_from_body(login_page.body)
        |> option.lazy_or(fn() { extract_csrf_from_cookies(login_page.headers) })

      use csrf_token <- result.try(case initial_csrf {
        Some(csrf) -> Ok(csrf)
        None -> Error(AuthenticationError("Could not extract CSRF token"))
      })

      // Extract session cookie if present
      let initial_session = extract_session_from_cookies(login_page.headers)

      // Step 2: POST login credentials
      let form_body =
        "csrfmiddlewaretoken="
        <> uri_encode(csrf_token)
        <> "&login="
        <> uri_encode(username)
        <> "&password="
        <> uri_encode(password)

      use post_req <- result.try(case uri.parse(login_url) {
        Ok(parsed) -> {
          let scheme = case parsed.scheme {
            Some("https") -> http.Https
            _ -> http.Http
          }
          let host = option.unwrap(parsed.host, "localhost")
          let cookie_header = case initial_session {
            Some(sid) -> "csrftoken=" <> csrf_token <> "; sessionid=" <> sid
            None -> "csrftoken=" <> csrf_token
          }
          let req =
            request.new()
            |> request.set_scheme(scheme)
            |> request.set_host(host)
            |> request.set_path(parsed.path)
            |> request.set_method(http.Post)
            |> request.set_body(form_body)
            |> request.prepend_header(
              "Content-Type",
              "application/x-www-form-urlencoded",
            )
            |> request.prepend_header("Cookie", cookie_header)
            |> request.prepend_header("Referer", login_url)

          let req_with_port = case parsed.port {
            Some(p) -> request.set_port(req, p)
            None -> req
          }
          Ok(req_with_port)
        }
        Error(_) -> Error(NetworkError("Failed to parse login URL"))
      })

      use login_resp <- result.try(execute_request(post_req))

      // Step 3: Extract session and CSRF from response cookies
      let session_id =
        extract_session_from_cookies(login_resp.headers)
        |> option.lazy_or(fn() { initial_session })

      let new_csrf =
        extract_csrf_from_cookies(login_resp.headers)
        |> option.lazy_or(fn() { Some(csrf_token) })

      case session_id, new_csrf {
        Some(sid), Some(csrf) -> {
          logger.debug("Tandoor login successful")
          Ok(with_session(config, sid, csrf))
        }
        _, _ -> {
          // Check if login failed based on status code
          case login_resp.status {
            302 | 200 -> {
              // Redirect or success but no session - check body for errors
              case string.contains(login_resp.body, "error") {
                True ->
                  Error(AuthenticationError("Login failed: invalid credentials"))
                False ->
                  Error(AuthenticationError(
                    "Login succeeded but no session cookie received",
                  ))
              }
            }
            401 | 403 ->
              Error(AuthenticationError("Login failed: invalid credentials"))
            _ ->
              Error(AuthenticationError(
                "Login failed with status " <> int.to_string(login_resp.status),
              ))
          }
        }
      }
    }
  }
}

/// Check if config has an active session
pub fn is_authenticated(config: ClientConfig) -> Bool {
  case config.auth {
    BearerAuth(_) -> True
    SessionAuth(_, _, session_id, _) -> option.is_some(session_id)
  }
}

/// Ensure config has an active session, logging in if necessary
pub fn ensure_authenticated(
  config: ClientConfig,
) -> Result(ClientConfig, TandoorError) {
  case is_authenticated(config) {
    True -> Ok(config)
    False -> login(config)
  }
}

// ============================================================================
// Internal Helpers
// ============================================================================

/// Execute an HTTP request and return the response
fn execute_request(
  req: request.Request(String),
) -> Result(response.Response(String), TandoorError) {
  case httpc.send(req) {
    Ok(resp) -> Ok(resp)
    Error(_) -> Error(NetworkError("Failed to connect to Tandoor"))
  }
}

/// Extract CSRF token from HTML body
fn extract_csrf_from_body(body: String) -> Option(String) {
  // Look for csrfmiddlewaretoken value="..."
  case string.split(body, "csrfmiddlewaretoken") {
    [_, rest, ..] -> {
      case string.split(rest, "value=\"") {
        [_, value_part, ..] -> {
          case string.split(value_part, "\"") {
            [token, ..] -> Some(token)
            _ -> None
          }
        }
        _ -> None
      }
    }
    _ -> None
  }
}

/// Extract CSRF token from cookies
fn extract_csrf_from_cookies(headers: List(#(String, String))) -> Option(String) {
  headers
  |> list.filter_map(fn(header) {
    let #(name, value) = header
    case string.lowercase(name) == "set-cookie" {
      True -> {
        case string.starts_with(value, "csrftoken=") {
          True -> {
            let token_part = string.drop_start(value, 10)
            case string.split(token_part, ";") {
              [token, ..] -> Ok(token)
              _ -> Error(Nil)
            }
          }
          False -> Error(Nil)
        }
      }
      False -> Error(Nil)
    }
  })
  |> list.first
  |> option.from_result
}

/// Extract session ID from cookies
fn extract_session_from_cookies(
  headers: List(#(String, String)),
) -> Option(String) {
  headers
  |> list.filter_map(fn(header) {
    let #(name, value) = header
    case string.lowercase(name) == "set-cookie" {
      True -> {
        case string.starts_with(value, "sessionid=") {
          True -> {
            let session_part = string.drop_start(value, 10)
            case string.split(session_part, ";") {
              [sid, ..] -> Ok(sid)
              _ -> Error(Nil)
            }
          }
          False -> Error(Nil)
        }
      }
      False -> Error(Nil)
    }
  })
  |> list.first
  |> option.from_result
}

/// Update config with session tokens after login
fn with_session(
  config: ClientConfig,
  session_id: String,
  csrf_token: String,
) -> ClientConfig {
  case config.auth {
    SessionAuth(username, password, _, _) ->
      ClientConfig(
        base_url: config.base_url,
        auth: SessionAuth(
          username: username,
          password: password,
          session_id: Some(session_id),
          csrf_token: Some(csrf_token),
        ),
        timeout_ms: config.timeout_ms,
        retry_on_transient: config.retry_on_transient,
        max_retries: config.max_retries,
      )
    BearerAuth(_) -> config
  }
}

/// Add authentication headers based on auth method
///
/// This function adds appropriate headers for Bearer or Session authentication.
/// For session auth with CSRF token, includes the X-CSRFToken header when
/// include_csrf is True.
///
/// # Arguments
/// * `req` - HTTP request to add headers to
/// * `auth` - Authentication method (Bearer or Session)
/// * `include_csrf` - Whether to include CSRF token for mutating requests
///
/// # Returns
/// Request with authentication headers added
pub fn add_auth_headers(
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

/// URL encode a string for query parameters
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
