/// HTTP handlers for FatSecret Food Diary list endpoints
///
/// Routes:
///   GET /api/fatsecret/diary/day/:date_int - Get all entries for date
///   GET /api/fatsecret/diary/month/:date_int - Get month summary
import gleam/http.{Get}
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import meal_planner/fatsecret/diary/service
import meal_planner/fatsecret/diary/types.{type FoodEntry}
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
          let totals = calculate_day_totals(entries)
          let date_str = types.int_to_date(date_int)

          let entries_json =
            list.map(entries, fn(entry) { food_entry_to_json(entry) })

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

        Error(e) -> error_response(e)
      }
    }
  }
}

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

        Error(e) -> error_response(e)
      }
    }
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Convert FoodEntry to JSON representation
fn food_entry_to_json(entry: FoodEntry) -> json.Json {
  json.object([
    #(
      "food_entry_id",
      json.string(types.food_entry_id_to_string(entry.food_entry_id)),
    ),
    #("food_entry_name", json.string(entry.food_entry_name)),
    #("food_entry_description", json.string(entry.food_entry_description)),
    #("food_id", json.string(entry.food_id)),
    #("serving_id", json.string(entry.serving_id)),
    #("number_of_units", json.float(entry.number_of_units)),
    #("meal", json.string(types.meal_type_to_string(entry.meal))),
    #("date_int", json.int(entry.date_int)),
    #("calories", json.float(entry.calories)),
    #("carbohydrate", json.float(entry.carbohydrate)),
    #("protein", json.float(entry.protein)),
    #("fat", json.float(entry.fat)),
    #("saturated_fat", case entry.saturated_fat {
      Some(f) -> json.float(f)
      None -> json.null()
    }),
    #("polyunsaturated_fat", case entry.polyunsaturated_fat {
      Some(f) -> json.float(f)
      None -> json.null()
    }),
    #("monounsaturated_fat", case entry.monounsaturated_fat {
      Some(f) -> json.float(f)
      None -> json.null()
    }),
    #("cholesterol", case entry.cholesterol {
      Some(f) -> json.float(f)
      None -> json.null()
    }),
    #("sodium", case entry.sodium {
      Some(f) -> json.float(f)
      None -> json.null()
    }),
    #("potassium", case entry.potassium {
      Some(f) -> json.float(f)
      None -> json.null()
    }),
    #("fiber", case entry.fiber {
      Some(f) -> json.float(f)
      None -> json.null()
    }),
    #("sugar", case entry.sugar {
      Some(f) -> json.float(f)
      None -> json.null()
    }),
  ])
}

/// Daily nutrition totals
type DayTotals {
  DayTotals(calories: Float, carbohydrate: Float, protein: Float, fat: Float)
}

/// Calculate daily totals from entries
fn calculate_day_totals(entries: List(FoodEntry)) -> DayTotals {
  list.fold(entries, DayTotals(0.0, 0.0, 0.0, 0.0), fn(totals, entry) {
    DayTotals(
      calories: totals.calories +. entry.calories,
      carbohydrate: totals.carbohydrate +. entry.carbohydrate,
      protein: totals.protein +. entry.protein,
      fat: totals.fat +. entry.fat,
    )
  })
}

/// Convert service error to HTTP error response
fn error_response(error: service.ServiceError) -> Response {
  case error {
    service.NotConnected ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("error", json.string("not_connected")),
            #(
              "message",
              json.string(
                "FatSecret account not connected. Please connect first.",
              ),
            ),
          ]),
        ),
        401,
      )

    service.NotConfigured ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("error", json.string("not_configured")),
            #(
              "message",
              json.string("FatSecret API credentials not configured."),
            ),
          ]),
        ),
        500,
      )

    service.AuthRevoked ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("error", json.string("auth_revoked")),
            #(
              "message",
              json.string(
                "FatSecret authorization revoked. Please reconnect your account.",
              ),
            ),
          ]),
        ),
        401,
      )

    service.ApiError(_) | service.StorageError(_) ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("error", json.string("api_error")),
            #("message", json.string(service.error_to_message(error))),
          ]),
        ),
        500,
      )
  }
}
