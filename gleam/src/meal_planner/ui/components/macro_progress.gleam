/// Macro Progress Bars Component Module
///
/// This module provides visual progress indicators for macronutrient tracking:
/// - Circular progress bars with SVG animations
/// - Linear progress bars with smooth transitions
/// - Color coding based on achievement (green/yellow/red)
/// - Percentage labels and current/goal displays
/// - Responsive design with CSS-only animations
/// - Full accessibility (ARIA labels, screen reader support)
///
/// All components use pure HTML/CSS with HTMX attributes (no JavaScript).
///
/// Features:
/// - Dynamic color transitions (under target: yellow, on target: green, over target: red)
/// - Smooth CSS animations for visual feedback
/// - Compact and detailed display modes
/// - Support for P/F/C macros and calories
/// - HTMX-powered real-time updates
///
/// See: Bead requirement for macro progress visualization
import gleam/float
import gleam/int
import lustre/attribute.{attribute, class}
import lustre/element.{type Element, text}
import lustre/element/html.{div, span, svg}
import meal_planner/nutrition_constants

// ===================================================================
// TYPE DEFINITIONS
// ===================================================================

/// Progress display style
pub type ProgressStyle {
  Linear
  Circular
  Compact
}

/// Macro progress data with current and goal values
pub type MacroProgress {
  MacroProgress(macro_name: String, current: Float, goal: Float, unit: String)
}

/// Complete macro set progress (P/F/C + Calories)
pub type MacroSet {
  MacroSet(
    protein: MacroProgress,
    fat: MacroProgress,
    carbs: MacroProgress,
    calories: MacroProgress,
  )
}

// ===================================================================
// COLOR CODING & STATUS
// ===================================================================

/// Determine color class based on achievement percentage
/// - Under (<80%): yellow/warning (deficiency)
/// - On target (80-120%): green/success
/// - Over (>120%): orange/red (excess)
fn get_color_class(percentage: Float) -> String {
  case percentage {
    p if p <. nutrition_constants.macro_under_threshold -> "progress-under"
    p if p <=. nutrition_constants.macro_on_target_upper -> "progress-on-target"
    p if p <=. nutrition_constants.macro_over_threshold -> "progress-over"
    _ -> "progress-excess"
  }
}

/// Get human-readable status text
fn get_status_text(percentage: Float) -> String {
  case percentage {
    p if p <. nutrition_constants.macro_under_threshold -> "Under target"
    p if p <=. nutrition_constants.macro_on_target_upper -> "On track"
    p if p <=. nutrition_constants.macro_over_threshold -> "Over target"
    _ -> "Excess"
  }
}

// ===================================================================
// CALCULATION HELPERS
// ===================================================================

/// Calculate percentage (0-100+)
fn calculate_percentage(current: Float, goal: Float) -> Float {
  case goal >. 0.0 {
    True -> {
      current /. goal *. 100.0
    }
    False -> 0.0
  }
}

/// Cap percentage for visual display (prevent overflow)
fn cap_percentage(percentage: Float) -> Float {
  case percentage >. nutrition_constants.progress_bar_visual_cap {
    True -> nutrition_constants.progress_bar_visual_cap
    False -> percentage
  }
}

/// Format float to integer string
fn format_int(value: Float) -> String {
  value |> float.truncate |> int.to_string
}

// ===================================================================
// LINEAR PROGRESS BAR
// ===================================================================

