//// Test harness for integration tests
//// Provides unified setup/teardown, credential loading, and graceful skipping

import gleam/io
import gleam/option.{None, Some}
import integration/helpers/credentials
import integration/helpers/http

/// Test credentials container
pub type TestCredentials {
  TestCredentials(
    tandoor: credentials.TandoorCreds,
    fatsecret: credentials.FatSecretCreds,
  )
}

/// Test context containing all resources needed for integration tests
pub type TestContext {
  TestContext(credentials: TestCredentials, server_available: Bool)
}

/// Setup test context - loads credentials and checks server availability
pub fn setup() -> TestContext {
  let creds = credentials.load()

  // Check if server is available by trying to connect
  let server_available = case http.get("/health") {
    Ok(_) -> True
    Error(_) -> False
  }

  // Extract credentials or use empty defaults
  let tandoor_creds = case creds.tandoor {
    Some(tc) -> tc
    None ->
      credentials.TandoorCreds(
        base_url: "http://localhost:8080",
        username: "",
        password: "",
      )
  }

  let fatsecret_creds = case creds.fatsecret {
    Some(fs) -> fs
    None -> credentials.FatSecretCreds(oauth_token: "", oauth_token_secret: "")
  }

  TestContext(
    credentials: TestCredentials(
      tandoor: tandoor_creds,
      fatsecret: fatsecret_creds,
    ),
    server_available: server_available,
  )
}

/// Teardown test context - cleanup resources
pub fn teardown(_context: TestContext) -> Result(Nil, String) {
  // No cleanup needed for now
  Ok(Nil)
}

/// Run a test with the provided context
pub fn run_test(
  context: TestContext,
  test_fn: fn(TestContext) -> Result(a, String),
) -> Result(a, String) {
  test_fn(context)
}

/// Skip test if service is unavailable
pub fn skip_if_unavailable(
  context: TestContext,
  service: String,
  test_fn: fn(TestContext) -> Result(a, String),
) -> Result(a, String) {
  case service {
    "tandoor" ->
      case context.server_available {
        True -> test_fn(context)
        False -> {
          io.println("  ⚠️  Skipping - Tandoor not configured")
          Error("Skipping - Tandoor not configured")
        }
      }
    "fatsecret" ->
      case context.credentials.fatsecret.oauth_token {
        "" -> {
          io.println("  ⚠️  Skipping - FatSecret not configured")
          Error("Skipping - FatSecret not configured")
        }
        _ -> test_fn(context)
      }
    _ -> Error("Unknown service: " <> service)
  }
}
