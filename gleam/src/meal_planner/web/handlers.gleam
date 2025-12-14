// TODO: Re-enable when modules are available
// import meal_planner/web/handlers/dashboard
/// Web handlers facade module
///
/// This module re-exports all handler functions from the handlers subdirectory.
/// It provides a single import point for all HTTP endpoint handlers.
///
/// Handler organization:
/// - health: Health check endpoint
/// - recipes: Recipe scoring endpoint
/// - diet: Vertical diet compliance check endpoint
/// - macros: Macro calculation endpoint
/// - dashboard: Dashboard UI with nutrition tracking
/// - fatsecret: FatSecret OAuth 3-legged authentication
/// - tandoor: Tandoor Recipe Manager integration
import meal_planner/web/handlers/diet
import meal_planner/web/handlers/fatsecret

// import meal_planner/web/handlers/foods
import meal_planner/web/handlers/health
import meal_planner/web/handlers/macros
import meal_planner/web/handlers/recipes
import meal_planner/web/handlers/tandoor
import pog
import wisp

/// Health check handler - GET /health or /
pub fn handle_health(req: wisp.Request) -> wisp.Response {
  health.handle(req)
}

/// Recipe scoring handler - POST /api/ai/score-recipe
pub fn handle_score_recipe(req: wisp.Request) -> wisp.Response {
  recipes.handle_score(req)
}

/// Diet compliance handler - GET /api/diet/vertical/compliance/{recipe_id}
pub fn handle_diet_compliance(
  req: wisp.Request,
  recipe_id: String,
) -> wisp.Response {
  diet.handle_compliance(req, recipe_id)
}

/// Macro calculation handler - POST /api/macros/calculate
pub fn handle_macros_calculate(req: wisp.Request) -> wisp.Response {
  macros.handle_calculate(req)
}

/// Dashboard handler - GET /dashboard
/// TODO: Re-enable when dashboard module is available
pub fn handle_dashboard(
  _req: wisp.Request,
  _conn: pog.Connection,
) -> wisp.Response {
  wisp.response(501)
  |> wisp.string_body("Dashboard handler not yet implemented")
}

/// Dashboard data handler - GET /api/dashboard/data
/// TODO: Re-enable when dashboard module is available
pub fn handle_dashboard_data(
  _req: wisp.Request,
  _conn: pog.Connection,
) -> wisp.Response {
  wisp.response(501)
  |> wisp.string_body("Dashboard data handler not yet implemented")
}

/// Log food form handler - GET /log/food/{fdc_id}
/// TODO: Re-enable when foods module is available
pub fn handle_log_food_form(
  _req: wisp.Request,
  _conn: pog.Connection,
  _fdc_id: String,
) -> wisp.Response {
  wisp.response(501)
  |> wisp.string_body("Log food form handler not yet implemented")
}

/// Log food API handler - POST /api/logs/food
/// TODO: Re-enable when foods module is available
pub fn handle_log_food(
  _req: wisp.Request,
  _conn: pog.Connection,
) -> wisp.Response {
  wisp.response(501)
  |> wisp.string_body("Log food handler not yet implemented")
}

/// FatSecret OAuth connect - GET /fatsecret/connect
pub fn handle_fatsecret_connect(
  req: wisp.Request,
  conn: pog.Connection,
  base_url: String,
) -> wisp.Response {
  fatsecret.handle_connect(req, conn, base_url)
}

/// FatSecret OAuth callback - GET /fatsecret/callback
pub fn handle_fatsecret_callback(
  req: wisp.Request,
  conn: pog.Connection,
) -> wisp.Response {
  fatsecret.handle_callback(req, conn)
}

/// FatSecret status - GET /fatsecret/status
pub fn handle_fatsecret_status(
  req: wisp.Request,
  conn: pog.Connection,
) -> wisp.Response {
  fatsecret.handle_status(req, conn)
}

/// FatSecret disconnect - POST /fatsecret/disconnect
pub fn handle_fatsecret_disconnect(
  req: wisp.Request,
  conn: pog.Connection,
) -> wisp.Response {
  fatsecret.handle_disconnect(req, conn)
}

/// FatSecret get profile - GET /api/fatsecret/profile
pub fn handle_fatsecret_profile(
  req: wisp.Request,
  conn: pog.Connection,
) -> wisp.Response {
  fatsecret.handle_get_profile(req, conn)
}

/// FatSecret get entries - GET /api/fatsecret/entries
pub fn handle_fatsecret_entries(
  req: wisp.Request,
  conn: pog.Connection,
) -> wisp.Response {
  fatsecret.handle_get_entries(req, conn)
}

// ============================================================================
// Tandoor Recipe Manager Handlers
// ============================================================================

/// Tandoor status - GET /tandoor/status
pub fn handle_tandoor_status(req: wisp.Request) -> wisp.Response {
  tandoor.handle_status(req)
}

/// Tandoor list recipes - GET /api/tandoor/recipes
pub fn handle_tandoor_list_recipes(req: wisp.Request) -> wisp.Response {
  tandoor.handle_list_recipes(req)
}

/// Tandoor get recipe - GET /api/tandoor/recipes/:id
pub fn handle_tandoor_get_recipe(
  req: wisp.Request,
  recipe_id: String,
) -> wisp.Response {
  tandoor.handle_get_recipe(req, recipe_id)
}

/// Tandoor get meal plan - GET /api/tandoor/meal-plan
pub fn handle_tandoor_get_meal_plan(req: wisp.Request) -> wisp.Response {
  tandoor.handle_get_meal_plan(req)
}

/// Tandoor create meal plan - POST /api/tandoor/meal-plan
pub fn handle_tandoor_create_meal_plan(req: wisp.Request) -> wisp.Response {
  tandoor.handle_create_meal_plan(req)
}

/// Tandoor delete meal plan - DELETE /api/tandoor/meal-plan/:id
pub fn handle_tandoor_delete_meal_plan(
  req: wisp.Request,
  entry_id: String,
) -> wisp.Response {
  tandoor.handle_delete_meal_plan(req, entry_id)
}
