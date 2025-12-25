/// HTTP handler for creating FatSecret Food Diary entries
///
/// POST /api/fatsecret/diary/entries - Create food entry
import birl
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http.{Post}
import gleam/int
import gleam/json
import gleam/option.{None, Some}
import meal_planner/fatsecret/diary/service
import meal_planner/fatsecret/diary/types.{type FoodEntryInput, Custom, FromFood}
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

  case parse_food_entry_input(body) {
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

/// Parse FoodEntryInput from JSON request body
fn parse_food_entry_input(
  body: dynamic.Dynamic,
) -> Result(FoodEntryInput, String) {
  let decoder = {
    use entry_type <- decode.field("type", decode.string)

    case entry_type {
      "from_food" -> {
        use food_id <- decode.field("food_id", decode.string)
        use food_entry_name <- decode.field("food_entry_name", decode.string)
        use serving_id <- decode.field("serving_id", decode.string)
        use number_of_units <- decode.field("number_of_units", decode.float)
        use meal_str <- decode.field("meal", decode.string)
        use date_str <- decode.optional_field(
          "date",
          None,
          decode.optional(decode.string),
        )

        // Parse meal type
        case types.meal_type_from_string(meal_str) {
          Error(_) ->
            decode.failure(
              FromFood(
                food_id: "",
                food_entry_name: "",
                serving_id: "",
                number_of_units: 0.0,
                meal: types.Breakfast,
                date_int: 0,
              ),
              "Invalid meal type",
            )
          Ok(meal) -> {
            // Handle date
            let date_int_result = case date_str {
              Some(ds) ->
                case types.date_to_int(ds) {
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
                case types.date_to_int(ds) {
                  Ok(di) -> Ok(di)
                  Error(_) -> Error("Failed to calculate today's date")
                }
              }
            }

            case date_int_result {
              Error(msg) ->
                decode.failure(
                  FromFood(
                    food_id: "",
                    food_entry_name: "",
                    serving_id: "",
                    number_of_units: 0.0,
                    meal: meal,
                    date_int: 0,
                  ),
                  msg,
                )
              Ok(date_int) ->
                decode.success(FromFood(
                  food_id: food_id,
                  food_entry_name: food_entry_name,
                  serving_id: serving_id,
                  number_of_units: number_of_units,
                  meal: meal,
                  date_int: date_int,
                ))
            }
          }
        }
      }

      "custom" -> {
        use food_entry_name <- decode.field("food_entry_name", decode.string)
        use serving_description <- decode.field(
          "serving_description",
          decode.string,
        )
        use number_of_units <- decode.field("number_of_units", decode.float)
        use meal_str <- decode.field("meal", decode.string)
        use date_str <- decode.optional_field(
          "date",
          None,
          decode.optional(decode.string),
        )
        use calories <- decode.field("calories", decode.float)
        use carbohydrate <- decode.field("carbohydrate", decode.float)
        use protein <- decode.field("protein", decode.float)
        use fat <- decode.field("fat", decode.float)

        // Parse meal type
        case types.meal_type_from_string(meal_str) {
          Error(_) ->
            decode.failure(
              Custom(
                food_entry_name: "",
                serving_description: "",
                number_of_units: 0.0,
                meal: types.Breakfast,
                date_int: 0,
                calories: 0.0,
                carbohydrate: 0.0,
                protein: 0.0,
                fat: 0.0,
              ),
              "Invalid meal type",
            )
          Ok(meal) -> {
            // Handle date
            let date_int_result = case date_str {
              Some(ds) ->
                case types.date_to_int(ds) {
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
                case types.date_to_int(ds) {
                  Ok(di) -> Ok(di)
                  Error(_) -> Error("Failed to calculate today's date")
                }
              }
            }

            case date_int_result {
              Error(msg) ->
                decode.failure(
                  Custom(
                    food_entry_name: "",
                    serving_description: "",
                    number_of_units: 0.0,
                    meal: meal,
                    date_int: 0,
                    calories: 0.0,
                    carbohydrate: 0.0,
                    protein: 0.0,
                    fat: 0.0,
                  ),
                  msg,
                )
              Ok(date_int) ->
                decode.success(Custom(
                  food_entry_name: food_entry_name,
                  serving_description: serving_description,
                  number_of_units: number_of_units,
                  meal: meal,
                  date_int: date_int,
                  calories: calories,
                  carbohydrate: carbohydrate,
                  protein: protein,
                  fat: fat,
                ))
            }
          }
        }
      }

      _ ->
        decode.failure(
          FromFood(
            food_id: "",
            food_entry_name: "",
            serving_id: "",
            number_of_units: 0.0,
            meal: types.Breakfast,
            date_int: 0,
          ),
          "Entry type must be 'from_food' or 'custom'",
        )
    }
  }

  case decode.run(body, decoder) {
    Error(_) -> Error("Invalid request body - missing required fields")
    Ok(input) -> Ok(input)
  }
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

/// Pad single digit numbers with leading zero
fn pad_zero(n: Int) -> String {
  case n < 10 {
    True -> "0" <> int.to_string(n)
    False -> int.to_string(n)
  }
}
