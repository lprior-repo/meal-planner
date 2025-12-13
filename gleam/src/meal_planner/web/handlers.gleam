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

import meal_planner/web/handlers/diet
import meal_planner/web/handlers/health
import meal_planner/web/handlers/macros
import meal_planner/web/handlers/recipes
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
