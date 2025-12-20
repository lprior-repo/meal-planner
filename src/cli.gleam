/// CLI entry point for meal-planner with unified startup
///
/// Supports three modes:
/// 1. Interactive TUI mode (when run with no arguments)
/// 2. Non-interactive CLI mode (when run with command arguments)
/// 3. Web server mode (when run with 'web' command)
///
/// All modes include startup health checks and service validation.
import argv
import dot_env
import gleam/int
import gleam/io
import gleam/string
import meal_planner/cli/glint_commands
import meal_planner/cli/shore_app
import meal_planner/config
import meal_planner/error
import meal_planner/startup

/// Main entry point - unified startup with health checks
pub fn main() {
  // Show welcome banner
  startup.show_welcome_banner()

  // Load .env file first
  dot_env.new()
  |> dot_env.set_path(".env")
  |> dot_env.set_debug(False)
  |> dot_env.set_ignore_missing_file(True)
  |> dot_env.load

  // Load configuration
  case config.load() {
    Ok(app_config) -> {
      // Run startup health checks
      let startup_status = startup.run_startup_checks(app_config)

      // Check if startup should continue
      case startup.print_status_and_continue(startup_status) {
        False -> {
          io.println("Cannot start. Fix the issues above.")
        }
        True -> {
          // Wait briefly for services to be ready
          startup.wait_for_services()

          // Get command-line arguments
          let args = argv.load().arguments

          // Mode detection: empty args = TUI, otherwise = CLI
          case args {
            [] -> {
              // TUI Mode: Launch interactive Shore application
              io.println("Launching interactive meal planner...\n")
              shore_app.start(app_config)
            }
            ["web"] -> {
              // Web server mode: Start HTTP server
              io.println(
                "Starting web server on port "
                <> int.to_string(app_config.server.port)
                <> "...\n",
              )
              // This would call the web server startup
              // For now, just show message
              io.println("Web server mode not yet implemented")
            }
            _ -> {
              // CLI Mode: Route through Glint for command parsing
              glint_commands.run(app_config, args)
            }
          }
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
        config.ValidationError(errors) ->
          error.config_error(
            "Configuration validation failed: " <> string.join(errors, ", "),
            "Fix the configuration errors listed above.",
          )
      }
      io.println(error.format_error(err))
    }
  }
}