/// Render linear progress bar with label and values
///
/// Features:
/// - Current/goal display (e.g., "145g / 180g")
/// - Color-coded progress bar
/// - Percentage label
/// - Smooth CSS transitions
/// - ARIA attributes for accessibility
///
/// Example:
/// ```gleam
/// render_progress_bar(MacroProgress("Protein", 145.0, 180.0, "g"))
/// ```
///
/// Renders:
/// <div class="macro-progress linear progress-on-target">
///   <div class="progress-header">
///     <span class="progress-label">Protein</span>
///     <span class="progress-values">145g / 180g</span>
///   </div>
///   <div class="progress-bar-container">
///     <div class="progress-bar-fill" style="width: 80%"></div>
///   </div>
///   <div class="progress-footer">
///     <span class="progress-percentage">80%</span>
///     <span class="progress-status">On track</span>
///   </div>
/// </div>
pub fn render_progress_bar(progress: MacroProgress) -> Element(msg) {
  let MacroProgress(macro_name, current, goal, unit) = progress

  let percentage = calculate_percentage(current, goal)
  let visual_percentage = cap_percentage(percentage)
  let color_class = get_color_class(percentage)
  let status_text = get_status_text(percentage)

  let current_str = format_int(current)
  let goal_str = format_int(goal)
  let pct_str = format_int(percentage)
  let width_str = format_int(visual_percentage)

  div([class("macro-progress linear " <> color_class)], [
    // Header with label and values
    div([class("progress-header")], [
      span([class("progress-label")], [text(macro_name)]),
      span([class("progress-values")], [
        text(current_str <> unit <> " / " <> goal_str <> unit),
      ]),
    ]),
    // Progress bar with animated fill
    div(
      [
        class("progress-bar-container"),
        attribute("role", "progressbar"),
        attribute("aria-valuenow", pct_str),
        attribute("aria-valuemin", "0"),
        attribute("aria-valuemax", "100"),
        attribute(
          "aria-label",
          macro_name
            <> ": "
            <> current_str
            <> " of "
            <> goal_str
            <> " "
            <> unit
            <> ", "
            <> pct_str
            <> " percent, "
            <> status_text,
        ),
      ],
      [
        div(
          [
            class("progress-bar-fill"),
            attribute("style", "width: " <> width_str <> "%"),
          ],
          [],
        ),
      ],
    ),
    // Footer with percentage and status
    div([class("progress-footer")], [
      span([class("progress-percentage")], [text(pct_str <> "%")]),
      span([class("progress-status")], [text(status_text)]),
    ]),
  ])
}

// ===================================================================
// CIRCULAR PROGRESS BAR
// ===================================================================

/// Render circular progress bar with SVG
///
/// Features:
/// - SVG-based circular progress indicator
/// - CSS animations for smooth transitions
/// - Center text showing percentage
/// - Color coding based on achievement
/// - Accessible with ARIA labels
///
/// Example:
/// ```gleam
/// render_circular_progress(MacroProgress("Protein", 145.0, 180.0, "g"))
/// ```
///
/// Renders a circular SVG progress indicator with:
/// - Outer circle (background)
/// - Animated progress circle (colored stroke)
/// - Center percentage text
/// - Macro name and values below
pub fn render_circular_progress(progress: MacroProgress) -> Element(msg) {
  let MacroProgress(macro_name, current, goal, unit) = progress

  let percentage = calculate_percentage(current, goal)
  let visual_percentage = cap_percentage(percentage)
  let color_class = get_color_class(percentage)
  let status_text = get_status_text(percentage)

  let current_str = format_int(current)
  let goal_str = format_int(goal)
  let pct_str = format_int(percentage)

  // SVG circle calculations
  // Radius: 45, Circumference: 2πr ≈ 282.74
  let radius = 45.0
  let circumference = 2.0 *. 3.14159 *. radius
  let progress_offset =
    circumference *. { 1.0 -. { visual_percentage /. 100.0 } }
  let stroke_dasharray = float.to_string(circumference)
  let stroke_dashoffset = float.to_string(progress_offset)

  div(
    [
      class("macro-progress circular " <> color_class),
      attribute("role", "progressbar"),
      attribute("aria-valuenow", pct_str),
      attribute("aria-valuemin", "0"),
      attribute("aria-valuemax", "100"),
      attribute(
        "aria-label",
        macro_name
          <> ": "
          <> current_str
          <> " of "
          <> goal_str
          <> " "
          <> unit
          <> ", "
          <> pct_str
          <> " percent, "
          <> status_text,
      ),
    ],
    [
      // SVG circular progress
      svg(
        [
          class("progress-circle-svg"),
          attribute("width", "120"),
          attribute("height", "120"),
          attribute("viewBox", "0 0 120 120"),
          attribute("xmlns", "http://www.w3.org/2000/svg"),
        ],
        [
          // Background circle
          element.element(
            "circle",
            [
              class("progress-circle-bg"),
              attribute("cx", "60"),
              attribute("cy", "60"),
              attribute("r", float.to_string(radius)),
              attribute("fill", "none"),
              attribute("stroke", "#e5e7eb"),
              attribute("stroke-width", "8"),
            ],
            [],
          ),
          // Progress circle with animation
          element.element(
            "circle",
            [
              class("progress-circle-fill"),
              attribute("cx", "60"),
              attribute("cy", "60"),
              attribute("r", float.to_string(radius)),
              attribute("fill", "none"),
              attribute("stroke", "currentColor"),
              attribute("stroke-width", "8"),
              attribute("stroke-linecap", "round"),
              attribute("stroke-dasharray", stroke_dasharray),
              attribute("stroke-dashoffset", stroke_dashoffset),
              attribute("transform", "rotate(-90 60 60)"),
              attribute(
                "style",
                "transition: stroke-dashoffset 0.5s ease-in-out",
              ),
            ],
            [],
          ),
        ],
      ),
      // Center text with percentage
      div([class("progress-circle-text")], [
        span([class("progress-percentage-large")], [text(pct_str <> "%")]),
      ]),
      // Macro info below circle
      div([class("progress-circle-info")], [
        span([class("progress-label")], [text(macro_name)]),
        span([class("progress-values")], [
          text(current_str <> " / " <> goal_str <> unit),
        ]),
        span([class("progress-status")], [text(status_text)]),
      ]),
    ],
  )
}

