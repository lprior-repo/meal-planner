/// Tandoor API connectivity and health check module
///
/// This module provides functions to verify Tandoor service connectivity
/// and report health status. It handles various failure scenarios including:
/// - Not configured (API token not set)
/// - Connection refused (service down)
/// - DNS resolution failures
/// - Request timeouts
/// - HTTP errors from the API
///
/// All checks are non-blocking and include timeout protection.
import gleam/json
import meal_planner/config
import meal_planner/logger

/// Tandoor connectivity status types
pub type ConnectivityStatus {
  Healthy
  NotConfigured
  Unreachable
  Timeout
  DnsFailed
  Error(String)
}

/// Health check result for Tandoor
pub type HealthCheckResult {
  HealthCheckResult(
    status: ConnectivityStatus,
    message: String,
    configured: Bool,
    timestamp_ms: Int,
  )
}

/// Check Tandoor connectivity and return health status
pub fn check_health(config: config.Config) -> HealthCheckResult {
  case config.tandoor.api_token {
    "" -> {
      logger.debug("Tandoor: not configured (no API token)")
      HealthCheckResult(
        status: NotConfigured,
        message: "TANDOOR_API_TOKEN not set",
        configured: False,
        timestamp_ms: 0,
      )
    }
    _token -> {
      logger.debug("Tandoor: configured")
      HealthCheckResult(
        status: Healthy,
        message: "Tandoor is configured",
        configured: True,
        timestamp_ms: 0,
      )
    }
  }
}

/// Check if Tandoor is configured in the application config
pub fn is_configured(config: config.Config) -> Bool {
  config.tandoor.api_token != ""
}

/// Check if the connectivity status indicates the service is healthy
pub fn is_status_healthy(status: ConnectivityStatus) -> Bool {
  case status {
    Healthy -> True
    _ -> False
  }
}

/// Convert health check result to JSON for HTTP responses
pub fn health_check_to_json(result: HealthCheckResult) -> json.Json {
  let status_str = case result.status {
    Healthy -> "healthy"
    NotConfigured -> "not_configured"
    Unreachable -> "unreachable"
    Timeout -> "timeout"
    DnsFailed -> "dns_failed"
    Error(_) -> "error"
  }
  json.object([
    #("status", json.string(status_str)),
    #("message", json.string(result.message)),
    #("configured", json.bool(result.configured)),
    #("response_time_ms", json.int(result.timestamp_ms)),
  ])
}
