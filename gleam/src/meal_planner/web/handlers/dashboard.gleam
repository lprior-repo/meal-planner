/// Dashboard handler with HTMX-only UI components
///
/// This module implements the main dashboard view with:
/// - Macro progress bars with color coding (blue/orange/green)
/// - Micronutrient daily summary with FDA RDA comparisons
/// - Recently logged foods quick access
/// - Daily log summary with meal entries
/// - Date selector navigation
///
/// All interactivity uses HTMX attributes only - NO JavaScript files.
import gleam/float
import gleam/http
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import meal_planner/fatsecret/service as fatsecret_service
import meal_planner/id
import meal_planner/storage
import meal_planner/types
import pog
import wisp

// ============================================================================
// Dashboard Handler
// ============================================================================

/// Dashboard page - GET /dashboard or GET /dashboard?date=YYYY-MM-DD
pub fn handle(req: wisp.Request, conn: pog.Connection) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  // Get date from query params or use today
  let date = case list.key_find(wisp.get_query(req), "date") {
    Ok(d) -> d
    Error(_) -> "2025-12-13"
  }

  // Get daily log data
  let daily_log = case storage.get_daily_log(conn, date) {
    Ok(log) -> Some(log)
    Error(_) -> None
  }

  // Get recently logged foods (for quick access)
  let recent_foods = case storage.get_recently_logged_foods(conn, 10) {
    Ok(foods) -> foods
    Error(_) -> []
  }

  // Get user profile for goals
  let profile = case storage.get_user_profile(conn) {
    Ok(p) -> Some(p)
    Error(_) -> None
  }

  // Get FatSecret connection status
  let fatsecret_status = fatsecret_service.check_status(conn)

  let html = render_dashboard(date, daily_log, recent_foods, profile, fatsecret_status)
  wisp.html_response(html, 200)
}

/// Get dashboard data as JSON for HTMX partial updates
pub fn handle_data(req: wisp.Request, conn: pog.Connection) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  let date = case list.key_find(wisp.get_query(req), "date") {
    Ok(d) -> d
    Error(_) -> "2025-12-13"
  }

  let daily_log = case storage.get_daily_log(conn, date) {
    Ok(log) -> Some(log)
    Error(_) -> None
  }

  let profile = case storage.get_user_profile(conn) {
    Ok(p) -> Some(p)
    Error(_) -> None
  }

  let html = render_daily_content(date, daily_log, profile)
  wisp.html_response(html, 200)
}

// ============================================================================
// Main Dashboard Layout
// ============================================================================

