/// Web server module for the Meal Planner API
///
/// This module provides HTTP routing to handler modules in web/handlers/:
/// - health: Health checks
/// - recipes: Recipe scoring
/// - diet: Vertical diet compliance checking
/// - macros: Macro calculations
/// - dashboard: Dashboard UI with nutrition tracking
///
import gleam/erlang/process
import gleam/http
import gleam/int
import gleam/io
import gleam/option
import meal_planner/config
import meal_planner/fatsecret/service as fatsecret_service
import meal_planner/postgres
import meal_planner/web/handlers
import mist
import pog
import wisp
import wisp/wisp_mist

/// Application context passed to handlers
pub type Context {
  Context(config: config.Config, db: pog.Connection)
}

/// Start the HTTP server
pub fn start(app_config: config.Config) -> Nil {
  // Connect to database
  let db_config =
    postgres.Config(
      host: app_config.database.host,
      port: app_config.database.port,
      database: app_config.database.name,
      user: app_config.database.user,
      password: option.Some(app_config.database.password),
      pool_size: 10,
    )

  let assert Ok(db) = postgres.connect(db_config)
  io.println("✓ Database connection established")

  // Validate FatSecret connection at startup
  let fatsecret_status = fatsecret_service.startup_check(db)
  io.println(fatsecret_status)

  let ctx = Context(config: app_config, db: db)

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
fn handle_request(req: wisp.Request, ctx: Context) -> wisp.Response {
  use <- wisp.log_request(req)

  let base_url =
    "http://localhost:" <> int.to_string(ctx.config.server.port)

  // Parse the request path and route to appropriate handler
  case wisp.path_segments(req) {
    // Health check endpoint
    [] -> handlers.handle_health(req)
    ["health"] -> handlers.handle_health(req)

    // Dashboard UI
    ["dashboard"] -> handlers.handle_dashboard(req, ctx.db)

    // Food logging UI
    ["log", "food", fdc_id] ->
      handlers.handle_log_food_form(req, ctx.db, fdc_id)

    // FatSecret OAuth 3-legged flow
    ["fatsecret", "connect"] ->
      handlers.handle_fatsecret_connect(req, ctx.db, base_url)
    ["fatsecret", "callback"] ->
      handlers.handle_fatsecret_callback(req, ctx.db)
    ["fatsecret", "status"] -> handlers.handle_fatsecret_status(req, ctx.db)
    ["fatsecret", "disconnect"] ->
      handlers.handle_fatsecret_disconnect(req, ctx.db)

    // API endpoints
    ["api", "dashboard", "data"] -> handlers.handle_dashboard_data(req, ctx.db)
    ["api", "ai", "score-recipe"] -> handlers.handle_score_recipe(req)
    ["api", "diet", "vertical", "compliance", recipe_id] ->
      handlers.handle_diet_compliance(req, recipe_id)
    ["api", "macros", "calculate"] -> handlers.handle_macros_calculate(req)
    ["api", "logs", "food"] -> handlers.handle_log_food(req, ctx.db)

    // FatSecret API endpoints (requires 3-legged auth)
    ["api", "fatsecret", "profile"] ->
      handlers.handle_fatsecret_profile(req, ctx.db)
    ["api", "fatsecret", "entries"] ->
      handlers.handle_fatsecret_entries(req, ctx.db)

    // Tandoor Recipe Manager
    ["tandoor", "status"] -> handlers.handle_tandoor_status(req)
    ["api", "tandoor", "recipes"] -> handlers.handle_tandoor_list_recipes(req)
    ["api", "tandoor", "recipes", recipe_id] ->
      handlers.handle_tandoor_get_recipe(req, recipe_id)
    ["api", "tandoor", "meal-plan"] -> {
      case req.method {
        http.Get -> handlers.handle_tandoor_get_meal_plan(req)
        http.Post -> handlers.handle_tandoor_create_meal_plan(req)
        _ -> wisp.method_not_allowed([http.Get, http.Post])
      }
    }
    ["api", "tandoor", "meal-plan", entry_id] ->
      handlers.handle_tandoor_delete_meal_plan(req, entry_id)

    // 404 for unknown routes
    _ -> wisp.not_found()
  }
}
