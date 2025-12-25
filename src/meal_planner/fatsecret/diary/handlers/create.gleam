/// HTTP handler for creating FatSecret Food Diary entries
///
/// POST /api/fatsecret/diary/entries - Create food entry
import gleam/http.{Post}
import gleam/json
import meal_planner/fatsecret/diary/decoders
import meal_planner/fatsecret/diary/service
import meal_planner/fatsecret/diary/types
import pog
import wisp.{type Request, type Response}

/// POST /api/fatsecret/diary/entries - Create a new food diary entry
///
/// Request body (JSON):
/// ```json
/// {
///   "type": "from_food",  // or "custom"
///   "food_id": "4142",    // Required for from_food
///   "serving_id": "12345", // Required for from_food
///   "number_of_units": 1.5,
///   "meal": "lunch",      // breakfast, lunch, dinner, snack
///   "date": "2024-01-15"  // Optional, defaults to today
/// }
/// ```
///
/// Or for custom entries:
/// ```json
/// {
///   "type": "custom",
///   "food_entry_name": "Custom Salad",
///   "serving_description": "Large bowl",
///   "number_of_units": 1.0,
///   "meal": "lunch",
///   "date": "2024-01-15",
///   "calories": 350.0,
///   "carbohydrate": 40.0,
///   "protein": 15.0,
///   "fat": 8.0
/// }
/// ```
///
/// Returns:
/// - 200: Success with entry ID
/// - 400: Invalid request
/// - 401: Not connected or auth revoked
/// - 500: Server error
pub fn create_entry(req: Request, conn: pog.Connection) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Post)
  use body <- wisp.require_json(req)

  case decoders.parse_food_entry_input(body) {
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

    Ok(input) -> {
      case service.create_food_entry(conn, input) {
        Ok(entry_id) ->
          wisp.json_response(
            json.to_string(
              json.object([
                #("success", json.bool(True)),
                #(
                  "entry_id",
                  json.string(types.food_entry_id_to_string(entry_id)),
                ),
                #("message", json.string("Entry created successfully")),
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
