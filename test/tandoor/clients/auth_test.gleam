/// Tests for Tandoor Authentication Client
///
/// Tests session and bearer configuration, authentication status checks,
/// and helper functions for authentication workflows.
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/tandoor/client.{BearerAuth, SessionAuth}
import meal_planner/tandoor/clients/auth

// ============================================================================
// Config Factory Tests
// ============================================================================

pub fn test_session_config_creates_client_config() {
  let config =
    auth.session_config("http://localhost:8000", "testuser", "testpass")

  config.base_url
  |> should.equal("http://localhost:8000")

  case config.auth {
    SessionAuth(username, password, session_id, csrf_token) -> {
      username |> should.equal("testuser")
      password |> should.equal("testpass")
      session_id |> should.equal(None)
      csrf_token |> should.equal(None)
    }
    _ -> should.fail()
  }
}

pub fn test_session_config_sets_default_timeout() {
  let config = auth.session_config("http://localhost:8000", "user", "pass")

  config.timeout_ms
  |> should.equal(10_000)
}

pub fn test_session_config_enables_retry_on_transient() {
  let config = auth.session_config("http://localhost:8000", "user", "pass")

  config.retry_on_transient
  |> should.be_true
}

pub fn test_bearer_config_creates_client_config() {
  let config = auth.bearer_config("http://localhost:8000", "test-bearer-token")

  config.base_url
  |> should.equal("http://localhost:8000")

  case config.auth {
    BearerAuth(token) -> {
      token |> should.equal("test-bearer-token")
    }
    _ -> should.fail()
  }
}

pub fn test_bearer_config_sets_default_timeout() {
  let config = auth.bearer_config("http://localhost:8000", "token")

  config.timeout_ms
  |> should.equal(10_000)
}

pub fn test_bearer_config_sets_max_retries() {
  let config = auth.bearer_config("http://localhost:8000", "token")

  config.max_retries
  |> should.equal(3)
}

// ============================================================================
// Authentication Status Tests
// ============================================================================

pub fn test_is_authenticated_returns_true_for_bearer_auth() {
  let config = auth.bearer_config("http://localhost:8000", "token")

  auth.is_authenticated(config)
  |> should.be_true
}

pub fn test_is_authenticated_returns_false_for_session_auth_without_session() {
  let config = auth.session_config("http://localhost:8000", "user", "pass")

  auth.is_authenticated(config)
  |> should.be_false
}

pub fn test_is_authenticated_returns_true_for_session_auth_with_session() {
  let config = auth.session_config("http://localhost:8000", "user", "pass")

  // Manually add session to config for testing
  let config_with_session =
    client.ClientConfig(
      base_url: config.base_url,
      auth: SessionAuth(
        username: "user",
        password: "pass",
        session_id: Some("test-session-id"),
        csrf_token: Some("test-csrf"),
      ),
      timeout_ms: config.timeout_ms,
      retry_on_transient: config.retry_on_transient,
      max_retries: config.max_retries,
    )

  auth.is_authenticated(config_with_session)
  |> should.be_true
}

// ============================================================================
// Ensure Authenticated Tests
// ============================================================================

pub fn test_ensure_authenticated_returns_ok_for_bearer_auth() {
  let config = auth.bearer_config("http://localhost:8000", "token")

  case auth.ensure_authenticated(config) {
    Ok(returned_config) -> {
      returned_config.base_url |> should.equal(config.base_url)
    }
    Error(_) -> should.fail()
  }
}

pub fn test_ensure_authenticated_returns_ok_for_session_with_session() {
  let config =
    client.ClientConfig(
      base_url: "http://localhost:8000",
      auth: SessionAuth(
        username: "user",
        password: "pass",
        session_id: Some("test-session"),
        csrf_token: Some("test-csrf"),
      ),
      timeout_ms: 10_000,
      retry_on_transient: True,
      max_retries: 3,
    )

  case auth.ensure_authenticated(config) {
    Ok(returned_config) -> {
      returned_config.base_url |> should.equal(config.base_url)
    }
    Error(_) -> should.fail()
  }
}
// Note: We cannot test the actual login flow without a mock HTTP client,
// as it requires network calls to the Tandoor server. Those tests would
// belong in integration tests, not unit tests.
