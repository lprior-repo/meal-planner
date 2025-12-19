/// Web CLI domain - handles web server management
///
/// This module provides CLI commands for:
/// - Starting the web server
/// - Checking server status
/// - Server configuration
import glint
import gleam/io
import gleam/int
import meal_planner/config.{type Config}
import meal_planner/web

// ============================================================================
// Glint Command Handler
// ============================================================================

/// Web domain command for Glint CLI
pub fn cmd(config: Config) -> glint.Command(Nil) {
  use <- glint.command_help("Start and manage the web server")
  use named, unnamed, flags <- glint.command()

  io.println("🍽️  Meal Planner Backend")
  io.println("========================")
  io.println("")
  io.println("✓ Configuration loaded")
  io.println(
    "  - Database: "
    <> config.database.host
    <> ":"
    <> int.to_string(config.database.port),
  )
  io.println("  - Server port: " <> int.to_string(config.server.port))
  io.println("  - Tandoor: " <> config.tandoor.base_url)
  io.println("  - Environment: " <> config.server.environment)
  io.println("")
  io.println("Starting web server...")
  io.println("")

  // Start the web server
  web.start(config)
}
