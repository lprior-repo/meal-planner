/// Web CLI domain - handles web server management
///
/// This module provides CLI commands for:
/// - Starting of web server
/// - Stopping of web server (stub)
/// - Server configuration
import gleam/int
import gleam/io
import gleam/string
import glint
import meal_planner/config.{type Config}
import meal_planner/web

// ============================================================================
// Glint Command Handler
// ============================================================================

/// Web domain command for Glint CLI
pub fn cmd(config: Config) -> glint.Command(Result(Nil, Nil)) {
  use <- glint.command_help("Start and manage of web server")
  use _named, unnamed, _flags <- glint.command()

  case unnamed {
    ["start"] -> {
      io.println("Starting web server...")
      io.println("")
      io.println("Configuration:")
      io.println(
        "  Database: "
        <> config.database.host
        <> ":"
        <> int.to_string(config.database.port),
      )
      io.println(
        "  Server: "
        <> config.server.host
        <> ":"
        <> int.to_string(config.server.port),
      )
      io.println("  Tandoor: " <> config.tandoor.base_url)
      io.println("")

      // Start of web server
      let _ = web.start(config)
      Ok(Nil)
    }
    ["stop"] -> {
      io.println("Stopping web server...")
      io.println("")
      io.println("Note: Server stop functionality not yet implemented.")
      io.println("The web server runs as a standalone process.")
      io.println("Use Ctrl+C to stop it, or use a process manager:")
      io.println("  - systemd: systemctl stop meal-planner")
      io.println("  - supervisord: supervisorctl stop meal-planner")
      io.println("  - docker: docker stop meal-planner (if using Docker)")
      io.println("")
      Ok(Nil)
    }
    _ -> {
      io.println("Web commands:")
      io.println("")
      io.println("  mp web start")
      io.println("    Starts the web server")
      io.println("")
      io.println("  mp web stop")
      io.println("    Stops the web server (stub - requires process manager)")
      io.println("")
      io.println("Examples:")
      io.println("  mp web start")
      io.println("  mp web stop")
      Ok(Nil)
    }
  }
}
