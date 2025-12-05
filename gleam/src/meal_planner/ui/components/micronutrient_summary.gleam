/// Micronutrient Daily Summary Component
///
/// This module provides a compact summary component for displaying daily micronutrient totals:
/// - Daily totals for key vitamins and minerals
/// - Daily value percentages
/// - Color coding (deficient/optimal/excess)
/// - Compact layout suitable for dashboard
///
/// Similar to macro_summary.gleam but for micronutrients.
/// See: Bead meal-planner-x4e2
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute.{attribute, class}
import lustre/element.{type Element, text}
import lustre/element/html.{div, h3, span}
import meal_planner/nutrition_constants
import meal_planner/types.{type Micronutrients}
import meal_planner/ui/components/micronutrient_panel

// ===================================================================
// TYPE DEFINITIONS
// ===================================================================

/// Daily micronutrient summary with key nutrients
pub type DailyMicronutrientSummary {
  DailyMicronutrientSummary(
    date: String,
    key_vitamins: List(micronutrient_panel.MicronutrientItem),
    key_minerals: List(micronutrient_panel.MicronutrientItem),
    other_nutrients: List(micronutrient_panel.MicronutrientItem),
    vitamin_adequacy: Float,
    mineral_adequacy: Float,
    overall_adequacy: Float,
  )
}

// ===================================================================
// HELPER FUNCTIONS
// ===================================================================

/// Calculate average adequacy percentage from a list of nutrients
fn calculate_adequacy(
  items: List(micronutrient_panel.MicronutrientItem),
) -> Float {
  case list.is_empty(items) {
    True -> 0.0
    False -> {
      let total =
        items
        |> list.fold(0.0, fn(sum, item) { sum +. item.percentage })
      let count = list.length(items) |> int.to_float
      total /. count
    }
  }
}

/// Select top priority vitamins (most important for daily tracking)
fn select_key_vitamins(
  vitamins: List(micronutrient_panel.MicronutrientItem),
) -> List(micronutrient_panel.MicronutrientItem) {
  // Priority order: Vitamin D, Vitamin C, Vitamin A, Vitamin B12
  let priority_order = ["Vitamin D", "Vitamin C", "Vitamin A", "Vitamin B12"]

  priority_order
  |> list.filter_map(fn(name) { list.find(vitamins, fn(v) { v.name == name }) })
  |> list.take(4)
}

/// Select top priority minerals (most important for daily tracking)
fn select_key_minerals(
  minerals: List(micronutrient_panel.MicronutrientItem),
) -> List(micronutrient_panel.MicronutrientItem) {
  // Priority order: Iron, Calcium, Magnesium, Potassium
  let priority_order = ["Iron", "Calcium", "Magnesium", "Potassium"]

  priority_order
  |> list.filter_map(fn(name) { list.find(minerals, fn(m) { m.name == name }) })
  |> list.take(4)
}

/// Select key other nutrients (fiber, sodium)
fn select_key_other(
  other: List(micronutrient_panel.MicronutrientItem),
) -> List(micronutrient_panel.MicronutrientItem) {
  let priority_order = ["Fiber", "Sodium"]

  priority_order
  |> list.filter_map(fn(name) { list.find(other, fn(n) { n.name == name }) })
  |> list.take(2)
}

/// Determine color class based on adequacy percentage
fn get_adequacy_color(percentage: Float) -> String {
  case percentage {
    p if p <. nutrition_constants.micronutrient_low_threshold -> "status-low"
    p if p <=. nutrition_constants.micronutrient_optimal_threshold ->
      "status-optimal"
    p if p <=. nutrition_constants.micronutrient_high_threshold -> "status-high"
    _ -> "status-excess"
  }
}

// ===================================================================
// SUMMARY CREATION
// ===================================================================

