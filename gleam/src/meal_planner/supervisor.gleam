/// Supervisor tree for Meal Planner application
///
/// This module defines the supervision tree structure for the application.
/// It manages child processes with appropriate restart strategies.
///
/// ## Supervisor Tree Structure
///
/// ```
/// meal_planner_sup (OneForOne)
/// ├── registry (ETS-based process registry for named services)
/// └── [future workers will be added here]
/// ```
///
/// ## Restart Strategies
///
/// - OneForOne: If a child terminates, only that child is restarted
/// - Restart tolerance: max 3 restarts in 5 seconds before supervisor gives up
import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import gleam/otp/static_supervisor.{type Supervisor} as supervisor
import gleam/otp/supervision
import meal_planner/logger

/// Registry state - holds references to named services
pub type RegistryState {
  RegistryState
}

/// Registry messages
pub type RegistryMessage {
  Shutdown
}

/// Start the main application supervisor tree
///
/// This creates the supervision tree and starts all child processes.
/// The supervisor uses OneForOne strategy - if a child crashes, only
/// that child is restarted.
pub fn start() -> actor.StartResult(Supervisor) {
  // Configure logger before starting supervision tree
  logger.configure()

  supervisor.new(supervisor.OneForOne)
  |> supervisor.restart_tolerance(intensity: 3, period: 5)
  |> supervisor.add(registry_child())
  |> supervisor.start
}

/// Create a child specification for embedding this supervisor in a parent tree
pub fn supervised() -> supervision.ChildSpecification(Supervisor) {
  supervision.supervisor(start)
}

/// Create the registry child specification
///
/// The registry is a simple actor that serves as a foundation for
/// service discovery. Future GenServers can register themselves here.
fn registry_child() -> supervision.ChildSpecification(Subject(RegistryMessage)) {
  supervision.worker(start_registry)
  |> supervision.restart(supervision.Transient)
}

/// Start the registry actor
///
/// This is a minimal actor that can be extended later to provide
/// process registration and discovery services.
fn start_registry() -> actor.StartResult(Subject(RegistryMessage)) {
  actor.new(RegistryState)
  |> actor.on_message(handle_registry_message)
  |> actor.start
}

/// Handle registry messages
fn handle_registry_message(
  _state: RegistryState,
  message: RegistryMessage,
) -> actor.Next(RegistryState, RegistryMessage) {
  case message {
    Shutdown -> actor.stop()
  }
}

/// Supervisor configuration options
pub type SupervisorConfig {
  SupervisorConfig(
    /// Maximum number of restarts allowed in the time period
    max_restarts: Int,
    /// Time period in seconds for counting restarts
    restart_period: Int,
  )
}

/// Default supervisor configuration
pub fn default_config() -> SupervisorConfig {
  SupervisorConfig(max_restarts: 3, restart_period: 5)
}

/// Start supervisor with custom configuration
pub fn start_with_config(
  config: SupervisorConfig,
) -> actor.StartResult(Supervisor) {
  // Configure logger before starting supervision tree
  logger.configure()

  supervisor.new(supervisor.OneForOne)
  |> supervisor.restart_tolerance(
    intensity: config.max_restarts,
    period: config.restart_period,
  )
  |> supervisor.add(registry_child())
  |> supervisor.start
}
