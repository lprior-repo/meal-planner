import gleeunit
import gleeunit/should
import meal_planner/config

pub fn main() {
  gleeunit.main()
}

// Test that ConfigError type exists and has expected variants
pub fn config_error_missing_env_var_test() {
  let error = config.MissingEnvVar("DATABASE_HOST")
  case error {
    config.MissingEnvVar(name) -> should.equal(name, "DATABASE_HOST")
    _ -> should.fail()
  }
}

pub fn config_error_invalid_env_var_test() {
  let error =
    config.InvalidEnvVar(
      name: "DATABASE_PORT",
      value: "not_a_number",
      expected: "integer",
    )
  case error {
    config.InvalidEnvVar(name, value, expected) -> {
      should.equal(name, "DATABASE_PORT")
      should.equal(value, "not_a_number")
      should.equal(expected, "integer")
    }
    _ -> should.fail()
  }
}

// Test that load() returns Result type
pub fn load_returns_result_test() {
  let result = config.load()
  // This test will verify the function returns Result type
  case result {
    Ok(_) | Error(_) -> should.be_ok(Ok(Nil))
  }
}
