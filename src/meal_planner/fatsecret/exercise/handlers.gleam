//// HTTP handlers for FatSecret Exercise endpoints
////
//// Routes:
////   GET /api/fatsecret/exercises - List exercise entries
////   POST /api/fatsecret/exercise-entries - Create exercise entry
////   GET /api/fatsecret/exercise-entries/:entry_id - Get single entry
////   PUT /api/fatsecret/exercise-entries/:entry_id - Update entry
////   DELETE /api/fatsecret/exercise-entries/:entry_id - Delete entry

import gleam/dynamic
import gleam/http.{Delete, Get, Post, Put}
import gleam/json
import pog
import wisp.{type Request, type Response}

// ============================================================================
// GET /api/fatsecret/exercises - List exercise entries
// ============================================================================

/// GET /api/fatsecret/exercises - List all exercise entries for the user
///
/// Query parameters (optional):
///   - date_int: Filter by specific date (e.g., 19723)
///   - limit: Max results (default: 50)
///   - offset: Pagination offset (default: 0)
///
/// Authorization: Requires valid OAuth token in Authorization header
///
/// Returns:
/// - 200: List of exercise entries
/// - 401: Not authorized or auth revoked
/// - 500: Server error
pub fn get_exercises(req: Request, _conn: pog.Connection) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Get)

  // Extract authorization header (TODO: implement auth validation)
  let _auth_header = ""

  // TODO: Parse query parameters (date_int, limit, offset)
  // TODO: Fetch exercises from FatSecret API
  // TODO: Build JSON response

  wisp.not_found()
}

// ============================================================================
// POST /api/fatsecret/exercise-entries - Create exercise entry
// ============================================================================

/// POST /api/fatsecret/exercise-entries - Create a new exercise entry
///
/// Request body (JSON):
/// ```json
/// {
///   "exercise_id": "12345",  // FatSecret exercise ID
///   "minutes": 30.0,
///   "date": "2024-01-15",    // Optional, defaults to today
///   "calories_burned": 250.0 // Optional, can be calculated
/// }
/// ```
///
/// Authorization: Requires valid OAuth token in Authorization header
///
/// Returns:
/// - 200: Success with entry ID
/// - 400: Invalid request
/// - 401: Not authorized
/// - 500: Server error
pub fn create_exercise_entry(req: Request, _conn: pog.Connection) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Post)
  use body <- wisp.require_json(req)

  // Extract authorization header (TODO: implement auth validation)
  let _auth_header = ""

  // TODO: Parse request body
  // TODO: Validate exercise_id exists in FatSecret
  // TODO: Create entry in database
  // TODO: Build success response

  case parse_exercise_entry_input(body) {
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

    Ok(_input) -> wisp.not_found()
  }
}

// ============================================================================
// GET /api/fatsecret/exercise-entries/:entry_id - Get single entry
// ============================================================================

/// GET /api/fatsecret/exercise-entries/:entry_id - Get an exercise entry by ID
///
/// Authorization: Requires valid OAuth token in Authorization header
///
/// Returns:
/// ```json
/// {
///   "exercise_entry_id": "123456",
///   "exercise_id": "12345",
///   "exercise_name": "Running",
///   "minutes": 30.0,
///   "calories_burned": 250.0,
///   "date_int": 19723,
///   "date": "2024-01-01"
/// }
/// ```
///
/// Returns:
/// - 200: Exercise entry data
/// - 401: Not authorized
/// - 404: Entry not found
/// - 500: Server error
pub fn get_exercise_entry(
  req: Request,
  _conn: pog.Connection,
  entry_id: String,
) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Get)

  // Extract authorization header (TODO: implement auth validation)
  let _auth_header = ""

  // TODO: Fetch exercise entry from database
  // TODO: Build JSON response

  let _entry_id = entry_id
  wisp.not_found()
}

// ============================================================================
// PUT /api/fatsecret/exercise-entries/:entry_id - Update entry
// ============================================================================

/// PUT /api/fatsecret/exercise-entries/:entry_id - Update an exercise entry
///
/// Request body (JSON):
/// ```json
/// {
///   "minutes": 45.0,
///   "calories_burned": 380.0
/// }
/// ```
/// Both fields are optional.
///
/// Authorization: Requires valid OAuth token in Authorization header
///
/// Returns:
/// - 200: Success
/// - 400: Invalid request
/// - 401: Not authorized
/// - 404: Entry not found
/// - 500: Server error
pub fn update_exercise_entry(
  req: Request,
  _conn: pog.Connection,
  _entry_id: String,
) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Put)
  use body <- wisp.require_json(req)

  // Extract authorization header (TODO: implement auth validation)
  let _auth_header = ""

  // TODO: Parse request body
  // TODO: Validate entry exists
  // TODO: Update in database
  // TODO: Build success response

  case parse_exercise_entry_update(body) {
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

    Ok(_update) -> wisp.not_found()
  }
}

// ============================================================================
// DELETE /api/fatsecret/exercise-entries/:entry_id - Delete entry
// ============================================================================

/// DELETE /api/fatsecret/exercise-entries/:entry_id - Delete an exercise entry
///
/// Authorization: Requires valid OAuth token in Authorization header
///
/// Returns:
/// - 200: Success
/// - 401: Not authorized
/// - 404: Entry not found
/// - 500: Server error
pub fn delete_exercise_entry(
  req: Request,
  _conn: pog.Connection,
  entry_id: String,
) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Delete)

  // Extract authorization header (TODO: implement auth validation)
  let _auth_header = ""

  // TODO: Delete exercise entry from database
  // TODO: Build success response

  let _entry_id = entry_id
  wisp.not_found()
}

// ============================================================================
// Routing Function
// ============================================================================

/// Route exercise requests to appropriate handler
pub fn handle_exercise_routes(req: Request, conn: pog.Connection) -> Response {
  case wisp.path_segments(req) {
    ["api", "fatsecret", "exercises"] -> get_exercises(req, conn)
    ["api", "fatsecret", "exercise-entries"] -> create_exercise_entry(req, conn)
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
// Helper Functions
// ============================================================================

/// Parse exercise entry input from JSON request body
fn parse_exercise_entry_input(_body: dynamic.Dynamic) -> Result(Nil, String) {
  // TODO: Implement JSON parsing for exercise entry creation
  Error("Not implemented")
}

/// Parse exercise entry update from JSON request body
fn parse_exercise_entry_update(_body: dynamic.Dynamic) -> Result(Nil, String) {
  // TODO: Implement JSON parsing for exercise entry updates
  Error("Not implemented")
}
