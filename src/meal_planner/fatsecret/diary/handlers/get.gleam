/// GET handler for single food diary entry
///
/// Route:
///   GET /api/fatsecret/diary/entries/:entry_id
import gleam/http.{Get}
import gleam/json
import gleam/option.{None, Some}
import meal_planner/fatsecret/diary/service
import meal_planner/fatsecret/diary/types.{type FoodEntry}
import pog
import wisp.{type Request, type Response}

/// GET /api/fatsecret/diary/entries/:entry_id - Get a food entry by ID
///
/// Returns:
/// ```json
/// {
///   "food_entry_id": "123456",
///   "food_entry_name": "Chicken Breast",
///   "food_entry_description": "Per 100g - Calories: 165kcal | Fat: 3.6g | Carbs: 0g | Protein: 31g",
///   "food_id": "4142",
///   "serving_id": "12345",
///   "number_of_units": 1.5,
///   "meal": "dinner",
///   "date_int": 19723,
///   "calories": 248.0,
///   "carbohydrate": 0.0,
///   "protein": 46.5,
///   "fat": 5.4,
///   "saturated_fat": 1.2,
///   "polyunsaturated_fat": 0.8,
///   "monounsaturated_fat": 1.5,
///   "cholesterol": 110.0,
///   "sodium": 95.0,
///   "potassium": 420.0,
///   "fiber": 0.0,
///   "sugar": 0.0
/// }
/// ```
pub fn get_entry(
  req: Request,
  conn: pog.Connection,
  entry_id: String,
) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Get)
  let entry_id_obj = types.food_entry_id(entry_id)
  case service.get_food_entry(conn, entry_id_obj) {
    Ok(entry) ->
      wisp.json_response(json.to_string(food_entry_to_json(entry)), 200)

    Error(e) -> error_response(e)
  }
}

/// Convert FoodEntry to JSON representation
fn food_entry_to_json(entry: FoodEntry) -> json.Json {
  json.object([
    #(
      "food_entry_id",
      json.string(types.food_entry_id_to_string(entry.food_entry_id)),
    ),
    #("food_entry_name", json.string(entry.food_entry_name)),
    #("food_entry_description", json.string(entry.food_entry_description)),
    #("food_id", json.string(entry.food_id)),
    #("serving_id", json.string(entry.serving_id)),
    #("number_of_units", json.float(entry.number_of_units)),
    #("meal", json.string(types.meal_type_to_string(entry.meal))),
    #("date_int", json.int(entry.date_int)),
    #("calories", json.float(entry.calories)),
    #("carbohydrate", json.float(entry.carbohydrate)),
    #("protein", json.float(entry.protein)),
    #("fat", json.float(entry.fat)),
    #("saturated_fat", case entry.saturated_fat {
      Some(f) -> json.float(f)
      None -> json.null()
    }),
    #("polyunsaturated_fat", case entry.polyunsaturated_fat {
      Some(f) -> json.float(f)
      None -> json.null()
    }),
    #("monounsaturated_fat", case entry.monounsaturated_fat {
      Some(f) -> json.float(f)
      None -> json.null()
    }),
    #("cholesterol", case entry.cholesterol {
      Some(f) -> json.float(f)
      None -> json.null()
    }),
    #("sodium", case entry.sodium {
      Some(f) -> json.float(f)
      None -> json.null()
    }),
    #("potassium", case entry.potassium {
      Some(f) -> json.float(f)
      None -> json.null()
    }),
    #("fiber", case entry.fiber {
      Some(f) -> json.float(f)
      None -> json.null()
    }),
    #("sugar", case entry.sugar {
      Some(f) -> json.float(f)
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
