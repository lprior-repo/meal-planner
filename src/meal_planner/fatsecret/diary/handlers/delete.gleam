/// HTTP handler for deleting FatSecret Food Diary entries
///
/// Routes:
///   DELETE /api/fatsecret/diary/entries/:entry_id - Delete entry
import gleam/http.{Delete}
import gleam/json
import meal_planner/fatsecret/diary/service
import meal_planner/fatsecret/diary/types
import pog
import wisp.{type Request, type Response}

// ============================================================================
// DELETE /api/fatsecret/diary/entries/:entry_id - Delete entry
// ============================================================================

/// DELETE /api/fatsecret/diary/entries/:entry_id - Delete a food entry
///
/// Returns:
/// - 200: Success
/// - 401: Not connected or auth revoked
/// - 500: Server error
pub fn delete_entry(
  req: Request,
  conn: pog.Connection,
  entry_id: String,
) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Delete)
  let entry_id_obj = types.food_entry_id(entry_id)
  case service.delete_food_entry(conn, entry_id_obj) {
    Ok(_) ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("success", json.bool(True)),
            #("message", json.string("Entry deleted successfully")),
          ]),
        ),
        200,
      )

    Error(e) -> error_response(e)
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
