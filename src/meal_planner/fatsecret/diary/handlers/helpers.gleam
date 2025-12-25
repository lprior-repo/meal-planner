/// Shared helper functions for FatSecret diary handlers
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import meal_planner/fatsecret/diary/service
import meal_planner/fatsecret/diary/types.{type FoodEntry}
import wisp.{type Response}

// ============================================================================
// Helper Types
// ============================================================================

/// Daily nutrition totals
pub type DayTotals {
  DayTotals(calories: Float, carbohydrate: Float, protein: Float, fat: Float)
}

// ============================================================================
// Public Helper Functions
// ============================================================================

/// Convert FoodEntry to JSON representation
pub fn food_entry_to_json(entry: FoodEntry) -> json.Json {
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

/// Calculate daily totals from entries
pub fn calculate_day_totals(entries: List(FoodEntry)) -> DayTotals {
  list.fold(entries, DayTotals(0.0, 0.0, 0.0, 0.0), fn(totals, entry) {
    DayTotals(
      calories: totals.calories +. entry.calories,
      carbohydrate: totals.carbohydrate +. entry.carbohydrate,
      protein: totals.protein +. entry.protein,
      fat: totals.fat +. entry.fat,
    )
  })
}

/// Convert service error to HTTP error response
pub fn error_response(error: service.ServiceError) -> Response {
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
