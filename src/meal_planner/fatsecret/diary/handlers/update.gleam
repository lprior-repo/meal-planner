/// HTTP handler for updating FatSecret Food Diary entries
///
/// Routes:
///   PATCH /api/fatsecret/diary/entries/:entry_id - Edit entry
import gleam/http.{Patch}
import gleam/json
import meal_planner/fatsecret/diary/decoders
import meal_planner/fatsecret/diary/service
import meal_planner/fatsecret/diary/types
import pog
import wisp.{type Request, type Response}

// ============================================================================
// PATCH /api/fatsecret/diary/entries/:entry_id - Edit entry
// ============================================================================

/// PATCH /api/fatsecret/diary/entries/:entry_id - Update a food entry
///
/// Request body (JSON):
/// ```json
/// {
///   "number_of_units": 2.0,
///   "meal": "dinner"
/// }
/// ```
/// Both fields are optional.
///
/// Returns:
/// - 200: Success
/// - 400: Invalid request
/// - 401: Not connected or auth revoked
/// - 500: Server error
pub fn update_entry(
  req: Request,
  conn: pog.Connection,
  entry_id: String,
) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Patch)
  use body <- wisp.require_json(req)

  case decoders.parse_food_entry_update(body) {
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
      let entry_id_obj = types.food_entry_id(entry_id)
      case service.update_food_entry(conn, entry_id_obj, update) {
        Ok(_) ->
          wisp.json_response(
            json.to_string(
              json.object([
                #("success", json.bool(True)),
                #("message", json.string("Entry updated successfully")),
              ]),
            ),
            200,
          )

        Error(e) -> error_response(e)
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
