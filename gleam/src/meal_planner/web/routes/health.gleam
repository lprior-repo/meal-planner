//// Health check routing module
////
//// Routes:
//// - GET / -> Health check
//// - GET /health -> Health check

import gleam/option.{type Option, None, Some}
import meal_planner/web/handlers
import meal_planner/web/routes/types
import wisp

/// Route health check requests
pub fn route(
  req: wisp.Request,
  segments: List(String),
  _ctx: types.Context,
) -> Option(wisp.Response) {
  case segments {
    [] -> Some(handlers.handle_health(req))
    ["health"] -> Some(handlers.handle_health(req))
    _ -> None
  }
}
