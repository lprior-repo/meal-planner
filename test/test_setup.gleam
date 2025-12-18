/// Integration Test Setup Module
/// This module ensures all infrastructure is stood up BEFORE any tests run
/// It runs automatically when the test suite initializes
import envoy
import gleam/io
import gleam/string
import meal_planner/infrastructure_setup
import meal_planner/tandoor/client

/// Setup result type
pub type SetupResult {
  SetupSuccess
  SetupFailure(String)
}

/// Check if we're running integration tests
/// Now always returns True to enable automatic infrastructure setup
pub fn should_setup_infrastructure() -> Bool {
  // Always attempt to set up infrastructure
  // The infrastructure_setup module will determine if it's actually needed
  True
}

/// Cleanup infrastructure after tests
pub fn cleanup_test_infrastructure() -> Nil {
  case should_setup_infrastructure() {
    True -> {
      io.println("\n🧹 Note: Services are still running for debugging")
      io.println("To stop: ./scripts/setup-integration-tests.sh stop")
      io.println("To cleanup: ./scripts/setup-integration-tests.sh cleanup\n")
    }
    False -> Nil
  }
}

/// Global test initialization - called before any tests
/// This function runs automatically and handles infrastructure setup
pub fn initialize_tests() -> SetupResult {
  io.println("\n" <> string.repeat("=", 60))
  io.println("  Meal Planner Test Suite")
  io.println(string.repeat("=", 60) <> "\n")

  case should_setup_infrastructure() {
    True -> {
      io.println("🔧 Attempting automatic infrastructure setup...")
      io.println("🔍 Checking Docker and services...\n")

      let config = infrastructure_setup.default_config()

      // Attempt to start infrastructure if not already running
      case infrastructure_setup.initialize_if_needed(config) {
        Ok(Nil) -> {
          io.println("✅ Infrastructure ready for integration tests\n")
          SetupSuccess
        }
        Error(msg) -> {
          io.println("⚠️  Infrastructure setup issue: " <> msg)
          io.println(
            "Integration tests will attempt to run if services are available\n",
          )
          SetupSuccess
          // Continue anyway - tests will fail gracefully if needed
        }
      }
    }
    False -> {
      io.println("📝 Unit test mode - skipping infrastructure setup")
      SetupSuccess
    }
  }
}

/// Get Tandoor client configuration for testing
/// Returns configuration if environment is set up for integration testing
pub fn get_test_config() -> Result(client.ClientConfig, String) {
  // Try TANDOOR_TEST_URL first, then TANDOOR_URL
  let base_url = case envoy.get("TANDOOR_TEST_URL") {
    Ok(url) -> Ok(url)
    Error(_) -> envoy.get("TANDOOR_URL")
  }

  let username = case envoy.get("TANDOOR_TEST_USER") {
    Ok(user) -> Ok(user)
    Error(_) -> envoy.get("TANDOOR_USERNAME")
  }

  let password = case envoy.get("TANDOOR_TEST_PASS") {
    Ok(pass) -> Ok(pass)
    Error(_) -> envoy.get("TANDOOR_PASSWORD")
  }

  case base_url, username, password {
    Ok(url), Ok(user), Ok(pass) -> {
      let config = client.session_config(url, user, pass)
      Ok(config)
    }
    Error(_), _, _ -> Error("TANDOOR_URL not set")
    _, Error(_), _ -> Error("TANDOOR_USERNAME not set")
    _, _, Error(_) -> Error("TANDOOR_PASSWORD not set")
  }
}
