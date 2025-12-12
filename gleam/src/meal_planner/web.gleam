/// Web server module for the Meal Planner API
///
/// This module provides HTTP endpoints for:
/// - Health checks
/// - Recipe scoring
/// - AI meal planning
/// - Macro calculations
/// - Vertical diet compliance
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

/// Mealie API configuration
pub type MealieConfig {
  MealieConfig(url: String, token: String)
}

/// Server configuration
pub type ServerConfig {
  ServerConfig(port: Int, database: DatabaseConfig, mealie: MealieConfig)
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

    // API endpoints (to be implemented)
    ["api", "recipes", "score"] -> recipe_score_handler(req)
    ["api", "meal-plan"] -> meal_plan_handler(req)
    ["api", "macros", "calculate"] -> macro_calc_handler(req)
    ["api", "vertical-diet", "check"] -> vertical_diet_handler(req)

    // Mealie integration endpoints
    ["api", "mealie", "recipes"] -> mealie_recipes_handler(req, ctx)
    ["api", "mealie", "recipes", id] ->
      mealie_recipe_detail_handler(req, ctx, id)

    // 404 for unknown routes
    _ -> wisp.not_found()
  }
}

/// Health check endpoint
/// Returns 200 OK with service status
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

/// Recipe scoring endpoint
/// POST /api/recipes/score
/// Scores recipes based on nutritional profile and user preferences
fn recipe_score_handler(req: wisp.Request) -> wisp.Response {
  use <- wisp.require_method(req, http.Post)

  // TODO: Implement recipe scoring logic
  let body =
    json.object([
      #("message", json.string("Recipe scoring endpoint - coming soon")),
      #("status", json.string("not_implemented")),
    ])
    |> json.to_string

  wisp.json_response(body, 501)
}

/// AI meal planning endpoint
/// POST /api/meal-plan
/// Generates optimized meal plans using AI
fn meal_plan_handler(req: wisp.Request) -> wisp.Response {
  use <- wisp.require_method(req, http.Post)

  // TODO: Implement meal planning logic
  let body =
    json.object([
      #("message", json.string("AI meal planning endpoint - coming soon")),
      #("status", json.string("not_implemented")),
    ])
    |> json.to_string

  wisp.json_response(body, 501)
}

/// Macro calculation endpoint
/// POST /api/macros/calculate
/// Calculates macros for recipes and meals
fn macro_calc_handler(req: wisp.Request) -> wisp.Response {
  use <- wisp.require_method(req, http.Post)

  // TODO: Implement macro calculation logic
  let body =
    json.object([
      #("message", json.string("Macro calculation endpoint - coming soon")),
      #("status", json.string("not_implemented")),
    ])
    |> json.to_string

  wisp.json_response(body, 501)
}

/// Vertical diet compliance endpoint
/// POST /api/vertical-diet/check
/// Checks if recipes comply with vertical diet guidelines
fn vertical_diet_handler(req: wisp.Request) -> wisp.Response {
  use <- wisp.require_method(req, http.Post)

  // TODO: Implement vertical diet compliance logic
  let body =
    json.object([
      #(
        "message",
        json.string("Vertical diet compliance endpoint - coming soon"),
      ),
      #("status", json.string("not_implemented")),
    ])
    |> json.to_string

  wisp.json_response(body, 501)
}

/// Mealie recipes list endpoint
/// GET /api/mealie/recipes
/// Fetches recipes from Mealie API
fn mealie_recipes_handler(req: wisp.Request, ctx: Context) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  // TODO: Implement Mealie API client integration
  let body =
    json.object([
      #("message", json.string("Mealie recipes endpoint - coming soon")),
      #("status", json.string("not_implemented")),
      #("mealie_url", json.string(ctx.config.mealie.url)),
    ])
    |> json.to_string

  wisp.json_response(body, 501)
}

/// Mealie recipe detail endpoint
/// GET /api/mealie/recipes/:id
/// Fetches a specific recipe from Mealie API
fn mealie_recipe_detail_handler(
  req: wisp.Request,
  ctx: Context,
  id: String,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  // TODO: Implement Mealie API client integration
  let body =
    json.object([
      #("message", json.string("Mealie recipe detail endpoint - coming soon")),
      #("status", json.string("not_implemented")),
      #("recipe_id", json.string(id)),
      #("mealie_url", json.string(ctx.config.mealie.url)),
    ])
    |> json.to_string

  wisp.json_response(body, 501)
}
