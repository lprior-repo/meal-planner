/// Weekly Calendar Component Module
///
/// Renders a 7-day weekly meal calendar with:
/// - 7 columns (Monday-Sunday)
/// - 3 meal slots per day (breakfast, lunch, dinner)
/// - Empty state placeholders
/// - Filled state with recipe names
/// - Semantic HTML structure
///
/// All components render as Lustre HTML elements suitable for SSR.
///
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute.{attribute, class}
import lustre/element.{type Element, text}
import lustre/element/html.{div, span, table, tbody, td, th, thead, tr}
import meal_planner/meal_plan.{type Meal}
import meal_planner/weekly_plan

// ===================================================================
// PUBLIC COMPONENT FUNCTIONS
// ===================================================================

/// Render weekly calendar with 7 day columns (empty state)
///
/// Renders a table-based calendar with columns for each day of the week.
/// Each column contains 3 meal slots (breakfast, lunch, dinner).
/// All slots are rendered in empty state.
pub fn render() -> Element(msg) {
  render_with_meals([])
}

/// Render weekly calendar with meal data
///
/// Renders a table-based calendar with meal data filled in.
/// Meals parameter is a list of lists, where outer list represents days (Monday-Sunday)
/// and inner list represents meals for that day (breakfast, lunch, dinner).
/// If a day has fewer than 3 meals, remaining slots are rendered as empty.
pub fn render_with_meals(meals_by_day: List(List(Meal))) -> Element(msg) {
  let days = weekly_plan.day_names()

  let header_row = render_header_row(days)
  let meal_rows = render_meal_rows_with_data(days, meals_by_day)

  div([class("weekly-calendar")], [
    table(
      [
        class("calendar-grid"),
        attribute("role", "grid"),
        attribute("aria-label", "Weekly meal calendar"),
      ],
      [header_row, meal_rows],
    ),
  ])
}

// ===================================================================
// PRIVATE HELPER FUNCTIONS
// ===================================================================

/// Render the header row with day names
fn render_header_row(days: List(String)) -> Element(msg) {
  let headers = days |> list.map(fn(day) { th([], [text(day)]) })

  thead([], [tr([], headers)])
}

/// Render meal rows (breakfast, lunch, dinner) with meal data
fn render_meal_rows_with_data(
  days: List(String),
  meals_by_day: List(List(Meal)),
) -> Element(msg) {
  let breakfast_row =
    render_meal_row_with_data(days, meals_by_day, 0, "breakfast")
  let lunch_row = render_meal_row_with_data(days, meals_by_day, 1, "lunch")
  let dinner_row = render_meal_row_with_data(days, meals_by_day, 2, "dinner")

  tbody([], [breakfast_row, lunch_row, dinner_row])
}

/// Render a single meal row with data across all 7 days
fn render_meal_row_with_data(
  days: List(String),
  meals_by_day: List(List(Meal)),
  meal_index: Int,
  meal_type: String,
) -> Element(msg) {
  let cells =
    list.index_map(days, fn(day, day_index) {
      let day_meals = get_at_index(meals_by_day, day_index)
      let meal = case day_meals {
        Some(meals) -> get_at_index(meals, meal_index)
        None -> None
      }
      render_meal_cell(day, meal_type, meal)
    })

  tr([class("meal-row meal-row-" <> meal_type)], cells)
}

/// Get element at index from list, returning None if out of bounds
fn get_at_index(items: List(a), index: Int) -> Option(a) {
  case items, index {
    [], _ -> None
    [first, ..], 0 -> Some(first)
    [_, ..rest], n -> get_at_index(rest, n - 1)
  }
}

/// Render a single meal cell with empty or filled state
///
/// If meal is None, renders empty state with placeholder.
/// If meal is Some(meal), renders filled state with recipe name.
fn render_meal_cell(
  day: String,
  meal_type: String,
  meal: Option(Meal),
) -> Element(msg) {
  let aria_label = day <> " " <> meal_type

  case meal {
    None -> render_empty_meal_cell(aria_label)
    Some(m) -> render_filled_meal_cell(aria_label, m)
  }
}

/// Render empty meal cell with placeholder
fn render_empty_meal_cell(aria_label: String) -> Element(msg) {
  td([class("meal-slot meal-slot-empty"), attribute("aria-label", aria_label)], [
    div([class("meal-content")], [
      span([class("placeholder")], [text("No meal planned")]),
    ]),
  ])
}

/// Render filled meal cell with recipe name
fn render_filled_meal_cell(aria_label: String, meal: Meal) -> Element(msg) {
  td(
    [class("meal-slot meal-slot-filled"), attribute("aria-label", aria_label)],
    [
      div([class("meal-content")], [
        span([class("recipe-name")], [text(meal.recipe.name)]),
      ]),
    ],
  )
}
