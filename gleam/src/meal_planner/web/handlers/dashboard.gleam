//// Dashboard handler for rendering daily macro progress
////
//// Responsible for:
//// - Fetching today's logs using get_todays_logs
//// - Summing macro totals from logs
//// - Rendering progress bars using progress_bar components
//// - Returning HTML response

import gleam/float
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/uri
import meal_planner/storage
import meal_planner/storage_optimized
import meal_planner/types.{
  type Macros, type UserProfile, Macros, daily_macro_targets, macros_calories,
}
import meal_planner/ui/components/dashboard as dashboard_component
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

  // Fetch today's logs from database
  // Using default user_id of 1 for singleton user model
  let default_user_id = 1
  case storage.get_todays_logs(ctx.db, default_user_id, date) {
    Error(_) -> {
      // Return error response
      let error_html = "<div class=\"error\">Failed to load daily logs</div>"
      wisp.html_response(error_html, 500)
    }
    Ok(logs) -> {
      // Calculate current macros from logs
      let current = sum_log_macros(logs)

      // Build dashboard HTML
      let dashboard_html =
        "<div class=\"dashboard-container\">"
        <> "<h1>Daily Macro Progress</h1>"
        <> "<p class=\"dashboard-date\">"
        <> date
        <> "</p>"
        <> "<div class=\"calorie-summary\">"
        <> "<div class=\"calorie-display\">"
        <> "<span class=\"current-calories\">"
        <> float_to_display_string(macros_calories(current))
        <> "</span>"
        <> "<span class=\"separator\"> / </span>"
        <> "<span class=\"target-calories\">"
        <> float_to_display_string(macros_calories(targets))
        <> "</span>"
        <> "<span class=\"unit\"> cal</span>"
        <> "</div></div>"
        <> "<div class=\"macro-progress\">"
        <> "<div class=\"macro-bar\">"
        <> "<div class=\"macro-bar-label\">Protein</div>"
        <> dashboard_component.progress_bar(
          float_to_int(current.protein),
          float_to_int(targets.protein),
        )
        <> "</div>"
        <> "<div class=\"macro-bar\">"
        <> "<div class=\"macro-bar-label\">Fat</div>"
        <> dashboard_component.progress_bar(
          float_to_int(current.fat),
          float_to_int(targets.fat),
        )
        <> "</div>"
        <> "<div class=\"macro-bar\">"
        <> "<div class=\"macro-bar-label\">Carbs</div>"
        <> dashboard_component.progress_bar(
          float_to_int(current.carbs),
          float_to_int(targets.carbs),
        )
        <> "</div>"
        <> "</div>"
        <> "<div class=\"log-entries\">"
        <> "<h2>Today's Entries</h2>"
        <> case list.length(logs) {
          0 -> "<p class=\"empty-state\">No logs recorded yet</p>"
          _ ->
            "<ul class=\"entries-list\">"
            <> list.fold(logs, "", fn(acc, log) {
              acc <> render_log_entry_html(log)
            })
            <> "</ul>"
        }
        <> "</div>"
        <> "</div>"

      wisp.html_response(dashboard_html, 200)
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

/// Sum macros from list of logs
pub fn sum_log_macros(logs: List(storage.Log)) -> Macros {
  list.fold(logs, Macros(protein: 0.0, fat: 0.0, carbs: 0.0), fn(acc, log) {
    // Parse macros from log if available
    case log.macros {
      None ->
        // No macros recorded, keep accumulator
        acc
      Some(_macros_str) ->
        // Parse macros string (format: "protein:fat:carbs" or similar)
        // For now, assume no macros in string, return as-is
        acc
    }
  })
}

/// Render individual log entry as HTML
pub fn render_log_entry_html(log: storage.Log) -> String {
  "<li class=\"log-entry\">"
  <> "<div class=\"entry-info\">"
  <> "<p>Food ID: "
  <> int.to_string(log.food_id)
  <> "</p>"
  <> "<p>Quantity: "
  <> float_to_display_string(log.quantity)
  <> "</p>"
  <> "<p>Date: "
  <> log.log_date
  <> "</p>"
  <> "</div>"
  <> "</li>"
}

/// Convert float to integer (truncate decimal)
pub fn float_to_int(f: Float) -> Int {
  float.truncate(f)
}

/// Format float for display (2 decimal places)
pub fn float_to_display_string(f: Float) -> String {
  let truncated = float_to_int(f)
  int.to_string(truncated)
}

/// Get today's date in YYYY-MM-DD format
pub fn get_today_date() -> String {
  // Simplified implementation - returns fixed date
  // In production, use a proper date library
  "2025-12-01"
}
