//// Dashboard handler for rendering daily macro progress
////
//// Responsible for:
//// - Fetching daily log using get_daily_log
//// - Converting to UI types for component rendering
//// - Rendering dashboard page with macros, calories, and meal log
//// - Returning HTML response

import gleam/float
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam/uri
import lustre/attribute
import lustre/element
import lustre/element/html
import meal_planner/nutrition_constants
import meal_planner/storage
import meal_planner/storage_optimized
import meal_planner/types.{
  type FoodLogEntry, type Macros, type UserProfile, Macros, daily_macro_targets,
  macros_calories,
} as types
import meal_planner/ui/components/progress
import meal_planner/ui/pages/dashboard as dashboard_page
import meal_planner/ui/types/ui_types
import pog
import wisp

/// Web context holding database connection
pub type Context {
  Context(db: pog.Connection, search_cache: storage_optimized.SearchCache)
}

/// GET /dashboard - Display daily macro progress dashboard
pub fn dashboard(req: wisp.Request, ctx: Context) -> wisp.Response {
  // Get user profile to determine target macros
  let profile = load_profile(ctx)
  let targets = daily_macro_targets(profile)

  // Get date from query parameters or use today's date
  let date = extract_date_param(req.query)

  // Fetch daily log from database
  case storage.get_daily_log(ctx.db, date) {
    Error(_) -> {
      // Return error response
      let error_html = "<div class=\"error\">Failed to load daily log</div>"
      wisp.html_response(error_html, 500)
    }
    Ok(daily_log) -> {
      // Convert food log entries to UI meal entry data
      let meal_entries = list.map(daily_log.entries, food_log_to_meal_entry)

      // Build dashboard data
      let dashboard_data =
        dashboard_page.DashboardData(
          profile_id: nutrition_constants.default_user_id
            |> int.to_string,
          daily_calories_current: macros_calories(daily_log.total_macros),
          daily_calories_target: macros_calories(targets),
          protein_current: daily_log.total_macros.protein,
          protein_target: targets.protein,
          fat_current: daily_log.total_macros.fat,
          fat_target: targets.fat,
          carbs_current: daily_log.total_macros.carbs,
          carbs_target: targets.carbs,
          date: date,
          meal_entries: meal_entries,
          total_micronutrients: daily_log.total_micronutrients,
        )

      // Render dashboard page with full HTML wrapper
      let content = [
        dashboard_page.render_dashboard(dashboard_data),
        // Modal container for HTMX dynamic content
        html.div([attribute.id("modal-container")], []),
      ]

      let page_html = render_full_page("Dashboard - Meal Planner", content)

      wisp.html_response(page_html, 200)
    }
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Load user profile from storage
fn load_profile(ctx: Context) -> UserProfile {
  storage.get_user_profile_or_default(ctx.db)
}

/// Extract date from query parameters or return today's date
pub fn extract_date_param(query: option.Option(String)) -> String {
  case uri.parse_query(query |> option.unwrap("")) {
    Ok(params) -> {
      case
        list.find(params, fn(p) { p.0 == "date" })
        |> result.map(fn(p) { p.1 })
      {
        Ok(date) -> date
        Error(_) -> get_today_date()
      }
    }
    Error(_) -> get_today_date()
  }
}

/// Convert FoodLogEntry to MealEntryData for UI rendering
fn food_log_to_meal_entry(entry: FoodLogEntry) -> ui_types.MealEntryData {
  // Extract time from logged_at timestamp (format: "2025-12-01T14:30:00Z")
  let time = case string.split(entry.logged_at, "T") {
    [_, time_part] ->
      case string.split(time_part, ":") {
        [hour, minute, _] -> hour <> ":" <> minute
        _ -> "00:00"
      }
    _ -> "00:00"
  }

  // Format portion (servings)
  let portion = case entry.servings {
    1.0 -> "1 serving"
    s -> float.to_string(s) <> " servings"
  }

  // Calculate total calories from macros
  let calories = macros_calories(entry.macros)

  // Convert meal type to string
  let meal_type_str = case entry.meal_type {
    types.Breakfast -> "breakfast"
    types.Lunch -> "lunch"
    types.Dinner -> "dinner"
    types.Snack -> "snack"
  }

  ui_types.MealEntryData(
    id: entry.id,
    time: time,
    food_name: entry.recipe_name,
    portion: portion,
    protein: entry.macros.protein,
    fat: entry.macros.fat,
    carbs: entry.macros.carbs,
    calories: calories,
    meal_type: meal_type_str,
  )
}

/// Get today's date in YYYY-MM-DD format
pub fn get_today_date() -> String {
  // Simplified implementation - returns fixed date
  // In production, use a proper date library
  "2025-12-05"
}

/// Render full HTML page with HTMX support
/// This ensures HTMX is loaded and modal container is present
fn render_full_page(
  title: String,
  content: List(element.Element(msg)),
) -> String {
  let body =
    html.html([attribute.attribute("lang", "en")], [
      html.head([], [
        html.meta([attribute.attribute("charset", "UTF-8")]),
        html.meta([
          attribute.name("viewport"),
          attribute.attribute(
            "content",
            "width=device-width, initial-scale=1.0",
          ),
        ]),
        html.title([], title),
        html.link([
          attribute.rel("stylesheet"),
          attribute.href("/static/styles.css"),
        ]),
        // HTMX library - the ONLY JavaScript allowed in the project
        // All interactivity must use HTMX attributes, not custom JS files
        html.script([attribute.src("https://unpkg.com/htmx.org@1.9.10")], ""),
      ]),
      html.body([], content),
    ])

  "<!DOCTYPE html>" <> element.to_string(body)
}
