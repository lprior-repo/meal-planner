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
/// - tandoor: Tandoor Recipe Manager integration
import meal_planner/fatsecret/foods/handlers as foods_handlers
import meal_planner/fatsecret/profile/handlers as profile_handlers
import meal_planner/web/handlers/diet
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

/// FatSecret get recipe types - GET /api/fatsecret/recipes/types
pub fn handle_fatsecret_recipe_types(_req: wisp.Request) -> wisp.Response {
  wisp.response(501)
  |> wisp.string_body("Recipe types handler not yet implemented")
}

/// FatSecret search recipes - GET /api/fatsecret/recipes/search
pub fn handle_fatsecret_search_recipes(_req: wisp.Request) -> wisp.Response {
  wisp.response(501)
  |> wisp.string_body("Recipe search handler not yet implemented")
}

/// FatSecret search recipes by type - GET /api/fatsecret/recipes/search/type/:type_id
pub fn handle_fatsecret_search_recipes_by_type(
  _req: wisp.Request,
  _type_id: String,
) -> wisp.Response {
  wisp.response(501)
  |> wisp.string_body("Recipe type search handler not yet implemented")
}

/// FatSecret get recipe - GET /api/fatsecret/recipes/:id
pub fn handle_fatsecret_get_recipe(
  _req: wisp.Request,
  _recipe_id: String,
) -> wisp.Response {
  wisp.response(501)
  |> wisp.string_body("Get recipe handler not yet implemented")
}

// ============================================================================
// FatSecret Foods API Handlers
// ============================================================================

/// FatSecret search foods - GET /api/fatsecret/foods/search
pub fn handle_fatsecret_search_foods(req: wisp.Request) -> wisp.Response {
  foods_handlers.handle_search_foods(req)
}

/// FatSecret get food - GET /api/fatsecret/foods/:id
pub fn handle_fatsecret_get_food(
  req: wisp.Request,
  food_id: String,
) -> wisp.Response {
  foods_handlers.handle_get_food(req, food_id)
}

/// Handle GET /api/fatsecret/foods/autocomplete
pub fn handle_fatsecret_autocomplete_foods(req: wisp.Request) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use _req <- wisp.handle_head(req)
  wisp.not_found()
}

/// Handle GET /api/fatsecret/recipes/autocomplete
pub fn handle_fatsecret_autocomplete_recipes(req: wisp.Request) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use _req <- wisp.handle_head(req)
  wisp.not_found()
}

// ============================================================================
// Tandoor Recipe Manager Handlers
// ============================================================================

/// Main Tandoor router - routes all Tandoor API requests
/// Handles all endpoints:
/// - GET /tandoor/status
/// - GET/POST/PATCH/DELETE /api/tandoor/recipes/*
/// - GET/POST/PATCH/DELETE /api/tandoor/ingredients/*
/// - GET/POST/PATCH/DELETE /api/tandoor/meal-plans/*
/// - GET /api/tandoor/keywords/*
/// - GET /api/tandoor/units
pub fn handle_tandoor_routes(req: wisp.Request) -> wisp.Response {
  tandoor.handle_tandoor_routes(req)
}

// ============================================================================
// FatSecret OAuth 3-Legged Flow Handlers
// ============================================================================

/// FatSecret OAuth connect - GET /fatsecret/connect
pub fn handle_fatsecret_connect(
  _req: wisp.Request,
  _conn: pog.Connection,
  _base_url: String,
) -> wisp.Response {
  wisp.response(501)
  |> wisp.string_body("FatSecret OAuth connect handler not yet implemented")
}

/// FatSecret OAuth callback - GET /fatsecret/callback
pub fn handle_fatsecret_callback(
  _req: wisp.Request,
  _conn: pog.Connection,
) -> wisp.Response {
  wisp.response(501)
  |> wisp.string_body("FatSecret OAuth callback handler not yet implemented")
}

/// FatSecret status - GET /fatsecret/status
pub fn handle_fatsecret_status(
  _req: wisp.Request,
  _conn: pog.Connection,
) -> wisp.Response {
  wisp.response(501)
  |> wisp.string_body("FatSecret status handler not yet implemented")
}

/// FatSecret disconnect - POST /fatsecret/disconnect
pub fn handle_fatsecret_disconnect(
  _req: wisp.Request,
  _conn: pog.Connection,
) -> wisp.Response {
  wisp.response(501)
  |> wisp.string_body("FatSecret disconnect handler not yet implemented")
}

/// FatSecret get profile - GET /api/fatsecret/profile
pub fn handle_fatsecret_profile(
  req: wisp.Request,
  conn: pog.Connection,
) -> wisp.Response {
  profile_handlers.get_profile(req, conn)
}

/// FatSecret create profile - POST /api/fatsecret/profile
pub fn handle_fatsecret_create_profile(
  req: wisp.Request,
  conn: pog.Connection,
) -> wisp.Response {
  profile_handlers.create_profile(req, conn)
}

/// FatSecret get profile auth - GET /api/fatsecret/profile/auth/:user_id
pub fn handle_fatsecret_get_profile_auth(
  req: wisp.Request,
  conn: pog.Connection,
  user_id: String,
) -> wisp.Response {
  profile_handlers.get_profile_auth(req, conn, user_id)
}
