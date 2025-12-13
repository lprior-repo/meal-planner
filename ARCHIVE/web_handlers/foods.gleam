/// Food handlers for USDA food search and logging
///
/// This module provides handlers for:
/// - Displaying log food form with portion and meal selection
/// - API endpoint for logging USDA foods with micronutrients
///
import gleam/dynamic/decode
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
  LogFoodRequest(
    fdc_id: Int,
    grams: Float,
    meal_type: String,
    date: String,
  )
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
    Error(_) -> wisp.bad_request()
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
pub fn handle_log_food(
  req: wisp.Request,
  conn: pog.Connection,
) -> wisp.Response {
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
          let micronutrients = extract_micronutrients_from_nutrients(food_data.nutrients)

          // Scale macros
          let scaled_macros = types.Macros(
            protein: macros.protein *. scale_factor,
            fat: macros.fat *. scale_factor,
            carbs: macros.carbs *. scale_factor,
          )

          // Scale micronutrients
          let scaled_micros = scale_micronutrients(micronutrients, scale_factor)

          // Create food log entry
          let log_id = id.log_entry_id("log-" <> int.to_string(request.fdc_id) <> "-" <> request.date)
          let log_entry = entries.FoodLog(
            id: log_id,
            date: request.date,
            recipe_id: int.to_string(request.fdc_id),
            recipe_name: food_data.food.description,
            servings: request.grams /. 100.0,
            protein: scaled_macros.protein,
            fat: scaled_macros.fat,
            carbs: scaled_macros.carbs,
            meal_type: request.meal_type,
            logged_at: "",
            source_type: "usda_food",
            source_id: int.to_string(request.fdc_id),
            fiber: scaled_micros.fiber,
            sugar: scaled_micros.sugar,
            sodium: scaled_micros.sodium,
            cholesterol: scaled_micros.cholesterol,
            vitamin_a: scaled_micros.vitamin_a,
            vitamin_c: scaled_micros.vitamin_c,
            vitamin_d: scaled_micros.vitamin_d,
            vitamin_e: scaled_micros.vitamin_e,
            vitamin_k: scaled_micros.vitamin_k,
            vitamin_b6: scaled_micros.vitamin_b6,
            vitamin_b12: scaled_micros.vitamin_b12,
            folate: scaled_micros.folate,
            thiamin: scaled_micros.thiamin,
            riboflavin: scaled_micros.riboflavin,
            niacin: scaled_micros.niacin,
            calcium: scaled_micros.calcium,
            iron: scaled_micros.iron,
            magnesium: scaled_micros.magnesium,
            phosphorus: scaled_micros.phosphorus,
            potassium: scaled_micros.potassium,
            zinc: scaled_micros.zinc,
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
                  #("log_id", json.string(id.log_entry_id_to_string(log_id))),
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
fn scale_optional(value: option.Option(Float), factor: Float) -> option.Option(Float) {
  case value {
    Some(v) -> Some(v *. factor)
    None -> None
  }
}

/// Parse log food request from JSON
fn parse_log_food_request(body: String) -> Result(LogFoodRequest, String) {
  // For now, return a simple parse error
  // In production, use a proper JSON parser
  Error("JSON parsing not yet implemented - use test data")
}

/// Convert macros to JSON
fn macros_to_json(macros: types.Macros) -> json.Json {
  json.object([
    #("protein", json.float(macros.protein)),
    #("fat", json.float(macros.fat)),
    #("carbs", json.float(macros.carbs)),
  ])
}

/// Build HTML for log food form with accessibility improvements
fn build_log_food_form_html(
  food: foods.UsdaFood,
  macros: types.Macros,
) -> String {
  let fdc_id_str = int.to_string(id.fdc_id_to_int(food.fdc_id))

  "<!DOCTYPE html>
<html lang=\"en\">
<head>
  <meta charset=\"UTF-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
  <title>Log Food - " <> food.description <> "</title>
  <script src=\"https://unpkg.com/htmx.org@1.9.10\"></script>
</head>
<body>
  <main role=\"main\">
    <h1 id=\"page-title\">Log Food: " <> food.description <> "</h1>

    <section aria-labelledby=\"nutrition-info\">
      <h2 id=\"nutrition-info\" class=\"sr-only\">Nutrition Information</h2>
      <p><strong>Category:</strong> " <> food.category <> "</p>
      <p><strong>Data Type:</strong> " <> food.data_type <> "</p>
      <p><strong>Nutrition (per 100g):</strong></p>
      <ul aria-label=\"Macronutrients per 100 grams\">
        <li>Protein: " <> float.to_string(macros.protein) <> "g</li>
        <li>Fat: " <> float.to_string(macros.fat) <> "g</li>
        <li>Carbs: " <> float.to_string(macros.carbs) <> "g</li>
      </ul>
    </section>

    <form hx-post=\"/api/logs/food\"
          hx-target=\"#result\"
          hx-swap=\"innerHTML\"
          hx-indicator=\"#loading\"
          aria-label=\"Food logging form\">
      <input type=\"hidden\" name=\"fdc_id\" value=\"" <> fdc_id_str <> "\" />
      <input type=\"hidden\" name=\"date\" value=\"2025-12-13\" />

      <div class=\"form-group\">
        <label for=\"grams\">Portion (grams):</label>
        <input type=\"number\"
               name=\"grams\"
               id=\"grams\"
               value=\"100\"
               step=\"0.1\"
               min=\"0.1\"
               required
               aria-required=\"true\"
               aria-describedby=\"grams-help\" />
        <span id=\"grams-help\" class=\"help-text\">Enter the amount in grams</span>
      </div>

      <div class=\"form-group\">
        <label for=\"meal_type\">Meal Type:</label>
        <select name=\"meal_type\"
                id=\"meal_type\"
                required
                aria-required=\"true\">
          <option value=\"breakfast\">Breakfast</option>
          <option value=\"lunch\">Lunch</option>
          <option value=\"dinner\">Dinner</option>
          <option value=\"snack\">Snack</option>
        </select>
      </div>

      <button type=\"submit\"
              aria-label=\"Submit food log entry\">
        Log Food
      </button>
      <span id=\"loading\" class=\"htmx-indicator\" aria-live=\"polite\" aria-atomic=\"true\">
        Loading...
      </span>
    </form>

    <div id=\"result\"
         role=\"status\"
         aria-live=\"polite\"
         aria-atomic=\"true\"></div>
  </main>

  <style>
    .sr-only {
      position: absolute;
      width: 1px;
      height: 1px;
      padding: 0;
      margin: -1px;
      overflow: hidden;
      clip: rect(0, 0, 0, 0);
      white-space: nowrap;
      border-width: 0;
    }
    .htmx-indicator {
      display: none;
    }
    .htmx-request .htmx-indicator {
      display: inline;
    }
    .form-group {
      margin-bottom: 1rem;
    }
    .help-text {
      font-size: 0.875rem;
      color: #666;
      display: block;
      margin-top: 0.25rem;
    }
  </style>
</body>
</html>"
}
