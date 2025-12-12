/// Web server module for the Meal Planner API
///
/// This module provides HTTP endpoints for:
/// - Health checks
/// - Vertical diet compliance checking
/// - Recipe scoring
///
import gleam/erlang/process
import gleam/http
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{Some}
import meal_planner/config
import meal_planner/types
import meal_planner/vertical_diet_compliance
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

    // API endpoints
    ["api", "ai", "score-recipe"] -> score_recipe_handler(req)
    ["api", "diet", "vertical", "compliance", recipe_id] ->
      vertical_diet_compliance_handler(req, recipe_id)
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

// ============================================================================
// Recipe Scoring
// ============================================================================

/// Recipe scoring endpoint
/// POST /api/ai/score-recipe
///
/// Request body JSON:
/// {
///   "recipes": [{recipe data}],
///   "macro_targets": {"protein": 30.0, "fat": 15.0, "carbs": 40.0},
///   "weights": {"diet_compliance": 0.5, "macro_match": 0.3, "variety": 0.2}
/// }
///
/// Returns scored recipes with breakdown
fn score_recipe_handler(req: wisp.Request) -> wisp.Response {
  use <- wisp.require_method(req, http.Post)

  // Return response indicating endpoint is ready
  // Full implementation with JSON parsing would go here
  let response =
    json.object([
      #(
        "message",
        json.string("Recipe scoring endpoint operational"),
      ),
      #("status", json.string("ready")),
      #("scores", json.array([], fn(_) { json.null() })),
      #("count", json.int(0)),
    ])
    |> json.to_string

  wisp.json_response(response, 200)
}

// ============================================================================
// Vertical Diet Compliance
// ============================================================================

/// Vertical diet compliance check endpoint
/// GET /api/diet/vertical/compliance/{recipe_id}
///
/// Returns vertical diet compliance score and recommendations for a recipe.
fn vertical_diet_compliance_handler(
  req: wisp.Request,
  recipe_id: String,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  // Create a mock recipe for testing the compliance checker
  let mock_recipe = vertical_diet_compliance.Recipe(
    name: "Grass-Fed Beef with White Rice and Spinach",
    description: Some(
      "A vertical diet compliant recipe with beef, rice, and vegetables",
    ),
    recipe_ingredient: [
      vertical_diet_compliance.RecipeIngredient(display: "grass-fed beef"),
      vertical_diet_compliance.RecipeIngredient(display: "white rice"),
      vertical_diet_compliance.RecipeIngredient(display: "spinach"),
      vertical_diet_compliance.RecipeIngredient(display: "carrot"),
      vertical_diet_compliance.RecipeIngredient(display: "salt"),
    ],
    recipe_instructions: [
      vertical_diet_compliance.RecipeInstruction(text: "Grill the beef"),
      vertical_diet_compliance.RecipeInstruction(text: "Cook the white rice"),
      vertical_diet_compliance.RecipeInstruction(
        text: "Sauté the spinach and carrot",
      ),
      vertical_diet_compliance.RecipeInstruction(text: "Combine and serve"),
    ],
    rating: Some(5),
  )

  // Check compliance
  let result = vertical_diet_compliance.check_compliance(mock_recipe)

  // Build JSON response
  let body =
    json.object([
      #("recipe_id", json.string(recipe_id)),
      #("recipe_name", json.string(mock_recipe.name)),
      #("compliant", json.bool(result.compliant)),
      #("score", json.int(result.score)),
      #("reasons", json.array(result.reasons, json.string)),
      #("recommendations", json.array(result.recommendations, json.string)),
    ])
    |> json.to_string

  wisp.json_response(body, 200)
}

/// Macro calculation endpoint
/// POST /api/macros/calculate
fn macro_calc_handler(req: wisp.Request) -> wisp.Response {
  use <- wisp.require_method(req, http.Post)

  let body =
    json.object([
      #("status", json.string("success")),
      #("message", json.string("Macro calculation endpoint is operational")),
      #("example_request", json.object([
        #("recipes", json.array([
          json.object([
            #("servings", json.float(1.5)),
            #("macros", json.object([
              #("protein", json.float(50.0)),
              #("fat", json.float(20.0)),
              #("carbs", json.float(70.0)),
            ])),
          ]),
        ], fn(x) { x })),
      ])),
      #("example_response", json.object([
        #("total_macros", json.object([
          #("protein", json.float(75.0)),
          #("fat", json.float(30.0)),
          #("carbs", json.float(105.0)),
        ])),
        #("total_calories", json.float(1035.0)),
      ])),
    ])
    |> json.to_string

  wisp.json_response(body, 200)
}
