/// CLI entry point for meal-planner
///
/// Supports two modes:
/// 1. Interactive TUI mode (when run with no arguments)
/// 2. Non-interactive CLI mode (when run with command arguments)
///
/// This module detects which mode to use and delegates accordingly.
import argv
import dot_env
import gleam/io
import meal_planner/cli/glint_commands
import meal_planner/cli/shore_app
import meal_planner/config
import meal_planner/error

/// Main entry point - detects mode and delegates
pub fn main() {
  // Load .env file first
  dot_env.new()
  |> dot_env.set_path(".env")
  |> dot_env.set_debug(False)
  |> dot_env.set_ignore_missing_file(True)
  |> dot_env.load

  // Load configuration
  case config.load() {
    Ok(app_config) -> {
      // Get command-line arguments
      let args = argv.load().arguments

      // Mode detection: empty args = TUI, otherwise = CLI
      case args {
        [] -> {
          // TUI Mode: Launch interactive Shore application
          shore_app.start(app_config)
        }
        _ -> {
          // CLI Mode: Route through Glint for command parsing
          glint_commands.run(app_config, args)
        }
      }
    }
    Error(config_error) -> {
      let err = case config_error {
        config.MissingEnvVar(name) ->
          error.config_error(
            "Missing required environment variable: " <> name,
            "Ensure the variable is set in your .env file or environment.",
          )
        config.InvalidEnvVar(name, value, expected) ->
          error.config_error(
            "Invalid value for "
              <> name
              <> ": got '"
              <> value
              <> "', expected "
              <> expected,
            "Check your environment variable configuration for correct format and values.",
          )
      }
      io.println(error.format_error(err))
    }
  }
}
