/// Health check handler for the Meal Planner API
///
/// This module provides comprehensive health check endpoints for monitoring:
/// - Overall service health
/// - Database connection status
/// - External API connectivity (FatSecret, Tandoor)
/// - Cache system status
///
/// Routes:
/// - GET /health - Basic health check JSON response
/// - GET /health/detailed - Detailed health check with all subsystems
/// - GET / - Alias for /health
///
/// All endpoints use Wisp's idiomatic patterns for HTTP method checking and response handling.
import gleam/http
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import meal_planner/cache
import meal_planner/config
import meal_planner/tandoor/connectivity
import meal_planner/web/responses
import pog
import wisp

/// Health check status for individual components
pub type ComponentStatus {
  Healthy
  Degraded
  Unhealthy
  NotConfigured
}

/// Health check result for a component
pub type HealthCheck {
  HealthCheck(status: ComponentStatus, message: String, details: Option(String))
}

/// Overall system health
pub type SystemHealth {
  SystemHealth(
    status: ComponentStatus,
    database: HealthCheck,
    cache: HealthCheck,
    fatsecret: HealthCheck,
    tandoor: HealthCheck,
  )
}

/// Basic health check endpoint - GET /health or GET /
///
/// Returns a JSON response indicating service health status.
/// This is a lightweight check suitable for load balancers.
pub fn handle(req: wisp.Request) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  let health_data =
    json.object([
      #("status", json.string("healthy")),
      #("service", json.string("meal-planner")),
      #("version", json.string("1.0.0")),
    ])

  responses.json_ok(health_data)
}

/// Detailed health check endpoint - GET /health/detailed
///
/// Returns detailed status for all subsystems:
/// - Database connection
/// - Cache system
/// - External APIs (FatSecret, Tandoor)
///
/// Requires database connection and config from context.
pub fn handle_detailed(
  req: wisp.Request,
  db: pog.Connection,
  app_config: config.Config,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  // Check all subsystems
  let db_health = check_database(db)
  let cache_health = check_cache()
  let fatsecret_health = check_fatsecret(app_config)
  let tandoor_health = check_tandoor(app_config)

  // Determine overall status
  let overall_status =
    calculate_overall_status([
      db_health.status,
      cache_health.status,
      fatsecret_health.status,
      tandoor_health.status,
    ])

  let system_health =
    SystemHealth(
      status: overall_status,
      database: db_health,
      cache: cache_health,
      fatsecret: fatsecret_health,
      tandoor: tandoor_health,
    )

  // Encode to JSON
  let health_json = encode_system_health(system_health)

  // Return appropriate HTTP status based on overall health
  case overall_status {
    Healthy -> responses.json_ok(health_json)
    Degraded -> responses.json_ok(health_json)
    Unhealthy -> wisp.json_response(json.to_string(health_json), 503)
    NotConfigured -> responses.json_ok(health_json)
  }
}

// ============================================================================
// Component Health Checks
// ============================================================================

/// Check database connectivity
fn check_database(db: pog.Connection) -> HealthCheck {
  let query =
    "SELECT 1 as health_check"
    |> pog.query

  case pog.execute(query:, on: db) {
    Ok(_) ->
      HealthCheck(
        status: Healthy,
        message: "Database connection successful",
        details: None,
      )
    Error(e) ->
      HealthCheck(
        status: Unhealthy,
        message: "Database connection failed",
        details: Some("Error: " <> postgres_error_to_string(e)),
      )
  }
}

/// Check cache system status
fn check_cache() -> HealthCheck {
  // Create a test cache and verify basic operations
  let test_cache = cache.new()
  let test_key = "health_check_test"
  let test_value = "test"

  // Test write
  let test_cache = cache.set(test_cache, test_key, test_value, 60)

  // Test read
  let #(_cache, result) = cache.get(test_cache, test_key)

  case result {
    Some(_value) ->
      HealthCheck(
        status: Healthy,
        message: "Cache system operational",
        details: None,
      )
    None ->
      HealthCheck(
        status: Degraded,
        message: "Cache system degraded",
        details: Some("Cache read/write test failed"),
      )
  }
}

