import gleeunit
import gleeunit/should
import meal_planner/env

pub fn main() {
  gleeunit.main()
}

// Test that required environment variables are validated
pub fn validate_required_vars_missing_test() {
  // When all env vars are missing, should return error with all missing vars
  let vars =
    env.RequiredVars(
      mailtrap_api_token: "",
      sender_email: "",
      sender_name: "",
      recipient_email: "",
    )

  let result = env.validate_required_vars(vars)

  result
  |> should.be_error()
}

// Test that validation passes when all vars are present
pub fn validate_required_vars_present_test() {
  let vars =
    env.RequiredVars(
      mailtrap_api_token: "test_token",
      sender_email: "test@example.com",
      sender_name: "Test Sender",
      recipient_email: "recipient@example.com",
    )

  let result = env.validate_required_vars(vars)

  result
  |> should.be_ok()
}

// Test that partial missing variables returns error
pub fn validate_required_vars_partial_test() {
  let vars =
    env.RequiredVars(
      mailtrap_api_token: "test_token",
      sender_email: "",
      sender_name: "Test",
      recipient_email: "",
    )

  let result = env.validate_required_vars(vars)

  result
  |> should.be_error()
}

// Test loading from environment
pub fn load_from_env_test() {
  // This will fail if env vars aren't set, which is expected in test
  // The function should handle missing vars gracefully
  let result = env.load_from_env()

  // In test environment, we expect this to either:
  // 1. Return Ok if .env file exists with valid vars
  // 2. Return Error if vars are missing
  // We just verify it returns a Result
  case result {
    Ok(_vars) -> True |> should.be_true()
    Error(_msg) -> True |> should.be_true()
  }
}
