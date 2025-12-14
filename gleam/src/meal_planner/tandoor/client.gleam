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
import meal_planner/logger
import meal_planner/tandoor/decoders/mealplan/meal_plan_decoder
import meal_planner/tandoor/types/mealplan/meal_plan.{
  type MealPlan, type MealPlanListResponse,
}
import meal_planner/tandoor/types/mealplan/meal_plan_entry.{type MealPlanEntry}
import meal_planner/tandoor/types/mealplan/meal_type.{
  type MealType, meal_type_to_string,
}

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

/// HTTP client configuration
pub type ClientConfig {
  ClientConfig(
    /// Base URL for Tandoor API (e.g., "http://localhost:8000")
    base_url: String,
    /// Authentication method
    auth: AuthMethod,
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
  ApiResponse(status: Int, headers: List(#(String, String)), body: String)
}

// ============================================================================
// Client Configuration
// ============================================================================

/// Create a client configuration with session-based authentication
///
/// This is the recommended method for Tandoor as it properly establishes
/// the space scope context required for multi-tenant operations.
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

/// Create a default client configuration (deprecated - use session_config)
///
/// # Arguments
/// * `base_url` - Base URL for Tandoor (e.g., "http://localhost:8000")
/// * `api_token` - Bearer token for authentication
///
/// # Returns
/// ClientConfig with bearer auth
pub fn default_config(base_url: String, api_token: String) -> ClientConfig {
  bearer_config(base_url, api_token)
}

/// Create a client configuration with custom timeout
pub fn with_timeout(config: ClientConfig, timeout_ms: Int) -> ClientConfig {
  ClientConfig(
    base_url: config.base_url,
    auth: config.auth,
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
    auth: config.auth,
    timeout_ms: config.timeout_ms,
    retry_on_transient: retry_on_transient,
    max_retries: max_retries,
  )
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
// Request Building
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
// HTTP Execution
// ============================================================================

/// Execute an HTTP request and return the response
///
/// This function handles the actual HTTP communication using httpc
fn execute_request(
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

// ============================================================================
// Recipe API Methods
// ============================================================================

/// Unit of measurement for ingredients
pub type Unit {
  Unit(id: Int, name: String, plural_name: Option(String), description: String)
}

/// Food item (base ingredient)
pub type Food {
  Food(
    id: Int,
    name: String,
    plural_name: Option(String),
    description: String,
    supermarket_category: Option(SupermarketCategory),
  )
}

/// Supermarket category for shopping list organization
pub type SupermarketCategory {
  SupermarketCategory(id: Int, name: String, description: String)
}

/// Ingredient in a recipe step
pub type Ingredient {
  Ingredient(
    id: Int,
    food: Option(Food),
    unit: Option(Unit),
    amount: Float,
    note: String,
    is_header: Bool,
    no_amount: Bool,
    original_text: Option(String),
  )
}

/// Step in a recipe with instructions and ingredients
pub type Step {
  Step(
    id: Int,
    name: String,
    instruction: String,
    ingredients: List(Ingredient),
    time: Int,
    order: Int,
    show_as_header: Bool,
    show_ingredients_table: Bool,
  )
}

/// Nutrition information per serving
pub type NutritionInfo {
  NutritionInfo(
    id: Int,
    carbohydrates: Float,
    fats: Float,
    proteins: Float,
    calories: Float,
    source: String,
  )
}

/// Recipe type for API responses (basic fields for list view)
pub type Recipe {
  Recipe(
    id: Int,
    name: String,
    slug: Option(String),
    description: Option(String),
    servings: Int,
    servings_text: Option(String),
    working_time: Option(Int),
    waiting_time: Option(Int),
    created_at: Option(String),
    updated_at: Option(String),
  )
}

/// Full recipe with ingredients, steps, and nutrition (for detail view)
pub type RecipeDetail {
  RecipeDetail(
    id: Int,
    name: String,
    slug: Option(String),
    description: Option(String),
    servings: Int,
    servings_text: Option(String),
    working_time: Option(Int),
    waiting_time: Option(Int),
    created_at: Option(String),
    updated_at: Option(String),
    steps: List(Step),
    nutrition: Option(NutritionInfo),
    keywords: List(Keyword),
    source_url: Option(String),
  )
}

/// Keyword/tag for recipes
pub type Keyword {
  Keyword(id: Int, name: String, description: String)
}

/// Paginated recipe list response
pub type RecipeListResponse {
  RecipeListResponse(
    count: Int,
    next: Option(String),
    previous: Option(String),
    results: List(Recipe),
  )
}

/// Request to create a new recipe
pub type CreateRecipeRequest {
  CreateRecipeRequest(
    name: String,
    description: Option(String),
    servings: Int,
    servings_text: Option(String),
    working_time: Option(Int),
    waiting_time: Option(Int),
  )
}

// ============================================================================
// Decoders for Recipe Components
// ============================================================================

/// Decoder for SupermarketCategory
fn supermarket_category_decoder() -> decode.Decoder(SupermarketCategory) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use description <- decode.optional_field("description", "", decode.string)

  decode.success(SupermarketCategory(
    id: id,
    name: name,
    description: description,
  ))
}

/// Decoder for Unit
fn unit_decoder() -> decode.Decoder(Unit) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use plural_name <- decode.optional_field(
    "plural_name",
    None,
    decode.optional(decode.string),
  )
  use description <- decode.optional_field("description", "", decode.string)

  decode.success(Unit(
    id: id,
    name: name,
    plural_name: plural_name,
    description: description,
  ))
}

/// Decoder for Food
fn food_decoder() -> decode.Decoder(Food) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use plural_name <- decode.optional_field(
    "plural_name",
    None,
    decode.optional(decode.string),
  )
  use description <- decode.optional_field("description", "", decode.string)
  use supermarket_category <- decode.optional_field(
    "supermarket_category",
    None,
    decode.optional(supermarket_category_decoder()),
  )

  decode.success(Food(
    id: id,
    name: name,
    plural_name: plural_name,
    description: description,
    supermarket_category: supermarket_category,
  ))
}

/// Decoder for Ingredient
fn ingredient_decoder() -> decode.Decoder(Ingredient) {
  use id <- decode.field("id", decode.int)
  use food <- decode.optional_field(
    "food",
    None,
    decode.optional(food_decoder()),
  )
  use unit <- decode.optional_field(
    "unit",
    None,
    decode.optional(unit_decoder()),
  )
  use amount <- decode.optional_field("amount", 0.0, decode.float)
  use note <- decode.optional_field("note", "", decode.string)
  use is_header <- decode.optional_field("is_header", False, decode.bool)
  use no_amount <- decode.optional_field("no_amount", False, decode.bool)
  use original_text <- decode.optional_field(
    "original_text",
    None,
    decode.optional(decode.string),
  )

  decode.success(Ingredient(
    id: id,
    food: food,
    unit: unit,
    amount: amount,
    note: note,
    is_header: is_header,
    no_amount: no_amount,
    original_text: original_text,
  ))
}

/// Decoder for Keyword
fn keyword_decoder() -> decode.Decoder(Keyword) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use description <- decode.optional_field("description", "", decode.string)

  decode.success(Keyword(id: id, name: name, description: description))
}

/// Decoder for Step
fn step_decoder() -> decode.Decoder(Step) {
  use id <- decode.field("id", decode.int)
  use name <- decode.optional_field("name", "", decode.string)
  use instruction <- decode.optional_field("instruction", "", decode.string)
  use ingredients <- decode.optional_field(
    "ingredients",
    [],
    decode.list(ingredient_decoder()),
  )
  use time <- decode.optional_field("time", 0, decode.int)
  use order <- decode.optional_field("order", 0, decode.int)
  use show_as_header <- decode.optional_field(
    "show_as_header",
    False,
    decode.bool,
  )
  use show_ingredients_table <- decode.optional_field(
    "show_ingredients_table",
    True,
    decode.bool,
  )

  decode.success(Step(
    id: id,
    name: name,
    instruction: instruction,
    ingredients: ingredients,
    time: time,
    order: order,
    show_as_header: show_as_header,
    show_ingredients_table: show_ingredients_table,
  ))
}

/// Decoder for NutritionInfo
fn nutrition_decoder() -> decode.Decoder(NutritionInfo) {
  use id <- decode.field("id", decode.int)
  use carbohydrates <- decode.optional_field("carbohydrates", 0.0, decode.float)
  use fats <- decode.optional_field("fats", 0.0, decode.float)
  use proteins <- decode.optional_field("proteins", 0.0, decode.float)
  use calories <- decode.optional_field("calories", 0.0, decode.float)
  use source <- decode.optional_field("source", "", decode.string)

  decode.success(NutritionInfo(
    id: id,
    carbohydrates: carbohydrates,
    fats: fats,
    proteins: proteins,
    calories: calories,
    source: source,
  ))
}

/// Decoder for RecipeDetail (full recipe with steps, ingredients, nutrition)
fn recipe_detail_decoder_internal() -> decode.Decoder(RecipeDetail) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use slug <- decode.optional_field(
    "slug",
    None,
    decode.optional(decode.string),
  )
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use servings <- decode.field("servings", decode.int)
  use servings_text <- decode.optional_field(
    "servings_text",
    None,
    decode.optional(decode.string),
  )
  use working_time <- decode.optional_field(
    "working_time",
    None,
    decode.optional(decode.int),
  )
  use waiting_time <- decode.optional_field(
    "waiting_time",
    None,
    decode.optional(decode.int),
  )
  use created_at <- decode.optional_field(
    "created_at",
    None,
    decode.optional(decode.string),
  )
  use updated_at <- decode.optional_field(
    "updated_at",
    None,
    decode.optional(decode.string),
  )
  use steps <- decode.optional_field("steps", [], decode.list(step_decoder()))
  use nutrition <- decode.optional_field(
    "nutrition",
    None,
    decode.optional(nutrition_decoder()),
  )
  use keywords <- decode.optional_field(
    "keywords",
    [],
    decode.list(keyword_decoder()),
  )
  use source_url <- decode.optional_field(
    "source_url",
    None,
    decode.optional(decode.string),
  )

  decode.success(RecipeDetail(
    id: id,
    name: name,
    slug: slug,
    description: description,
    servings: servings,
    servings_text: servings_text,
    working_time: working_time,
    waiting_time: waiting_time,
    created_at: created_at,
    updated_at: updated_at,
    steps: steps,
    nutrition: nutrition,
    keywords: keywords,
    source_url: source_url,
  ))
}

