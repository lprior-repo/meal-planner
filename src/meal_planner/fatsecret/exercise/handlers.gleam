//// HTTP handlers for FatSecret Exercise endpoints
////
//// Routes:
////   GET /api/fatsecret/exercises - Search exercises (2-legged OAuth)
////   GET /api/fatsecret/exercise-entries - List exercise entries for date (3-legged OAuth)
////   POST /api/fatsecret/exercise-entries - Create exercise entry (3-legged OAuth)
////   GET /api/fatsecret/exercise-entries/:entry_id - Get single entry (3-legged OAuth)
////   PUT /api/fatsecret/exercise-entries/:entry_id - Update entry (3-legged OAuth)
////   DELETE /api/fatsecret/exercise-entries/:entry_id - Delete entry (3-legged OAuth)

import gleam/dynamic
import gleam/dynamic/decode
import gleam/http.{Delete, Get, Post, Put}
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import meal_planner/fatsecret/exercise/client
import meal_planner/fatsecret/exercise/service
import meal_planner/fatsecret/exercise/types
import meal_planner/fatsecret/handlers_helpers as helpers
import meal_planner/fatsecret/storage
import pog
import wisp.{type Request, type Response}

// ============================================================================
// GET /api/fatsecret/exercises - Search exercises (2-legged OAuth)
// ============================================================================

/// GET /api/fatsecret/exercises?q=running - Search for exercises
///
/// Query parameters:
///   - q: Search query (optional)
///
/// This is a 2-legged OAuth endpoint (no user auth required).
/// Currently returns empty list as the FatSecret API doesn't have a public
/// exercise search endpoint. Exercise IDs must be known beforehand.
///
/// Returns:
/// - 200: Success with empty array (exercise search not available in API)
/// - 400: Invalid request
/// - 500: Server error
pub fn get_exercises(req: Request, _conn: pog.Connection) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Get)

  // FatSecret API doesn't provide a public exercise search endpoint
  // Exercise IDs are predefined and must be known
  // Return empty list for now
  json.object([#("exercises", json.array([], json.string))])
  |> json.to_string
  |> wisp.json_response(200)
}

// ============================================================================
// GET /api/fatsecret/exercise-entries - List exercise entries by date
// ============================================================================

/// GET /api/fatsecret/exercise-entries?date=YYYY-MM-DD - Get entries for date
///
/// Query parameters:
///   - date: Date in YYYY-MM-DD format (required)
///
/// Authorization: Requires valid OAuth token stored in database
///
/// Returns:
/// - 200: List of exercise entries for the date
/// - 400: Missing or invalid date parameter
/// - 401: Not authorized or auth revoked
/// - 500: Server error
pub fn get_exercise_entries_by_date(
  req: Request,
  conn: pog.Connection,
) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Get)

  // Parse query parameters
  let query_params = wisp.get_query(req)

  // Get date parameter (required)
  case helpers.get_query_param(query_params, "date") {
    None ->
      helpers.error_response(
        400,
        "Missing required parameter: date (YYYY-MM-DD)",
      )

    Some(date_str) -> {
      // Convert date string to date_int
      case types.date_to_int(date_str) {
        Error(_) ->
          helpers.error_response(
            400,
            "Invalid date format. Expected YYYY-MM-DD",
          )

        Ok(date_int) -> {
          // Get user's OAuth token from database
          case storage.get_access_token(conn) {
            Error(_) ->
              helpers.error_response(
                401,
                "Not authenticated. Please connect FatSecret account first.",
              )

            Ok(access_token) -> {
              // Fetch exercise entries from service
              case service.get_exercise_entries(access_token, date_int) {
                Ok(entries) -> {
                  // Encode entries to JSON
                  let entries_json =
                    list.map(entries, fn(entry) {
                      json.object([
                        #(
                          "exercise_entry_id",
                          json.string(types.exercise_entry_id_to_string(
                            entry.exercise_entry_id,
                          )),
                        ),
                        #(
                          "exercise_id",
                          json.string(types.exercise_id_to_string(
                            entry.exercise_id,
                          )),
                        ),
                        #("exercise_name", json.string(entry.exercise_name)),
                        #("duration_min", json.int(entry.duration_min)),
                        #("calories", json.float(entry.calories)),
                        #("date_int", json.int(entry.date_int)),
                        #(
                          "date",
                          json.string(types.int_to_date(entry.date_int)),
                        ),
                      ])
                    })

                  json.object([
                    #("entries", json.array(entries_json, fn(x) { x })),
                  ])
                  |> json.to_string
                  |> wisp.json_response(200)
                }

                Error(service.NotConfigured) ->
                  helpers.error_response(
                    500,
                    "FatSecret API not configured. Set FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET.",
                  )

                Error(service.ApiError(inner)) ->
                  helpers.error_response(
                    502,
                    "FatSecret API error: " <> client.error_to_string(inner),
                  )

                Error(service.NotAuthenticated) ->
                  helpers.error_response(401, "User not authenticated")
              }
            }
          }
        }
      }
    }
  }
}