// ===================================================================
// COMPACT PROGRESS BAR
// ===================================================================

/// Render compact progress indicator (minimal space)
///
/// Features:
/// - Single-line display
/// - Inline progress bar
/// - Abbreviated labels
/// - Suitable for cards or tight spaces
///
/// Example:
/// ```gleam
/// render_compact_progress(MacroProgress("Protein", 145.0, 180.0, "g"))
/// ```
pub fn render_compact_progress(progress: MacroProgress) -> Element(msg) {
  let MacroProgress(macro_name, current, goal, unit) = progress

  let percentage = calculate_percentage(current, goal)
  let visual_percentage = cap_percentage(percentage)
  let color_class = get_color_class(percentage)

  let current_str = format_int(current)
  let goal_str = format_int(goal)
  let pct_str = format_int(percentage)
  let width_str = format_int(visual_percentage)

  // Abbreviate macro names (Protein -> P, Fat -> F, Carbs -> C)
  let abbrev = case macro_name {
    "Protein" -> "P"
    "Fat" -> "F"
    "Carbs" -> "C"
    _ -> macro_name
  }

  div(
    [
      class("macro-progress compact " <> color_class),
      attribute("role", "progressbar"),
      attribute("aria-valuenow", pct_str),
      attribute("aria-valuemin", "0"),
      attribute("aria-valuemax", "100"),
      attribute(
        "aria-label",
        macro_name <> ": " <> current_str <> " of " <> goal_str <> " " <> unit,
      ),
    ],
    [
      span([class("progress-label-compact")], [text(abbrev)]),
      div([class("progress-bar-compact")], [
        div(
          [
            class("progress-bar-fill"),
            attribute("style", "width: " <> width_str <> "%"),
          ],
          [],
        ),
      ]),
      span([class("progress-values-compact")], [
        text(current_str <> "/" <> goal_str),
      ]),
    ],
  )
}

// ===================================================================
// MACRO SET DISPLAYS
// ===================================================================

/// Render all macros (P/F/C + Calories) as linear progress bars
///
/// Displays a complete set of macro progress bars in a grid layout
/// with HTMX support for real-time updates.
///
/// Example:
/// ```gleam
/// let macros = MacroSet(
///   protein: MacroProgress("Protein", 145.0, 180.0, "g"),
///   fat: MacroProgress("Fat", 65.0, 70.0, "g"),
///   carbs: MacroProgress("Carbs", 210.0, 250.0, "g"),
///   calories: MacroProgress("Calories", 1850.0, 2100.0, " kcal"),
/// )
/// render_macro_set_linear(macros)
/// ```
pub fn render_macro_set_linear(macros: MacroSet) -> Element(msg) {
  let MacroSet(protein, fat, carbs, calories) = macros

  div([class("macro-progress-set linear"), attribute("id", "macro-progress")], [
    render_progress_bar(protein),
    render_progress_bar(fat),
    render_progress_bar(carbs),
    render_progress_bar(calories),
  ])
}

