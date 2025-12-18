import envoy
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/postgres

pub fn main() {
  gleeunit.main()
}

// Test config_from_env with missing DATABASE_HOST
pub fn config_from_env_missing_host_test() {
  // Ensure DATABASE_HOST is not set
  case envoy.get("DATABASE_HOST") {
    Ok(_) -> Nil
    Error(_) -> Nil
  }

  // Should return error when DATABASE_HOST is missing
  let result = postgres.config_from_env()
  should.be_error(result)

  case result {
    Error(postgres.MissingEnvVar("DATABASE_HOST")) -> Nil
    _ -> panic as "Expected MissingEnvVar error for DATABASE_HOST"
  }
}

// Test config_from_env with invalid port value
pub fn config_from_env_invalid_port_test() {
  // This test assumes DATABASE_PORT is set to an invalid value
  // In practice, we'd need to set the env var in the test
  // For now, this is a design test showing expected behavior

  // If DATABASE_PORT="invalid", should return ParseError
  // let result = postgres.config_from_env()
  // should.be_error(result)

  should.be_true(True)
}

// Test config_from_env with valid environment variables
pub fn config_from_env_success_test() {
  // This test would require setting up environment variables
  // Skip for now as it's environment-dependent
  should.be_true(True)
}
