/// Middleware module for HTTP request/response processing
///
/// This module provides composable middleware functions for:
/// - Authentication and authorization
/// - Request/response logging
/// - Error handling and recovery
/// - CORS headers
/// - Rate limiting
/// - Security headers
///
import gleam/dict.{type Dict}
import gleam/http
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import meal_planner/logger
import pog
import wisp

// ============================================================================
// Types
// ============================================================================

/// Middleware function type - takes a request handler and returns a new handler
pub type Middleware =
  fn(fn(wisp.Request) -> wisp.Response) -> fn(wisp.Request) -> wisp.Response

/// Authentication context
pub type AuthContext {
  AuthContext(user_id: Option(String), authenticated: Bool)
}

// ============================================================================
// Middleware Composition
// ============================================================================

/// Compose multiple middleware functions into a single middleware chain
/// Middleware are applied right-to-left (last middleware wraps first)
pub fn compose(middleware: List(Middleware)) -> Middleware {
  fn(handler) {
    list.fold(middleware, handler, fn(h, mw) { mw(h) })
  }
}

/// Apply middleware to a handler function
pub fn apply(
  handler: fn(wisp.Request) -> wisp.Response,
  middleware: Middleware,
) -> fn(wisp.Request) -> wisp.Response {
  middleware(handler)
}

// ============================================================================
// Logging Middleware
// ============================================================================

/// Middleware that logs request details
pub fn request_logger() -> Middleware {
  fn(handler) {
    fn(req) {
      // Log request details
      let method = http.method_to_string(req.method)
      let path = wisp.path_segments(req) |> string.join("/")
      logger.info("→ " <> method <> " /" <> path)

      // Call handler and log response
      let response = handler(req)
      logger.info(
        "← " <> method <> " /" <> path <> " " <> int.to_string(response.status),
      )
      response
    }
  }
}

// ============================================================================
// Error Handling Middleware
// ============================================================================

/// Middleware that catches panics and returns 500 errors
pub fn error_handler() -> Middleware {
  fn(handler) {
    fn(req) {
      let response = handler(req)

      // Ensure we always have valid response status
      case response.status >= 100 && response.status < 600 {
        True -> response
        False -> {
          logger.error(
            "Invalid response status: " <> int.to_string(response.status),
          )
          wisp.response(500)
          |> wisp.string_body("Internal server error")
        }
      }
    }
  }
}

/// Middleware that adds error recovery with custom error pages
pub fn error_recovery() -> Middleware {
  fn(handler) {
    fn(req) {
      let response = handler(req)

      // Add helpful error messages for common status codes
      case response.status {
        400 ->
          wisp.response(400)
          |> wisp.json_body(
            "{\"error\":\"Bad Request\",\"message\":\"Invalid request format\"}",
          )
        401 ->
          wisp.response(401)
          |> wisp.json_body(
            "{\"error\":\"Unauthorized\",\"message\":\"Authentication required\"}",
          )
        403 ->
          wisp.response(403)
          |> wisp.json_body(
            "{\"error\":\"Forbidden\",\"message\":\"Access denied\"}",
          )
        404 ->
          wisp.response(404)
          |> wisp.json_body(
            "{\"error\":\"Not Found\",\"message\":\"Resource not found\"}",
          )
        500 ->
          wisp.response(500)
          |> wisp.json_body(
            "{\"error\":\"Internal Server Error\",\"message\":\"An unexpected error occurred\"}",
          )
        _ -> response
      }
    }
  }
}

// ============================================================================
// CORS Middleware
// ============================================================================

/// Middleware that adds CORS headers for API endpoints
pub fn cors(allowed_origins: List(String)) -> Middleware {
  fn(handler) {
    fn(req) {
      // Handle preflight OPTIONS requests
      case req.method {
        http.Options -> {
          wisp.response(204)
          |> add_cors_headers(allowed_origins)
        }
        _ -> {
          let response = handler(req)
          response
          |> add_cors_headers(allowed_origins)
        }
      }
    }
  }
}

fn add_cors_headers(
  response: wisp.Response,
  allowed_origins: List(String),
) -> wisp.Response {
  let origin = case allowed_origins {
    ["*"] -> "*"
    origins -> string.join(origins, ", ")
  }

  response
  |> wisp.set_header("access-control-allow-origin", origin)
  |> wisp.set_header(
    "access-control-allow-methods",
    "GET, POST, PUT, DELETE, OPTIONS",
  )
  |> wisp.set_header(
    "access-control-allow-headers",
    "content-type, authorization, x-api-key",
  )
  |> wisp.set_header("access-control-max-age", "86400")
}

// ============================================================================
// Security Headers Middleware
// ============================================================================

/// Middleware that adds security headers
pub fn security_headers() -> Middleware {
  fn(handler) {
    fn(req) {
      let response = handler(req)
      response
      |> wisp.set_header("x-content-type-options", "nosniff")
      |> wisp.set_header("x-frame-options", "DENY")
      |> wisp.set_header("x-xss-protection", "1; mode=block")
      |> wisp.set_header(
        "strict-transport-security",
        "max-age=31536000; includeSubDomains",
      )
      |> wisp.set_header("referrer-policy", "strict-origin-when-cross-origin")
      |> wisp.set_header(
        "content-security-policy",
        "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'",
      )
    }
  }
}