fn render_dashboard(
  date: String,
  daily_log: Option(types.DailyLog),
  recent_foods: List(storage.UsdaFood),
  profile: Option(types.UserProfile),
  fatsecret_status: fatsecret_service.ConnectionStatus,
) -> String {
  "<!DOCTYPE html>
<html lang=\"en\">
<head>
  <meta charset=\"UTF-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
  <title>Meal Planner Dashboard</title>
  <script src=\"https://unpkg.com/htmx.org@1.9.10\"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: #f5f5f5;
      color: #333;
      line-height: 1.6;
    }
    .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
    header {
      background: white;
      padding: 20px;
      margin-bottom: 20px;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    h1 { color: #2c3e50; font-size: 28px; margin-bottom: 10px; }
    .date-nav {
      display: flex;
      gap: 10px;
      align-items: center;
      margin-top: 15px;
    }
    .date-nav button {
      background: #3498db;
      color: white;
      border: none;
      padding: 8px 16px;
      border-radius: 4px;
      cursor: pointer;
      font-size: 14px;
    }
    .date-nav button:hover { background: #2980b9; }
    .date-nav input[type=\"date\"] {
      padding: 8px;
      border: 1px solid #ddd;
      border-radius: 4px;
      font-size: 14px;
    }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 20px;
    }
    .card {
      background: white;
      padding: 20px;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    .card h2 {
      font-size: 18px;
      margin-bottom: 15px;
      color: #2c3e50;
      border-bottom: 2px solid #3498db;
      padding-bottom: 8px;
    }
    .progress-bar {
      background: #e5e7eb;
      border-radius: 4px;
      overflow: hidden;
      height: 24px;
      margin: 10px 0;
      position: relative;
    }
    .progress-fill {
      height: 100%;
      transition: width 0.6s ease-out;
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
      font-weight: bold;
      font-size: 12px;
    }
    .progress-fill.protein { background: #3b82f6; }
    .progress-fill.fat { background: #f97316; }
    .progress-fill.carbs { background: #22c55e; }
    .progress-label {
      margin-bottom: 5px;
      font-size: 14px;
      font-weight: 500;
    }
    .micro-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
      gap: 10px;
      margin-top: 10px;
    }
    .micro-item {
      padding: 8px;
      background: #f8f9fa;
      border-radius: 4px;
      border-left: 3px solid #3498db;
    }
    .micro-item.low { border-left-color: #e74c3c; }
    .micro-item.ok { border-left-color: #2ecc71; }
    .micro-name {
      font-size: 11px;
      color: #7f8c8d;
      text-transform: uppercase;
      margin-bottom: 3px;
    }
    .micro-value {
      font-size: 14px;
      font-weight: bold;
      color: #2c3e50;
    }
    .micro-target {
      font-size: 11px;
      color: #95a5a6;
    }
    .recent-chips {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      margin-top: 10px;
    }
    .chip {
      background: #ecf0f1;
      border: 1px solid #bdc3c7;
      border-radius: 20px;
      padding: 6px 12px;
      font-size: 13px;
      cursor: pointer;
      transition: all 0.2s;
    }
    .chip:hover {
      background: #3498db;
      color: white;
      border-color: #3498db;
    }
    .meal-list {
      list-style: none;
    }
    .meal-item {
      padding: 12px;
      border-bottom: 1px solid #ecf0f1;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .meal-item:last-child { border-bottom: none; }
    .meal-name {
      font-weight: 500;
      color: #2c3e50;
    }
    .meal-macros {
      font-size: 12px;
      color: #7f8c8d;
      margin-top: 4px;
    }
    .meal-badge {
      background: #3498db;
      color: white;
      padding: 4px 8px;
      border-radius: 4px;
      font-size: 11px;
      text-transform: uppercase;
    }
    .empty-state {
      text-align: center;
      padding: 40px 20px;
      color: #95a5a6;
    }
    .integration-status {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 12px;
      border-radius: 6px;
      margin-bottom: 10px;
    }
    .integration-status.connected { background: #d4edda; border: 1px solid #28a745; }
    .integration-status.disconnected { background: #fff3cd; border: 1px solid #ffc107; }
    .integration-status.error { background: #f8d7da; border: 1px solid #dc3545; }
    .status-icon { font-size: 24px; }
    .status-text { flex: 1; }
    .status-label { font-weight: 600; color: #2c3e50; }
    .status-detail { font-size: 12px; color: #6c757d; }
    .connect-btn {
      background: #3498db;
      color: white;
      border: none;
      padding: 8px 16px;
      border-radius: 4px;
      cursor: pointer;
      font-weight: 500;
      text-decoration: none;
      display: inline-block;
    }
    .connect-btn:hover { background: #2980b9; }
    .connect-btn.success { background: #28a745; }
    .connect-btn.success:hover { background: #218838; }
    .summary-stats {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 15px;
      margin-bottom: 20px;
    }
    .stat-box {
      text-align: center;
      padding: 15px;
      background: #f8f9fa;
      border-radius: 6px;
    }
    .stat-value {
      font-size: 24px;
      font-weight: bold;
      color: #2c3e50;
    }
    .stat-label {
      font-size: 12px;
      color: #7f8c8d;
      text-transform: uppercase;
      margin-top: 5px;
    }
  </style>
</head>
<body>
  <div class=\"container\">
    <header>
      <h1>Nutrition Dashboard</h1>
      " <> render_date_selector(date) <> "
    </header>

    <div class=\"grid\">
      " <> render_integrations_status(fatsecret_status) <> "
      " <> render_calorie_summary(daily_log, profile) <> "
      " <> render_macro_progress(daily_log, profile) <> "
      " <> render_micronutrients(daily_log, profile) <> "
      " <> render_recent_foods(recent_foods) <> "
      " <> render_daily_log(daily_log) <> "
    </div>
  </div>
</body>
</html>"
}

// ============================================================================
// Component Renderers
// ============================================================================

fn render_integrations_status(fatsecret_status: fatsecret_service.ConnectionStatus) -> String {
  let fatsecret_html = case fatsecret_status {
    fatsecret_service.Connected(_) ->
      "<div class=\"integration-status connected\">
        <span class=\"status-icon\">✓</span>
        <div class=\"status-text\">
          <div class=\"status-label\">FatSecret</div>
          <div class=\"status-detail\">Connected - syncing your food diary</div>
        </div>
        <a href=\"/fatsecret/status\" class=\"connect-btn success\">Manage</a>
      </div>"

    fatsecret_service.Disconnected(reason) ->
      "<div class=\"integration-status disconnected\">
        <span class=\"status-icon\">⚠</span>
        <div class=\"status-text\">
          <div class=\"status-label\">FatSecret</div>
          <div class=\"status-detail\">" <> reason <> "</div>
        </div>
        <a href=\"/fatsecret/connect\" class=\"connect-btn\">Connect</a>
      </div>"

    fatsecret_service.ConfigMissing ->
      "<div class=\"integration-status error\">
        <span class=\"status-icon\">✗</span>
        <div class=\"status-text\">
          <div class=\"status-label\">FatSecret</div>
          <div class=\"status-detail\">API keys not configured</div>
        </div>
      </div>"

    fatsecret_service.EncryptionKeyMissing ->
      "<div class=\"integration-status error\">
        <span class=\"status-icon\">✗</span>
        <div class=\"status-text\">
          <div class=\"status-label\">FatSecret</div>
          <div class=\"status-detail\">OAUTH_ENCRYPTION_KEY not set</div>
        </div>
      </div>"
  }

  "<div class=\"card\">
    <h2>Integrations</h2>
    " <> fatsecret_html <> "
  </div>"
}

fn render_date_selector(date: String) -> String {
  // Calculate previous and next dates using simple string manipulation
  let prev_date = calculate_previous_date(date)
  let next_date = calculate_next_date(date)

  "<div class=\"date-nav\">
    <button hx-get=\"/api/dashboard/data?date=" <> prev_date <> "\"
            hx-target=\".grid\"
            hx-swap=\"innerHTML\"
            hx-push-url=\"/dashboard?date=" <> prev_date <> "\">
      ← Previous Day
    </button>
    <input type=\"date\"
           value=\"" <> date <> "\"
           name=\"date\"
           hx-get=\"/api/dashboard/data\"
           hx-trigger=\"change\"
           hx-target=\".grid\"
           hx-swap=\"innerHTML\"
           hx-include=\"this\"
           hx-push-url=\"true\">
    <button hx-get=\"/api/dashboard/data?date=" <> next_date <> "\"
            hx-target=\".grid\"
            hx-swap=\"innerHTML\"
            hx-push-url=\"/dashboard?date=" <> next_date <> "\">
      Next Day →
    </button>
  </div>"
}

/// Calculate the previous date (simple decrement, may not handle month boundaries)
/// For production, use a proper date library
fn calculate_previous_date(date: String) -> String {
  // Parse YYYY-MM-DD and decrement day by 1
  // This is a simplified version - for production use birl or tempo
  case string.split(date, "-") {
    [year, month, day_str] -> {
      case int.parse(day_str) {
        Ok(day) if day > 1 -> {
          let new_day = day - 1
          let padded_day = case new_day < 10 {
            True -> "0" <> int.to_string(new_day)
            False -> int.to_string(new_day)
          }
          year <> "-" <> month <> "-" <> padded_day
        }
        Ok(1) -> {
          // Handle month boundary - simplified, just go to day 28
          case int.parse(month) {
            Ok(m) if m > 1 -> {
              let new_month = m - 1
              let padded_month = case new_month < 10 {
                True -> "0" <> int.to_string(new_month)
                False -> int.to_string(new_month)
              }
              year <> "-" <> padded_month <> "-28"
            }
            _ -> year <> "-12-31"
          }
        }
        _ -> date
      }
    }
    _ -> date
  }
}

/// Calculate the next date (simple increment, may not handle month boundaries)
/// For production, use a proper date library
fn calculate_next_date(date: String) -> String {
  // Parse YYYY-MM-DD and increment day by 1
  case string.split(date, "-") {
    [year, month, day_str] -> {
      case int.parse(day_str) {
        Ok(day) if day < 28 -> {
          let new_day = day + 1
          let padded_day = case new_day < 10 {
            True -> "0" <> int.to_string(new_day)
            False -> int.to_string(new_day)
          }
          year <> "-" <> month <> "-" <> padded_day
        }
        Ok(_) -> {
          // Handle month boundary - simplified
          case int.parse(month) {
            Ok(m) if m < 12 -> {
              let new_month = m + 1
              let padded_month = case new_month < 10 {
                True -> "0" <> int.to_string(new_month)
                False -> int.to_string(new_month)
              }
              year <> "-" <> padded_month <> "-01"
            }
            _ -> {
              case int.parse(year) {
                Ok(y) -> {
                  let new_year = y + 1
                  int.to_string(new_year) <> "-01-01"
                }
                _ -> date
              }
            }
          }
        }
        _ -> date
      }
    }
    _ -> date
  }
}

fn render_calorie_summary(
  daily_log: Option(types.DailyLog),
  profile: Option(types.UserProfile),
) -> String {
  let total_cals = case daily_log {
    Some(log) -> types.macros_calories(log.total_macros)
    None -> 0.0
  }

  let target_cals = case profile {
    Some(p) -> types.daily_calorie_target(p)
    None -> 2000.0
  }

  let remaining = target_cals -. total_cals

  "<div class=\"card\">
    <h2>Calorie Summary</h2>
    <div class=\"summary-stats\">
      <div class=\"stat-box\">
        <div class=\"stat-value\">" <> float_to_string_1dp(total_cals) <> "</div>
        <div class=\"stat-label\">Consumed</div>
      </div>
      <div class=\"stat-box\">
        <div class=\"stat-value\">" <> float_to_string_1dp(remaining) <> "</div>
        <div class=\"stat-label\">Remaining</div>
      </div>
    </div>
    <div class=\"stat-box\">
      <div class=\"stat-value\">" <> float_to_string_1dp(target_cals) <> "</div>
      <div class=\"stat-label\">Daily Target</div>
    </div>
  </div>"
}

fn render_macro_progress(
  daily_log: Option(types.DailyLog),
  profile: Option(types.UserProfile),
) -> String {
  let macros = case daily_log {
    Some(log) -> log.total_macros
    None -> types.macros_zero()
  }

  let targets = case profile {
    Some(p) -> types.daily_macro_targets(p)
    None -> types.Macros(protein: 150.0, fat: 65.0, carbs: 200.0)
  }

  "<div class=\"card\">
    <h2>Macronutrient Progress</h2>
    " <> render_macro_bar("Protein", macros.protein, targets.protein, "protein") <> "
    " <> render_macro_bar("Fat", macros.fat, targets.fat, "fat") <> "
    " <> render_macro_bar("Carbs", macros.carbs, targets.carbs, "carbs") <> "
  </div>"
}

fn render_macro_bar(
  label: String,
  current: Float,
  target: Float,
  css_class: String,
) -> String {
  let percentage = case target >. 0.0 {
    True -> float.min(100.0, { current /. target } *. 100.0)
    False -> 0.0
  }

  let width_pct = float_to_string_1dp(percentage)

  "<div>
    <div class=\"progress-label\">
      " <> label <> ": " <> float_to_string_1dp(current) <> "g / " <> float_to_string_1dp(
    target,
  ) <> "g
    </div>
    <div class=\"progress-bar\">
      <div class=\"progress-fill " <> css_class <> "\" style=\"width: " <> width_pct <> "%\">
        " <> width_pct <> "%
      </div>
    </div>
  </div>"
}

fn render_micronutrients(
  daily_log: Option(types.DailyLog),
  profile: Option(types.UserProfile),
) -> String {
  let micros = case daily_log {
    Some(log) -> log.total_micronutrients
    None -> None
  }

  let goals = case profile {
    Some(p) -> p.micronutrient_goals
    None -> Some(types.fda_rda_defaults())
  }

  let items = case micros, goals {
    Some(m), Some(g) -> render_micro_items(m, g)
    _, _ -> "<div class=\"empty-state\">No micronutrient data available</div>"
  }

  "<div class=\"card\">
    <h2>Micronutrients (Daily Values)</h2>
    <div class=\"micro-grid\">
      " <> items <> "
    </div>
  </div>"
}

fn render_micro_items(
  micros: types.Micronutrients,
  goals: types.MicronutrientGoals,
) -> String {
  let items = [
    render_micro_item("Fiber", micros.fiber, goals.fiber, "g"),
    render_micro_item("Sugar", micros.sugar, goals.sugar, "g"),
    render_micro_item("Sodium", micros.sodium, goals.sodium, "mg"),
    render_micro_item("Vitamin C", micros.vitamin_c, goals.vitamin_c, "mg"),
    render_micro_item("Vitamin D", micros.vitamin_d, goals.vitamin_d, "mcg"),
    render_micro_item("Calcium", micros.calcium, goals.calcium, "mg"),
    render_micro_item("Iron", micros.iron, goals.iron, "mg"),
    render_micro_item("Magnesium", micros.magnesium, goals.magnesium, "mg"),
    render_micro_item("Potassium", micros.potassium, goals.potassium, "mg"),
    render_micro_item("Zinc", micros.zinc, goals.zinc, "mg"),
  ]

  string.join(items, "\n")
}

fn render_micro_item(
  name: String,
  current: Option(Float),
  target: Option(Float),
  unit: String,
) -> String {
  case current, target {
    Some(c), Some(t) -> {
      let pct = { c /. t } *. 100.0
      let status_class = case pct >=. 80.0 {
        True -> "ok"
        False -> "low"
      }

      "<div class=\"micro-item " <> status_class <> "\">
        <div class=\"micro-name\">" <> name <> "</div>
        <div class=\"micro-value\">" <> float_to_string_1dp(c) <> unit <> "</div>
        <div class=\"micro-target\">" <> float_to_string_1dp(pct) <> "% of " <> float_to_string_1dp(
        t,
      ) <> unit <> "</div>
      </div>"
    }
    Some(c), None -> {
      "<div class=\"micro-item\">
        <div class=\"micro-name\">" <> name <> "</div>
        <div class=\"micro-value\">" <> float_to_string_1dp(c) <> unit <> "</div>
        <div class=\"micro-target\">No target</div>
      </div>"
    }
    None, _ -> ""
  }
}

fn render_recent_foods(foods: List(storage.UsdaFood)) -> String {
  let chips = case list.is_empty(foods) {
    True -> "<div class=\"empty-state\">No recent foods</div>"
    False -> {
      let chips_html = list.map(foods, fn(food) { "<button class=\"chip\"
                hx-get=\"/api/foods/" <> id.fdc_id_to_string(food.fdc_id) <> "\"
                hx-target=\"#food-details\"
                hx-swap=\"innerHTML\">
          " <> food.description <> "
        </button>" })
      string.join(chips_html, "\n")
    }
  }

  "<div class=\"card\">
    <h2>Recently Logged Foods</h2>
    <div class=\"recent-chips\">
      " <> chips <> "
    </div>
    <div id=\"food-details\" style=\"margin-top: 15px;\"></div>
  </div>"
}

fn render_daily_log(daily_log: Option(types.DailyLog)) -> String {
  let entries = case daily_log {
    Some(log) -> log.entries
    None -> []
  }

  let items = case list.is_empty(entries) {
    True -> "<div class=\"empty-state\">No meals logged today</div>"
    False -> {
      let items_html = list.map(entries, render_meal_item)
      "<ul class=\"meal-list\">" <> string.join(items_html, "\n") <> "</ul>"
    }
  }

  "<div class=\"card\">
    <h2>Today's Meals</h2>
    " <> items <> "
  </div>"
}

fn render_meal_item(entry: types.FoodLogEntry) -> String {
  let meal_type_str = case entry.meal_type {
    types.Breakfast -> "Breakfast"
    types.Lunch -> "Lunch"
    types.Dinner -> "Dinner"
    types.Snack -> "Snack"
  }

  "<li class=\"meal-item\">
    <div>
      <div class=\"meal-name\">" <> entry.recipe_name <> "</div>
      <div class=\"meal-macros\">
        P: " <> float_to_string_1dp(entry.macros.protein) <> "g |
        F: " <> float_to_string_1dp(entry.macros.fat) <> "g |
        C: " <> float_to_string_1dp(entry.macros.carbs) <> "g
      </div>
    </div>
    <span class=\"meal-badge\">" <> meal_type_str <> "</span>
  </li>"
}

fn render_daily_content(
  _date: String,
  daily_log: Option(types.DailyLog),
  profile: Option(types.UserProfile),
) -> String {
  render_calorie_summary(daily_log, profile) <> "
  " <> render_macro_progress(daily_log, profile) <> "
  " <> render_micronutrients(daily_log, profile) <> "
  " <> render_daily_log(daily_log)
}

// ============================================================================
// Helper Functions
// ============================================================================

fn float_to_string_1dp(f: Float) -> String {
  let rounded = int.to_float(float.round(f *. 10.0)) /. 10.0
  float.to_string(rounded)
}
