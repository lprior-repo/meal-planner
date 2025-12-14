/// HTTP handlers for FatSecret Food Diary endpoints
///
/// Routes:
///   POST /api/fatsecret/diary/entries - Create food entry
///   GET /api/fatsecret/diary/entries/:entry_id - Get single entry
///   PATCH /api/fatsecret/diary/entries/:entry_id - Edit entry
///   DELETE /api/fatsecret/diary/entries/:entry_id - Delete entry
///   GET /api/fatsecret/diary/day/:date_int - Get all entries for date
///   GET /api/fatsecret/diary/month/:date_int - Get month summary
import birl
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http.{Delete, Get, Patch, Post}
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import meal_planner/fatsecret/diary/service
import meal_planner/fatsecret/diary/types.{
  type FoodEntry, type FoodEntryId, type FoodEntryInput, type FoodEntryUpdate,
  type MealType, Custom, FromFood,
}
import pog
import wisp.{type Request, type Response}

// ============================================================================
// POST /api/fatsecret/diary/entries - Create food entry
// ============================================================================

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
  case req.method {
    Post -> {
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
    _ -> wisp.method_not_allowed([Post])
  }
}

// ============================================================================
// GET /api/fatsecret/diary/entries/:entry_id - Get single entry
// ============================================================================

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
pub fn get_entry(req: Request, conn: pog.Connection, entry_id: String) -> Response {
  case req.method {
    Get -> {
      let entry_id_obj = types.food_entry_id(entry_id)
      case service.get_food_entry(conn, entry_id_obj) {
        Ok(entry) ->
          wisp.json_response(
            json.to_string(food_entry_to_json(entry)),
            200,
          )

        Error(e) -> error_response(e)
      }
    }
    _ -> wisp.method_not_allowed([Get])
  }
}

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
  case req.method {
    Patch -> {
      use body <- wisp.require_json(req)

      case parse_food_entry_update(body) {
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
    _ -> wisp.method_not_allowed([Patch])
  }
}

// ============================================================================
// DELETE /api/fatsecret/diary/entries/:entry_id - Delete entry
// ============================================================================

/// DELETE /api/fatsecret/diary/entries/:entry_id - Delete a food entry
///
/// Returns:
/// - 200: Success
/// - 401: Not connected or auth revoked
/// - 500: Server error
pub fn delete_entry(req: Request, conn: pog.Connection, entry_id: String) -> Response {
  case req.method {
    Delete -> {
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
    _ -> wisp.method_not_allowed([Delete])
  }
}

// ============================================================================
// GET /api/fatsecret/diary/day/:date_int - Get all entries for date
// ============================================================================

/// GET /api/fatsecret/diary/day/:date_int - Get all food entries for a date
///
/// Example: GET /api/fatsecret/diary/day/19723
///
/// Returns:
/// ```json
/// {
///   "date_int": 19723,
///   "date": "2024-01-01",
///   "entries": [
///     { "food_entry_id": "123456", "food_entry_name": "Chicken", ... },
///     { "food_entry_id": "123457", "food_entry_name": "Rice", ... }
///   ],
///   "totals": {
///     "calories": 2100.0,
///     "carbohydrate": 200.0,
///     "protein": 150.0,
///     "fat": 70.0
///   }
/// }
/// ```
pub fn get_day(req: Request, conn: pog.Connection, date_int_str: String) -> Response {
  case req.method {
    Get -> {
      case int.parse(date_int_str) {
        Error(_) ->
          wisp.json_response(
            json.to_string(
              json.object([
                #("error", json.string("invalid_parameters")),
                #("message", json.string("date_int must be a valid integer")),
              ]),
            ),
            400,
          )

        Ok(date_int) -> {
          case service.get_day_entries(conn, date_int) {
            Ok(entries) -> {
              // Calculate totals
              let totals = calculate_day_totals(entries)
              let date_str = types.int_to_date(date_int)

              let entries_json = list.map(entries, fn(entry) {
                food_entry_to_json(entry)
              })

              wisp.json_response(
                json.to_string(
                  json.object([
                    #("date_int", json.int(date_int)),
                    #("date", json.string(date_str)),
                    #("entries", json.array(entries_json, fn(x) { x })),
                    #(
                      "totals",
                      json.object([
                        #("calories", json.float(totals.calories)),
                        #("carbohydrate", json.float(totals.carbohydrate)),
                        #("protein", json.float(totals.protein)),
                        #("fat", json.float(totals.fat)),
                      ]),
                    ),
                  ]),
                ),
                200,
              )
            }

            Error(e) -> error_response(e)
          }
        }
      }
    }
    _ -> wisp.method_not_allowed([Get])
  }
}

// ============================================================================
// GET /api/fatsecret/diary/month/:date_int - Get month summary
// ============================================================================

/// GET /api/fatsecret/diary/month/:date_int - Get monthly nutrition summary
///
/// Example: GET /api/fatsecret/diary/month/19723
///
/// Returns:
/// ```json
/// {
///   "month": 1,
///   "year": 2024,
///   "days": [
///     { "date_int": 19723, "date": "2024-01-01", "calories": 2100.0, "carbohydrate": 200.0, "protein": 150.0, "fat": 70.0 },
///     { "date_int": 19724, "date": "2024-01-02", "calories": 1950.0, "carbohydrate": 180.0, "protein": 140.0, "fat": 65.0 }
///   ]
/// }
/// ```
pub fn get_month(req: Request, conn: pog.Connection, date_int_str: String) -> Response {
  case req.method {
    Get -> {
      case int.parse(date_int_str) {
        Error(_) ->
          wisp.json_response(
            json.to_string(
              json.object([
                #("error", json.string("invalid_parameters")),
                #("message", json.string("date_int must be a valid integer")),
              ]),
            ),
            400,
          )

        Ok(date_int) -> {
          case service.get_month_summary(conn, date_int) {
            Ok(summary) -> {
              let days_json = list.map(summary.days, fn(day) {
                json.object([
                  #("date_int", json.int(day.date_int)),
                  #("date", json.string(types.int_to_date(day.date_int))),
                  #("calories", json.float(day.calories)),
                  #("carbohydrate", json.float(day.carbohydrate)),
                  #("protein", json.float(day.protein)),
                  #("fat", json.float(day.fat)),
                ])
              })

              wisp.json_response(
                json.to_string(
                  json.object([
                    #("month", json.int(summary.month)),
                    #("year", json.int(summary.year)),
                    #("days", json.array(days_json, fn(x) { x })),
                  ]),
                ),
                200,
              )
            }

            Error(e) -> error_response(e)
          }
        }
      }
    }
    _ -> wisp.method_not_allowed([Get])
  }
}

// ============================================================================
// Routing Function
// ============================================================================

/// Route diary requests to appropriate handler
pub fn handle_diary_routes(req: Request, conn: pog.Connection) -> Response {
  case wisp.path_segments(req) {
    ["api", "fatsecret", "diary", "entries"] -> create_entry(req, conn)
    ["api", "fatsecret", "diary", "entries", entry_id] ->
      case req.method {
        Get -> get_entry(req, conn, entry_id)
        Patch -> update_entry(req, conn, entry_id)
        Delete -> delete_entry(req, conn, entry_id)
        _ -> wisp.method_not_allowed([Get, Patch, Delete])
      }
    ["api", "fatsecret", "diary", "day", date_int] -> get_day(req, conn, date_int)
    ["api", "fatsecret", "diary", "month", date_int] -> get_month(req, conn, date_int)
    _ -> wisp.not_found()
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Parse FoodEntryInput from JSON request body
fn parse_food_entry_input(body: dynamic.Dynamic) -> Result(FoodEntryInput, String) {
  let decoder = {
    use entry_type <- decode.field("type", decode.string)

    case entry_type {
      "from_food" -> {
        use food_id <- decode.field("food_id", decode.string)
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
            decode.failure(FromFood(
              food_id: "",
              serving_id: "",
              number_of_units: 0.0,
              meal: types.Breakfast,
              date_int: 0,
            ), "Invalid meal type")
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
              Error(msg) -> decode.failure(FromFood(
                food_id: "",
                serving_id: "",
                number_of_units: 0.0,
                meal: meal,
                date_int: 0,
              ), msg)
              Ok(date_int) ->
                decode.success(FromFood(
                  food_id: food_id,
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
            decode.failure(Custom(
              food_entry_name: "",
              serving_description: "",
              number_of_units: 0.0,
              meal: types.Breakfast,
              date_int: 0,
              calories: 0.0,
              carbohydrate: 0.0,
              protein: 0.0,
              fat: 0.0,
            ), "Invalid meal type")
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
              Error(msg) -> decode.failure(Custom(
                food_entry_name: "",
                serving_description: "",
                number_of_units: 0.0,
                meal: meal,
                date_int: 0,
                calories: 0.0,
                carbohydrate: 0.0,
                protein: 0.0,
                fat: 0.0,
              ), msg)
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
        decode.failure(FromFood(
          food_id: "",
          serving_id: "",
          number_of_units: 0.0,
          meal: types.Breakfast,
          date_int: 0,
        ), "Entry type must be 'from_food' or 'custom'")
    }
  }

  case decode.run(body, decoder) {
    Error(_) ->
      Error("Invalid request body - missing required fields")
    Ok(input) -> Ok(input)
  }
}

/// Parse FoodEntryUpdate from JSON request body
fn parse_food_entry_update(body: dynamic.Dynamic) -> Result(FoodEntryUpdate, String) {
  let decoder = {
    use number_of_units <- decode.optional_field(
      "number_of_units",
      None,
      decode.optional(decode.float),
    )
    use meal_str <- decode.optional_field(
      "meal",
      None,
      decode.optional(decode.string),
    )

    // Parse meal type if provided
    let meal_result = case meal_str {
      None -> Ok(None)
      Some(ms) ->
        case types.meal_type_from_string(ms) {
          Ok(m) -> Ok(Some(m))
          Error(_) -> Error("Invalid meal type")
        }
    }

    case meal_result {
      Error(msg) ->
        decode.failure(types.FoodEntryUpdate(number_of_units: None, meal: None), msg)
      Ok(meal) ->
        decode.success(types.FoodEntryUpdate(
          number_of_units: number_of_units,
          meal: meal,
        ))
    }
  }

  case decode.run(body, decoder) {
    Error(_) -> Error("Invalid request body")
    Ok(update) -> Ok(update)
  }
}

/// Convert FoodEntry to JSON representation
fn food_entry_to_json(entry: FoodEntry) -> json.Json {
  json.object([
    #("food_entry_id", json.string(types.food_entry_id_to_string(entry.food_entry_id))),
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
    #(
      "saturated_fat",
      case entry.saturated_fat {
        Some(f) -> json.float(f)
        None -> json.null()
      },
    ),
    #(
      "polyunsaturated_fat",
      case entry.polyunsaturated_fat {
        Some(f) -> json.float(f)
        None -> json.null()
      },
    ),
    #(
      "monounsaturated_fat",
      case entry.monounsaturated_fat {
        Some(f) -> json.float(f)
        None -> json.null()
      },
    ),
    #(
      "cholesterol",
      case entry.cholesterol {
        Some(f) -> json.float(f)
        None -> json.null()
      },
    ),
    #(
      "sodium",
      case entry.sodium {
        Some(f) -> json.float(f)
        None -> json.null()
      },
    ),
    #(
      "potassium",
      case entry.potassium {
        Some(f) -> json.float(f)
        None -> json.null()
      },
    ),
    #(
      "fiber",
      case entry.fiber {
        Some(f) -> json.float(f)
        None -> json.null()
      },
    ),
    #(
      "sugar",
      case entry.sugar {
        Some(f) -> json.float(f)
        None -> json.null()
      },
    ),
  ])
}

/// Daily nutrition totals
type DayTotals {
  DayTotals(calories: Float, carbohydrate: Float, protein: Float, fat: Float)
}

/// Calculate daily totals from entries
fn calculate_day_totals(entries: List(FoodEntry)) -> DayTotals {
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

    service.ApiError(_)
    | service.StorageError(_) ->
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
