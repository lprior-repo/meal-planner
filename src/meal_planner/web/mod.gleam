//// Web module facade
////
//// This module provides a centralized import point for all web handlers and routes.
//// It re-exports all handler functions and provides a unified routing interface.

import gleam/option.{None, Some}
import meal_planner/web/handlers
import meal_planner/web/routes
import meal_planner/web/routes/types.{type Context}
import wisp

/// Route request to appropriate handler
///
/// This is the main entry point for all web requests. It delegates to the
/// appropriate domain router based on the request path.
pub fn route(req: wisp.Request, ctx: Context) -> wisp.Response {
  routes.route(req, ctx)
}
