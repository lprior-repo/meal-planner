/// Web server module for the Meal Planner API
///
/// This module provides HTTP routing to handler modules in web/handlers/:
/// - health: Health checks
/// - recipes: Recipe scoring
/// - diet: Vertical diet compliance checking
/// - macros: Macro calculations
///
import gleam/erlang/process
import gleam/int
import gleam/io
import meal_planner/config
import meal_planner/web/handlers
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

  // Parse the request path and route to appropriate handler
  case wisp.path_segments(req) {
    // Health check endpoint
    [] -> handlers.handle_health(req)
    ["health"] -> handlers.handle_health(req)

    // API endpoints
    ["api", "ai", "score-recipe"] -> handlers.handle_score_recipe(req)
    ["api", "diet", "vertical", "compliance", recipe_id] ->
      handlers.handle_diet_compliance(req, recipe_id)
    ["api", "macros", "calculate"] -> handlers.handle_macros_calculate(req)

    // 404 for unknown routes
    _ -> wisp.not_found()
  }
}
