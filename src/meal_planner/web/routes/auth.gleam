//// FatSecret OAuth routing module
////
//// Routes (3-legged OAuth flow):
//// - GET /fatsecret/connect -> Start OAuth flow
//// - GET /fatsecret/callback -> OAuth callback handler
//// - GET /fatsecret/status -> Check auth status
//// - POST /fatsecret/disconnect -> Disconnect account

import gleam/int
import gleam/option.{type Option, None, Some}
import meal_planner/web/handlers
import meal_planner/web/routes/types
import wisp

/// Route FatSecret OAuth requests
pub fn route(
  req: wisp.Request,
  segments: List(String),
  ctx: types.Context,
) -> Option(wisp.Response) {
  let base_url = "http://localhost:" <> int.to_string(ctx.config.server.port)

  case segments {
    ["fatsecret", "connect"] ->
      Some(handlers.handle_fatsecret_connect(req, ctx.db, base_url))

    ["fatsecret", "callback"] ->
      Some(handlers.handle_fatsecret_callback(req, ctx.db))

    ["fatsecret", "status"] ->
      Some(handlers.handle_fatsecret_status(req, ctx.db))

    ["fatsecret", "disconnect"] ->
      Some(handlers.handle_fatsecret_disconnect(req, ctx.db))

    _ -> None
  }
}
