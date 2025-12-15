/// FatSecret Exercise API HTTP handlers
///
/// Routes:
/// - GET /api/fatsecret/exercises/:id - Get exercise details (2-legged)
/// - GET /api/fatsecret/exercise-entries/:date - Get entries for date (3-legged)
/// - PUT /api/fatsecret/exercise-entries/:id - Edit entry (3-legged)
/// - GET /api/fatsecret/exercise-entries/month/:year/:month - Get month summary (3-legged)
/// - POST /api/fatsecret/exercise-entries/commit/:date - Commit day (3-legged)
/// - POST /api/fatsecret/exercise-entries/template - Save template (3-legged)
import gleam/http
import gleam/int
import gleam/json
import gleam/result
import meal_planner/fatsecret/exercise/service
import meal_planner/fatsecret/exercise/types
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
    Error(service.NotConfigured) -> {
      error_response(
        500,
        "FatSecret API not configured. Set FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET.",
      )
    Error(service.ApiError(inner)) -> {
      error_response(
        502,
        "FatSecret API error: "
          <> service.error_to_string(service.ApiError(inner)),
      )
    Error(service.NotAuthenticated) -> {
      // Should not happen for 2-legged endpoints
      error_response(500, "Unexpected authentication error")
  }
}

// ============================================================================
// GET /api/fatsecret/exercise-entries/:date - Get entries for date (3-legged)
// ============================================================================

/// Get user's exercise entries for a specific date
///
/// ## Example Request
/// ```
/// GET /api/fatsecret/exercise-entries/2025-12-14
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
///       "calories": 300.0,
///       "date": "2025-12-14"
///     }
///   ]
/// }
/// ```
pub fn handle_get_exercise_entries(req: wisp.Request) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Get)

  // TODO: Extract access_token from Authorization header
  // For now, return not implemented
  error_response(501, "Authentication not yet implemented")
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
///
/// ## Example Response
/// ```json
/// {
///   "success": true
/// }
/// ```
pub fn handle_edit_exercise_entry(req: wisp.Request) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Put)

  // TODO: Extract access_token from Authorization header
  // TODO: Parse JSON body for update fields
  // For now, return not implemented
  error_response(501, "Authentication not yet implemented")
}

// ============================================================================
// GET /api/fatsecret/exercise-entries/month/:year/:month - Month summary (3-legged)
// ============================================================================

/// Get monthly exercise summary
///
/// ## Example Request
/// ```
/// GET /api/fatsecret/exercise-entries/month/2024/12
/// Headers:
///   Authorization: Bearer {access_token}
/// ```
///
/// ## Example Response
/// ```json
/// {
///   "month": 12,
///   "year": 2024,
///   "days": [
///     {
///       "date": "2024-12-01",
///       "exercise_calories": 450.0
///     },
///     {
///       "date": "2024-12-02",
///       "exercise_calories": 300.0
///     }
///   ]
/// }
/// ```
pub fn handle_get_exercise_month(
  req: wisp.Request,
  year_str: String,
  month_str: String,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Get)

  // Parse year and month
  let year = int.parse(year_str) |> result.unwrap(0)
  let month = int.parse(month_str) |> result.unwrap(0)

  // Validate ranges
  case year < 1970 || year > 2100 || month < 1 || month > 12 {
    True -> error_response(400, "Invalid year or month")
    False -> {
      // TODO: Extract access_token from Authorization header
      // For now, return not implemented
      error_response(501, "Authentication not yet implemented")
  }
}

// ============================================================================
// POST /api/fatsecret/exercise-entries/commit/:date - Commit day (3-legged)
// ============================================================================

/// Commit exercise entries for a specific date
///
/// ## Example Request
/// ```
/// POST /api/fatsecret/exercise-entries/commit/2025-12-14
/// Headers:
///   Authorization: Bearer {access_token}
/// ```
///
/// ## Example Response
/// ```json
/// {
///   "success": true
/// }
/// ```
pub fn handle_commit_exercise_day(req: wisp.Request) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Post)

  // TODO: Extract access_token from Authorization header
  // For now, return not implemented
  error_response(501, "Authentication not yet implemented")
}

// ============================================================================
// POST /api/fatsecret/exercise-entries/template - Save template (3-legged)
// ============================================================================

/// Save exercise entries as a template
///
/// ## Example Request
/// ```
/// POST /api/fatsecret/exercise-entries/template
/// Headers:
///   Authorization: Bearer {access_token}
///   Content-Type: application/json
/// Body:
/// {
///   "template_name": "Morning Routine",
///   "exercise_entry_ids": ["123456", "123457"]
/// }
/// ```
///
/// ## Example Response
/// ```json
/// {
///   "success": true
/// }
/// ```
pub fn handle_save_exercise_template(req: wisp.Request) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Post)

  // TODO: Extract access_token from Authorization header
  // TODO: Parse JSON body for template_name and exercise_entry_ids
  // For now, return not implemented
  error_response(501, "Authentication not yet implemented")
}

// ============================================================================
// Helper Functions
// ============================================================================

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
