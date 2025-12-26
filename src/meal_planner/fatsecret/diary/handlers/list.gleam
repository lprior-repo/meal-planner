/// HTTP handlers for FatSecret Food Diary list endpoints
///
/// Routes:
///   GET /api/fatsecret/diary/day/:date_int - Get all entries for date
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
// GET /api/fatsecret/diary/day/:date_int - Get all entries for date
// ============================================================================

/// GET /api/fatsecret/diary/day/:date_int - Get all food entries for a date
///
/// Example: GET /api/fatsecret/diary/day/19723
///
/// Returns:
/// ```json
/// {
///   "date_int": 19723,
///   "date": "2024-01-01",
///   "entries": [
///     { "food_entry_id": "123456", "food_entry_name": "Chicken", ... },
///     { "food_entry_id": "123457", "food_entry_name": "Rice", ... }
///   ],
///   "totals": {
///     "calories": 2100.0,
///     "carbohydrate": 200.0,
///     "protein": 150.0,
///     "fat": 70.0
///   }
/// }
/// ```
pub fn get_day(
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
      case service.get_day_entries(conn, date_int) {
        Ok(entries) -> {
          // Calculate totals
          let totals = helpers.calculate_day_totals(entries)
          let date_str = types.int_to_date(date_int)

          let entries_json =
            list.map(entries, fn(entry) { helpers.food_entry_to_json(entry) })

          wisp.json_response(
            json.to_string(
              json.object([
                #("date_int", json.int(date_int)),
                #("date", json.string(date_str)),
                #("entries", json.array(entries_json, fn(x) { x })),
                #(
                  "totals",
                  json.object([
                    #("calories", json.float(totals.calories)),
                    #("carbohydrate", json.float(totals.carbohydrate)),
                    #("protein", json.float(totals.protein)),
                    #("fat", json.float(totals.fat)),
                  ]),
                ),
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
