/// Meal Planner - Backend for meal planning with nutritional tracking
///
/// This module provides the main entry point for the meal planner backend.
/// It starts the HTTP server and integrates with Mealie for recipe management.
///
import envoy
import gleam/int
import gleam/io
import gleam/result
import meal_planner/web

/// Application entry point
pub fn main() {
  io.println("🍽️  Meal Planner Backend")
  io.println("========================")
  io.println("")

  // Load configuration from environment
  case load_config() {
    Ok(config) -> {
      io.println("✓ Configuration loaded")
      io.println(
        "  - Database: "
        <> config.db_host
        <> ":"
        <> int.to_string(config.db_port),
      )
      io.println("  - Mealie: " <> config.mealie_url)
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
      io.println("  - MEALIE_BASE_URL (default: http://localhost:9000)")
      io.println("  - MEALIE_API_TOKEN (optional)")
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

  let db_host =
    envoy.get("DATABASE_HOST")
    |> result.unwrap("localhost")

  let db_port =
    envoy.get("DATABASE_PORT")
    |> result.try(int.parse)
    |> result.unwrap(5432)

  let db_name =
    envoy.get("DATABASE_NAME")
    |> result.unwrap("meal_planner")

  let db_user =
    envoy.get("DATABASE_USER")
    |> result.unwrap("postgres")

  let db_password = case envoy.get("DATABASE_PASSWORD") {
    Ok(pwd) -> pwd
    Error(_) -> ""
  }

  let mealie_url =
    envoy.get("MEALIE_BASE_URL")
    |> result.unwrap("http://localhost:9000")

  let mealie_token =
    envoy.get("MEALIE_API_TOKEN")
    |> result.unwrap("")

  Ok(web.ServerConfig(
    port: port,
    db_host: db_host,
    db_port: db_port,
    db_name: db_name,
    db_user: db_user,
    db_password: db_password,
    mealie_url: mealie_url,
    mealie_token: mealie_token,
  ))
}