// ============================================================================
// POST /api/fatsecret/exercise-entries - Create exercise entry
// ============================================================================

/// POST /api/fatsecret/exercise-entries - Create a new exercise entry
///
/// Request body (JSON):
/// ```json
/// {
///   "exercise_id": "1",
///   "duration_min": 30,
///   "date": "2024-01-15"
/// }
/// ```
///
/// Authorization: Requires valid OAuth token in database
///
/// Returns:
/// - 201: Success with entry ID
/// - 400: Invalid request body
/// - 401: Not authorized
/// - 500: Server error
pub fn create_exercise_entry(req: Request, conn: pog.Connection) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Post)
  use json_body <- wisp.require_json(req)

  // Parse request body
  case parse_exercise_entry_create(json_body) {
    Error(msg) ->
      json.object([
        #("error", json.string("invalid_request")),
        #("message", json.string(msg)),
      ])
      |> json.to_string
      |> wisp.json_response(400)

    Ok(#(exercise_id, duration_min, date_str)) -> {
      // Convert date to date_int
      case types.date_to_int(date_str) {
        Error(_) ->
          helpers.error_response(
            400,
            "Invalid date format. Expected YYYY-MM-DD",
          )

        Ok(date_int) -> {
          // Get user's OAuth token from database
          case storage.get_access_token(conn) {
            Error(_) ->
              helpers.error_response(
                401,
                "Not authenticated. Please connect FatSecret account first.",
              )

            Ok(access_token) -> {
              let input =
                types.ExerciseEntryInput(
                  exercise_id: exercise_id,
                  duration_min: duration_min,
                  date_int: date_int,
                )

              case service.create_exercise_entry(access_token, input) {
                Ok(entry_id) ->
                  json.object([
                    #(
                      "exercise_entry_id",
                      json.string(types.exercise_entry_id_to_string(entry_id)),
                    ),
                    #(
                      "message",
                      json.string("Exercise entry created successfully"),
                    ),
                  ])
                  |> json.to_string
                  |> wisp.json_response(201)

                Error(service.NotConfigured) ->
                  helpers.error_response(500, "FatSecret API not configured")

                Error(service.ApiError(inner)) ->
                  helpers.error_response(
                    502,
                    "FatSecret API error: " <> client.error_to_string(inner),
                  )

                Error(service.NotAuthenticated) ->
                  helpers.error_response(401, "User not authenticated")
              }
            }
          }
        }
      }
    }
  }
}

// ============================================================================
// GET /api/fatsecret/exercise-entries/:entry_id - Get single entry
// ============================================================================

/// GET /api/fatsecret/exercise-entries/:entry_id - Get an exercise entry by ID
///
/// Authorization: Requires valid OAuth token in database
///
/// Returns:
/// - 200: Exercise entry data
/// - 401: Not authorized
/// - 404: Entry not found (not implemented yet)
/// - 501: Not implemented
pub fn get_exercise_entry(
  req: Request,
  _conn: pog.Connection,
  _entry_id: String,
) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Get)

  // Not implemented - FatSecret API doesn't have a single entry get endpoint
  wisp.response(501)
  |> wisp.string_body("Get single exercise entry not yet implemented")
}

// ============================================================================
// PUT /api/fatsecret/exercise-entries/:entry_id - Update entry
// ============================================================================

