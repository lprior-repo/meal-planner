/// HTTP handler for FatSecret Food Diary copy meal endpoint
///
/// Routes:
///   POST /api/fatsecret/diary/copy-meal - Copy entries between meal types
import gleam/dynamic/decode
import gleam/http.{Post}
import gleam/json
import meal_planner/fatsecret/diary/service
import meal_planner/fatsecret/diary/types
import pog
import wisp.{type Request, type Response}

// ============================================================================
// POST /api/fatsecret/diary/copy-meal - Copy entries between meal types
// ============================================================================

/// POST /api/fatsecret/diary/copy-meal - Copy entries from one meal to another
///
/// Request body (JSON):
/// ```json
/// {
///   "from_date_int": 19723,
///   "from_meal": "lunch",
///   "to_date_int": 19724,
///   "to_meal": "dinner"
/// }
/// ```
///
/// Returns:
/// - 200: Success
/// - 400: Invalid request
/// - 401: Not connected or auth revoked
/// - 500: Server error
pub fn copy_meal(req: Request, conn: pog.Connection) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Post)
  use body <- wisp.require_json(req)

  let decoder = {
    use from_date_int <- decode.field("from_date_int", decode.int)
    use from_meal_str <- decode.field("from_meal", decode.string)
    use to_date_int <- decode.field("to_date_int", decode.int)
    use to_meal_str <- decode.field("to_meal", decode.string)
    decode.success(#(from_date_int, from_meal_str, to_date_int, to_meal_str))
  }

  case decode.run(body, decoder) {
    Error(_) ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("error", json.string("invalid_request")),
            #(
              "message",
              json.string(
                "Missing required fields: from_date_int, from_meal, to_date_int, to_meal",
              ),
            ),
          ]),
        ),
        400,
      )

    Ok(#(from_date_int, from_meal_str, to_date_int, to_meal_str)) -> {
      // Parse meal types
      case
        types.meal_type_from_string(from_meal_str),
        types.meal_type_from_string(to_meal_str)
      {
        Error(_), _ | _, Error(_) ->
          wisp.json_response(
            json.to_string(
              json.object([
                #("error", json.string("invalid_request")),
                #(
                  "message",
                  json.string(
                    "Invalid meal type. Use: breakfast, lunch, dinner, or other",
                  ),
                ),
              ]),
            ),
            400,
          )

        Ok(from_meal), Ok(to_meal) -> {
          case
            service.copy_meal(
              conn,
              from_date_int,
              from_meal,
              to_date_int,
              to_meal,
            )
          {
            Ok(_) ->
              wisp.json_response(
                json.to_string(
                  json.object([
                    #("success", json.bool(True)),
                    #("message", json.string("Meal copied successfully")),
                  ]),
                ),
                200,
              )

            Error(e) -> error_response(e)
          }
        }
      }
    }
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

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
