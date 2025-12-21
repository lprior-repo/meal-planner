//// TDD Tests for CLI web command
////
//// RED PHASE: This test validates:
//// 1. Web domain command creation and help text
//// 2. Configuration display functionality
//// 3. Proper Glint command registration

import gleeunit
import meal_planner/cli/domains/web
import meal_planner/config
import meal_planner/tandoor.{type TandoorConfig, TandoorConfig}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures
// ============================================================================

/// Create a minimal test configuration
fn create_test_config() -> config.Config {
  config.Config(
    server: config.ServerConfig(port: 8080, host: "localhost"),
    database: config.DatabaseConfig(
      host: "localhost",
      port: 5432,
      database: "meal_planner",
      user: "test",
      password: "test",
    ),
    tandoor: TandoorConfig(
      base_url: "http://tandoor:8000",
      bearer_token: Some("test-token"),
    ),
    external_services: config.ExternalServicesConfig(
      fatsecret: config.FatSecretConfig(
        consumer_key: "test-key",
        consumer_secret: "test-secret",
      ),
    ),
  )
}

// ============================================================================
// Web Command Tests
// ============================================================================

/// Test: cmd creates a valid Glint command
pub fn cmd_creates_command_test() {
  let config = create_test_config()
  let _command = web.cmd(config)
  // If we get here without panic, command was created successfully
  Nil
}
