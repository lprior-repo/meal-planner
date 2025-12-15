//// Legacy endpoint routing module
////
//// Routes that are being phased out or miscellaneous:
//// - Dashboard UI: /dashboard, /log/food/:id
//// - Legacy API: /api/dashboard/data, /api/ai/score-recipe, etc.

import gleam/option.{type Option, None, Some}
import meal_planner/web/handlers
import meal_planner/web/routes/types
import wisp

/// Route legacy and miscellaneous requests
pub fn route(
  req: wisp.Request,
  segments: List(String),
  ctx: types.Context,
) -> Option(wisp.Response) {
  case segments {
    // Dashboard UI (legacy)
    ["dashboard"] -> Some(handlers.handle_dashboard(req, ctx.db))
    ["log", "food", fdc_id] ->
      Some(handlers.handle_log_food_form(req, ctx.db, fdc_id))

    // Legacy API endpoints
    ["api", "dashboard", "data"] ->
      Some(handlers.handle_dashboard_data(req, ctx.db))
    ["api", "ai", "score-recipe"] -> Some(handlers.handle_score_recipe(req))
    ["api", "diet", "vertical", "compliance", recipe_id] ->
      Some(handlers.handle_diet_compliance(req, recipe_id))
    ["api", "macros", "calculate"] ->
      Some(handlers.handle_macros_calculate(req))
    ["api", "logs", "food"] -> Some(handlers.handle_log_food(req, ctx.db))

    _ -> None
  }
}
