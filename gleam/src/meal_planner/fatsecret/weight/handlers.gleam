/// HTTP handlers for FatSecret Weight endpoints
///
/// Routes:
///   POST /api/fatsecret/weight - Update weight measurement
///   GET /api/fatsecret/weight/month/:year/:month - Get monthly summary
import birl
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http.{Get, Post}
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import meal_planner/fatsecret/diary/types as diary_types
import meal_planner/fatsecret/weight/service
import meal_planner/fatsecret/weight/types.{type WeightUpdate, WeightUpdate}
import pog
import wisp.{type Request}

// ============================================================================
// POST /api/fatsecret/weight - Update weight measurement
// ============================================================================

/// POST /api/fatsecret/weight - Log a weight measurement
///
/// Request body (JSON):
/// ```json
/// {
///   "weight_kg": 75.5,
///   "date": "2024-01-15",        // Optional, defaults to today
///   "goal_weight_kg": 70.0,      // Optional
///   "height_cm": 175.0,          // Optional
///   "comment": "Morning weight"   // Optional
/// }
/// ```
///
/// Returns:
/// - 200: Success
/// - 400: Invalid date (error 205/206)
/// - 401: Not connected or auth revoked
/// - 500: Server error
pub fn update_weight(req: Request, conn: pog.Connection) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Post)
  // Parse request body
  use body <- wisp.require_json(req)

  case parse_weight_update(body) {
    Error(msg) ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("error", json.string("invalid_request")),
            #("message", json.string(msg)),
          ]),
        ),
        400,
      )

    Ok(update) -> {
      case service.update_weight(conn, update) {
        Ok(_) ->
          wisp.json_response(
            json.to_string(
              json.object([
                #("success", json.bool(True)),
                #("message", json.string("Weight updated successfully")),
              ]),
            ),
            200,
          )

        Error(e) -> {
          // Map date validation errors to 400
          case service.is_date_validation_error(e) {
            True -> date_validation_error_response(e)
            False -> error_response(e)
          }
        }
      }
    }
  }
}

// ============================================================================
// GET /api/fatsecret/weight?date=YYYY-MM-DD - Get weight for specific date
// ============================================================================

