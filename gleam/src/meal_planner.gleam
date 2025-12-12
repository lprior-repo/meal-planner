/// Meal Planner - Backend for meal planning with nutritional tracking
///
/// This module provides the main entry point for the meal planner backend.
///
import dot_env
import gleam/int
import gleam/io
import meal_planner/config
import meal_planner/web

/// Application entry point
pub fn main() {
  // Load .env file
  dot_env.new()
  |> dot_env.set_path(".env")
  |> dot_env.set_debug(False)
  |> dot_env.set_ignore_missing_file(True)
  |> dot_env.load

  io.println("🍽️  Meal Planner Backend")
  io.println("========================")
  io.println("")

  // Load configuration from environment
  let app_config = config.load()

  io.println("✓ Configuration loaded")
  io.println(
    "  - Database: "
    <> app_config.database.host
    <> ":"
    <> int.to_string(app_config.database.port),
  )
  io.println(
    "  - Server port: " <> int.to_string(app_config.server.port),
  )
  io.println(
    "  - Tandoor: "
    <> app_config.tandoor.base_url,
  )
  io.println(
    "  - Environment: " <> app_config.server.environment,
  )
  io.println("")

  // Check production readiness
  case config.is_production_ready(app_config) {
    True -> io.println("✓ Configuration is production ready")
    False ->
      case app_config.server.environment {
        "production" -> {
          io.println(
            "⚠️  Running in production mode but missing some required settings",
          )
        }
        _ -> io.println("ℹ Development mode configuration loaded")
      }
  }
  io.println("")

  // Start the web server
  web.start(app_config)
}
