/// Web server module for the Meal Planner API
///
/// This module provides HTTP endpoints for:
/// - Health checks
/// - Macro calculations
/// - Meal planning (stub)
///
import gleam/erlang/process
import gleam/http
import gleam/int
import gleam/io
import gleam/json
import mist
import wisp
import wisp/wisp_mist

/// Database configuration
pub type DatabaseConfig {
  DatabaseConfig(
    host: String,
    port: Int,
    name: String,
    user: String,
    password: String,
  )
}

/// Server configuration
pub type ServerConfig {
  ServerConfig(port: Int, database: DatabaseConfig)
}

/// Application context passed to handlers
pub type Context {
  Context(config: ServerConfig)
}

/// Start the HTTP server
pub fn start(config: ServerConfig) -> Nil {
  let ctx = Context(config: config)

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
    |> mist.port(config.port)
    |> mist.start

  io.println(
    "🚀 Meal Planner API server started on http://localhost:"
    <> int.to_string(config.port),
  )

  // Keep the server running
  process.sleep_forever()
}

/// Main request router
fn handle_request(req: wisp.Request, ctx: Context) -> wisp.Response {
  use <- wisp.log_request(req)

  // Parse the request path
  case wisp.path_segments(req) {
    // Health check endpoint
    [] -> health_handler(req)
    ["health"] -> health_handler(req)

    // API endpoints (stubs - to be implemented)
    ["api", "meal-plan"] -> meal_plan_handler(req, ctx)
    ["api", "macros", "calculate"] -> macro_calc_handler(req)

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

/// AI meal planning endpoint (stub)
/// POST /api/meal-plan
fn meal_plan_handler(req: wisp.Request, _ctx: Context) -> wisp.Response {
  use <- wisp.require_method(req, http.Post)

  let body =
    json.object([
      #("message", json.string("Meal planning endpoint - coming soon")),
      #("status", json.string("not_implemented")),
    ])
    |> json.to_string

  wisp.json_response(body, 501)
}

/// Macro calculation endpoint (stub)
/// POST /api/macros/calculate
fn macro_calc_handler(req: wisp.Request) -> wisp.Response {
  use <- wisp.require_method(req, http.Post)

  let body =
    json.object([
      #("message", json.string("Macro calculation endpoint - coming soon")),
      #("status", json.string("not_implemented")),
    ])
    |> json.to_string

  wisp.json_response(body, 501)
}
