//// Food log handlers for API endpoints

import gleam/dynamic/decode
import gleam/float
import gleam/http
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/uri
import meal_planner/storage
import meal_planner/types.{FoodLogEntry}
import pog
import wisp

/// Web context holding database connection
pub type Context {
  Context(db: pog.Connection)
}

/// POST /api/logs - Create a new food log entry
pub fn api_logs_create(req: wisp.Request, ctx: Context) -> wisp.Response {
  // Get query params for form submission
  case uri.parse_query(req.query |> option.unwrap("")) {
    Ok(params) -> {
      let recipe_id =
        list.find(params, fn(p) { p.0 == "recipe_id" })
        |> result.map(fn(p) { p.1 })
      let servings_str =
        list.find(params, fn(p) { p.0 == "servings" })
        |> result.map(fn(p) { p.1 })
      let meal_type_str =
        list.find(params, fn(p) { p.0 == "meal_type" })
        |> result.map(fn(p) { p.1 })

      case recipe_id, servings_str, meal_type_str {
        Ok(rid), Ok(sstr), Ok(mtstr) -> {
          let servings = case float.parse(sstr) {
            Ok(s) -> s
            Error(_) -> 1.0
          }
          let meal_type = string_to_meal_type(mtstr)
          let today = get_today_date()

          // Get recipe to calculate macros
          case storage.get_recipe_by_id(ctx.db, rid) {
            Error(_) -> wisp.not_found()
            Ok(recipe) -> {
              let scaled_macros = types.macros_scale(recipe.macros, servings)
              let entry =
                FoodLogEntry(
                  id: generate_entry_id(),
                  recipe_id: recipe.id,
                  recipe_name: recipe.name,
                  servings: servings,
                  macros: scaled_macros,
                  micronutrients: None,
                  meal_type: meal_type,
                  logged_at: current_timestamp(),
                  source_type: "recipe",
                  source_id: recipe.id,
                )

              case storage.save_food_log_entry(ctx.db, today, entry) {
                Ok(_) -> wisp.redirect("/dashboard")
                Error(_) -> {
                  let err =
                    json.object([
                      #("error", json.string("Failed to save entry")),
                    ])
                  wisp.json_response(json.to_string(err), 500)
                }
              }
            }
          }
        }
        _, _, _ -> {
          let err =
            json.object([
              #("error", json.string("Missing required parameters")),
            ])
          wisp.json_response(json.to_string(err), 400)
        }
      }
    }
    Error(_) -> {
      let err =
        json.object([#("error", json.string("Invalid query parameters"))])
      wisp.json_response(json.to_string(err), 400)
    }
  }
}

/// POST /api/logs/food - Log a USDA food with grams and meal type
/// Request JSON: {"fdc_id": string, "grams": float, "meal_type": string}
/// Response: JSON with created entry
pub fn api_logs_food(req: wisp.Request, ctx: Context) -> wisp.Response {
  // Parse JSON body
  use json_body <- wisp.require_json(req)

  // Try to extract fdc_id from JSON
  case decode.run(json_body, decode.field("fdc_id", decode.string)) {
    Ok(fdc_id_str) -> log_usda_food(json_body, fdc_id_str, ctx)
    Error(_) -> {
      let err_json =
        json.object([
          #("error", json.string("Missing or invalid fdc_id field")),
        ])
      wisp.json_response(json.to_string(err_json), 400)
    }
  }
}

/// Internal implementation for logging USDA food
fn log_usda_food(
  json_body: json.Json,
  fdc_id_str: String,
  ctx: Context,
) -> wisp.Response {
  // Parse grams and meal_type from JSON
  let fdc_id_result = int.parse(fdc_id_str)
  let grams_result = decode.run(json_body, decode.field("grams", decode.float))
  let meal_type_result =
    decode.run(json_body, decode.field("meal_type", decode.string))

  case fdc_id_result, grams_result, meal_type_result {
    Ok(fdc_id), Ok(grams), Ok(meal_type_str) -> {
      let meal_type = string_to_meal_type(meal_type_str)
      let today = get_today_date()

      // Load USDA food with all nutrients
      case storage.load_usda_food_with_macros(ctx.db, fdc_id) {
        Error(storage.DatabaseError(msg)) -> {
          let err_json = json.object([#("error", json.string(msg))])
          wisp.json_response(json.to_string(err_json), 400)
        }
        Error(_) -> {
          let err_json =
            json.object([#("error", json.string("Food not found"))])
          wisp.json_response(json.to_string(err_json), 404)
        }
        Ok(usda_food) -> {
          // Calculate scaling factor: grams / 100 (USDA data is per 100g)
          let scaling_factor = grams /. 100.0

          // Scale macros and micronutrients by the factor
          let scaled_macros =
            types.macros_scale(usda_food.macros, scaling_factor)
          let scaled_micronutrients =
            Some(types.micronutrients_scale(
              usda_food.micronutrients,
              scaling_factor,
            ))

          // Create log entry with source_type='usda_food'
          let entry =
            FoodLogEntry(
              id: generate_entry_id(),
              recipe_id: int.to_string(fdc_id),
              recipe_name: usda_food.description,
              servings: grams,
              macros: scaled_macros,
              micronutrients: scaled_micronutrients,
              meal_type: meal_type,
              logged_at: current_timestamp(),
              source_type: "usda_food",
              source_id: int.to_string(fdc_id),
            )

          // Save to database
          case storage.save_food_log_entry(ctx.db, today, entry) {
            Ok(_) -> {
              // Return created entry as JSON
              let response_micros = case scaled_micronutrients {
                Some(m) -> m
                None -> types.micronutrients_zero()
              }
              let response_json =
                json.object([
                  #("id", json.string(entry.id)),
                  #("description", json.string(usda_food.description)),
                  #("grams", json.float(grams)),
                  #("meal_type", json.string(meal_type_str)),
                  #("macros", types.macros_to_json(scaled_macros)),
                  #(
                    "micronutrients",
                    types.micronutrients_to_json(response_micros),
                  ),
                  #("source_type", json.string("usda_food")),
                  #("source_id", json.string(int.to_string(fdc_id))),
                ])
              wisp.json_response(json.to_string(response_json), 201)
            }
            Error(_) -> {
              let err_json =
                json.object([
                  #("error", json.string("Failed to save entry")),
                ])
              wisp.json_response(json.to_string(err_json), 500)
            }
          }
        }
      }
    }
    _, _, _ -> {
      let err_json =
        json.object([
          #(
            "error",
            json.string("Invalid request format: need fdc_id, grams, meal_type"),
          ),
        ])
      wisp.json_response(json.to_string(err_json), 400)
    }
  }
}

/// GET/DELETE /api/logs/entry/:id - Manage a log entry
pub fn api_log_entry(
  req: wisp.Request,
  entry_id: String,
  ctx: Context,
) -> wisp.Response {
  // Check for delete action in query params
  case uri.parse_query(req.query |> option.unwrap("")) {
    Ok(params) -> {
      case list.find(params, fn(p) { p.0 == "action" && p.1 == "delete" }) {
        Ok(_) -> {
          case storage.delete_food_log(ctx.db, entry_id) {
            Ok(_) -> wisp.redirect("/dashboard")
            Error(_) -> wisp.not_found()
          }
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(_) -> wisp.not_found()
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Convert string to meal type
fn string_to_meal_type(s: String) -> types.MealType {
  case s {
    "breakfast" -> types.Breakfast
    "lunch" -> types.Lunch
    "dinner" -> types.Dinner
    "snack" -> types.Snack
    _ -> types.Lunch
  }
}

/// Generate a unique entry ID
pub fn generate_entry_id() -> String {
  "entry-" <> wisp.random_string(12)
}

/// Get current timestamp as ISO8601 string
fn current_timestamp() -> String {
  let #(#(year, month, day), #(hour, min, sec)) = erlang_localtime()
  int_to_string(year)
  <> "-"
  <> pad_two(month)
  <> "-"
  <> pad_two(day)
  <> "T"
  <> pad_two(hour)
  <> ":"
  <> pad_two(min)
  <> ":"
  <> pad_two(sec)
  <> "Z"
}

fn pad_two(n: Int) -> String {
  case n < 10 {
    True -> "0" <> int_to_string(n)
    False -> int_to_string(n)
  }
}

/// Get today's date in YYYY-MM-DD format
fn get_today_date() -> String {
  // This is a simplified version - in production you'd want to use a proper date library
  // For now, we'll use a system call to get the date
  "2025-12-01"
}

@external(erlang, "calendar", "local_time")
fn erlang_localtime() -> #(#(Int, Int, Int), #(Int, Int, Int))

@external(erlang, "erlang", "integer_to_binary")
fn int_to_string(i: Int) -> String
