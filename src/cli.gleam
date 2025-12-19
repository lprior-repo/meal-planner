/// CLI entry point for meal-planner
///
/// Supports two modes:
/// 1. Interactive TUI mode (when run with no arguments)
/// 2. Non-interactive CLI mode (when run with command arguments)
///
/// This module detects which mode to use and delegates accordingly.
import argv
import dot_env
import gleam/erlang/process
import gleam/io
import gleam/list
import meal_planner/cli/glint_commands
import meal_planner/cli/shore_app
import meal_planner/cli/types
import meal_planner/config

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
      io.println_error(
        "❌ Configuration Error: " <> config.format_error(config_error),
      )
      // Exit with error code 1
      exit_with_code(1)
    }
  }
}

/// Helper to exit with specific code
fn exit_with_code(code: Int) -> Nil {
  process.exit(code)
}
