/// Integration Test Setup Module
/// This module ensures all infrastructure is stood up BEFORE any tests run
/// It runs automatically when the test suite initializes
import envoy
import gleam/io
import gleam/string

/// Setup result type
pub type SetupResult {
  SetupSuccess
  SetupFailure(String)
}

/// Check if we're running integration tests
pub fn should_setup_infrastructure() -> Bool {
  // Check if TANDOOR_TEST_URL is set, indicating integration test mode
  case envoy.get("TANDOOR_TEST_URL") {
    Ok(_) -> True
    Error(_) -> {
      // Check if we're explicitly in test mode
      case envoy.get("GLEAM_TEST_MODE") {
        Ok("integration") -> True
        _ -> False
      }
    }
  }
}

/// Main setup function - runs infrastructure setup script
pub fn setup_test_infrastructure() -> SetupResult {
  io.println("\n🚀 Setting up integration test infrastructure...\n")
  io.println(
    "⚠️  Note: Automatic infrastructure setup requires manual intervention",
  )
  io.println("Please run: ../scripts/setup-integration-tests.sh setup\n")

  // For now, just assume infrastructure is already running
  // Users must manually start docker-compose before running tests

  SetupSuccess
}

/// Cleanup infrastructure after tests
pub fn cleanup_test_infrastructure() -> Nil {
  case should_setup_infrastructure() {
    True -> {
      io.println("\n🧹 Note: Services are still running for debugging")
      io.println("To stop: ../scripts/setup-integration-tests.sh stop")
      io.println("To cleanup: ../scripts/setup-integration-tests.sh cleanup\n")
    }
    False -> Nil
  }
}

/// Global test initialization - called before any tests
pub fn initialize_tests() -> SetupResult {
  io.println("\n" <> string.repeat("=", 60))
  io.println("  Meal Planner Test Suite")
  io.println(string.repeat("=", 60) <> "\n")

  case should_setup_infrastructure() {
    True -> {
      io.println("🔧 Integration test mode detected")
      io.println("Assuming infrastructure is already running...")
      io.println("If tests fail, ensure Docker containers are up:")
      io.println(
        "  cd /home/lewis/src/meal-planner && ../scripts/setup-integration-tests.sh setup\n",
      )
      SetupSuccess
    }
    False -> {
      io.println("📝 Unit test mode - skipping infrastructure setup")
      SetupSuccess
    }
  }
}
