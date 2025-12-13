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

import meal_planner/web/handlers/dashboard
import meal_planner/web/handlers/diet
import meal_planner/web/handlers/health
import meal_planner/web/handlers/macros
import meal_planner/web/handlers/recipes
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
pub fn handle_dashboard(req: wisp.Request, conn: pog.Connection) -> wisp.Response {
  dashboard.handle(req, conn)
}

/// Dashboard data handler - GET /api/dashboard/data
pub fn handle_dashboard_data(
  req: wisp.Request,
  conn: pog.Connection,
) -> wisp.Response {
  dashboard.handle_data(req, conn)
}
