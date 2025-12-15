/// Infrastructure Setup Module
/// Automatically starts Docker containers for integration tests
/// 
/// This module handles:
/// - Checking if Docker/docker-compose are available
/// - Starting services if not already running
/// - Waiting for services to be healthy
/// - Setting up environment variables for tests
import gleam/int
import gleam/io
import gleam/option.{None, Some}

/// Infrastructure configuration
pub type InfrastructureConfig {
  InfrastructureConfig(
    docker_compose_file: String,
    project_root: String,
    tandoor_url: String,
    tandoor_port: Int,
    max_wait_seconds: Int,
  )
}

/// Setup status result
pub type SetupStatus {
  AlreadyRunning
  SetupStarted
  SetupFailed(String)
  SetupNotNeeded
}

/// Get default infrastructure configuration
pub fn default_config() -> InfrastructureConfig {
  InfrastructureConfig(
    docker_compose_file: "gleam/docker-compose.test.yml",
    project_root: "/home/lewis/src/meal-planner",
    tandoor_url: "http://localhost:8100",
    tandoor_port: 8100,
    max_wait_seconds: 120,
  )
}

/// Check if a command exists in PATH
@external(erlang, "os", "find_executable")
fn find_executable(command: String) -> option.Option(String)

/// Execute a shell command and return exit code
@external(erlang, "os", "system")
fn system_call(command: String) -> Int

/// Check if Docker is available
pub fn check_docker() -> Result(Nil, String) {
  case find_executable("docker") {
    Some(_) -> Ok(Nil)
    None -> Error("Docker not found in PATH")
  }
}

/// Check if docker-compose is available
pub fn check_docker_compose() -> Result(Nil, String) {
  case find_executable("docker-compose") {
    Some(_) -> Ok(Nil)
    None -> {
      // Try docker compose (new version)
      case find_executable("docker") {
        Some(_) -> Ok(Nil)
        None -> Error("docker-compose not found in PATH")
      }
    }
  }
}

/// Check if Tandoor is already running by testing HTTP connection
pub fn check_tandoor_running(url: String) -> Bool {
  let cmd = "curl -sf " <> url <> " > /dev/null 2>&1"
  let exit_code = system_call(cmd)
  exit_code == 0
}

/// Start Docker infrastructure using the setup script
pub fn start_infrastructure(config: InfrastructureConfig) -> SetupStatus {
  // Check prerequisites
  case check_docker() {
    Error(msg) -> {
      io.println("❌ " <> msg)
      SetupFailed(msg)
    }
    Ok(Nil) -> {
      case check_docker_compose() {
        Error(msg) -> {
          io.println("❌ " <> msg)
          SetupFailed(msg)
        }
        Ok(Nil) -> {
          // Check if already running
          case check_tandoor_running(config.tandoor_url) {
            True -> {
              io.println(
                "✅ Tandoor is already running at " <> config.tandoor_url,
              )
              AlreadyRunning
            }
            False -> {
              // Start infrastructure
              io.println("🚀 Starting Docker infrastructure...")
              let script_path =
                config.project_root <> "/scripts/setup-integration-tests.sh"
              let cmd = "bash " <> script_path <> " setup"
              let exit_code = system_call(cmd)

              case exit_code {
                0 -> {
                  io.println("✅ Infrastructure setup complete")
                  SetupStarted
                }
                _ -> {
                  let error_msg =
                    "Infrastructure setup failed with exit code "
                    <> int.to_string(exit_code)
                  io.println("❌ " <> error_msg)
                  SetupFailed(error_msg)
                }
              }
            }
          }
        }
      }
    }
  }
}

/// Initialize infrastructure if needed (for integration tests)
pub fn initialize_if_needed(config: InfrastructureConfig) -> Result(Nil, String) {
  // Always attempt to set up infrastructure
  case start_infrastructure(config) {
    AlreadyRunning -> {
      // Infrastructure already running, ensure environment is configured
      configure_test_environment(config)
      Ok(Nil)
    }
    SetupStarted -> {
      // Infrastructure was just started, configure environment
      configure_test_environment(config)
      Ok(Nil)
    }
    SetupNotNeeded -> Ok(Nil)
    SetupFailed(msg) -> {
      // Infrastructure setup failed - still continue
      // Tests will fail with proper error messages if services unavailable
      io.println(
        "⚠️  Warning: Infrastructure setup had issues, but continuing anyway",
      )
      Error(msg)
    }
  }
}

/// Configure test environment variables
/// This ensures tests can connect to Tandoor
fn configure_test_environment(config: InfrastructureConfig) -> Nil {
  io.println("📝 Tandoor available at: " <> config.tandoor_url)
  io.println("📝 Use TANDOOR_URL env var or default: admin/admin credentials")

  // Note: The actual environment variables are set by the setup script.
  // If not set, test_setup.get_test_config() will detect missing vars
  // and tests will be marked as failing appropriately.
  Nil
}

/// Get Tandoor configuration for tests
/// Returns URL and default credentials that can be used if env vars aren't set
pub fn get_tandoor_defaults(
  _config: InfrastructureConfig,
) -> #(String, String, String) {
  // Return (url, username, password) as fallback defaults
  // The actual values should come from environment variables set by setup script
  #("http://localhost:8100", "admin", "admin")
}
