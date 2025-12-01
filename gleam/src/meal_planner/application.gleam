/// OTP Application module for Meal Planner
///
/// This module provides the OTP application supervision tree for the meal planner.
/// It manages application lifecycle and provides a centralized point for starting
/// all application services.
import gleam/erlang/process
import gleam/otp/actor
import gleam/otp/static_supervisor.{type Supervisor}
import gleam/otp/supervision
import meal_planner/storage
import meal_planner/supervisor

/// Application state returned after successful startup
pub type AppState {
  AppState(supervisor: Supervisor)
}

/// Errors that can occur during application startup
pub type StartupError {
  DatabaseInitError(String)
  SupervisorStartError(actor.StartError)
}

/// Start the OTP application supervisor tree
///
/// This initializes all application services including:
/// - Database schema initialization
/// - Supervisor tree with registry and workers
/// - Logger configuration
///
/// Returns the supervisor reference on success, or an error describing
/// what failed during startup.
pub fn start() -> Result(AppState, StartupError) {
  // First, ensure database is initialized
  case storage.initialize_database() {
    Error(err) -> Error(DatabaseInitError(err))
    Ok(Nil) -> {
      // Create and start the supervisor tree
      case supervisor.start() {
        Ok(started) -> Ok(AppState(supervisor: started.data))
        Error(err) -> Error(SupervisorStartError(err))
      }
    }
  }
}

/// Create a child specification for adding this application's supervisor
/// to a parent supervision tree.
///
/// Use this when you need to run the meal planner as part of a larger
/// OTP application.
pub fn supervised() -> supervision.ChildSpecification(Supervisor) {
  supervisor.supervised()
}

/// Run the application and keep it alive
///
/// This is useful for running the application as a long-lived service
/// rather than a one-shot CLI command.
pub fn run_forever() -> Result(Nil, StartupError) {
  case start() {
    Ok(_state) -> {
      process.sleep_forever()
      Ok(Nil)
    }
    Error(err) -> Error(err)
  }
}

/// Format a startup error for display
pub fn format_error(error: StartupError) -> String {
  case error {
    DatabaseInitError(msg) -> "Database initialization failed: " <> msg
    SupervisorStartError(err) -> {
      case err {
        actor.InitTimeout -> "Supervisor initialization timed out"
        actor.InitFailed(reason) ->
          "Supervisor initialization failed: " <> reason
        actor.InitExited(_) -> "Supervisor process exited unexpectedly"
      }
    }
  }
}
