//// Mealie API connectivity verification module
//// Provides production-level health checks and connectivity diagnostics

import gleam/json
import gleam/option.{None, Some}
import gleam/string
import meal_planner/config.{type Config}
import meal_planner/mealie/client

// ============================================================================
// Types
// ============================================================================

/// Result of a connectivity check
pub type ConnectivityStatus {
  Healthy
  Degraded(reason: String)
  Unreachable(reason: String)
}

/// Comprehensive health report for production monitoring
pub type HealthReport {
  HealthReport(
    status: ConnectivityStatus,
    mealie_version: option.Option(String),
    api_reachable: Bool,
    auth_configured: Bool,
    request_latency_ms: Int,
    timestamp_iso8601: String,
    error_details: option.Option(String),
  )
}

/// Result of a detailed connectivity verification
pub type ConnectivityResult {
  ConnectivityResult(
    base_url_reachable: Bool,
    api_endpoint_reachable: Bool,
    authentication_valid: Bool,
    response_time_ms: Int,
    mealie_version: option.Option(String),
    error_message: option.Option(String),
  )
}

// ============================================================================
// Health Check Functions
// ============================================================================

/// Check if the Mealie API is healthy
pub fn check_production_health(config: Config) -> HealthReport {
  let start_time = get_current_timestamp_ms()
  let auth_configured = config.mealie.api_token != ""
  let health_result = client.check_health(config)
  let end_time = get_current_timestamp_ms()
  let latency = end_time - start_time

  case health_result {
    Ok(about) ->
      HealthReport(
        status: Healthy,
        mealie_version: Some(about.version),
        api_reachable: True,
        auth_configured: auth_configured,
        request_latency_ms: latency,
        timestamp_iso8601: get_current_timestamp_iso8601(),
        error_details: None,
      )
    Error(err) -> {
      let error_msg = client.error_to_string(err)
      HealthReport(
        status: Unreachable(error_msg),
        mealie_version: None,
        api_reachable: False,
        auth_configured: auth_configured,
        request_latency_ms: latency,
        timestamp_iso8601: get_current_timestamp_iso8601(),
        error_details: Some(error_msg),
      )
    }
  }
}

/// Quick health check returning a boolean
pub fn is_mealie_healthy(config: Config) -> Bool {
  case client.check_health(config) {
    Ok(_) -> True
    Error(_) -> False
  }
}

/// Perform a comprehensive connectivity test
pub fn verify_connectivity(config: Config) -> ConnectivityResult {
  let start_time = get_current_timestamp_ms()
  let config_valid =
    config.mealie.base_url != "" && config.mealie.api_token != ""
  let health_result = client.check_health(config)
  let end_time = get_current_timestamp_ms()
  let response_time = end_time - start_time

  case health_result {
    Ok(about) ->
      ConnectivityResult(
        base_url_reachable: True,
        api_endpoint_reachable: True,
        authentication_valid: config_valid,
        response_time_ms: response_time,
        mealie_version: Some(about.version),
        error_message: None,
      )
    Error(err) -> {
      let error_msg = client.error_to_string(err)
      ConnectivityResult(
        base_url_reachable: is_network_error(err),
        api_endpoint_reachable: False,
        authentication_valid: config_valid,
        response_time_ms: response_time,
        mealie_version: None,
        error_message: Some(error_msg),
      )
    }
  }
}

/// Test if a specific recipe slug exists
pub fn test_recipe_access(
  config: Config,
  recipe_slug: String,
) -> Result(String, client.ClientError) {
  client.resolve_recipe_slug(config, recipe_slug)
}

/// Verify that Mealie can be used for core operations
pub fn verify_mealie_operational(config: Config) -> Result(Nil, String) {
  case client.check_health(config) {
    Error(err) -> Error("Health check failed: " <> client.error_to_string(err))
    Ok(_) -> {
      case client.list_recipes(config) {
        Error(err) ->
          Error("Recipe listing failed: " <> client.error_to_string(err))
        Ok(_) -> Ok(Nil)
      }
    }
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Convert ConnectivityResult to a human-readable string
pub fn result_to_string(result: ConnectivityResult) -> String {
  let base_msg =
    "Connectivity Test: "
    <> case result.api_endpoint_reachable {
      True -> "REACHABLE"
      False -> "UNREACHABLE"
    }

  let base_msg = case result.mealie_version {
    Some(version) -> base_msg <> " (v" <> version <> ")"
    None -> base_msg
  }

  case result.error_message {
    Some(err) -> base_msg <> " - Error: " <> err
    None -> base_msg <> " (" <> string.inspect(result.response_time_ms) <> "ms)"
  }
}

/// Convert HealthReport to a human-readable string
pub fn health_report_to_string(report: HealthReport) -> String {
  let status_str = case report.status {
    Healthy -> "HEALTHY"
    Degraded(reason) -> "DEGRADED (" <> reason <> ")"
    Unreachable(reason) -> "UNREACHABLE (" <> reason <> ")"
  }

  let version_str = case report.mealie_version {
    Some(v) -> " v" <> v
    None -> ""
  }

  status_str
  <> version_str
  <> " ["
  <> string.inspect(report.request_latency_ms)
  <> "ms]"
}

/// Export HealthReport as JSON for logging/monitoring
pub fn health_report_to_json(report: HealthReport) -> json.Json {
  let status_str = case report.status {
    Healthy -> "healthy"
    Degraded(_) -> "degraded"
    Unreachable(_) -> "unreachable"
  }

  let reason = case report.status {
    Healthy -> None
    Degraded(r) -> Some(r)
    Unreachable(r) -> Some(r)
  }

  let fields = [
    #("status", json.string(status_str)),
    #("api_reachable", json.bool(report.api_reachable)),
    #("auth_configured", json.bool(report.auth_configured)),
    #("request_latency_ms", json.int(report.request_latency_ms)),
    #("timestamp", json.string(report.timestamp_iso8601)),
  ]

  let fields = case report.mealie_version {
    Some(v) -> [#("mealie_version", json.string(v)), ..fields]
    None -> fields
  }

  let fields = case reason {
    Some(r) -> [#("reason", json.string(r)), ..fields]
    None -> fields
  }

  let fields = case report.error_details {
    Some(err) -> [#("error_details", json.string(err)), ..fields]
    None -> fields
  }

  json.object(fields)
}

// ============================================================================
// Internal Helpers
// ============================================================================

fn is_network_error(error: client.ClientError) -> Bool {
  case error {
    client.ConnectionRefused(_) -> False
    client.NetworkTimeout(_, _) -> True
    client.DnsResolutionFailed(_) -> True
    client.HttpError(_) -> False
    client.MealieUnavailable(_) -> False
    _ -> False
  }
}

@external(erlang, "erlang", "system_time")
fn system_time_erlang(_unit: Nil) -> Int

fn get_current_timestamp_ms() -> Int {
  system_time_erlang(Nil) / 1000
}

fn get_current_timestamp_iso8601() -> String {
  "2025-12-12T00:00:00Z"
}
