//// Advisor API routing module
////
//// Routes:
//// - GET /api/advisor/daily -> Daily recommendations for today
//// - GET /api/advisor/daily/:date -> Daily recommendations for specific date
//// - GET /api/advisor/trends -> Weekly trends for past 7 days
//// - GET /api/advisor/trends/:end_date -> Weekly trends ending on specific date
//// - GET /api/advisor/suggestions -> Meal adjustment suggestions
//// - GET /api/advisor/compliance -> Weekly compliance score

import gleam/option.{type Option, None, Some}
import meal_planner/web/handlers/advisor
import meal_planner/web/routes/types
import wisp

/// Route advisor API requests
pub fn route(
  req: wisp.Request,
  segments: List(String),
  ctx: types.Context,
) -> Option(wisp.Response) {
  case segments {
    ["api", "advisor", "daily"] -> Some(advisor.handle_daily_today(req, ctx.db))
    ["api", "advisor", "daily", date_str] ->
      Some(advisor.handle_daily_date(req, date_str, ctx.db))
    ["api", "advisor", "trends"] ->
      Some(advisor.handle_trends_week(req, ctx.db))
    ["api", "advisor", "trends", end_date_str] ->
      Some(advisor.handle_trends_date(req, end_date_str, ctx.db))
    ["api", "advisor", "suggestions"] ->
      Some(advisor.handle_suggestions(req, ctx.db))
    ["api", "advisor", "compliance"] ->
      Some(advisor.handle_compliance(req, ctx.db))
    _ -> None
  }
}
