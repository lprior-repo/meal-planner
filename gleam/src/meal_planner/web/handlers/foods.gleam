/// Food handlers for USDA food search and logging
///
/// This module provides handlers for:
/// - Displaying log food form with portion and meal selection
/// - API endpoint for logging USDA foods with micronutrients
///
import gleam/float
import gleam/http
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import meal_planner/id
import meal_planner/storage/foods
import meal_planner/storage/logs/entries
import meal_planner/types
import pog
import wisp

// ============================================================================
// Types
// ============================================================================

/// Request body for logging a USDA food
pub type LogFoodRequest {
  LogFoodRequest(fdc_id: Int, grams: Float, meal_type: String, date: String)
}

// ============================================================================
// Handlers
// ============================================================================

/// Display the log food form for a specific USDA food
/// GET /log/food/{fdc_id}
pub fn handle_log_food_form(
  req: wisp.Request,
  conn: pog.Connection,
  fdc_id_str: String,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  // Parse FDC ID
  case int.parse(fdc_id_str) {
    Error(_) -> wisp.response(400)
    Ok(fdc_id_int) -> {
      let fdc_id = id.fdc_id(fdc_id_int)

      // Fetch food details with nutrients
      case foods.load_usda_food_with_macros(conn, fdc_id) {
        Error(_) -> wisp.not_found()
        Ok(food_data) -> {
          // Calculate macros from nutrients (per 100g)
          let macros = extract_macros_from_nutrients(food_data.nutrients)

          // Build HTML response
          let html = build_log_food_form_html(food_data.food, macros)
          wisp.html_response(html, 200)
        }
      }
    }
  }
}