/// GET /api/fatsecret/weight?date=YYYY-MM-DD - Get weight for a specific date
///
/// Query parameters:
/// - date: YYYY-MM-DD format (required)
///
/// Returns:
/// ```json
/// {
///   "date": "2024-01-15",
///   "weight_kg": 75.5,
///   "date_int": 19723
/// }
/// ```
pub fn get_weight_by_date(req: Request, conn: pog.Connection) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Get)
  // Extract date from query parameter
  case get_query_param(req, "date") {
    None ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("error", json.string("missing_parameter")),
            #("message", json.string("Missing required query parameter: date")),
          ]),
        ),
        400,
      )

    Some(date_str) -> {
      case diary_types.date_to_int(date_str) {
        Error(_) ->
          wisp.json_response(
            json.to_string(
              json.object([
                #("error", json.string("invalid_date")),
                #(
                  "message",
                  json.string("Invalid date format (use YYYY-MM-DD)"),
                ),
              ]),
            ),
            400,
          )

        Ok(date_int) -> {
          case service.get_weight_by_date(conn, date_int) {
            Ok(weight) -> {
              wisp.json_response(
                json.to_string(
                  json.object([
                    #(
                      "date",
                      json.string(diary_types.int_to_date(weight.date_int)),
                    ),
                    #("weight_kg", json.float(weight.weight_kg)),
                    #("date_int", json.int(weight.date_int)),
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
  }
}

// ============================================================================
// GET /api/fatsecret/weight/month/:year/:month - Get monthly summary
// ============================================================================

/// GET /api/fatsecret/weight/month/:year/:month - Get weight measurements for a month
///
/// Example: GET /api/fatsecret/weight/month/2024/1
///
/// Returns:
/// ```json
/// {
///   "month": 1,
///   "year": 2024,
///   "days": [
///     { "date": "2024-01-15", "weight_kg": 75.5, "date_int": 19723 },
///     { "date": "2024-01-16", "weight_kg": 75.3, "date_int": 19724 }
///   ]
/// }
/// ```
pub fn get_weight_month(
  req: Request,
  conn: pog.Connection,
  year: String,
  month: String,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Get)
  // Parse year and month
  case int.parse(year), int.parse(month) {
    Ok(year_int), Ok(month_int) if month_int >= 1 && month_int <= 12 -> {
      // Calculate date_int for first day of month
      let date_str =
        int.to_string(year_int) <> "-" <> pad_zero(month_int) <> "-01"

      case diary_types.date_to_int(date_str) {
        Error(_) ->
          wisp.json_response(
            json.to_string(
              json.object([
                #("error", json.string("invalid_date")),
                #("message", json.string("Invalid year/month")),
              ]),
            ),
            400,
          )

        Ok(date_int) -> {
          case service.get_weight_month_summary(conn, date_int) {
            Ok(summary) -> {
              let days_json =
                list.map(summary.days, fn(day) {
                  json.object([
                    #(
                      "date",
                      json.string(diary_types.int_to_date(day.date_int)),
                    ),
                    #("weight_kg", json.float(day.weight_kg)),
                    #("date_int", json.int(day.date_int)),
                  ])
                })

              wisp.json_response(
                json.to_string(
                  json.object([
                    #("month", json.int(month_int)),
                    #("year", json.int(year_int)),
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

    _, _ ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("error", json.string("invalid_parameters")),
            #("message", json.string("Year and month must be valid integers")),
          ]),
        ),
        400,
      )
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Parse WeightUpdate from JSON request body (Dynamic from wisp.require_json)
fn parse_weight_update(body: dynamic.Dynamic) -> Result(WeightUpdate, String) {
  // Build decoder for all fields
  let decoder = {
    use weight_kg <- decode.field("weight_kg", decode.float)
    use date_str <- decode.optional_field(
      "date",
      None,
      decode.optional(decode.string),
    )
    use goal_weight_kg <- decode.optional_field(
      "goal_weight_kg",
      None,
      decode.optional(decode.float),
    )
    use height_cm <- decode.optional_field(
      "height_cm",
      None,
      decode.optional(decode.float),
    )
    use comment <- decode.optional_field(
      "comment",
      None,
      decode.optional(decode.string),
    )
    decode.success(#(weight_kg, date_str, goal_weight_kg, height_cm, comment))
  }

  case decode.run(body, decoder) {
    Error(_) -> Error("Missing or invalid weight_kg")
    Ok(#(weight_kg, date_str, goal_weight_kg, height_cm, comment)) -> {
      // Handle date: if not provided, use today
      let date_int_result = case date_str {
        Some(ds) ->
          case diary_types.date_to_int(ds) {
            Ok(di) -> Ok(di)
            Error(_) -> Error("Invalid date format (use YYYY-MM-DD)")
          }
        None -> {
          // Use today's date
          let today = birl.now()
          let day = birl.get_day(today)
          let ds =
            int.to_string(day.year)
            <> "-"
            <> pad_zero(day.month)
            <> "-"
            <> pad_zero(day.date)
          case diary_types.date_to_int(ds) {
            Ok(di) -> Ok(di)
            Error(_) -> Error("Failed to calculate today's date")
          }
        }
      }

      case date_int_result {
        Error(msg) -> Error(msg)
        Ok(date_int) ->
          Ok(WeightUpdate(
            current_weight_kg: weight_kg,
            date_int: date_int,
            goal_weight_kg: goal_weight_kg,
            height_cm: height_cm,
            comment: comment,
          ))
      }
    }
  }
}

/// Get query parameter from request
fn get_query_param(req: Request, param: String) -> option.Option(String) {
  case req.query {
    Some(query) -> {
      query
      |> string.split("&")
      |> list.find(fn(pair) {
        case string.split(pair, "=") {
          [key, value] if key == param -> True
          _ -> False
        }
      })
      |> result.then(fn(pair) {
        case string.split(pair, "=") {
          [_key, value] -> Ok(value)
          _ -> Error(Nil)
        }
      })
      |> option.from_result
    }
    None -> None
  }
}

/// Pad single digit numbers with leading zero
fn pad_zero(n: Int) -> String {
  case n < 10 {
    True -> "0" <> int.to_string(n)
    False -> int.to_string(n)
  }
}

/// Convert service error to HTTP error response
fn error_response(error: service.ServiceError) -> wisp.Response {
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

    service.DateTooFar
    | service.DateEarlierThanExisting
    | service.ApiError(_)
    | service.StorageError(_) ->
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

/// Convert date validation errors to 400 Bad Request
fn date_validation_error_response(error: service.ServiceError) -> wisp.Response {
  let #(error_code, message) = case error {
    service.DateTooFar -> #(
      "date_too_far",
      "Weight date must be within 2 days of today",
    )
    service.DateEarlierThanExisting -> #(
      "date_earlier_than_existing",
      "Cannot update a date earlier than existing weight entries",
    )
    _ -> #("unknown", "Unknown date validation error")
  }

  wisp.json_response(
    json.to_string(
      json.object([
        #("error", json.string(error_code)),
        #("message", json.string(message)),
      ]),
    ),
    400,
  )
}