/// Decode a RecipeDetail from JSON
pub fn recipe_detail_decoder(
  json_value: dynamic.Dynamic,
) -> Result(RecipeDetail, String) {
  decode.run(json_value, recipe_detail_decoder_internal())
  |> result.map_error(fn(errors) {
    "Failed to decode recipe detail: "
    <> string.join(
      list.map(errors, fn(e) {
        case e {
          decode.DecodeError(expected, _found, path) ->
            expected <> " at " <> string.join(path, ".")
        }
      }),
      ", ",
    )
  })
}

/// Decoder for Recipe from JSON (internal)
fn recipe_decoder_internal() -> decode.Decoder(Recipe) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use slug <- decode.optional_field(
    "slug",
    None,
    decode.optional(decode.string),
  )
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use servings <- decode.field("servings", decode.int)
  use servings_text <- decode.optional_field(
    "servings_text",
    None,
    decode.optional(decode.string),
  )
  use working_time <- decode.optional_field(
    "working_time",
    None,
    decode.optional(decode.int),
  )
  use waiting_time <- decode.optional_field(
    "waiting_time",
    None,
    decode.optional(decode.int),
  )
  use created_at <- decode.optional_field(
    "created_at",
    None,
    decode.optional(decode.string),
  )
  use updated_at <- decode.optional_field(
    "updated_at",
    None,
    decode.optional(decode.string),
  )

  decode.success(Recipe(
    id: id,
    name: name,
    slug: slug,
    description: description,
    servings: servings,
    servings_text: servings_text,
    working_time: working_time,
    waiting_time: waiting_time,
    created_at: created_at,
    updated_at: updated_at,
  ))
}

