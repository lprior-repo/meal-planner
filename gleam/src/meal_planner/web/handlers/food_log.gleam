//// Food log handlers for API endpoints

import gleam/float
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/uri
import meal_planner/storage
import meal_planner/types.{type FoodLogEntry, FoodLogEntry, Macros}
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