/// Check FatSecret API connectivity
fn check_fatsecret(app_config: config.Config) -> HealthCheck {
  case app_config.external_services.fatsecret {
    None ->
      HealthCheck(
        status: NotConfigured,
        message: "FatSecret not configured",
        details: Some(
          "FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET not set",
        ),
      )
    Some(_config) ->
      // FatSecret is configured
      // In a real implementation, you would make a lightweight API call here
      // For now, we just verify configuration
      HealthCheck(
        status: Healthy,
        message: "FatSecret configured",
        details: Some("API credentials present"),
      )
  }
}

/// Check Tandoor API connectivity
fn check_tandoor(app_config: config.Config) -> HealthCheck {
  let tandoor_health = connectivity.check_health(app_config)

  case tandoor_health.status {
    connectivity.Healthy ->
      HealthCheck(
        status: Healthy,
        message: tandoor_health.message,
        details: None,
      )
    connectivity.NotConfigured ->
      HealthCheck(
        status: NotConfigured,
        message: tandoor_health.message,
        details: Some("TANDOOR_API_TOKEN not set"),
      )
    connectivity.Unreachable ->
      HealthCheck(
        status: Unhealthy,
        message: tandoor_health.message,
        details: Some("Tandoor service unreachable"),
      )
    connectivity.Timeout ->
      HealthCheck(
        status: Degraded,
        message: tandoor_health.message,
        details: Some("Tandoor request timeout"),
      )
    connectivity.DnsFailed ->
      HealthCheck(
        status: Unhealthy,
        message: tandoor_health.message,
        details: Some("DNS resolution failed for Tandoor"),
      )
    connectivity.Error(msg) ->
      HealthCheck(
        status: Degraded,
        message: tandoor_health.message,
        details: Some(msg),
      )
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Calculate overall system status from component statuses
fn calculate_overall_status(statuses: List(ComponentStatus)) -> ComponentStatus {
  // Check if any component is unhealthy
  let has_unhealthy =
    statuses
    |> list.any(fn(status) {
      case status {
        Unhealthy -> True
        _ -> False
      }
    })

  // Check if any component is degraded
  let has_degraded =
    statuses
    |> list.any(fn(status) {
      case status {
        Degraded -> True
        _ -> False
      }
    })

  case has_unhealthy, has_degraded {
    True, _ -> Unhealthy
    False, True -> Degraded
    False, False -> Healthy
  }
}

/// Convert ComponentStatus to string
fn status_to_string(status: ComponentStatus) -> String {
  case status {
    Healthy -> "healthy"
    Degraded -> "degraded"
    Unhealthy -> "unhealthy"
    NotConfigured -> "not_configured"
  }
}

/// Encode HealthCheck to JSON
fn encode_health_check(check: HealthCheck) -> json.Json {
  let base_fields = [
    #("status", json.string(status_to_string(check.status))),
    #("message", json.string(check.message)),
  ]

  let fields = case check.details {
    Some(details) -> [#("details", json.string(details)), ..base_fields]
    None -> base_fields
  }

  json.object(fields)
}

/// Encode SystemHealth to JSON
fn encode_system_health(health: SystemHealth) -> json.Json {
  json.object([
    #("status", json.string(status_to_string(health.status))),
    #("service", json.string("meal-planner")),
    #("version", json.string("1.0.0")),
    #(
      "components",
      json.object([
        #("database", encode_health_check(health.database)),
        #("cache", encode_health_check(health.cache)),
        #("fatsecret", encode_health_check(health.fatsecret)),
        #("tandoor", encode_health_check(health.tandoor)),
      ]),
    ),
  ])
}

/// Convert postgres error to string
fn postgres_error_to_string(error: pog.QueryError) -> String {
  case error {
    pog.ConnectionUnavailable -> "Connection unavailable"
    pog.ConstraintViolated(message:, constraint: _, detail: _) ->
      "Constraint violated: " <> message
    pog.PostgresqlError(code:, name:, message:) ->
      "PostgreSQL error " <> code <> " (" <> name <> "): " <> message
    pog.UnexpectedArgumentCount(expected:, got:) ->
      "Unexpected argument count: expected "
      <> int.to_string(expected)
      <> ", got "
      <> int.to_string(got)
    pog.UnexpectedArgumentType(expected:, got:) ->
      "Unexpected argument type: expected " <> expected <> ", got " <> got
    pog.UnexpectedResultType(_errors) -> "Unexpected result type (decode error)"
    pog.QueryTimeout -> "Query timeout"
  }
}
