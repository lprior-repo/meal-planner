/// Nutrition control plane routing
///
/// Routes:
/// - GET /api/nutrition/daily-status - Get daily nutrition status
/// - GET /api/nutrition/recommend-dinner - Get dinner recommendations
import gleam/option.{type Option}
import meal_planner/web/handler_nutrition
import meal_planner/web/route_types
import wisp

pub fn route(
  req: wisp.Request,
  segments: List(String),
  _ctx: types.Context,
) -> Option(wisp.Response) {
  nutrition.handle(req, segments)
}
