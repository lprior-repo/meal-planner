/// Progress & Indicator Components Module
///
/// This module provides components for displaying progress and status:
/// - Progress bars with percentage fill
/// - Macro progress bars (protein, fat, carbs)
/// - Macro badges (inline labels)
/// - Status badges and indicators
/// - Circular progress indicators
///
/// All components render as Lustre HTML elements suitable for SSR.
///
/// See: docs/component_signatures.md (section: Progress Indicators)
import gleam/float
import gleam/int
import lustre/attribute
import lustre/element
import lustre/element/html
import meal_planner/ui/types/ui_types

/// Progress bar component
///
/// Renders:
/// <div class="progress-bar">
///   <div class="progress-fill" style="width: 75%"></div>
/// </div>
pub fn progress_bar(
  current: Float,
  target: Float,
  color: String,
) -> element.Element(msg) {
  // CONTRACT: Returns Lustre element for progress bar
  let percentage = calculate_percentage(current, target)
  let pct_int = float_to_int(percentage)
  let pct_str = int_to_string(pct_int)
  let width_style = pct_str <> "%"

  html.div(
    [
      attribute.class("progress-bar " <> color),
      attribute.attribute("role", "progressbar"),
      attribute.attribute("aria-valuenow", pct_str),
      attribute.attribute("aria-valuemin", "0"),
      attribute.attribute("aria-valuemax", "100"),
      attribute.attribute("aria-label", "Progress: " <> pct_str <> " percent"),
    ],
    [
      html.div([attribute.style("width", "width: " <> width_style)], []),
      html.span([attribute.class("progress-text")], [element.text(pct_str)]),
    ],
  )
}

/// Macro progress bar with label
///
/// Renders:
/// <div class="macro-bar">
///   <div class="macro-bar-header">
///     <span>Protein</span>
///     <span>120g / 150g</span>
///   </div>
///   <div class="progress-bar">
///     <div class="progress-fill" style="width: 80%"></div>
///   </div>
/// </div>
pub fn macro_bar(
  label: String,
  current: Float,
  target: Float,
  color: String,
) -> element.Element(msg) {
  // CONTRACT: Returns Lustre element for macro progress bar
  let percentage = calculate_percentage(current, target)
  let pct_int = float_to_int(percentage)
  let current_int = float_to_int(current)
  let target_int = float_to_int(target)
  let pct_str = int_to_string(pct_int)
  let current_str = int_to_string(current_int)
  let target_str = int_to_string(target_int)
  let width_style = pct_str <> "%"

  html.div([attribute.class("macro-bar " <> color)], [
    html.div([attribute.class("macro-bar-header")], [
      html.span([], [element.text(label)]),
      html.span([], [element.text(current_str <> "g / " <> target_str <> "g")]),
    ]),
    html.div(
      [
        attribute.class("progress-bar"),
        attribute.attribute("role", "progressbar"),
        attribute.attribute("aria-valuenow", pct_str),
        attribute.attribute("aria-valuemin", "0"),
        attribute.attribute("aria-valuemax", "100"),
        attribute.attribute(
          "aria-label",
          label <> ": " <> current_str <> " of " <> target_str <> " grams",
        ),
      ],
      [html.div([attribute.style("width", "width: " <> width_style)], [])],
    ),
  ])
}

/// Macro badge (inline label with value)
///
/// Renders: <span class="macro-badge">Protein: 120g</span>
pub fn macro_badge(label: String, value: Float) -> element.Element(msg) {
  // CONTRACT: Returns Lustre element for macro badge
  let value_int = float_to_int(value)
  let value_str = int_to_string(value_int)

  html.span([attribute.class("macro-badge")], [
    element.text(label <> ": " <> value_str <> "g"),
  ])
}

/// Macro badges group container (empty placeholder)
///
/// Renders: <div class="macro-badges"></div>
///
/// Note: This component is a container placeholder. Typically populated dynamically
/// with individual macro_badge components via your rendering framework.
pub fn macro_badges() -> element.Element(msg) {
  // CONTRACT: Returns Lustre element for macro badges group
  html.div([attribute.class("macro-badges")], [])
}