/// Create daily micronutrient summary from micronutrients data
pub fn create_daily_summary(
  date: String,
  micros: Option(Micronutrients),
) -> Option(DailyMicronutrientSummary) {
  case micros {
    None -> None
    Some(m) -> {
      let dv = micronutrient_panel.standard_daily_values()
      let vitamins = micronutrient_panel.extract_vitamins(m, dv)
      let minerals = micronutrient_panel.extract_minerals(m, dv)
      let other = micronutrient_panel.extract_other_nutrients(m, dv)

      // If no data at all, return None
      case
        list.is_empty(vitamins)
        && list.is_empty(minerals)
        && list.is_empty(other)
      {
        True -> None
        False -> {
          let key_vitamins = select_key_vitamins(vitamins)
          let key_minerals = select_key_minerals(minerals)
          let key_other = select_key_other(other)

          let vitamin_adequacy = calculate_adequacy(vitamins)
          let mineral_adequacy = calculate_adequacy(minerals)

          // Overall adequacy is average of vitamin and mineral adequacy
          let overall_adequacy = case
            list.is_empty(vitamins) && list.is_empty(minerals)
          {
            True -> 0.0
            False -> {
              case list.is_empty(vitamins), list.is_empty(minerals) {
                True, False -> mineral_adequacy
                False, True -> vitamin_adequacy
                _, _ -> { vitamin_adequacy +. mineral_adequacy } /. 2.0
              }
            }
          }

          Some(DailyMicronutrientSummary(
            date: date,
            key_vitamins: key_vitamins,
            key_minerals: key_minerals,
            other_nutrients: key_other,
            vitamin_adequacy: vitamin_adequacy,
            mineral_adequacy: mineral_adequacy,
            overall_adequacy: overall_adequacy,
          ))
        }
      }
    }
  }
}

// ===================================================================
// COMPONENT RENDERING
// ===================================================================

/// Render a compact micronutrient item (single line with percentage)
fn micronutrient_compact_item(
  item: micronutrient_panel.MicronutrientItem,
) -> Element(msg) {
  let percentage_str = item.percentage |> float.truncate |> int.to_string
  let color_class = get_adequacy_color(item.percentage)

  div([class("micro-compact-item " <> color_class)], [
    span([class("micro-compact-name")], [text(item.name)]),
    span([class("micro-compact-percentage")], [text(percentage_str <> "%")]),
  ])
}

/// Render compact micronutrient section
fn micronutrient_compact_section(
  title: String,
  items: List(micronutrient_panel.MicronutrientItem),
) -> Element(msg) {
  case items {
    [] -> element.none()
    _ -> {
      div([class("micro-compact-section")], [
        span([class("micro-compact-title")], [text(title)]),
        div(
          [class("micro-compact-items")],
          list.map(items, micronutrient_compact_item),
        ),
      ])
    }
  }
}

/// Render overall adequacy badge
fn adequacy_badge(label: String, percentage: Float) -> Element(msg) {
  let pct_str = percentage |> float.truncate |> int.to_string
  let color_class = get_adequacy_color(percentage)

  div([class("adequacy-badge " <> color_class)], [
    span([class("adequacy-label")], [text(label)]),
    span([class("adequacy-value")], [text(pct_str <> "%")]),
  ])
}

/// Render daily micronutrient summary panel
///
/// Displays:
/// - Date header
/// - Overall adequacy badge
/// - Key vitamins (top 4)
/// - Key minerals (top 4)
/// - Key other nutrients (fiber, sodium)
/// - Vitamin and mineral adequacy percentages
///
/// This is a compact version suitable for the dashboard,
/// showing only the most important nutrients.
pub fn daily_micronutrient_summary_panel(
  summary: DailyMicronutrientSummary,
) -> Element(msg) {
  div([class("micronutrient-summary-panel daily")], [
    div([class("summary-header")], [
      h3([class("summary-title")], [text("Micronutrient Summary")]),
      span([class("summary-date")], [text(summary.date)]),
    ]),
    div([class("summary-body")], [
      // Overall adequacy
      div([class("adequacy-badges")], [
        adequacy_badge("Overall", summary.overall_adequacy),
        adequacy_badge("Vitamins", summary.vitamin_adequacy),
        adequacy_badge("Minerals", summary.mineral_adequacy),
      ]),
      // Key nutrients
      micronutrient_compact_section("Key Vitamins", summary.key_vitamins),
      micronutrient_compact_section("Key Minerals", summary.key_minerals),
      micronutrient_compact_section("Other", summary.other_nutrients),
    ]),
  ])
}

/// Render empty state when no micronutrient data available
pub fn empty_micronutrient_summary() -> Element(msg) {
  div([class("micronutrient-summary-panel empty")], [
    div([class("summary-header")], [
      h3([class("summary-title")], [text("Micronutrient Summary")]),
    ]),
    div([class("summary-body")], [
      div([class("empty-message")], [
        text("No micronutrient data available for this date"),
      ]),
    ]),
  ])
}
