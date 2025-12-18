//// Tests for Tandoor authentication functions

import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/client.{
  type ClientConfig, BearerAuth, ClientConfig, SessionAuth,
}
import meal_planner/tandoor/clients/auth

/// Test is_authenticated returns True for BearerAuth
pub fn is_authenticated_bearer_test() {
  let config =
    ClientConfig(
      base_url: "http://localhost:8000",
      auth: BearerAuth(token: "test-token"),
      timeout_ms: 10_000,
      retry_on_transient: True,
      max_retries: 3,
    )

  auth.is_authenticated(config)
  |> should.be_true
}

/// Test is_authenticated returns True for SessionAuth with session_id
pub fn is_authenticated_session_with_id_test() {
  let config =
    ClientConfig(
      base_url: "http://localhost:8000",
      auth: SessionAuth(
        username: "test",
        password: "pass",
        session_id: Some("session123"),
        csrf_token: Some("csrf123"),
      ),
      timeout_ms: 10_000,
      retry_on_transient: True,
      max_retries: 3,
    )

  auth.is_authenticated(config)
  |> should.be_true
}

/// Test is_authenticated returns False for SessionAuth without session_id
pub fn is_authenticated_session_without_id_test() {
  let config =
    ClientConfig(
      base_url: "http://localhost:8000",
      auth: SessionAuth(
        username: "test",
        password: "pass",
        session_id: None,
        csrf_token: None,
      ),
      timeout_ms: 10_000,
      retry_on_transient: True,
      max_retries: 3,
    )

  auth.is_authenticated(config)
  |> should.be_false
}

/// Test ensure_authenticated returns Ok for already authenticated config
pub fn ensure_authenticated_already_authenticated_test() {
  let config =
    ClientConfig(
      base_url: "http://localhost:8000",
      auth: BearerAuth(token: "test-token"),
      timeout_ms: 10_000,
      retry_on_transient: True,
      max_retries: 3,
    )

  case auth.ensure_authenticated(config) {
    Ok(c) -> {
      c.base_url
      |> should.equal("http://localhost:8000")
    }
    Error(_) -> should.fail()
  }
}
