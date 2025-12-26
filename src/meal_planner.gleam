/// Meal Planner - Backend for meal planning with nutritional tracking
///
/// This module provides the CLI entry point for the meal planner application.
/// Executes commands via: `mp <domain> <command> [flags]`
///
import argv
import dot_env
import gleam/io
import gleam/string
import meal_planner/cli/glint_commands
import meal_planner/config
import meal_planner/error

/// Application entry point - CLI command interface
pub fn main() {
  // Load .env file
  dot_env.new()
  |> dot_env.set_path(".env")
  |> dot_env.set_debug(False)
  |> dot_env.set_ignore_missing_file(True)
  |> dot_env.load

  // Load configuration from environment with error handling
  case config.load() {
    Ok(app_config) -> {
      // Get command-line arguments
      let args = argv.load().arguments

      // Execute CLI command
      glint_commands.run(app_config, args)
    }
    Error(config.MissingEnvVar(name)) -> {
      let err =
        error.config_error(
          "Missing required environment variable: " <> name,
          "Ensure the variable is set in your .env file or environment.",
        )
      io.println(error.format_error(err))
    }
    Error(config.InvalidEnvVar(name, value, expected)) -> {
      let err =
        error.config_error(
          "Invalid value for "
            <> name
            <> ": got '"
            <> value
            <> "', expected "
            <> expected,
          "Check your environment variable configuration for correct format and values.",
        )
      io.println(error.format_error(err))
    }
    Error(config.ValidationError(errors)) -> {
      let err =
        error.config_error(
          "Configuration validation failed: " <> string.join(errors, ", "),
          "Fix the configuration errors listed above.",
        )
      io.println(error.format_error(err))
    }
  }
}
