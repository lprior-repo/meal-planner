/// Integration Test Helper
/// Provides utilities for integration tests and ensures setup runs first
import gleam/io
import test_setup

/// Main test suite entry point
/// This is called FIRST when running tests
pub fn main() {
  io.println("\n🚀 Starting test suite initialization...\n")

  // Setup infrastructure BEFORE any tests run
  case test_setup.initialize_tests() {
    test_setup.SetupSuccess -> {
      io.println("✅ Test infrastructure ready - proceeding with tests\n")
      Nil
    }
    test_setup.SetupFailure(msg) -> {
      io.println("❌ Test infrastructure setup failed: " <> msg)
      io.println("\n⚠️  Tests may fail. Please run setup manually:")
      io.println("   ../scripts/setup-integration-tests.sh setup\n")

      // Still proceed but warn
      Nil
    }
  }
}