/// Render all macros as circular progress bars
///
/// Displays macros in a grid of circular progress indicators.
/// Suitable for dashboard displays.
pub fn render_macro_set_circular(macros: MacroSet) -> Element(msg) {
  let MacroSet(protein, fat, carbs, calories) = macros

  div(
    [class("macro-progress-set circular"), attribute("id", "macro-progress")],
    [
      render_circular_progress(protein),
      render_circular_progress(fat),
      render_circular_progress(carbs),
      render_circular_progress(calories),
    ],
  )
}

/// Render all macros compactly (for cards)
///
/// Displays macros in a minimal vertical stack.
pub fn render_macro_set_compact(macros: MacroSet) -> Element(msg) {
  let MacroSet(protein, fat, carbs, calories) = macros

  div([class("macro-progress-set compact"), attribute("id", "macro-progress")], [
    render_compact_progress(protein),
    render_compact_progress(fat),
    render_compact_progress(carbs),
    render_compact_progress(calories),
  ])
}

// ===================================================================
// HTMX-ENABLED MACRO PROGRESS
// ===================================================================

/// Render macro progress with HTMX auto-refresh
///
/// Adds HTMX attributes to enable automatic updates when macro data changes.
/// Updates are triggered by the server (via SSE or polling).
///
/// Example:
/// ```gleam
/// render_macro_progress_with_refresh(macros, Linear, "/api/macros/today")
/// ```
///
/// HTMX attributes:
/// - hx-get: Endpoint to fetch updated macro data
/// - hx-trigger: Auto-refresh every 30s or on "macroUpdate" event
/// - hx-swap: Replace entire macro progress section
/// - hx-target: Update self (#macro-progress)
pub fn render_macro_progress_with_refresh(
  macros: MacroSet,
  style: ProgressStyle,
  refresh_url: String,
) -> Element(msg) {
  let base_element = case style {
    Linear -> render_macro_set_linear(macros)
    Circular -> render_macro_set_circular(macros)
    Compact -> render_macro_set_compact(macros)
  }

  // Wrap with HTMX attributes for auto-refresh
  div(
    [
      class("macro-progress-container"),
      attribute("hx-get", refresh_url),
      attribute("hx-trigger", "every 30s, macroUpdate from:body"),
      attribute("hx-target", "#macro-progress"),
      attribute("hx-swap", "outerHTML"),
      attribute("hx-indicator", "#macro-loading"),
    ],
    [
      base_element,
      // Loading indicator (hidden by default)
      div(
        [
          attribute("id", "macro-loading"),
          class("htmx-indicator"),
          attribute("role", "status"),
          attribute("aria-live", "polite"),
        ],
        [span([], [text("Updating macros...")])],
      ),
    ],
  )
}

// ===================================================================
// HELPER CONSTRUCTORS
// ===================================================================

/// Create MacroProgress from values
pub fn macro_progress(
  name: String,
  current: Float,
  goal: Float,
  unit: String,
) -> MacroProgress {
  MacroProgress(macro_name: name, current: current, goal: goal, unit: unit)
}

/// Create MacroSet from individual values
pub fn macro_set(
  protein_current: Float,
  protein_goal: Float,
  fat_current: Float,
  fat_goal: Float,
  carbs_current: Float,
  carbs_goal: Float,
  calories_current: Float,
  calories_goal: Float,
) -> MacroSet {
  MacroSet(
    protein: macro_progress("Protein", protein_current, protein_goal, "g"),
    fat: macro_progress("Fat", fat_current, fat_goal, "g"),
    carbs: macro_progress("Carbs", carbs_current, carbs_goal, "g"),
    calories: macro_progress(
      "Calories",
      calories_current,
      calories_goal,
      " kcal",
    ),
  )
}
