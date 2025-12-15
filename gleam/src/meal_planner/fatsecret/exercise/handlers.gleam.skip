/// FatSecret Exercise API HTTP handlers
///
/// Routes:
/// - GET /api/fatsecret/exercises/:id - Get exercise details (2-legged)
/// - GET /api/fatsecret/exercise-entries?date=YYYY-MM-DD - Get entries for date (3-legged)
/// - POST /api/fatsecret/exercise-entries - Create entry (3-legged)
/// - PUT /api/fatsecret/exercise-entries/:id - Edit entry (3-legged)
/// - DELETE /api/fatsecret/exercise-entries/:id - Delete entry (3-legged)
/// - GET /api/fatsecret/exercise-entries/month/:year/:month - Get month summary (3-legged)
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import meal_planner/fatsecret/core/oauth
import meal_planner/fatsecret/exercise/service
import meal_planner/fatsecret/exercise/types
import meal_planner/fatsecret/storage
import pog
import wisp

// ============================================================================
// GET /api/fatsecret/exercises/:id - Get exercise details (2-legged)
// ============================================================================

/// Get exercise details by ID from public database
///
/// ## Example Request
/// ```
/// GET /api/fatsecret/exercises/1
/// ```
///
/// ## Example Response (Success)
/// ```json
/// {
///   "exercise_id": "1",
///   "exercise_name": "Running",
///   "calories_per_hour": 600.0
/// }
/// ```
///
/// ## Error Responses
/// - 404: Exercise not found
/// - 500: FatSecret not configured
/// - 502: API error
pub fn handle_get_exercise(
  req: wisp.Request,
  exercise_id: String,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Get)

  let exercise_id_typed = types.exercise_id(exercise_id)

  case service.get_exercise(exercise_id_typed) {
    Ok(exercise) -> {
      json.to_string(exercise_to_json(exercise))
      |> wisp.json_response(200)
    }
    Error(service.NotConfigured) -> {
      error_response(
        500,
        "FatSecret API not configured. Set FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET.",
      )
    }
    Error(service.ApiError(inner)) -> {
      error_response(
        502,
        "FatSecret API error: "
          <> service.error_to_string(service.ApiError(inner)),
      )
    }
    Error(service.NotAuthenticated) -> {
      // Should not happen for 2-legged endpoints
      error_response(500, "Unexpected authentication error")
    }
  }
}

// ============================================================================
// GET /api/fatsecret/exercise-entries - Get entries for date (3-legged)
// ============================================================================

/// Get user's exercise entries for a specific date
///
/// Query parameters:
/// - date: YYYY-MM-DD format (required)
///
/// ## Example Request
/// ```
/// GET /api/fatsecret/exercise-entries?date=2025-12-14
/// Headers:
///   Authorization: Bearer {access_token}
/// ```
///
/// ## Example Response
/// ```json
/// {
///   "entries": [
///     {
///       "exercise_entry_id": "123456",
///       "exercise_id": "1",
///       "exercise_name": "Running",
///       "duration_min": 30,
///       "calories": 300.0
///     }
///   ]
/// }
/// ```
pub fn handle_get_exercise_entries(
  req: wisp.Request,
  conn: pog.Connection,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Get)

  case extract_access_token(req) {
    Error(msg) -> error_response(401, msg)
    Ok(token) -> {
      case get_query_param(req, "date") {
        None -> error_response(400, "Missing required query parameter: date")
        Some(date_str) -> {
          case service.get_exercise_entries(token, 0) {
            Ok(entries) -> {
              let entries_json =
                list.map(entries, exercise_entry_to_json)
              json.object([#("entries", json.array(entries_json, fn(x) { x }))])
              |> json.to_string
              |> wisp.json_response(200)
            }
            Error(service.NotConfigured) ->
              error_response(500, "FatSecret not configured")
            Error(service.NotAuthenticated) ->
              error_response(401, "Not authenticated")
            Error(service.ApiError(e)) ->
              error_response(500, "API error: " <> service.error_to_string(service.ApiError(e)))
          }
        }
      }
    }
  }
}

/// POST /api/fatsecret/exercise-entries - Create new entry (3-legged)
pub fn handle_create_exercise_entry(
  req: wisp.Request,
  conn: pog.Connection,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Post)

  case extract_access_token(req) {
    Error(msg) -> error_response(401, msg)
    Ok(token) -> {
      use body <- wisp.require_json(req)
      case parse_exercise_entry_input(body) {
        Error(msg) -> error_response(400, msg)
        Ok(input) -> {
          case service.create_exercise_entry(token, input) {
            Ok(entry_id) -> {
              json.object([
                #("success", json.bool(True)),
                #("entry_id", json.string(types.exercise_entry_id_to_string(entry_id))),
                #("message", json.string("Exercise entry created successfully")),
              ])
              |> json.to_string
              |> wisp.json_response(200)
            }
            Error(service.NotConfigured) ->
              error_response(500, "FatSecret not configured")
            Error(service.NotAuthenticated) ->
              error_response(401, "Not authenticated")
            Error(service.ApiError(e)) ->
              error_response(500, "API error: " <> service.error_to_string(service.ApiError(e)))
          }
        }
      }
    }
  }
}

