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
import meal_planner/ui/types/ui_types

/// Progress bar component
///
/// Renders:
/// <div class="progress-bar">
///   <div class="progress-fill" style="width: 75%"></div>
/// </div>
pub fn progress_bar(current: Float, target: Float, color: String) -> String {
  // CONTRACT: Returns HTML string for progress bar
  let percentage = calculate_percentage(current, target)
  let pct_int = float_to_int(percentage)
  let width_style = "width: " <> int_to_string(pct_int) <> "%"

  "<div class=\"progress-bar "
  <> color
  <> "\">"
  <> "<div class=\"progress-fill\" style=\""
  <> width_style
  <> "\"></div>"
  <> "<span class=\"progress-text\">"
  <> int_to_string(pct_int)
  <> "</span>"
  <> "</div>"
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
) -> String {
  // CONTRACT: Returns HTML string for macro progress bar
  let percentage = calculate_percentage(current, target)
  let pct_int = float_to_int(percentage)
  let current_int = float_to_int(current)
  let target_int = float_to_int(target)
  let width_style = "width: " <> int_to_string(pct_int) <> "%"

  "<div class=\"macro-bar "
  <> color
  <> "\">"
  <> "<div class=\"macro-bar-header\">"
  <> "<span>"
  <> label
  <> "</span>"
  <> "<span>"
  <> int_to_string(current_int)
  <> "g / "
  <> int_to_string(target_int)
  <> "g</span>"
  <> "</div>"
  <> "<div class=\"progress-bar\">"
  <> "<div class=\"progress-fill\" style=\""
  <> width_style
  <> "\"></div>"
  <> "</div>"
  <> "</div>"
}

/// Macro badge (inline label with value)
///
/// Renders: <span class="macro-badge">Protein: 120g</span>
pub fn macro_badge(label: String, value: Float) -> String {
  // CONTRACT: Returns HTML string for macro badge
  let value_int = float_to_int(value)
  "<span class=\"macro-badge\">"
  <> label
  <> ": "
  <> int_to_string(value_int)
  <> "g</span>"
}

/// Macro badges group container (empty placeholder)
///
/// Renders: <div class="macro-badges"></div>
///
/// Note: This component is a container placeholder. Typically populated dynamically
/// with individual macro_badge components via your rendering framework.
pub fn macro_badges() -> String {
  // CONTRACT: Returns HTML string for macro badges group
  "<div class=\"macro-badges\"></div>"
}

/// Status badge/indicator
///
/// Renders: <span class="badge badge-success">Completed</span>
pub fn status_badge(label: String, status: ui_types.StatusType) -> String {
  // CONTRACT: Returns HTML string for status badge
  let status_class = case status {
    ui_types.StatusSuccess -> "status-success"
    ui_types.StatusWarning -> "status-warning"
    ui_types.StatusError -> "status-error"
    ui_types.StatusInfo -> "status-info"
  }

  "<span class=\"status-badge " <> status_class <> "\">" <> label <> "</span>"
}

/// Circular progress indicator (percentage)
///
/// Renders:
/// <div class="progress-circle">
///   <div class="circle-progress" style="--progress: 75%;"></div>
///   <span class="progress-percent">75%</span>
///   <span class="progress-label">Label</span>
/// </div>
pub fn progress_circle(percentage: Float, label: String) -> String {
  // CONTRACT: Returns HTML string for circular progress indicator
  let pct_int = float_to_int(percentage)

  "<div class=\"progress-circle\">"
  <> "<div class=\"circle-progress\" style=\"--progress: "
  <> int_to_string(pct_int)
  <> "%; \"></div>"
  <> "<span class=\"progress-percent\">"
  <> int_to_string(pct_int)
  <> "%</span>"
  <> "<span class=\"progress-label\">"
  <> label
  <> "</span>"
  <> "</div>"
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
) -> String {
  // CONTRACT: Returns HTML string for progress bar with label
  let percentage = calculate_percentage(current, target)
  let pct_int = float_to_int(percentage)
  let current_int = float_to_int(current)
  let width_style = "width: " <> int_to_string(pct_int) <> "%"

  "<div class=\"progress-with-label\">"
  <> "<div class=\"progress-header\">"
  <> "<span class=\"progress-label-text\">"
  <> label
  <> "</span>"
  <> "<span class=\"progress-value\">"
  <> int_to_string(current_int)
  <> " / "
  <> int_to_string(float_to_int(target))
  <> "</span>"
  <> "</div>"
  <> "<div class=\"progress-bar\">"
  <> "<div class=\"progress-fill\" style=\""
  <> width_style
  <> "\"></div>"
  <> "</div>"
  <> "</div>"
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
