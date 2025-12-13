/// Security middleware for the Meal Planner API
///
/// This module provides security-related middleware including:
/// - Content Security Policy (CSP) headers
/// - Rate limiting for API endpoints
/// - Security headers (X-Frame-Options, X-Content-Type-Options, etc.)
import gleam/dict.{type Dict}
import gleam/http/response
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import wisp

/// Rate limiting state per IP address
pub type RateLimitState {
  RateLimitState(
    // Map of IP -> (request_count, window_start_timestamp)
    requests: Dict(String, #(Int, Int)),
  )
}

/// Rate limit configuration
pub type RateLimitConfig {
  RateLimitConfig(
    max_requests: Int,
    // Window in seconds
    window_seconds: Int,
  )
}

/// Create new rate limit state
pub fn new_rate_limit_state() -> RateLimitState {
  RateLimitState(requests: dict.new())
}

/// Default rate limit: 100 requests per 60 seconds
pub fn default_rate_limit() -> RateLimitConfig {
  RateLimitConfig(max_requests: 100, window_seconds: 60)
}

/// Add Content Security Policy headers to response
///
/// CSP Configuration:
/// - default-src 'self': Only load resources from same origin
/// - script-src 'self' https://unpkg.com/htmx.org: Allow HTMX from CDN
/// - style-src 'self' 'unsafe-inline': Allow inline styles (required for some frameworks)
/// - img-src 'self' data:: Allow images from same origin and data URIs
pub fn add_csp_headers(response: wisp.Response) -> wisp.Response {
  let csp_policy =
    "default-src 'self'; "
    <> "script-src 'self' https://unpkg.com/htmx.org; "
    <> "style-src 'self' 'unsafe-inline'; "
    <> "img-src 'self' data:; "
    <> "connect-src 'self'; "
    <> "font-src 'self'; "
    <> "object-src 'none'; "
    <> "base-uri 'self'; "
    <> "form-action 'self'"

  response
  |> wisp.set_header("content-security-policy", csp_policy)
  |> wisp.set_header("x-content-type-options", "nosniff")
  |> wisp.set_header("x-frame-options", "DENY")
  |> wisp.set_header("x-xss-protection", "1; mode=block")
  |> wisp.set_header("referrer-policy", "strict-origin-when-cross-origin")
}

/// Check if request exceeds rate limit
///
/// Returns Error with Retry-After seconds if rate limited, Ok(()) otherwise
pub fn check_rate_limit(
  ip: String,
  state: RateLimitState,
  config: RateLimitConfig,
  current_time: Int,
) -> Result(RateLimitState, Int) {
  case dict.get(state.requests, ip) {
    Ok(#(count, window_start)) -> {
      // Check if we're still in the same time window
      let elapsed = current_time - window_start
      case elapsed < config.window_seconds {
        True -> {
          // Still in window - check count
          case count >= config.max_requests {
            True -> {
              // Rate limited
              let retry_after = config.window_seconds - elapsed
              Error(retry_after)
            }
            False -> {
              // Increment count
              let new_state =
                RateLimitState(
                  requests: dict.insert(state.requests, ip, #(
                    count + 1,
                    window_start,
                  )),
                )
              Ok(new_state)
            }
          }
        }
        False -> {
          // New window - reset count
          let new_state =
            RateLimitState(
              requests: dict.insert(state.requests, ip, #(1, current_time)),
            )
          Ok(new_state)
        }
      }
    }
    Error(_) -> {
      // First request from this IP
      let new_state =
        RateLimitState(
          requests: dict.insert(state.requests, ip, #(1, current_time)),
        )
      Ok(new_state)
    }
  }
}

/// Extract client IP from request
///
/// Checks X-Forwarded-For header first (for proxies), falls back to direct connection
pub fn get_client_ip(req: wisp.Request) -> String {
  // Try X-Forwarded-For header first
  case request.get_header(req, "x-forwarded-for") {
    Ok(forwarded) -> {
      // Take first IP if comma-separated list
      case string.split(forwarded, ",") {
        [first, ..] -> string.trim(first)
        [] -> "unknown"
      }
    }
    Error(_) -> {
      // Fall back to direct connection (we'd need access to socket for this)
      // For now, use a placeholder - in production would extract from Mist connection
      "direct"
    }
  }
}

/// Create a 429 Too Many Requests response
pub fn rate_limit_response(retry_after: Int) -> wisp.Response {
  wisp.response(429)
  |> wisp.set_header("retry-after", int.to_string(retry_after))
  |> wisp.set_header("content-type", "application/json")
  |> wisp.string_body(
    "{\"error\":\"Too many requests\",\"retry_after\":"
    <> int.to_string(retry_after)
    <> "}",
  )
}

/// Middleware wrapper to add security headers to any response
pub fn with_security_headers(
  handler: fn(wisp.Request) -> wisp.Response,
) -> fn(wisp.Request) -> wisp.Response {
  fn(req: wisp.Request) -> wisp.Response {
    handler(req)
    |> add_csp_headers
  }
}
