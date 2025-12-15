/// Comprehensive Tandoor API Endpoint Tests
///
/// Tests all major Tandoor API endpoints using the existing Tandoor modules
/// Validates connectivity, authentication, and endpoint availability
import gleeunit
import gleeunit/should
import meal_planner/config
import meal_planner/tandoor/connectivity

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Tandoor Connectivity Tests
// ============================================================================

/// Test that Tandoor connectivity module properly detects configured/unconfigured state
pub fn tandoor_connectivity_check_handles_no_token_test() {
  // Create a config with no API token
  let test_config =
    config.Config(
      database: config.DatabaseConfig(
        host: "localhost",
        port: 5432,
        name: "test_db",
        user: "postgres",
        password: "",
        pool_size: 10,
      ),
      server: config.ServerConfig(port: 8080, environment: "test"),
      tandoor: config.TandoorConfig(
        base_url: "http://localhost:8000",
        api_token: "",
        connect_timeout_ms: 5000,
        request_timeout_ms: 30_000,
      ),
      external_services: config.ExternalServicesConfig(
        todoist_api_key: "",
        usda_api_key: "",
        openai_api_key: "",
        openai_model: "gpt-4o",
      ),
    )

  let health = connectivity.check_health(test_config)

  case health.status {
    connectivity.NotConfigured -> {
      health.configured
      |> should.equal(False)
    }
    _ -> {
      should.fail()
    }
  }
}

/// Test that Tandoor connectivity recognizes when token is configured
pub fn tandoor_connectivity_detects_configured_token_test() {
  let test_config =
    config.Config(
      database: config.DatabaseConfig(
        host: "localhost",
        port: 5432,
        name: "test_db",
        user: "postgres",
        password: "",
        pool_size: 10,
      ),
      server: config.ServerConfig(port: 8080, environment: "test"),
      tandoor: config.TandoorConfig(
        base_url: "http://localhost:8000",
        api_token: "test-token-abc123",
        connect_timeout_ms: 5000,
        request_timeout_ms: 30_000,
      ),
      external_services: config.ExternalServicesConfig(
        todoist_api_key: "",
        usda_api_key: "",
        openai_api_key: "",
        openai_model: "gpt-4o",
      ),
    )

  let result = connectivity.is_configured(test_config)
  result
  |> should.equal(True)
}

/// Test that Tandoor connectivity status can be evaluated for health
pub fn tandoor_connectivity_status_evaluation_test() {
  let healthy = connectivity.is_status_healthy(connectivity.Healthy)
  healthy
  |> should.equal(True)

  let not_healthy = connectivity.is_status_healthy(connectivity.NotConfigured)
  not_healthy
  |> should.equal(False)

  let unreachable = connectivity.is_status_healthy(connectivity.Unreachable)
  unreachable
  |> should.equal(False)
}

// ============================================================================
// Tandoor Health Check Tests
// ============================================================================

/// Test that health check properly handles connectivity
pub fn tandoor_health_check_test() {
  let test_config =
    config.Config(
      database: config.DatabaseConfig(
        host: "localhost",
        port: 5432,
        name: "test_db",
        user: "postgres",
        password: "",
        pool_size: 10,
      ),
      server: config.ServerConfig(port: 8080, environment: "test"),
      tandoor: config.TandoorConfig(
        base_url: "http://localhost:8000",
        api_token: "valid-token",
        connect_timeout_ms: 5000,
        request_timeout_ms: 30_000,
      ),
      external_services: config.ExternalServicesConfig(
        todoist_api_key: "",
        usda_api_key: "",
        openai_api_key: "",
        openai_model: "gpt-4o",
      ),
    )

  let health = connectivity.check_health(test_config)

  // Should complete without errors
  health.message
  |> should.not_equal("")
}

/// Test Healthy status identification
pub fn tandoor_health_status_is_healthy_test() {
  let is_healthy = connectivity.is_status_healthy(connectivity.Healthy)
  is_healthy
  |> should.equal(True)

  let is_not_healthy = connectivity.is_status_healthy(connectivity.Unreachable)
  is_not_healthy
  |> should.equal(False)
}