/// Status badge/indicator
///
/// Renders: <span class="badge badge-success">Completed</span>
pub fn status_badge(
  label: String,
  status: ui_types.StatusType,
) -> element.Element(msg) {
  // CONTRACT: Returns Lustre element for status badge
  let status_class = case status {
    ui_types.StatusSuccess -> "status-success"
    ui_types.StatusWarning -> "status-warning"
    ui_types.StatusError -> "status-error"
    ui_types.StatusInfo -> "status-info"
  }

  html.span([attribute.class("status-badge " <> status_class)], [
    element.text(label),
  ])
}

/// Circular progress indicator (percentage)
///
/// Renders:
/// <div class="progress-circle">
///   <div class="circle-progress" style="--progress: 75%;"></div>
///   <span class="progress-percent">75%</span>
///   <span class="progress-label">Label</span>
/// </div>
pub fn progress_circle(percentage: Float, label: String) -> element.Element(msg) {
  // CONTRACT: Returns Lustre element for circular progress indicator
  let pct_int = float_to_int(percentage)
  let pct_str = int_to_string(pct_int)

  html.div(
    [
      attribute.class("progress-circle"),
      attribute.attribute("role", "progressbar"),
      attribute.attribute("aria-valuenow", pct_str),
      attribute.attribute("aria-valuemin", "0"),
      attribute.attribute("aria-valuemax", "100"),
      attribute.attribute("aria-label", label <> ": " <> pct_str <> " percent"),
    ],
    [
      html.div(
        [
          attribute.class("circle-progress"),
          attribute.style("--progress", "--progress: " <> pct_str <> "%"),
        ],
        [],
      ),
      html.span([attribute.class("progress-percent")], [
        element.text(pct_str <> "%"),
      ]),
      html.span([attribute.class("progress-label")], [element.text(label)]),
    ],
  )
}

/// Linear progress bar with percentage text
///
/// Renders:
/// <div class="progress-with-label">
///   <div class="progress-header">
///     <span class="progress-label-text">Calories</span>
///     <span class="progress-value">1850 / 2100</span>
///   </div>
///   <div class="progress-bar">...</div>
/// </div>
pub fn progress_with_label(
  current: Float,
  target: Float,
  label: String,
) -> element.Element(msg) {
  // CONTRACT: Returns Lustre element for progress bar with label
  let percentage = calculate_percentage(current, target)
  let pct_int = float_to_int(percentage)
  let current_int = float_to_int(current)
  let target_int = float_to_int(target)
  let pct_str = int_to_string(pct_int)
  let current_str = int_to_string(current_int)
  let target_str = int_to_string(target_int)
  let width_style = pct_str <> "%"

  html.div([attribute.class("progress-with-label")], [
    html.div([attribute.class("progress-header")], [
      html.span([attribute.class("progress-label-text")], [element.text(label)]),
      html.span([attribute.class("progress-value")], [
        element.text(current_str <> " / " <> target_str),
      ]),
    ]),
    html.div(
      [
        attribute.class("progress-bar"),
        attribute.attribute("role", "progressbar"),
        attribute.attribute("aria-valuenow", pct_str),
        attribute.attribute("aria-valuemin", "0"),
        attribute.attribute("aria-valuemax", "100"),
        attribute.attribute(
          "aria-label",
          label <> ": " <> current_str <> " of " <> target_str,
        ),
      ],
      [html.div([attribute.style("width", "width: " <> width_style)], [])],
    ),
  ])
}

// ===================================================================
// INTERNAL HELPERS
// ===================================================================

/// Convert float to integer (truncate decimal)
fn float_to_int(value: Float) -> Int {
  value |> float.truncate
}

/// Convert integer to string
fn int_to_string(value: Int) -> String {
  int.to_string(value)
}

/// Calculate percentage with bounds (0-100)
///
/// Returns 100 if current > target, otherwise (current / target) * 100
fn calculate_percentage(current: Float, target: Float) -> Float {
  case target >. 0.0 {
    True -> {
      let pct = current /. target *. 100.0
      case pct >. 100.0 {
        True -> 100.0
        False -> pct
      }
    }
    False -> 0.0
  }
}
// ===================================================================
// Additional component enhancements will be added as needed
// ===================================================================