// ============================================================================
// PUT /api/fatsecret/exercise-entries/:id - Edit entry (3-legged)
// ============================================================================

/// Edit an existing exercise entry
///
/// ## Example Request
/// ```
/// PUT /api/fatsecret/exercise-entries/123456
/// Headers:
///   Authorization: Bearer {access_token}
///   Content-Type: application/json
/// Body:
/// {
///   "exercise_id": "2",
///   "duration_min": 45
/// }
/// ```
pub fn handle_edit_exercise_entry(
  req: wisp.Request,
  conn: pog.Connection,
  entry_id: String,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Put)

  case extract_access_token(req) {
    Error(msg) -> error_response(401, msg)
    Ok(token) -> {
      use body <- wisp.require_json(req)
      case parse_exercise_entry_update(body) {
        Error(msg) -> error_response(400, msg)
        Ok(update) -> {
          let entry_id_obj = types.exercise_entry_id(entry_id)
          case service.edit_exercise_entry(token, entry_id_obj, update) {
            Ok(_) -> {
              json.object([
                #("success", json.bool(True)),
                #("message", json.string("Exercise entry updated successfully")),
              ])
              |> json.to_string
              |> wisp.json_response(200)
            }
            Error(service.NotConfigured) ->
              error_response(500, "FatSecret not configured")
            Error(service.NotAuthenticated) ->
              error_response(401, "Not authenticated")
            Error(service.ApiError(e)) ->
              error_response(500, "API error: " <> service.error_to_string(service.ApiError(e)))
          }
        }
      }
    }
  }
}

// ============================================================================
// DELETE /api/fatsecret/exercise-entries/:id - Delete entry (3-legged)
// ============================================================================

/// Delete an exercise entry
pub fn handle_delete_exercise_entry(
  req: wisp.Request,
  conn: pog.Connection,
  entry_id: String,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Delete)

  case extract_access_token(req) {
    Error(msg) -> error_response(401, msg)
    Ok(token) -> {
      let entry_id_obj = types.exercise_entry_id(entry_id)
      case service.delete_exercise_entry(token, entry_id_obj) {
        Ok(_) -> {
          json.object([
            #("success", json.bool(True)),
            #("message", json.string("Exercise entry deleted successfully")),
          ])
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(service.NotConfigured) ->
          error_response(500, "FatSecret not configured")
        Error(service.NotAuthenticated) ->
          error_response(401, "Not authenticated")
        Error(service.ApiError(e)) ->
          error_response(500, "API error: " <> service.error_to_string(service.ApiError(e)))
      }
    }
  }
}

// ============================================================================
// GET /api/fatsecret/exercise-entries/month/:year/:month - Month summary (3-legged)
// ============================================================================

