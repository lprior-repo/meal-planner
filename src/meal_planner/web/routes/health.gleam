//// Health check routing module
////
//// Routes:
//// - GET / -> Basic health check
//// - GET /health -> Basic health check
//// - GET /health/detailed -> Detailed health check with subsystem status

import gleam/option.{type Option, None, Some}
import meal_planner/web/handlers
import meal_planner/web/routes/types
import wisp

/// Route health check requests
pub fn route(
  req: wisp.Request,
  segments: List(String),
  ctx: types.Context,
) -> Option(wisp.Response) {
  case segments {
    [] -> Some(handlers.handle_health(req))
    ["health"] -> Some(handlers.handle_health(req))
    ["health", "detailed"] ->
      Some(handlers.handle_health_detailed(req, ctx.db, ctx.config))
    _ -> None
  }
}
