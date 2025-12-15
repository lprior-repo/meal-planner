/// HTTP handlers for FatSecret Profile endpoints
///
/// Routes:
///   POST /api/fatsecret/profile - Create user profile
///   GET /api/fatsecret/profile/auth/:user_id - Get profile auth status
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http.{Get, Post}
import gleam/json
import gleam/option.{None, Some}
import meal_planner/fatsecret/profile/service
import meal_planner/fatsecret/profile/types
import pog
import wisp.{type Request, type Response}

// ============================================================================
// POST /api/fatsecret/profile - Create user profile
// ============================================================================

/// POST /api/fatsecret/profile - Create a new FatSecret profile
///
/// Request body (JSON):
/// ```json
/// {
///   "user_id": "user-12345"
/// }
/// ```
///
/// Response on success (200):
/// ```json
/// {
///   "success": true,
///   "auth_token": "***REMOVED***",
///   "auth_secret": "cadff7ef247744b4bff48fb2489451fc"
/// }
/// ```
///
/// Error responses:
/// - 400: Invalid request (missing user_id)
/// - 401: Not connected or auth revoked
/// - 500: Server error
pub fn create_profile(req: Request, conn: pog.Connection) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Post)
  use body <- wisp.require_json(req)

  case parse_profile_create_input(body) {
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

    Ok(user_id) -> {
      case service.create_profile(conn, user_id) {
        Ok(auth) ->
          wisp.json_response(
            json.to_string(profile_auth_to_json(True, auth)),
            200,
          )

        Error(e) -> error_response(e)
      }
    }
  }
}

// ============================================================================
// GET /api/fatsecret/profile/auth/:user_id - Get profile auth status
// ============================================================================

/// GET /api/fatsecret/profile/auth/:user_id - Get profile authentication credentials
///
/// Example: GET /api/fatsecret/profile/auth/user-12345
///
/// Response on success (200):
/// ```json
/// {
///   "auth_token": "***REMOVED***",
///   "auth_secret": "cadff7ef247744b4bff48fb2489451fc"
/// }
/// ```
///
/// Error responses:
/// - 401: Not connected or auth revoked
/// - 500: Server error
pub fn get_profile_auth(
  req: Request,
  conn: pog.Connection,
  user_id: String,
) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Get)

  case service.get_profile_auth(conn, user_id) {
    Ok(auth) -> wisp.json_response(json.to_string(auth_to_json(auth)), 200)

    Error(e) -> error_response(e)
  }
}

// ============================================================================
// GET /api/fatsecret/profile - Get user profile
// ============================================================================

/// GET /api/fatsecret/profile - Get the current user's FatSecret profile
///
/// Response on success (200):
/// ```json
/// {
///   "goal_weight_kg": 75.5,
///   "last_weight_kg": 80.2,
///   "last_weight_date_int": 20251214,
///   "last_weight_comment": "Woohoo!",
///   "height_cm": 175.0,
///   "calorie_goal": 2000,
///   "weight_measure": "Kg",
///   "height_measure": "Cm"
/// }
/// ```
///
/// Error responses:
/// - 401: Not connected or auth revoked
/// - 500: Server error
pub fn get_profile(req: Request, conn: pog.Connection) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Get)

  case service.get_profile(conn) {
    Ok(profile) ->
      wisp.json_response(json.to_string(profile_to_json(profile)), 200)

    Error(e) -> error_response(e)
  }
}

// ============================================================================
// Routing Function
// ============================================================================

/// Route profile requests to appropriate handler
pub fn handle_profile_routes(req: Request, conn: pog.Connection) -> Response {
  case wisp.path_segments(req) {
    ["api", "fatsecret", "profile"] -> create_profile(req, conn)
    ["api", "fatsecret", "profile", "auth", user_id] ->
      get_profile_auth(req, conn, user_id)
    _ -> wisp.not_found()
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Parse ProfileCreateInput from JSON request body
fn parse_profile_create_input(body: dynamic.Dynamic) -> Result(String, String) {
  let decoder = {
    use user_id <- decode.field("user_id", decode.string)
    decode.success(user_id)
  }

  case decode.run(body, decoder) {
    Error(_) -> Error("Invalid request body - missing 'user_id' field")
    Ok(user_id) -> Ok(user_id)
  }
}

/// Convert ProfileAuth to JSON with success flag
fn profile_auth_to_json(success: Bool, auth: types.ProfileAuth) -> json.Json {
  json.object([
    #("success", json.bool(success)),
    #("auth_token", json.string(auth.auth_token)),
    #("auth_secret", json.string(auth.auth_secret)),
  ])
}

/// Convert ProfileAuth to JSON response
fn auth_to_json(auth: types.ProfileAuth) -> json.Json {
  json.object([
    #("auth_token", json.string(auth.auth_token)),
    #("auth_secret", json.string(auth.auth_secret)),
  ])
}

/// Convert Profile to JSON response
fn profile_to_json(profile: types.Profile) -> json.Json {
  json.object([
    #("goal_weight_kg", case profile.goal_weight_kg {
      Some(w) -> json.float(w)
      None -> json.null()
    }),
    #("last_weight_kg", case profile.last_weight_kg {
      Some(w) -> json.float(w)
      None -> json.null()
    }),
    #("last_weight_date_int", case profile.last_weight_date_int {
      Some(d) -> json.int(d)
      None -> json.null()
    }),
    #("last_weight_comment", case profile.last_weight_comment {
      Some(c) -> json.string(c)
      None -> json.null()
    }),
    #("height_cm", case profile.height_cm {
      Some(h) -> json.float(h)
      None -> json.null()
    }),
    #("calorie_goal", case profile.calorie_goal {
      Some(c) -> json.int(c)
      None -> json.null()
    }),
    #("weight_measure", case profile.weight_measure {
      Some(m) -> json.string(m)
      None -> json.null()
    }),
    #("height_measure", case profile.height_measure {
      Some(m) -> json.string(m)
      None -> json.null()
    }),
  ])
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
                "FatSecret account not connected. Please authorize first.",
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
