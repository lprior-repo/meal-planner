//// Food log handlers for API endpoints

import gleam/dynamic
import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam/uri
import meal_planner/nutrient_parser.{UsdaNutrient}
import meal_planner/storage
import meal_planner/storage/profile.{DatabaseError}
import meal_planner/types.{FoodLogEntry}
import meal_planner/utils/datetime
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
          let today = datetime.get_today_date()

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
  case decode.run(json_body, decode.at(["fdc_id"], decode.string)) {
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
  json_body: dynamic.Dynamic,
  fdc_id_str: String,
  ctx: Context,
) -> wisp.Response {
  // Parse grams and meal_type from JSON
  let fdc_id_result = int.parse(fdc_id_str)
  let grams_result = decode.run(json_body, decode.at(["grams"], decode.float))
  let meal_type_result =
    decode.run(json_body, decode.at(["meal_type"], decode.string))

  case fdc_id_result, grams_result, meal_type_result {
    Ok(fdc_id), Ok(grams), Ok(meal_type_str) -> {
      let meal_type = string_to_meal_type(meal_type_str)
      let today = datetime.get_today_date()

      // Load USDA food with all nutrients
      case storage.load_usda_food_with_macros(ctx.db, fdc_id) {
        Error(DatabaseError(msg)) -> {
          let err_json = json.object([#("error", json.string(msg))])
          wisp.json_response(json.to_string(err_json), 400)
        }
        Error(_) -> {
          let err_json =
            json.object([#("error", json.string("Food not found"))])
          wisp.json_response(json.to_string(err_json), 404)
        }
        Ok(usda_food_data) -> {
          // Calculate scaling factor: grams / 100 (USDA data is per 100g)
          let scaling_factor = grams /. 100.0

          // Extract macros from nutrients and scale them
          let scaled_macros =
            extract_macros_from_nutrients(
              usda_food_data.nutrients,
              scaling_factor,
            )

          // Extract micronutrients from nutrients and scale them
          let scaled_micronutrients =
            extract_micronutrients_from_nutrients(
              usda_food_data.nutrients,
              scaling_factor,
            )

          // Create log entry with source_type='usda_food'
          let entry =
            FoodLogEntry(
              id: generate_entry_id(),
              recipe_id: int.to_string(fdc_id),
              recipe_name: usda_food_data.food.description,
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
                  #("description", json.string(usda_food_data.food.description)),
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

// Note: get_today_date is now imported from meal_planner/utils/datetime

@external(erlang, "calendar", "local_time")
fn erlang_localtime() -> #(#(Int, Int, Int), #(Int, Int, Int))

@external(erlang, "erlang", "integer_to_binary")
fn int_to_string(i: Int) -> String

/// Extract macros from nutrient list and scale by factor
/// Nutrient IDs: Protein=1003, Total Fat=1004, Carbs=1005
fn extract_macros_from_nutrients(
  nutrients: List(storage.FoodNutrientValue),
  scaling_factor: Float,
) -> types.Macros {
  let protein =
    list.find(nutrients, fn(n) { n.nutrient_id == 1003 })
    |> result.map(fn(n) { n.amount *. scaling_factor })
    |> result.unwrap(0.0)

  let fat =
    list.find(nutrients, fn(n) { n.nutrient_id == 1004 })
    |> result.map(fn(n) { n.amount *. scaling_factor })
    |> result.unwrap(0.0)

  let carbs =
    list.find(nutrients, fn(n) { n.nutrient_id == 1005 })
    |> result.map(fn(n) { n.amount *. scaling_factor })
    |> result.unwrap(0.0)

  types.Macros(protein: protein, fat: fat, carbs: carbs)
}

/// Extract micronutrients from nutrient list and scale by factor
/// Returns None if no micronutrients are available, otherwise Some(Micronutrients)
///
/// USDA Nutrient IDs:
/// - Fiber: 1079
/// - Sugars: 2000
/// - Sodium: 1093
/// - Cholesterol: 1253
/// - Vitamin A: 1106
/// - Vitamin C: 1162
/// - Vitamin D: 1114
/// - Vitamin E: 1109
/// - Vitamin K: 1185
/// - Vitamin B6: 1175
/// - Vitamin B12: 1178
/// - Folate: 1177
/// - Thiamin: 1165
/// - Riboflavin: 1166
/// - Niacin: 1167
/// - Calcium: 1087
/// - Iron: 1089
/// - Magnesium: 1090
/// - Phosphorus: 1091
/// - Potassium: 1092
/// - Zinc: 1095
fn extract_micronutrients_from_nutrients(
  nutrients: List(storage.FoodNutrientValue),
  scaling_factor: Float,
) -> option.Option(types.Micronutrients) {
  // Extract each micronutrient value and scale
  let find_and_scale = fn(nutrient_id: Int) -> option.Option(Float) {
    list.find(nutrients, fn(n) { n.nutrient_id == nutrient_id })
    |> result.map(fn(n) { n.amount *. scaling_factor })
    |> option.from_result
  }

  let fiber = find_and_scale(1079)
  let sugar = find_and_scale(2000)
  let sodium = find_and_scale(1093)
  let cholesterol = find_and_scale(1253)
  let vitamin_a = find_and_scale(1106)
  let vitamin_c = find_and_scale(1162)
  let vitamin_d = find_and_scale(1114)
  let vitamin_e = find_and_scale(1109)
  let vitamin_k = find_and_scale(1185)
  let vitamin_b6 = find_and_scale(1175)
  let vitamin_b12 = find_and_scale(1178)
  let folate = find_and_scale(1177)
  let thiamin = find_and_scale(1165)
  let riboflavin = find_and_scale(1166)
  let niacin = find_and_scale(1167)
  let calcium = find_and_scale(1087)
  let iron = find_and_scale(1089)
  let magnesium = find_and_scale(1090)
  let phosphorus = find_and_scale(1091)
  let potassium = find_and_scale(1092)
  let zinc = find_and_scale(1095)

  // Check if at least one micronutrient is available
  let has_any_micronutrients =
    list.any(
      [
        fiber, sugar, sodium, cholesterol, vitamin_a, vitamin_c, vitamin_d,
        vitamin_e, vitamin_k, vitamin_b6, vitamin_b12, folate, thiamin,
        riboflavin, niacin, calcium, iron, magnesium, phosphorus, potassium,
        zinc,
      ],
      fn(opt) {
        case opt {
          Some(_) -> True
          None -> False
        }
      },
    )

  case has_any_micronutrients {
    True ->
      Some(types.Micronutrients(
        fiber: fiber,
        sugar: sugar,
        sodium: sodium,
        cholesterol: cholesterol,
        vitamin_a: vitamin_a,
        vitamin_c: vitamin_c,
        vitamin_d: vitamin_d,
        vitamin_e: vitamin_e,
        vitamin_k: vitamin_k,
        vitamin_b6: vitamin_b6,
        vitamin_b12: vitamin_b12,
        folate: folate,
        thiamin: thiamin,
        riboflavin: riboflavin,
        niacin: niacin,
        calcium: calcium,
        iron: iron,
        magnesium: magnesium,
        phosphorus: phosphorus,
        potassium: potassium,
        zinc: zinc,
      ))
    False -> None
  }
}

/// GET /api/fragments/food-log-form?fdc_id=123 - Return HTML form for logging food
pub fn api_food_log_form_fragment(
  req: wisp.Request,
  ctx: Context,
) -> wisp.Response {
  case uri.parse_query(req.query |> option.unwrap("")) {
    Ok(params) -> {
      case list.find(params, fn(p) { p.0 == "fdc_id" }) {
        Ok(#(_, fdc_id_str)) -> {
          case int.parse(fdc_id_str) {
            Ok(fdc_id) -> {
              case storage.get_food_by_id(ctx.db, fdc_id) {
                Ok(food) -> render_food_log_form(food)
                Error(_) ->
                  wisp.html_response(
                    "<div class=\"error\">Food not found</div>",
                    404,
                  )
              }
            }
            Error(_) ->
              wisp.html_response(
                "<div class=\"error\">Invalid food ID</div>",
                400,
              )
          }
        }
        Error(_) ->
          wisp.html_response(
            "<div class=\"error\">Missing fdc_id parameter</div>",
            400,
          )
      }
    }
    Error(_) ->
      wisp.html_response("<div class=\"error\">Invalid parameters</div>", 400)
  }
}

fn render_food_log_form(food: storage.UsdaFood) -> wisp.Response {
  let form_html =
    "<div class=\"modal-content\">"
    <> "<div class=\"modal-header\"><h3>Add to Food Log</h3>"
    <> "<button type=\"button\" class=\"modal-close\" aria-label=\"Close\" onclick=\"document.getElementById('food-log-modal').innerHTML=''\">&times;</button></div>"
    <> "<div class=\"modal-body\"><p class=\"food-name\"><strong>"
    <> escape_html_string(food.description)
    <> "</strong></p>"
    <> "<form action=\"/api/logs/food-form?fdc_id="
    <> int.to_string(food.fdc_id)
    <> "\" method=\"GET\" hx-get=\"/api/logs/food-form?fdc_id="
    <> int.to_string(food.fdc_id)
    <> "\" hx-target=\"#food-log-result\" hx-swap=\"innerHTML\">"
    <> "<div class=\"form-group\"><label for=\"grams\">Amount (grams):</label>"
    <> "<input type=\"number\" id=\"grams\" name=\"grams\" class=\"input\" min=\"1\" step=\"1\" value=\"100\" required /></div>"
    <> "<div class=\"form-group\"><label for=\"meal-type\">Meal Type:</label>"
    <> "<select id=\"meal-type\" name=\"meal_type\" class=\"input\" required>"
    <> "<option value=\"breakfast\">Breakfast</option><option value=\"lunch\" selected>Lunch</option>"
    <> "<option value=\"dinner\">Dinner</option><option value=\"snack\">Snack</option></select></div>"
    <> "<div class=\"form-actions\"><button type=\"submit\" class=\"btn btn-primary\">Add to Log</button>"
    <> "<button type=\"button\" class=\"btn btn-secondary\" onclick=\"document.getElementById('food-log-modal').innerHTML=''\">Cancel</button></div></form>"
    <> "<div id=\"food-log-result\"></div></div></div>"
  wisp.html_response(form_html, 200)
}

/// GET /api/logs/food-form - Submit food log via form parameters
pub fn api_food_log_form_submit(
  req: wisp.Request,
  ctx: Context,
) -> wisp.Response {
  case uri.parse_query(req.query |> option.unwrap("")) {
    Ok(params) -> {
      let fdc_id_result =
        list.find(params, fn(p) { p.0 == "fdc_id" })
        |> result.map(fn(p) { int.parse(p.1) })
        |> result.flatten
      let grams_result =
        list.find(params, fn(p) { p.0 == "grams" })
        |> result.map(fn(p) {
          // Try float parse, if that fails try int parse and convert
          case float.parse(p.1) {
            Ok(f) -> Ok(f)
            Error(_) ->
              case int.parse(p.1) {
                Ok(i) -> Ok(int.to_float(i))
                Error(_) -> Error(Nil)
              }
          }
        })
        |> result.flatten
      let meal_type_result =
        list.find(params, fn(p) { p.0 == "meal_type" })
        |> result.map(fn(p) { p.1 })

      case fdc_id_result, grams_result, meal_type_result {
        Ok(fdc_id), Ok(grams), Ok(meal_type_str) -> {
          let meal_type = string_to_meal_type(meal_type_str)
          let today = datetime.get_today_date()

          case storage.load_usda_food_with_macros(ctx.db, fdc_id) {
            Error(DatabaseError(msg)) ->
              wisp.html_response(
                "<div class=\"error\">Error: "
                  <> escape_html_string(msg)
                  <> "</div>",
                400,
              )
            Error(_) ->
              wisp.html_response(
                "<div class=\"error\">Food not found</div>",
                404,
              )
            Ok(usda_food_data) -> {
              let scaling_factor = grams /. 100.0
              let scaled_macros =
                extract_macros_from_nutrients(
                  usda_food_data.nutrients,
                  scaling_factor,
                )
              let scaled_micronutrients =
                extract_micronutrients_from_nutrients(
                  usda_food_data.nutrients,
                  scaling_factor,
                )
              let entry =
                FoodLogEntry(
                  id: generate_entry_id(),
                  recipe_id: int.to_string(fdc_id),
                  recipe_name: usda_food_data.food.description,
                  servings: grams,
                  macros: scaled_macros,
                  micronutrients: scaled_micronutrients,
                  meal_type: meal_type,
                  logged_at: current_timestamp(),
                  source_type: "usda_food",
                  source_id: int.to_string(fdc_id),
                )

              case storage.save_food_log_entry(ctx.db, today, entry) {
                Ok(_) ->
                  // Redirect to dashboard to see updated data
                  wisp.redirect("/dashboard")
                Error(_) ->
                  wisp.html_response(
                    "<div class=\"error\">Failed to save entry</div>",
                    500,
                  )
              }
            }
          }
        }
        _, _, _ -> {
          // Debug: Log what we received
          let debug_msg =
            "Missing fields - fdc_id: "
            <> case fdc_id_result {
              Ok(id) -> "OK(" <> int.to_string(id) <> ")"
              Error(_) -> "ERROR"
            }
            <> ", grams: "
            <> case grams_result {
              Ok(g) -> "OK(" <> float.to_string(g) <> ")"
              Error(_) -> "ERROR"
            }
            <> ", meal_type: "
            <> case meal_type_result {
              Ok(mt) -> "OK(" <> mt <> ")"
              Error(_) -> "ERROR"
            }

          wisp.html_response(
            "<div class=\"error\">Missing required fields. "
              <> debug_msg
              <> "</div>",
            400,
          )
        }
      }
    }
    Error(_) ->
      wisp.html_response("<div class=\"error\">Invalid form data</div>", 400)
  }
}

fn escape_html_string(text: String) -> String {
  text
  |> string.replace("&", "&amp;")
  |> string.replace("<", "&lt;")
  |> string.replace(">", "&gt;")
  |> string.replace("\"", "&quot;")
  |> string.replace("'", "&#39;")
}