/// PUT /api/fatsecret/exercise-entries/:entry_id - Update an exercise entry
///
/// Request body (JSON):
/// ```json
/// {
///   "duration_min": 45
/// }
/// ```
///
/// Authorization: Requires valid OAuth token in database
///
/// Returns:
/// - 200: Success
/// - 400: Invalid request
/// - 401: Not authorized
/// - 404: Entry not found
/// - 500: Server error
pub fn update_exercise_entry(
  req: Request,
  conn: pog.Connection,
  entry_id: String,
) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Put)
  use json_body <- wisp.require_json(req)

  case parse_exercise_entry_update(json_body) {
    Error(msg) -> helpers.error_response(400, "Invalid request: " <> msg)

    Ok(update) -> {
      // Get user's OAuth token
      case storage.get_access_token(conn) {
        Error(_) -> helpers.error_response(401, "Not authenticated")

        Ok(access_token) -> {
          let entry_id_typed = types.exercise_entry_id(entry_id)

          case
            service.edit_exercise_entry(access_token, entry_id_typed, update)
          {
            Ok(_) ->
              json.object([#("message", json.string("Exercise entry updated"))])
              |> json.to_string
              |> wisp.json_response(200)

            Error(service.NotConfigured) ->
              helpers.error_response(500, "FatSecret API not configured")

            Error(service.ApiError(inner)) ->
              helpers.error_response(
                502,
                "FatSecret API error: " <> client.error_to_string(inner),
              )

            Error(service.NotAuthenticated) ->
              helpers.error_response(401, "User not authenticated")
          }
        }
      }
    }
  }
}

// ============================================================================
// DELETE /api/fatsecret/exercise-entries/:entry_id - Delete entry
// ============================================================================

/// DELETE /api/fatsecret/exercise-entries/:entry_id - Delete an exercise entry
///
/// Authorization: Requires valid OAuth token in database
///
/// Returns:
/// - 200: Success
/// - 401: Not authorized
/// - 404: Entry not found
/// - 500: Server error
pub fn delete_exercise_entry(
  req: Request,
  conn: pog.Connection,
  entry_id: String,
) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Delete)

  // Get user's OAuth token
  case storage.get_access_token(conn) {
    Error(_) -> helpers.error_response(401, "Not authenticated")

    Ok(access_token) -> {
      let entry_id_typed = types.exercise_entry_id(entry_id)

      case service.delete_exercise_entry(access_token, entry_id_typed) {
        Ok(_) ->
          json.object([#("message", json.string("Exercise entry deleted"))])
          |> json.to_string
          |> wisp.json_response(200)

        Error(service.NotConfigured) ->
          helpers.error_response(500, "FatSecret API not configured")

        Error(service.ApiError(inner)) ->
          helpers.error_response(
            502,
            "FatSecret API error: " <> client.error_to_string(inner),
          )

        Error(service.NotAuthenticated) ->
          helpers.error_response(401, "User not authenticated")
      }
    }
  }
}

// ============================================================================
// Routing Function
// ============================================================================

/// Route exercise requests to appropriate handler
pub fn handle_exercise_routes(req: Request, conn: pog.Connection) -> Response {
  case wisp.path_segments(req) {
    ["api", "fatsecret", "exercises"] ->
      case req.method {
        Get -> get_exercises(req, conn)
        _ -> wisp.method_not_allowed([Get])
      }

    ["api", "fatsecret", "exercise-entries"] ->
      case req.method {
        Get -> get_exercise_entries_by_date(req, conn)
        Post -> create_exercise_entry(req, conn)
        _ -> wisp.method_not_allowed([Get, Post])
      }

    ["api", "fatsecret", "exercise-entries", entry_id] ->
      case req.method {
        Get -> get_exercise_entry(req, conn, entry_id)
        Put -> update_exercise_entry(req, conn, entry_id)
        Delete -> delete_exercise_entry(req, conn, entry_id)
        _ -> wisp.method_not_allowed([Get, Put, Delete])
      }

    _ -> wisp.not_found()
  }
}

// ============================================================================
// Helper Functions for JSON Parsing
// ============================================================================

/// Parse exercise entry creation from JSON request body
fn parse_exercise_entry_create(
  body: dynamic.Dynamic,
) -> Result(#(types.ExerciseId, Int, String), String) {
  let decoder = {
    use exercise_id_str <- decode.field("exercise_id", decode.string)
    use duration_min <- decode.field("duration_min", decode.int)
    use date_str <- decode.field("date", decode.string)
    decode.success(#(types.exercise_id(exercise_id_str), duration_min, date_str))
  }

  decode.run(body, decoder)
  |> result.map_error(fn(_errors) { "Invalid request body" })
}

/// Parse exercise entry update from JSON request body
fn parse_exercise_entry_update(
  body: dynamic.Dynamic,
) -> Result(types.ExerciseEntryUpdate, String) {
  // Both fields are optional for update - decode and then check if at least one exists
  let decoder = {
    use exercise_id_opt <- decode.optional_field(
      "exercise_id",
      None,
      decode.optional(decode.string),
    )
    use duration_opt <- decode.optional_field(
      "duration_min",
      None,
      decode.optional(decode.int),
    )

    decode.success(types.ExerciseEntryUpdate(
      exercise_id: exercise_id_opt |> option.map(types.exercise_id),
      duration_min: duration_opt,
    ))
  }

  decode.run(body, decoder)
  |> result.map_error(fn(_) { "Invalid request body" })
  |> result.then(fn(update) {
    // Validate at least one field is provided
    case update.exercise_id, update.duration_min {
      None, None -> Error("At least one field must be provided for update")
      _, _ -> Ok(update)
    }
  })
}
