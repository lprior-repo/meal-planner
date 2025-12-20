/// Rate limiting middleware using token bucket algorithm
///
/// This module provides token bucket rate limiting for HTTP requests.
/// It supports:
/// - User-specific quotas with configurable token bucket parameters
/// - Automatic token refill based on elapsed time
/// - Periodic cleanup of inactive buckets
/// - Integration with Wisp middleware pattern
///
/// Token Bucket Algorithm:
/// - Each user has a bucket with a maximum capacity
/// - Tokens refill at a fixed rate (tokens per second)
/// - Each request consumes one token
/// - Request is rejected if bucket is empty
///
/// Example usage:
/// ```gleam
/// let limiter = rate_limit.new(max_tokens: 100, refill_rate: 10.0)
/// use <- rate_limit.require_rate_limit(req, limiter, user_id)
/// // Handler logic continues if rate limit not exceeded
/// ```
import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import wisp

// ============================================================================
// Types
// ============================================================================

/// Token bucket for a single user
/// Tracks available tokens and last refill timestamp
pub type TokenBucket {
  TokenBucket(
    /// Number of tokens currently available
    tokens: Float,
    /// Maximum bucket capacity
    max_tokens: Int,
    /// Tokens added per second
    refill_rate: Float,
    /// Unix timestamp of last token refill
    last_refill: Int,
  )
}

/// Rate limiter state containing all user buckets
pub type RateLimiter {
  RateLimiter(
    /// Map from user ID to their token bucket
    buckets: Dict(String, TokenBucket),
    /// Default maximum tokens per user
    default_max_tokens: Int,
    /// Default token refill rate (tokens/second)
    default_refill_rate: Float,
  )
}

/// Result of rate limit check
pub type RateLimitResult {
  /// Request is allowed, bucket updated
  Allowed(limiter: RateLimiter, remaining: Int)
  /// Request is rate limited, retry after N seconds
  RateLimited(retry_after: Int)
}

// ============================================================================
// Core Rate Limiter Functions
// ============================================================================

/// Create a new rate limiter with default settings
///
/// ## Parameters
/// - max_tokens: Maximum number of tokens per user bucket
/// - refill_rate: Number of tokens to add per second
///
/// ## Example
/// ```gleam
/// let limiter = new(max_tokens: 100, refill_rate: 10.0)
/// ```
pub fn new(
  max_tokens max_tokens: Int,
  refill_rate refill_rate: Float,
) -> RateLimiter {
  RateLimiter(
    buckets: dict.new(),
    default_max_tokens: max_tokens,
    default_refill_rate: refill_rate,
  )
}

/// Get current Unix timestamp in seconds
fn now() -> Int {
  system_time_seconds()
}

@external(erlang, "erlang", "system_time")
fn system_time_seconds() -> Int

/// Refill tokens in a bucket based on elapsed time
///
/// Tokens are added at the configured refill rate.
/// The bucket cannot exceed its maximum capacity.
fn refill_bucket(bucket: TokenBucket) -> TokenBucket {
  let current_time = now()
  let elapsed = int.to_float(current_time - bucket.last_refill)
  let new_tokens = bucket.tokens +. { elapsed *. bucket.refill_rate }
  let capped_tokens = float.min(new_tokens, int.to_float(bucket.max_tokens))

  TokenBucket(..bucket, tokens: capped_tokens, last_refill: current_time)
}

/// Create a new token bucket for a user
fn new_bucket(max_tokens: Int, refill_rate: Float) -> TokenBucket {
  TokenBucket(
    tokens: int.to_float(max_tokens),
    max_tokens: max_tokens,
    refill_rate: refill_rate,
    last_refill: now(),
  )
}

/// Check if a request is allowed for a user
///
/// This consumes one token from the user's bucket.
/// If no tokens are available, the request is rate limited.
///
/// ## Parameters
/// - limiter: Current rate limiter state
/// - user_id: Unique identifier for the user
///
/// ## Returns
/// - Allowed: Request is permitted, includes updated limiter and remaining tokens
/// - RateLimited: Request is denied, includes retry_after seconds
pub fn check_rate_limit(
  limiter: RateLimiter,
  user_id: String,
) -> RateLimitResult {
  // Get or create bucket for this user
  let bucket = case dict.get(limiter.buckets, user_id) {
    Ok(existing_bucket) -> refill_bucket(existing_bucket)
    Error(_) ->
      new_bucket(limiter.default_max_tokens, limiter.default_refill_rate)
  }

  // Check if we have tokens available
  case bucket.tokens >=. 1.0 {
    True -> {
      // Consume one token
      let updated_bucket = TokenBucket(..bucket, tokens: bucket.tokens -. 1.0)
      let updated_buckets =
        dict.insert(limiter.buckets, user_id, updated_bucket)
      let updated_limiter = RateLimiter(..limiter, buckets: updated_buckets)

      let remaining = float.truncate(updated_bucket.tokens)
      Allowed(limiter: updated_limiter, remaining: remaining)
    }
    False -> {
      // Calculate retry_after based on how long until one token refills
      let tokens_needed = 1.0 -. bucket.tokens
      let seconds_until_token =
        float.ceiling(tokens_needed /. bucket.refill_rate)
      let retry_after = float.truncate(seconds_until_token)

      RateLimited(retry_after: retry_after)
    }
  }
}