/// Get monthly exercise summary
pub fn handle_get_exercise_month(
  req: wisp.Request,
  conn: pog.Connection,
  year_str: String,
  month_str: String,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Get)

  // Parse year and month
  case int.parse(year_str), int.parse(month_str) {
    Ok(year), Ok(month) if month >= 1 && month <= 12 -> {
      case extract_access_token(req) {
        Error(msg) -> error_response(401, msg)
        Ok(token) -> {
          case service.get_exercise_month_summary(token, year, month) {
            Ok(summary) -> {
              let days_json =
                list.map(summary.days, fn(day) {
                  json.object([
                    #("date_int", json.int(day.date_int)),
                    #("exercise_calories", json.float(day.exercise_calories)),
                  ])
                })
              json.object([
                #("month", json.int(summary.month)),
                #("year", json.int(summary.year)),
                #("days", json.array(days_json, fn(x) { x })),
              ])
              |> json.to_string
              |> wisp.json_response(200)
            }
            Error(service.NotConfigured) ->
              error_response(500, "FatSecret not configured")
            Error(service.NotAuthenticated) ->
              error_response(401, "Not authenticated")
            Error(service.ApiError(e)) ->
              error_response(500, "API error: " <> service.error_to_string(service.ApiError(e)))
          }
        }
      }
    }
    _, _ -> error_response(400, "Invalid year or month")
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Extract Authorization header and parse Bearer token
fn extract_access_token(req: wisp.Request) -> Result(oauth.AccessToken, String) {
  case list.find(req.headers, fn(h) { h.0 == "authorization" }) {
    Error(_) -> Error("Missing Authorization header")
    Ok(#(_, auth_header)) -> {
      case string.split(auth_header, " ") {
        ["Bearer", token] -> {
          // For now, return a placeholder token
          // In production, would decode JWT or lookup from storage
          Ok(oauth.AccessToken(oauth_token: token, oauth_token_secret: ""))
        }
        _ -> Error("Invalid Authorization header format. Use: Bearer <token>")
      }
    }
  }
}

/// Get query parameter from request
fn get_query_param(req: wisp.Request, param: String) -> option.Option(String) {
  case string.split(req.path, "?") {
    [_, query] -> {
      query
      |> string.split("&")
      |> list.find_map(fn(pair) {
        case string.split(pair, "=") {
          [key, value] if key == param -> Some(value)
          _ -> None
        }
      })
    }
    _ -> None
  }
}

/// Parse exercise entry input from JSON
fn parse_exercise_entry_input(
  body: dynamic.Dynamic,
) -> Result(types.ExerciseEntryInput, String) {
  let decoder = {
    use exercise_id_str <- decode.field("exercise_id", decode.string)
    use duration_min <- decode.field("duration_min", decode.int)
    use date_int <- decode.optional_field("date_int", None, decode.optional(decode.int))
    decode.success(#(exercise_id_str, duration_min, date_int))
  }

  case decode.run(body, decoder) {
    Error(_) -> Error("Invalid request body")
    Ok(#(exercise_id_str, duration_min, date_int)) -> {
      Ok(types.ExerciseEntryInput(
        exercise_id: types.exercise_id(exercise_id_str),
        duration_min: duration_min,
        date_int: date_int |> option.unwrap(0),
      ))
    }
  }
}

/// Parse exercise entry update from JSON
fn parse_exercise_entry_update(
  body: dynamic.Dynamic,
) -> Result(types.ExerciseEntryUpdate, String) {
  let decoder = {
    use exercise_id <- decode.optional_field(
      "exercise_id",
      None,
      decode.optional(decode.string),
    )
    use duration_min <- decode.optional_field(
      "duration_min",
      None,
      decode.optional(decode.int),
    )
    decode.success(#(exercise_id, duration_min))
  }

  case decode.run(body, decoder) {
    Error(_) -> Error("Invalid request body")
    Ok(#(exercise_id, duration_min)) -> {
      let exercise_id_opt = case exercise_id {
        Some(id) -> Some(types.exercise_id(id))
        None -> None
      }
      Ok(types.ExerciseEntryUpdate(
        exercise_id: exercise_id_opt,
        duration_min: duration_min,
      ))
    }
  }
}

/// Create error response JSON
fn error_response(status: Int, message: String) -> wisp.Response {
  json.object([#("error", json.string(message))])
  |> json.to_string
  |> wisp.json_response(status)
}

// ============================================================================
// JSON Encoding
// ============================================================================

/// Encode Exercise to JSON
fn exercise_to_json(exercise: types.Exercise) -> json.Json {
  json.object([
    #(
      "exercise_id",
      json.string(types.exercise_id_to_string(exercise.exercise_id)),
    ),
    #("exercise_name", json.string(exercise.exercise_name)),
    #("calories_per_hour", json.float(exercise.calories_per_hour)),
  ])
}

/// Encode ExerciseEntry to JSON
fn exercise_entry_to_json(entry: types.ExerciseEntry) -> json.Json {
  json.object([
    #("exercise_entry_id", json.string(types.exercise_entry_id_to_string(entry.exercise_entry_id))),
    #("exercise_id", json.string(types.exercise_id_to_string(entry.exercise_id))),
    #("exercise_name", json.string(entry.exercise_name)),
    #("duration_min", json.int(entry.duration_min)),
    #("date_int", json.int(entry.date_int)),
  ])
}
