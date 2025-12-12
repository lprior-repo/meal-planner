/// Web server module for the Meal Planner API
///
/// This module provides HTTP endpoints for:
/// - Health checks
///
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/json
import meal_planner/config
import mist
import wisp
import wisp/wisp_mist

/// Application context passed to handlers
pub type Context {
  Context(config: config.Config)
}

/// Start the HTTP server
pub fn start(app_config: config.Config) -> Nil {
  let ctx = Context(config: app_config)

  // Configure logging
  wisp.configure_logger()

  // Create the handler function
  let handler = fn(req: wisp.Request) -> wisp.Response {
    handle_request(req, ctx)
  }

  // Create a secret key base for session handling
  let secret_key_base = wisp.random_string(64)

  // Start the Mist server with Wisp handler
  let assert Ok(_) =
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(app_config.server.port)
    |> mist.start

  io.println(
    "🚀 Meal Planner API server started on http://localhost:"
    <> int.to_string(app_config.server.port),
  )

  // Keep the server running
  process.sleep_forever()
}

/// Main request router
fn handle_request(req: wisp.Request, _ctx: Context) -> wisp.Response {
  use <- wisp.log_request(req)

  // Parse the request path
  case wisp.path_segments(req) {
    // Health check endpoint
    [] -> health_handler(req)
    ["health"] -> health_handler(req)

    // 404 for unknown routes
    _ -> wisp.not_found()
  }
}

// ============================================================================
// Health Check
// ============================================================================

/// Health check endpoint
/// Returns 200 OK with service status
/// GET /health or /
fn health_handler(_req: wisp.Request) -> wisp.Response {
  let body =
    json.object([
      #("status", json.string("healthy")),
      #("service", json.string("meal-planner")),
      #("version", json.string("1.0.0")),
    ])
    |> json.to_string

  wisp.json_response(body, 200)
}