/// Decode a Recipe from JSON
pub fn recipe_decoder(json_value: dynamic.Dynamic) -> Result(Recipe, String) {
  decode.run(json_value, recipe_decoder_internal())
  |> result.map_error(fn(errors) {
    "Failed to decode recipe: "
    <> string.join(
      list.map(errors, fn(e) {
        case e {
          decode.DecodeError(expected, _found, path) ->
            expected <> " at " <> string.join(path, ".")
        }
      }),
      ", ",
    )
  })
}

/// Decode a paginated recipe list response
fn recipe_list_decoder_internal() -> decode.Decoder(RecipeListResponse) {
  use count <- decode.field("count", decode.int)
  use next <- decode.field("next", decode.optional(decode.string))
  use previous <- decode.field("previous", decode.optional(decode.string))
  use results <- decode.field("results", decode.list(recipe_decoder_internal()))

  decode.success(RecipeListResponse(
    count: count,
    next: next,
    previous: previous,
    results: results,
  ))
}

/// Get all recipes from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `limit` - Optional limit for number of results (default: 100)
/// * `offset` - Optional offset for pagination (default: 0)
///
/// # Returns
/// Result with paginated recipe list or error
pub fn get_recipes(
  config: ClientConfig,
  limit: Option(Int),
  offset: Option(Int),
) -> Result(RecipeListResponse, TandoorError) {
  let limit_val = option.unwrap(limit, 100)
  let offset_val = option.unwrap(offset, 0)

  let query_params = [
    #("limit", int.to_string(limit_val)),
    #("offset", int.to_string(offset_val)),
  ]

  use req <- result.try(build_get_request(config, "/api/recipe/", query_params))
  logger.debug("Tandoor GET /api/recipe/")

  use resp <- result.try(execute_and_parse(req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, recipe_list_decoder_internal()) {
        Ok(recipe_list) -> Ok(recipe_list)
        Error(errors) -> {
          let error_msg =
            "Failed to decode recipe list: "
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

/// Get a single recipe by ID from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `recipe_id` - The ID of the recipe to fetch
///
/// # Returns
/// Result with recipe details or error
pub fn get_recipe_by_id(
  config: ClientConfig,
  recipe_id: Int,
) -> Result(Recipe, TandoorError) {
  let path = "/api/recipe/" <> int.to_string(recipe_id) <> "/"

  use req <- result.try(build_get_request(config, path, []))
  logger.debug("Tandoor GET " <> path)

  use resp <- result.try(execute_and_parse(req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, recipe_decoder_internal()) {
        Ok(recipe) -> Ok(recipe)
        Error(errors) -> {
          let error_msg =
            "Failed to decode recipe: "
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

/// Get a single recipe with full details (steps, ingredients, nutrition) by ID
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `recipe_id` - The ID of the recipe to fetch
///
/// # Returns
/// Result with full recipe details including steps, ingredients, and nutrition
pub fn get_recipe_detail(
  config: ClientConfig,
  recipe_id: Int,
) -> Result(RecipeDetail, TandoorError) {
  let path = "/api/recipe/" <> int.to_string(recipe_id) <> "/"

  use req <- result.try(build_get_request(config, path, []))
  logger.debug("Tandoor GET (detail) " <> path)

  use resp <- result.try(execute_and_parse(req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, recipe_detail_decoder_internal()) {
        Ok(recipe) -> Ok(recipe)
        Error(errors) -> {
          let error_msg =
            "Failed to decode recipe detail: "
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

/// Create a new recipe in Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `recipe_request` - Recipe data to create
///
/// # Returns
/// Result with created recipe details or error
pub fn create_recipe(
  config: ClientConfig,
  recipe_request: CreateRecipeRequest,
) -> Result(Recipe, TandoorError) {
  let body = encode_create_recipe(recipe_request)

  use req <- result.try(build_post_request(config, "/api/recipe/", body))
  logger.debug("Tandoor POST /api/recipe/")

  use resp <- result.try(execute_and_parse(req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, recipe_decoder_internal()) {
        Ok(recipe) -> Ok(recipe)
        Error(errors) -> {
          let error_msg =
            "Failed to decode created recipe: "
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

/// Delete a recipe from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `recipe_id` - The ID of the recipe to delete
///
/// # Returns
/// Result with unit or error
pub fn delete_recipe(
  config: ClientConfig,
  recipe_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/recipe/" <> int.to_string(recipe_id) <> "/"

  use req <- result.try(build_delete_request(config, path))
  logger.debug("Tandoor DELETE " <> path)

  use _resp <- result.try(execute_and_parse(req))
  Ok(Nil)
}

/// Test connection to Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with API token
///
/// # Returns
/// Result with True if connected, or error
pub fn test_connection(config: ClientConfig) -> Result(Bool, TandoorError) {
  use req <- result.try(
    build_get_request(config, "/api/recipe/", [
      #("limit", "1"),
    ]),
  )
  logger.debug("Tandoor connection test")

  case execute_and_parse(req) {
    Ok(_) -> Ok(True)
    Error(e) -> Error(e)
  }
}

/// Encode a CreateRecipeRequest to JSON string
fn encode_create_recipe(request: CreateRecipeRequest) -> String {
  let working_time_json = case request.working_time {
    Some(val) -> json.int(val)
    None -> json.int(0)
  }

  let waiting_time_json = case request.waiting_time {
    Some(val) -> json.int(val)
    None -> json.int(0)
  }

  let description_json = case request.description {
    Some(val) -> json.string(val)
    None -> json.null()
  }

  let servings_text_json = case request.servings_text {
    Some(val) -> json.string(val)
    None -> json.null()
  }

  // Tandoor requires steps with ingredients array
  let empty_step =
    json.object([
      #("instruction", json.string("")),
      #("ingredients", json.array([], json.object)),
    ])

  let body =
    json.object([
      #("name", json.string(request.name)),
      #("description", description_json),
      #("servings", json.int(request.servings)),
      #("servings_text", servings_text_json),
      #("working_time", working_time_json),
      #("waiting_time", waiting_time_json),
      #("steps", json.array([empty_step], fn(x) { x })),
    ])

  json.to_string(body)
}

// ============================================================================
// Meal Plan API Types
// ============================================================================

/// Request to create a meal plan entry
pub type CreateMealPlanRequest {
  CreateMealPlanRequest(
    title: String,
    recipe: Option(Int),
    servings: Float,
    note: String,
    from_date: String,
    to_date: String,
    meal_type: MealType,
  )
}

// ============================================================================
// Meal Plan API Methods
// ============================================================================

/// Get meal plan entries from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `from_date` - Optional start date filter (YYYY-MM-DD)
/// * `to_date` - Optional end date filter (YYYY-MM-DD)
///
/// # Returns
/// Result with paginated meal plan list or error
/// Get meal plan entries from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `from_date` - Optional start date filter (YYYY-MM-DD)
/// * `to_date` - Optional end date filter (YYYY-MM-DD)
///
/// # Returns
/// Result with paginated meal plan list or error
// FIXME(meal-planner-242): Incomplete MealPlan API implementation

pub fn get_meal_plan(
  config: ClientConfig,
  from_date: Option(String),
  to_date: Option(String),
) -> Result(MealPlanListResponse, TandoorError) {
  let query_params =
    []
    |> fn(params) {
      case from_date {
        Some(d) -> [#("from_date", d), ..params]
        None -> params
      }
    }
    |> fn(params) {
      case to_date {
        Some(d) -> [#("to_date", d), ..params]
        None -> params
      }
    }

  use req <- result.try(build_get_request(
    config,
    "/api/meal-plan/",
    query_params,
  ))
  logger.debug("Tandoor GET /api/meal-plan/")

  use resp <- result.try(execute_and_parse(req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case
        decode.run(
          json_data,
          meal_plan_decoder.meal_plan_list_decoder_internal(),
        )
      {
        Ok(meal_plan_list) -> Ok(meal_plan_list)
        Error(errors) -> {
          let error_msg =
            "Failed to decode meal plan: "
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

/// Create a meal plan entry in Tandoor
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `entry` - Meal plan entry to create
///
/// # Returns
/// Result with created meal plan entry or error
// FIXME(meal-planner-242): Incomplete MealPlan API implementation

pub fn create_meal_plan_entry(
  config: ClientConfig,
  entry: CreateMealPlanRequest,
) -> Result(MealPlanEntry, TandoorError) {
  let recipe_json = case entry.recipe {
    Some(id) -> json.int(id)
    None -> json.null()
  }

  let body =
    json.object([
      #("recipe", recipe_json),
      #("recipe_name", json.string(entry.title)),
      #("servings", json.float(entry.servings)),
      #("note", json.string(entry.note)),
      #("from_date", json.string(entry.from_date)),
      #("to_date", json.string(entry.to_date)),
      #("meal_type", json.string(meal_type_to_string(entry.meal_type))),
    ])
    |> json.to_string

  use req <- result.try(build_post_request(config, "/api/meal-plan/", body))
  logger.debug("Tandoor POST /api/meal-plan/")

  use resp <- result.try(execute_and_parse(req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, meal_plan_decoder.meal_plan_entry_decoder()) {
        Ok(meal_plan) -> Ok(meal_plan)
        Error(errors) -> {
          let error_msg =
            "Failed to decode created meal plan: "
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

// 
// /// Delete a meal plan entry from Tandoor
// ///
// /// # Arguments
// /// * `config` - Client configuration with API token
// /// * `entry_id` - The ID of the meal plan entry to delete
// ///
// /// # Returns
// /// Result with unit or error
pub fn delete_meal_plan_entry(
  config: ClientConfig,
  entry_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/meal-plan/" <> int.to_string(entry_id) <> "/"

  use req <- result.try(build_delete_request(config, path))
  logger.debug("Tandoor DELETE " <> path)

  use _resp <- result.try(execute_and_parse(req))
  Ok(Nil)
}

/// Get today's meal plan entries
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `today` - Today's date in YYYY-MM-DD format
///
/// # Returns
/// Result with meal plan entries for today or error
// FIXME(meal-planner-242): Incomplete MealPlan API implementation

pub fn get_todays_meals(
  config: ClientConfig,
  today: String,
) -> Result(MealPlanListResponse, TandoorError) {
  get_meal_plan(config, Some(today), Some(today))
}