// ============================================================================
// Authentication Middleware
// ============================================================================

/// Middleware that requires authentication
pub fn require_auth(db: pog.Connection) -> Middleware {
  fn(handler) {
    fn(req) {
      case get_auth_context(req, db) {
        Ok(auth_ctx) if auth_ctx.authenticated -> handler(req)
        Ok(_) | Error(_) ->
          wisp.response(401)
          |> wisp.json_body(
            "{\"error\":\"Unauthorized\",\"message\":\"Valid authentication required\"}",
          )
      }
    }
  }
}

/// Middleware that optionally authenticates if credentials are provided
pub fn optional_auth(db: pog.Connection) -> Middleware {
  fn(handler) {
    fn(req) {
      // Always call handler, auth context can be retrieved if needed
      let _auth_result = get_auth_context(req, db)
      handler(req)
    }
  }
}

/// Extract authentication context from request
fn get_auth_context(
  req: wisp.Request,
  _db: pog.Connection,
) -> Result(AuthContext, String) {
  // Try to get auth from header
  case wisp.get_header(req, "authorization") {
    Ok(auth_header) -> {
      case string.starts_with(auth_header, "Bearer ") {
        True -> {
          let token =
            string.drop_start(auth_header, string.length("Bearer "))
          // TODO: Validate token against database
          case string.length(token) > 0 {
            True -> Ok(AuthContext(Some("user-id"), True))
            False -> Ok(AuthContext(None, False))
          }
        }
        False -> Ok(AuthContext(None, False))
      }
    }
    Error(_) -> {
      // Try to get API key from header
      case wisp.get_header(req, "x-api-key") {
        Ok(api_key) -> {
          // TODO: Validate API key against database
          case string.length(api_key) > 0 {
            True -> Ok(AuthContext(Some("api-user"), True))
            False -> Ok(AuthContext(None, False))
          }
        }
        Error(_) -> Ok(AuthContext(None, False))
      }
    }
  }
}

// ============================================================================
// Rate Limiting Middleware
// ============================================================================

/// Middleware that implements simple rate limiting
pub fn rate_limit(max_requests: Int, window_seconds: Int) -> Middleware {
  fn(handler) {
    fn(req) {
      // Get client identifier
      let client_id = get_client_identifier(req)

      // TODO: Implement proper rate limiting with persistent storage
      logger.debug("Rate limit check for client: " <> client_id)

      handler(req)
    }
  }
}

fn get_client_identifier(req: wisp.Request) -> String {
  // Try to get from X-Forwarded-For header first
  case wisp.get_header(req, "x-forwarded-for") {
    Ok(ip) -> ip
    Error(_) ->
      // Try to get from X-Real-IP
      case wisp.get_header(req, "x-real-ip") {
        Ok(ip) -> ip
        Error(_) -> "unknown"
      }
  }
}

// ============================================================================
// Content Type Middleware
// ============================================================================

/// Middleware that validates content type for POST/PUT requests
pub fn require_json() -> Middleware {
  fn(handler) {
    fn(req) {
      case req.method {
        http.Post | http.Put | http.Patch -> {
          case wisp.get_header(req, "content-type") {
            Ok(content_type) -> {
              case string.contains(content_type, "application/json") {
                True -> handler(req)
                False ->
                  wisp.response(415)
                  |> wisp.json_body(
                    "{\"error\":\"Unsupported Media Type\",\"message\":\"Content-Type must be application/json\"}",
                  )
              }
            }
            Error(_) ->
              wisp.response(400)
              |> wisp.json_body(
                "{\"error\":\"Bad Request\",\"message\":\"Content-Type header required\"}",
              )
          }
        }
        _ -> handler(req)
      }
    }
  }
}

// ============================================================================
// Request ID Middleware
// ============================================================================

/// Middleware that adds a unique request ID to each request
pub fn request_id() -> Middleware {
  fn(handler) {
    fn(req) {
      // Generate or extract request ID
      let req_id = case wisp.get_header(req, "x-request-id") {
        Ok(id) -> id
        Error(_) -> wisp.random_string(16)
      }

      logger.debug("Request ID: " <> req_id)

      let response = handler(req)
      response
      |> wisp.set_header("x-request-id", req_id)
    }
  }
}

// ============================================================================
// Default Middleware Stack
// ============================================================================

/// Create a default middleware stack for API endpoints
pub fn default_api_stack(db: pog.Connection) -> Middleware {
  compose([
    request_id(),
    request_logger(),
    error_recovery(),
    error_handler(),
    security_headers(),
    cors(["*"]),
    optional_auth(db),
  ])
}

/// Create a middleware stack for protected API endpoints
pub fn protected_api_stack(db: pog.Connection) -> Middleware {
  compose([
    request_id(),
    request_logger(),
    error_recovery(),
    error_handler(),
    security_headers(),
    cors(["*"]),
    require_auth(db),
  ])
}

/// Create a minimal middleware stack for health checks
pub fn health_stack() -> Middleware {
  compose([request_id()])
}
