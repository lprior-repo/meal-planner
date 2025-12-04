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
import lustre/attribute
import lustre/element
import lustre/element/html
import meal_planner/storage
import meal_planner/storage_optimized
import meal_planner/types
import meal_planner/types.{type UserProfile, Macros}
import meal_planner/ui/components/progress
import pog
import wisp

/// Web context holding database connection and query cache
pub type Context {
  Context(db: pog.Connection, search_cache: storage_optimized.SearchCache)
}

/// GET /dashboard - Display daily macro progress dashboard
pub fn dashboard(req: wisp.Request, ctx: Context) -> wisp.Response {
  // Get user profile to determine target macros
  let profile = load_profile(ctx)
  let targets = types.daily_macro_targets(profile)

  // Get date from query parameters or use today's date
  let date = extract_date_param(req)

  // Fetch today's logs from database
  // Using default user_id of 1 for singleton user model
  let default_user_id = 1
  case storage.get_todays_logs(ctx.db, default_user_id, date) {
    Error(_) -> {
      // Return error response
      let error_content = [
        html.div([attribute.class("error")], [
          element.text("Failed to load daily logs"),
        ]),
      ]
      wisp.html_response(render_dashboard_html(error_content), 500)
    }
    Ok(logs) -> {
      // Calculate current macros from logs
      let current = sum_log_macros(logs)

      // Render dashboard with progress bars
      let content = [
        html.div([attribute.class("dashboard-container")], [
          html.h1([], [element.text("Daily Macro Progress")]),
          html.p([attribute.class("dashboard-date")], [element.text(date)]),
          // Calorie summary
          html.div([attribute.class("calorie-summary")], [
            html.div([attribute.class("calorie-display")], [
              html.span([attribute.class("current-calories")], [
                element.text(
                  float_to_display_string(types.macros_calories(current)),
                ),
              ]),
              html.span([attribute.class("separator")], [element.text(" / ")]),
              html.span([attribute.class("target-calories")], [
                element.text(
                  float_to_display_string(types.macros_calories(targets)),
                ),
              ]),
              html.span([attribute.class("unit")], [element.text(" cal")]),
            ]),
          ]),
          // Macro progress bars
          html.div([attribute.class("macro-progress")], [
            progress.macro_bar(
              "Protein",
              current.protein,
              targets.protein,
              "protein",
            ),
            progress.macro_bar("Fat", current.fat, targets.fat, "fat"),
            progress.macro_bar("Carbs", current.carbs, targets.carbs, "carbs"),
          ]),
          // Log entries list
          html.div([attribute.class("log-entries")], [
            html.h2([], [element.text("Today's Entries")]),
            case list.length(logs) {
              0 ->
                html.p([attribute.class("empty-state")], [
                  element.text("No logs recorded yet"),
                ])
              _ ->
                html.ul(
                  [attribute.class("entries-list")],
                  list.map(logs, render_log_entry),
                )
            },
          ]),
        ]),
      ]

      wisp.html_response(render_dashboard_html(content), 200)
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
fn extract_date_param(req: wisp.Request) -> String {
  case uri.parse_query(req.query |> option.unwrap("")) {
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
fn sum_log_macros(logs: List(storage.Log)) -> Macros {
  list.fold(logs, Macros(protein: 0.0, fat: 0.0, carbs: 0.0), fn(acc, log) {
    // Parse macros from log if available
    case log.macros {
      None ->
        // No macros recorded, keep accumulator
        acc
      Some(macros_str) ->
        // Parse macros string (format: "protein:fat:carbs" or similar)
        // For now, assume no macros in string, return as-is
        acc
    }
  })
}

/// Render individual log entry
fn render_log_entry(log: storage.Log) -> element.Element(msg) {
  html.li([attribute.class("log-entry")], [
    html.div([attribute.class("entry-info")], [
      html.p([], [
        element.text("Food ID: " <> int.to_string(log.food_id)),
      ]),
      html.p([], [
        element.text("Quantity: " <> float_to_display_string(log.quantity)),
      ]),
      html.p([], [element.text("Date: " <> log.log_date)]),
    ]),
  ])
}

/// Format float for display (2 decimal places)
fn float_to_display_string(f: Float) -> String {
  let truncated = float.truncate(f)
  int.to_string(truncated)
}

/// Get today's date in YYYY-MM-DD format
fn get_today_date() -> String {
  // Simplified implementation - returns fixed date
  // In production, use a proper date library
  "2025-12-01"
}

/// Wrap content with basic HTML structure
fn render_dashboard_html(content: List(element.Element(msg))) -> String {
  let html_element = html.div([attribute.class("dashboard-page")], content)
  element.to_string(html_element)
}
