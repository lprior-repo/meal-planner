import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/tandoor/client.{
  type AuthMethod, type ClientConfig, BearerAuth, ClientConfig, SessionAuth,
}

pub fn main() {
  gleeunit.main()
}

// Test that ClientConfig and AuthMethod types are exported
pub fn test_client_config_type() {
  let config =
    ClientConfig(
      base_url: "http://localhost:8000",
      auth: BearerAuth(token: "test-token"),
      timeout_ms: 10_000,
      retry_on_transient: True,
      max_retries: 3,
    )

  should.equal(config.base_url, "http://localhost:8000")
  should.equal(config.timeout_ms, 10_000)
}

pub fn test_auth_method_bearer() {
  let auth = BearerAuth(token: "test-token")
  case auth {
    BearerAuth(token) -> should.equal(token, "test-token")
    _ -> should.fail()
  }
}

pub fn test_auth_method_session() {
  let auth =
    SessionAuth(
      username: "user",
      password: "pass",
      session_id: Some("session-123"),
      csrf_token: None,
    )
  case auth {
    SessionAuth(username, password, session_id, csrf_token) -> {
      should.equal(username, "user")
      should.equal(password, "pass")
      should.equal(session_id, Some("session-123"))
      should.equal(csrf_token, None)
    }
    _ -> should.fail()
  }
}
