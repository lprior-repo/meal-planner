/// Weekly Calendar Component Module
///
/// Renders a 7-day weekly meal calendar with:
/// - 7 columns (Monday-Sunday)
/// - 3 meal slots per day (breakfast, lunch, dinner)
/// - Empty state placeholders
/// - Semantic HTML structure
///
/// All components render as HTML strings suitable for SSR.
///
import gleam/list
import gleam/string
import meal_planner/weekly_plan

// ===================================================================
// PUBLIC COMPONENT FUNCTIONS
// ===================================================================

/// Render weekly calendar with 7 day columns
///
/// Renders a table-based calendar with columns for each day of the week.
/// Each column contains 3 meal slots (breakfast, lunch, dinner).
pub fn render() -> String {
  let days = weekly_plan.day_names()

  let header_row = render_header_row(days)
  let meal_rows = render_meal_rows(days)

  "<div class=\"weekly-calendar\">"
  <> "<table class=\"calendar-grid\" role=\"grid\" aria-label=\"Weekly meal calendar\">"
  <> header_row
  <> meal_rows
  <> "</table>"
  <> "</div>"
}

// ===================================================================
// PRIVATE HELPER FUNCTIONS
// ===================================================================

/// Render the header row with day names
fn render_header_row(days: List(String)) -> String {
  let headers =
    days
    |> list.map(fn(day) { "<th>" <> day <> "</th>" })
    |> string.join("")

  "<thead><tr>" <> headers <> "</tr></thead>"
}

/// Render meal rows (breakfast, lunch, dinner)
fn render_meal_rows(days: List(String)) -> String {
  let breakfast_row = render_meal_row(days, "breakfast", "Breakfast")
  let lunch_row = render_meal_row(days, "lunch", "Lunch")
  let dinner_row = render_meal_row(days, "dinner", "Dinner")

  "<tbody>" <> breakfast_row <> lunch_row <> dinner_row <> "</tbody>"
}

/// Render a single meal row across all 7 days
fn render_meal_row(days: List(String), meal_type: String, meal_label: String) -> String {
  let cells =
    days
    |> list.map(fn(day) { render_meal_cell(day, meal_type) })
    |> string.join("")

  "<tr class=\"meal-row meal-row-" <> meal_type <> "\">" <> cells <> "</tr>"
}

/// Render a single meal cell (empty state by default)
fn render_meal_cell(day: String, meal_type: String) -> String {
  let aria_label = day <> " " <> meal_type

  "<td class=\"meal-slot meal-slot-empty\" aria-label=\""
  <> aria_label
  <> "\">"
  <> "<div class=\"meal-content\">"
  <> "<span class=\"placeholder\">No meal planned</span>"
  <> "</div>"
  <> "</td>"
}
