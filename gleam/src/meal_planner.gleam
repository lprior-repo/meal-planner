/// Meal Planner - Backend for meal planning with nutritional tracking
///
/// This module provides the main entry point for the meal planner backend.
///
import dot_env
import envoy
import gleam/int
import gleam/io
import gleam/result
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
  case load_config() {
    Ok(config) -> {
      io.println("✓ Configuration loaded")
      io.println(
        "  - Database: "
        <> config.database.host
        <> ":"
        <> int.to_string(config.database.port),
      )
      io.println("  - Server port: " <> int.to_string(config.port))
      io.println("")

      // Start the web server
      web.start(config)
    }
    Error(err) -> {
      io.println("✗ Failed to load configuration: " <> err)
      io.println("")
      io.println("Required environment variables:")
      io.println("  - DATABASE_HOST (default: localhost)")
      io.println("  - DATABASE_PORT (default: 5432)")
      io.println("  - DATABASE_NAME (default: meal_planner)")
      io.println("  - DATABASE_USER (default: postgres)")
      io.println("  - DATABASE_PASSWORD")
      io.println("  - PORT (default: 8080)")
      Nil
    }
  }
}

/// Load server configuration from environment variables
fn load_config() -> Result(web.ServerConfig, String) {
  let port =
    envoy.get("PORT")
    |> result.try(int.parse)
    |> result.unwrap(8080)

  let database =
    web.DatabaseConfig(
      host: envoy.get("DATABASE_HOST")
        |> result.unwrap("localhost"),
      port: envoy.get("DATABASE_PORT")
        |> result.try(int.parse)
        |> result.unwrap(5432),
      name: envoy.get("DATABASE_NAME")
        |> result.unwrap("meal_planner"),
      user: envoy.get("DATABASE_USER")
        |> result.unwrap("postgres"),
      password: case envoy.get("DATABASE_PASSWORD") {
        Ok(pwd) -> pwd
        Error(_) -> ""
      },
    )

  let tandoor =
    web.TandoorConfig(
      url: envoy.get("TANDOOR_BASE_URL")
        |> result.unwrap("http://localhost:9000"),
      token: envoy.get("TANDOOR_API_TOKEN")
        |> result.unwrap(""),
    )

  Ok(web.ServerConfig(port: port, database: database, tandoor: tandoor))
}