/// API endpoint for logging a USDA food
/// POST /api/logs/food
///
/// Request body JSON:
/// {
///   "fdc_id": 123456,
///   "grams": 150.0,
///   "meal_type": "lunch",
///   "date": "2025-12-13"
/// }
pub fn handle_log_food(req: wisp.Request, conn: pog.Connection) -> wisp.Response {
  use <- wisp.require_method(req, http.Post)

  // Read and parse request body
  use body <- wisp.require_string_body(req)

  case parse_log_food_request(body) {
    Error(error_msg) -> {
      let response =
        json.object([
          #("status", json.string("error")),
          #("error", json.string(error_msg)),
        ])
        |> json.to_string
      wisp.json_response(response, 400)
    }
    Ok(request) -> {
      let fdc_id = id.fdc_id(request.fdc_id)

      // Load food with nutrients
      case foods.load_usda_food_with_macros(conn, fdc_id) {
        Error(_) -> {
          let response =
            json.object([
              #("status", json.string("error")),
              #("error", json.string("Food not found")),
            ])
            |> json.to_string
          wisp.json_response(response, 404)
        }
        Ok(food_data) -> {
          // Calculate macros and micronutrients proportionally
          let scale_factor = request.grams /. 100.0
          let macros = extract_macros_from_nutrients(food_data.nutrients)
          let micronutrients =
            extract_micronutrients_from_nutrients(food_data.nutrients)

          // Scale macros
          let scaled_macros =
            types.Macros(
              protein: macros.protein *. scale_factor,
              fat: macros.fat *. scale_factor,
              carbs: macros.carbs *. scale_factor,
            )

          // Scale micronutrients
          let _scaled_micros =
            scale_micronutrients(micronutrients, scale_factor)

          // Create food log entry
          let log_id_str =
            "log-" <> int.to_string(request.fdc_id) <> "-" <> request.date
          let log_entry =
            entries.FoodLog(
              id: log_id_str,
              date: request.date,
              recipe_id: int.to_string(request.fdc_id),
              recipe_name: food_data.food.description,
              servings: request.grams /. 100.0,
              protein: scaled_macros.protein,
              fat: scaled_macros.fat,
              carbs: scaled_macros.carbs,
              meal_type: request.meal_type,
              logged_at: "",
              fiber: micronutrients.fiber,
              sugar: micronutrients.sugar,
              sodium: micronutrients.sodium,
              cholesterol: micronutrients.cholesterol,
              vitamin_a: micronutrients.vitamin_a,
              vitamin_c: micronutrients.vitamin_c,
              vitamin_d: micronutrients.vitamin_d,
              vitamin_e: micronutrients.vitamin_e,
              vitamin_k: micronutrients.vitamin_k,
              vitamin_b6: micronutrients.vitamin_b6,
              vitamin_b12: micronutrients.vitamin_b12,
              folate: micronutrients.folate,
              thiamin: micronutrients.thiamin,
              riboflavin: micronutrients.riboflavin,
              niacin: micronutrients.niacin,
              calcium: micronutrients.calcium,
              iron: micronutrients.iron,
              magnesium: micronutrients.magnesium,
              phosphorus: micronutrients.phosphorus,
              potassium: micronutrients.potassium,
              zinc: micronutrients.zinc,
            )

          // Save to database
          case entries.save_food_log(conn, log_entry) {
            Error(_) -> {
              let response =
                json.object([
                  #("status", json.string("error")),
                  #("error", json.string("Failed to save food log")),
                ])
                |> json.to_string
              wisp.json_response(response, 500)
            }
            Ok(_) -> {
              let response =
                json.object([
                  #("status", json.string("success")),
                  #("log_id", json.string(log_id_str)),
                  #("food_name", json.string(food_data.food.description)),
                  #("grams", json.float(request.grams)),
                  #("macros", macros_to_json(scaled_macros)),
                ])
                |> json.to_string
              wisp.json_response(response, 201)
            }
          }
        }
      }
    }
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Extract macros from nutrient list (per 100g)
fn extract_macros_from_nutrients(
  nutrients: List(foods.FoodNutrientValue),
) -> types.Macros {
  let protein = find_nutrient(nutrients, 1003) |> option.unwrap(0.0)
  let fat = find_nutrient(nutrients, 1004) |> option.unwrap(0.0)
  let carbs = find_nutrient(nutrients, 1005) |> option.unwrap(0.0)

  types.Macros(protein: protein, fat: fat, carbs: carbs)
}

/// Extract micronutrients from nutrient list (per 100g)
fn extract_micronutrients_from_nutrients(
  nutrients: List(foods.FoodNutrientValue),
) -> types.Micronutrients {
  types.Micronutrients(
    fiber: find_nutrient(nutrients, 1079),
    sugar: find_nutrient(nutrients, 2000),
    sodium: find_nutrient(nutrients, 1093),
    cholesterol: find_nutrient(nutrients, 1253),
    vitamin_a: find_nutrient(nutrients, 1106),
    vitamin_c: find_nutrient(nutrients, 1162),
    vitamin_d: find_nutrient(nutrients, 1114),
    vitamin_e: find_nutrient(nutrients, 1109),
    vitamin_k: find_nutrient(nutrients, 1185),
    vitamin_b6: find_nutrient(nutrients, 1175),
    vitamin_b12: find_nutrient(nutrients, 1178),
    folate: find_nutrient(nutrients, 1177),
    thiamin: find_nutrient(nutrients, 1165),
    riboflavin: find_nutrient(nutrients, 1166),
    niacin: find_nutrient(nutrients, 1167),
    calcium: find_nutrient(nutrients, 1087),
    iron: find_nutrient(nutrients, 1089),
    magnesium: find_nutrient(nutrients, 1090),
    phosphorus: find_nutrient(nutrients, 1091),
    potassium: find_nutrient(nutrients, 1092),
    zinc: find_nutrient(nutrients, 1095),
  )
}

/// Find nutrient by ID
fn find_nutrient(
  nutrients: List(foods.FoodNutrientValue),
  nutrient_id: Int,
) -> option.Option(Float) {
  list.find(nutrients, fn(n) { n.nutrient_id == nutrient_id })
  |> result.map(fn(n) { n.amount })
  |> option.from_result
}

/// Scale micronutrients by a factor
fn scale_micronutrients(
  micros: types.Micronutrients,
  factor: Float,
) -> types.Micronutrients {
  types.Micronutrients(
    fiber: scale_optional(micros.fiber, factor),
    sugar: scale_optional(micros.sugar, factor),
    sodium: scale_optional(micros.sodium, factor),
    cholesterol: scale_optional(micros.cholesterol, factor),
    vitamin_a: scale_optional(micros.vitamin_a, factor),
    vitamin_c: scale_optional(micros.vitamin_c, factor),
    vitamin_d: scale_optional(micros.vitamin_d, factor),
    vitamin_e: scale_optional(micros.vitamin_e, factor),
    vitamin_k: scale_optional(micros.vitamin_k, factor),
    vitamin_b6: scale_optional(micros.vitamin_b6, factor),
    vitamin_b12: scale_optional(micros.vitamin_b12, factor),
    folate: scale_optional(micros.folate, factor),
    thiamin: scale_optional(micros.thiamin, factor),
    riboflavin: scale_optional(micros.riboflavin, factor),
    niacin: scale_optional(micros.niacin, factor),
    calcium: scale_optional(micros.calcium, factor),
    iron: scale_optional(micros.iron, factor),
    magnesium: scale_optional(micros.magnesium, factor),
    phosphorus: scale_optional(micros.phosphorus, factor),
    potassium: scale_optional(micros.potassium, factor),
    zinc: scale_optional(micros.zinc, factor),
  )
}

/// Scale optional float
fn scale_optional(
  value: option.Option(Float),
  factor: Float,
) -> option.Option(Float) {
  case value {
    Some(v) -> Some(v *. factor)
    None -> None
  }
}

/// Parse log food request from JSON
fn parse_log_food_request(body: String) -> Result(LogFoodRequest, String) {
  // Parse form-encoded data (HTMX sends form data, not JSON)
  // Expected format: fdc_id=123&grams=150.0&meal_type=lunch&date=2025-12-13
  case parse_form_data(body) {
    Ok(data) -> {
      // Extract and validate fields
      case
        get_form_field(data, "fdc_id"),
        get_form_field(data, "grams"),
        get_form_field(data, "meal_type"),
        get_form_field(data, "date")
      {
        Some(fdc_id_str), Some(grams_str), Some(meal_type), Some(date) -> {
          case int.parse(fdc_id_str), float.parse(grams_str) {
            Ok(fdc_id), Ok(grams) -> {
              Ok(LogFoodRequest(
                fdc_id: fdc_id,
                grams: grams,
                meal_type: meal_type,
                date: date,
              ))
            }
            _, _ -> Error("Invalid numeric values for fdc_id or grams")
          }
        }
        _, _, _, _ ->
          Error("Missing required fields: fdc_id, grams, meal_type, or date")
      }
    }
    Error(msg) -> Error(msg)
  }
}

/// Parse form-encoded data into a list of key-value pairs
fn parse_form_data(body: String) -> Result(List(#(String, String)), String) {
  let pairs = string.split(body, "&")
  let parsed =
    list.map(pairs, fn(pair) {
      case string.split(pair, "=") {
        [key, value] -> Ok(#(key, value))
        _ -> Error("Invalid form data format")
      }
    })

  // Check if all parsing succeeded
  case list.all(parsed, result.is_ok) {
    True -> Ok(list.filter_map(parsed, fn(x) { x }))
    False -> Error("Failed to parse form data")
  }
}

/// Get form field value by key
fn get_form_field(
  data: List(#(String, String)),
  key: String,
) -> option.Option(String) {
  list.find(data, fn(pair) { pair.0 == key })
  |> result.map(fn(pair) { pair.1 })
  |> option.from_result
}

/// Convert macros to JSON
fn macros_to_json(macros: types.Macros) -> json.Json {
  json.object([
    #("protein", json.float(macros.protein)),
    #("fat", json.float(macros.fat)),
    #("carbs", json.float(macros.carbs)),
  ])
}

/// Build HTML for log food form
fn build_log_food_form_html(
  food: foods.UsdaFood,
  macros: types.Macros,
) -> String {
  let fdc_id_str = int.to_string(id.fdc_id_to_int(food.fdc_id))
  let calories = types.macros_calories(macros)

  "<!DOCTYPE html>
<html>
<head>
  <meta charset=\"UTF-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
  <title>Log Food - " <> food.description <> "</title>
  <script src=\"https://unpkg.com/htmx.org@1.9.10\"></script>
  <style>
    body { font-family: system-ui, -apple-system, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
    h1 { color: #333; }
    .info-section { background: #f5f5f5; padding: 15px; border-radius: 8px; margin-bottom: 20px; }
    .info-section p { margin: 5px 0; }
    .nutrition-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 10px; margin: 15px 0; }
    .nutrition-item { background: white; padding: 10px; border-radius: 4px; text-align: center; }
    .nutrition-item strong { display: block; color: #666; font-size: 0.9em; }
    .nutrition-item span { display: block; font-size: 1.5em; color: #333; margin-top: 5px; }
    form { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    .form-group { margin-bottom: 15px; }
    label { display: block; margin-bottom: 5px; font-weight: 500; color: #555; }
    input, select { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; font-size: 16px; box-sizing: border-box; }
    button { background: #007bff; color: white; border: none; padding: 12px 24px; border-radius: 4px; font-size: 16px; cursor: pointer; width: 100%; }
    button:hover { background: #0056b3; }
    #result { margin-top: 20px; padding: 15px; border-radius: 4px; }
    .success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
    .error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
  </style>
</head>
<body>
  <h1>Log Food: " <> food.description <> "</h1>

  <div class=\"info-section\">
    <p><strong>Category:</strong> " <> food.category <> "</p>
    <p><strong>Data Type:</strong> " <> food.data_type <> "</p>
    <p><strong>Nutrition per 100g:</strong></p>
    <div class=\"nutrition-grid\">
      <div class=\"nutrition-item\">
        <strong>Protein</strong>
        <span>" <> float.to_string(macros.protein) <> "g</span>
      </div>
      <div class=\"nutrition-item\">
        <strong>Fat</strong>
        <span>" <> float.to_string(macros.fat) <> "g</span>
      </div>
      <div class=\"nutrition-item\">
        <strong>Carbs</strong>
        <span>" <> float.to_string(macros.carbs) <> "g</span>
      </div>
      <div class=\"nutrition-item\">
        <strong>Calories</strong>
        <span>" <> float.to_string(calories) <> "</span>
      </div>
    </div>
  </div>

  <form hx-post=\"/api/logs/food\" hx-target=\"#result\" hx-swap=\"innerHTML\">
    <input type=\"hidden\" name=\"fdc_id\" value=\"" <> fdc_id_str <> "\" />
    <input type=\"hidden\" name=\"date\" id=\"date-input\" />

    <div class=\"form-group\">
      <label for=\"grams\">Portion (grams):</label>
      <input type=\"number\" name=\"grams\" id=\"grams\" value=\"100\" step=\"0.1\" min=\"0\" required />
    </div>

    <div class=\"form-group\">
      <label for=\"meal_type\">Meal Type:</label>
      <select name=\"meal_type\" id=\"meal_type\" required>
        <option value=\"breakfast\">Breakfast</option>
        <option value=\"lunch\">Lunch</option>
        <option value=\"dinner\">Dinner</option>
        <option value=\"snack\">Snack</option>
      </select>
    </div>

    <button type=\"submit\">Log Food</button>
  </form>

  <div id=\"result\"></div>

  <script>
    document.getElementById('date-input').value = new Date().toISOString().split('T')[0];
  </script>
</body>
</html>"
}