/// Remove inactive buckets to prevent memory growth
///
/// Buckets are considered inactive if they haven't been accessed
/// for longer than the inactivity threshold (in seconds).
///
/// ## Parameters
/// - limiter: Current rate limiter state
/// - inactivity_threshold: Seconds of inactivity before cleanup (default: 3600 = 1 hour)
///
/// ## Returns
/// Updated limiter with inactive buckets removed
pub fn cleanup_inactive_buckets(
  limiter: RateLimiter,
  inactivity_threshold inactivity_threshold: Int,
) -> RateLimiter {
  let current_time = now()
  let cutoff_time = current_time - inactivity_threshold

  let active_buckets =
    dict.filter(limiter.buckets, fn(_user_id, bucket) {
      bucket.last_refill >= cutoff_time
    })

  RateLimiter(..limiter, buckets: active_buckets)
}

/// Get bucket statistics for a user
///
/// Returns information about a user's current rate limit status.
///
/// ## Returns
/// Option containing:
/// - available_tokens: Current token count
/// - max_tokens: Maximum bucket capacity
/// - refill_rate: Tokens per second refill rate
pub fn get_user_quota(
  limiter: RateLimiter,
  user_id: String,
) -> Option(#(Int, Int, Float)) {
  case dict.get(limiter.buckets, user_id) {
    Ok(bucket) -> {
      let refilled_bucket = refill_bucket(bucket)
      let available = float.truncate(refilled_bucket.tokens)
      Some(#(available, bucket.max_tokens, bucket.refill_rate))
    }
    Error(_) -> None
  }
}

/// Set custom quota for a specific user
///
/// Allows per-user rate limit customization (e.g., premium users get higher limits).
///
/// ## Parameters
/// - limiter: Current rate limiter state
/// - user_id: User to configure
/// - max_tokens: Maximum tokens for this user
/// - refill_rate: Token refill rate for this user
pub fn set_user_quota(
  limiter: RateLimiter,
  user_id: String,
  max_tokens max_tokens: Int,
  refill_rate refill_rate: Float,
) -> RateLimiter {
  let custom_bucket = new_bucket(max_tokens, refill_rate)
  let updated_buckets = dict.insert(limiter.buckets, user_id, custom_bucket)
  RateLimiter(..limiter, buckets: updated_buckets)
}

/// Reset a user's rate limit bucket to full capacity
///
/// Useful for manual resets or testing.
pub fn reset_user_limit(limiter: RateLimiter, user_id: String) -> RateLimiter {
  let buckets = dict.delete(limiter.buckets, user_id)
  RateLimiter(..limiter, buckets: buckets)
}

// ============================================================================
// Wisp Middleware Integration
// ============================================================================

/// Extract user ID from request
///
/// This is a simple implementation that uses the remote IP address.
/// In production, you would extract from JWT token, session cookie, or API key.
fn get_user_id(req: wisp.Request) -> String {
  // Use remote IP as user identifier
  // In production: parse Authorization header, session cookie, etc.
  case list.find(req.headers, fn(header) {
    string.lowercase(header.0) == "x-forwarded-for"
  }) {
    Ok(#(_, ip)) -> ip
    Error(_) -> "unknown"
  }
}

/// Wisp middleware function for rate limiting
///
/// This function checks the rate limit and either:
/// - Continues to the next handler if allowed
/// - Returns 429 Too Many Requests if rate limited
///
/// ## Parameters
/// - req: Wisp request
/// - limiter: Rate limiter state (pass via handler context)
/// - user_id: User identifier (typically from auth middleware)
/// - next: Continuation function to call if rate limit allows
///
/// ## Example
/// ```gleam
/// pub fn handle_request(req: wisp.Request, limiter: RateLimiter) -> wisp.Response {
///   let user_id = get_user_id(req)
///   use limiter <- require_rate_limit(req, limiter, user_id)
///   // Your handler logic here
///   wisp.response(200)
/// }
/// ```
pub fn require_rate_limit(
  req: wisp.Request,
  limiter: RateLimiter,
  user_id: String,
  next: fn(RateLimiter) -> wisp.Response,
) -> wisp.Response {
  case check_rate_limit(limiter, user_id) {
    Allowed(limiter: updated_limiter, remaining: remaining) -> {
      // Add rate limit headers to response
      let response = next(updated_limiter)
      response
      |> wisp.set_header(
        "x-ratelimit-limit",
        int.to_string(limiter.default_max_tokens),
      )
      |> wisp.set_header("x-ratelimit-remaining", int.to_string(remaining))
    }
    RateLimited(retry_after: retry_after) -> {
      // Return 429 Too Many Requests
      wisp.response(429)
      |> wisp.set_header("retry-after", int.to_string(retry_after))
      |> wisp.set_header("content-type", "application/json")
      |> wisp.string_body(
        "{\"error\":\"Rate limit exceeded\",\"retry_after\":"
        <> int.to_string(retry_after)
        <> "}",
      )
    }
  }
}

/// Convenience wrapper that extracts user ID from request automatically
///
/// ## Example
/// ```gleam
/// pub fn handle_request(req: wisp.Request, limiter: RateLimiter) -> wisp.Response {
///   use limiter <- check_request_rate_limit(req, limiter)
///   // Your handler logic here
///   wisp.response(200)
/// }
/// ```
pub fn check_request_rate_limit(
  req: wisp.Request,
  limiter: RateLimiter,
  next: fn(RateLimiter) -> wisp.Response,
) -> wisp.Response {
  let user_id = get_user_id(req)
  require_rate_limit(req, limiter, user_id, next)
}

// ============================================================================
// Utility Functions
// ============================================================================

/// Get total number of tracked users
pub fn bucket_count(limiter: RateLimiter) -> Int {
  dict.size(limiter.buckets)
}

/// Get rate limiter configuration
pub fn get_config(limiter: RateLimiter) -> #(Int, Float) {
  #(limiter.default_max_tokens, limiter.default_refill_rate)
}
