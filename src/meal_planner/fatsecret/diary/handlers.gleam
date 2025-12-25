/// HTTP handlers for FatSecret Food Diary endpoints
///
/// This module re-exports the routing functionality from handlers/mod.gleam
/// All handler implementations are located in their respective submodules.
import meal_planner/fatsecret/diary/handlers/mod
import pog
import wisp.{type Request, type Response}

/// Route diary requests to appropriate handler
pub fn handle_diary_routes(req: Request, conn: pog.Connection) -> Response {
  mod.handle_diary_routes(req, conn)
}
