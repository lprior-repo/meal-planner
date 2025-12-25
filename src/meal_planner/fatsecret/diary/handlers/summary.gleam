/// HTTP handlers for FatSecret Food Diary summary endpoints
///
/// Routes:
///   GET /api/fatsecret/diary/month/:date_int - Get month summary
import gleam/http.{Get}
import gleam/int
import gleam/json
import gleam/list
import meal_planner/fatsecret/diary/handlers/helpers
import meal_planner/fatsecret/diary/service
import meal_planner/fatsecret/diary/types
import pog
import wisp.{type Request, type Response}

// ============================================================================
// GET /api/fatsecret/diary/month/:date_int - Get month summary
// ============================================================================

/// GET /api/fatsecret/diary/month/:date_int - Get monthly nutrition summary
///
/// Example: GET /api/fatsecret/diary/month/19723
///
/// Returns:
/// ```json
/// {
///   "month": 1,
///   "year": 2024,
///   "days": [
///     { "date_int": 19723, "date": "2024-01-01", "calories": 2100.0, "carbohydrate": 200.0, "protein": 150.0, "fat": 70.0 },
///     { "date_int": 19724, "date": "2024-01-02", "calories": 1950.0, "carbohydrate": 180.0, "protein": 140.0, "fat": 65.0 }
///   ]
/// }
/// ```
pub fn get_month(
  req: Request,
  conn: pog.Connection,
  date_int_str: String,
) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Get)
  case int.parse(date_int_str) {
    Error(_) ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("error", json.string("invalid_parameters")),
            #("message", json.string("date_int must be a valid integer")),
          ]),
        ),
        400,
      )

    Ok(date_int) -> {
      case service.get_month_summary(conn, date_int) {
        Ok(summary) -> {
          let days_json =
            list.map(summary.days, fn(day) {
              json.object([
                #("date_int", json.int(day.date_int)),
                #("date", json.string(types.int_to_date(day.date_int))),
                #("calories", json.float(day.calories)),
                #("carbohydrate", json.float(day.carbohydrate)),
                #("protein", json.float(day.protein)),
                #("fat", json.float(day.fat)),
              ])
            })

          wisp.json_response(
            json.to_string(
              json.object([
                #("month", json.int(summary.month)),
                #("year", json.int(summary.year)),
                #("days", json.array(days_json, fn(x) { x })),
              ]),
            ),
            200,
          )
        }

        Error(e) -> helpers.error_response(e)
      }
    }
  }
}
