/// Tests for macro_progress component
///
/// Validates:
/// - Component rendering
/// - Percentage calculations
/// - Color coding logic
/// - Accessibility attributes
/// - HTMX integration
import gleam/string
import gleeunit
import gleeunit/should
import lustre/element
import meal_planner/ui/components/macro_progress

pub fn main() {
  gleeunit.main()
}

// ===================================================================
// TYPE CREATION TESTS
// ===================================================================

pub fn macro_progress_create_test() {
  let progress = macro_progress.macro_progress("Protein", 145.0, 180.0, "g")

  progress.macro_name
  |> should.equal("Protein")

  progress.current
  |> should.equal(145.0)

  progress.goal
  |> should.equal(180.0)

  progress.unit
  |> should.equal("g")
}

pub fn macro_set_create_test() {
  let macros =
    macro_progress.macro_set(
      145.0,
      180.0,
      65.0,
      70.0,
      210.0,
      250.0,
      1850.0,
      2100.0,
    )

  macros.protein.current
  |> should.equal(145.0)

  macros.fat.goal
  |> should.equal(70.0)

  macros.carbs.macro_name
  |> should.equal("Carbs")

  macros.calories.unit
  |> should.equal(" kcal")
}

// ===================================================================
// RENDERING TESTS
// ===================================================================

pub fn render_linear_progress_test() {
  let progress = macro_progress.macro_progress("Protein", 145.0, 180.0, "g")

  let html =
    macro_progress.render_progress_bar(progress)
    |> element.to_string

  // Check structure
  html
  |> string.contains("macro-progress linear")
  |> should.be_true

  html
  |> string.contains("progress-header")
  |> should.be_true

  html
  |> string.contains("progress-bar-container")
  |> should.be_true

  html
  |> string.contains("progress-footer")
  |> should.be_true

  // Check values rendered
  html
  |> string.contains("Protein")
  |> should.be_true

  html
  |> string.contains("145g / 180g")
  |> should.be_true

  html
  |> string.contains("80%")
  |> should.be_true
}

pub fn render_circular_progress_test() {
  let progress = macro_progress.macro_progress("Fat", 65.0, 70.0, "g")

  let html =
    macro_progress.render_circular_progress(progress)
    |> element.to_string

  // Check SVG structure
  html
  |> string.contains("macro-progress circular")
  |> should.be_true

  html
  |> string.contains("progress-circle-svg")
  |> should.be_true

  html
  |> string.contains("progress-circle-fill")
  |> should.be_true

  // Check values
  html
  |> string.contains("Fat")
  |> should.be_true

  html
  |> string.contains("65 / 70g")
  |> should.be_true

  html
  |> string.contains("92%")
  |> should.be_true
}

pub fn render_compact_progress_test() {
  let progress = macro_progress.macro_progress("Carbs", 210.0, 250.0, "g")

  let html =
    macro_progress.render_compact_progress(progress)
    |> element.to_string

  // Check structure
  html
  |> string.contains("macro-progress compact")
  |> should.be_true

  html
  |> string.contains("progress-label-compact")
  |> should.be_true

  html
  |> string.contains("progress-bar-compact")
  |> should.be_true

  // Check abbreviated label
  html
  |> string.contains(">C<")
  |> should.be_true

  html
  |> string.contains("210/250")
  |> should.be_true
}

// ===================================================================
// COLOR CODING TESTS
// ===================================================================

pub fn color_under_target_test() {
  // 70% - should be yellow/warning
  let progress = macro_progress.macro_progress("Protein", 126.0, 180.0, "g")

  let html =
    macro_progress.render_progress_bar(progress)
    |> element.to_string

  html
  |> string.contains("progress-under")
  |> should.be_true

  html
  |> string.contains("Under target")
  |> should.be_true
}

pub fn color_on_target_test() {
  // 90% - should be green/success
  let progress = macro_progress.macro_progress("Protein", 162.0, 180.0, "g")

  let html =
    macro_progress.render_progress_bar(progress)
    |> element.to_string

  html
  |> string.contains("progress-on-target")
  |> should.be_true

  html
  |> string.contains("On track")
  |> should.be_true
}

pub fn color_over_target_test() {
  // 130% - should be orange/warning
  let progress = macro_progress.macro_progress("Fat", 91.0, 70.0, "g")

  let html =
    macro_progress.render_progress_bar(progress)
    |> element.to_string

  html
  |> string.contains("progress-over")
  |> should.be_true

  html
  |> string.contains("Over target")
  |> should.be_true
}

pub fn color_excess_test() {
  // 160% - should be red/danger
  let progress = macro_progress.macro_progress("Carbs", 400.0, 250.0, "g")

  let html =
    macro_progress.render_progress_bar(progress)
    |> element.to_string

  html
  |> string.contains("progress-excess")
  |> should.be_true

  html
  |> string.contains("Excess")
  |> should.be_true
}

// ===================================================================
// ACCESSIBILITY TESTS
// ===================================================================

pub fn aria_attributes_test() {
  let progress = macro_progress.macro_progress("Protein", 145.0, 180.0, "g")

  let html =
    macro_progress.render_progress_bar(progress)
    |> element.to_string

  // Check ARIA attributes
  html
  |> string.contains("role=\"progressbar\"")
  |> should.be_true

  html
  |> string.contains("aria-valuenow=\"80\"")
  |> should.be_true

  html
  |> string.contains("aria-valuemin=\"0\"")
  |> should.be_true

  html
  |> string.contains("aria-valuemax=\"100\"")
  |> should.be_true

  html
  |> string.contains("aria-label=\"Protein: 145 of 180 g")
  |> should.be_true
}

pub fn circular_accessibility_test() {
  let progress = macro_progress.macro_progress("Fat", 65.0, 70.0, "g")

  let html =
    macro_progress.render_circular_progress(progress)
    |> element.to_string

  // Check ARIA labels for circular progress
  html
  |> string.contains("role=\"progressbar\"")
  |> should.be_true

  html
  |> string.contains("aria-label=\"Fat: 65 of 70 g, 92 percent")
  |> should.be_true
}

// ===================================================================
// MACRO SET TESTS
// ===================================================================

pub fn macro_set_linear_test() {
  let macros =
    macro_progress.macro_set(
      145.0,
      180.0,
      65.0,
      70.0,
      210.0,
      250.0,
      1850.0,
      2100.0,
    )

  let html =
    macro_progress.render_macro_set_linear(macros)
    |> element.to_string

  // Check all macros are present
  html
  |> string.contains("Protein")
  |> should.be_true

  html
  |> string.contains("Fat")
  |> should.be_true

  html
  |> string.contains("Carbs")
  |> should.be_true

  html
  |> string.contains("Calories")
  |> should.be_true

  html
  |> string.contains("macro-progress-set linear")
  |> should.be_true
}

pub fn macro_set_circular_test() {
  let macros =
    macro_progress.macro_set(
      145.0,
      180.0,
      65.0,
      70.0,
      210.0,
      250.0,
      1850.0,
      2100.0,
    )

  let html =
    macro_progress.render_macro_set_circular(macros)
    |> element.to_string

  html
  |> string.contains("macro-progress-set circular")
  |> should.be_true

  html
  |> string.contains("progress-circle-svg")
  |> should.be_true
}

pub fn macro_set_compact_test() {
  let macros =
    macro_progress.macro_set(
      145.0,
      180.0,
      65.0,
      70.0,
      210.0,
      250.0,
      1850.0,
      2100.0,
    )

  let html =
    macro_progress.render_macro_set_compact(macros)
    |> element.to_string

  html
  |> string.contains("macro-progress-set compact")
  |> should.be_true

  // Check abbreviated labels
  html
  |> string.contains(">P<")
  |> should.be_true

  html
  |> string.contains(">F<")
  |> should.be_true

  html
  |> string.contains(">C<")
  |> should.be_true
}

// ===================================================================
// HTMX INTEGRATION TESTS
// ===================================================================

pub fn htmx_refresh_attributes_test() {
  let macros =
    macro_progress.macro_set(
      145.0,
      180.0,
      65.0,
      70.0,
      210.0,
      250.0,
      1850.0,
      2100.0,
    )

  let html =
    macro_progress.render_macro_progress_with_refresh(
      macros,
      macro_progress.Linear,
      "/api/macros/today",
    )
    |> element.to_string

  // Check HTMX attributes
  html
  |> string.contains("hx-get=\"/api/macros/today\"")
  |> should.be_true

  html
  |> string.contains("hx-trigger=\"every 30s, macroUpdate from:body\"")
  |> should.be_true

  html
  |> string.contains("hx-target=\"#macro-progress\"")
  |> should.be_true

  html
  |> string.contains("hx-swap=\"outerHTML\"")
  |> should.be_true

  html
  |> string.contains("hx-indicator=\"#macro-loading\"")
  |> should.be_true
}

pub fn htmx_loading_indicator_test() {
  let macros =
    macro_progress.macro_set(
      145.0,
      180.0,
      65.0,
      70.0,
      210.0,
      250.0,
      1850.0,
      2100.0,
    )

  let html =
    macro_progress.render_macro_progress_with_refresh(
      macros,
      macro_progress.Linear,
      "/api/macros/today",
    )
    |> element.to_string

  // Check loading indicator
  html
  |> string.contains("id=\"macro-loading\"")
  |> should.be_true

  html
  |> string.contains("htmx-indicator")
  |> should.be_true

  html
  |> string.contains("Updating macros...")
  |> should.be_true

  html
  |> string.contains("role=\"status\"")
  |> should.be_true

  html
  |> string.contains("aria-live=\"polite\"")
  |> should.be_true
}

// ===================================================================
// EDGE CASE TESTS
// ===================================================================

pub fn zero_goal_test() {
  let progress = macro_progress.macro_progress("Protein", 100.0, 0.0, "g")

  let html =
    macro_progress.render_progress_bar(progress)
    |> element.to_string

  // Should handle division by zero gracefully
  html
  |> string.contains("0%")
  |> should.be_true
}

pub fn exceed_cap_test() {
  // 200% should be capped at visual cap (150%)
  let progress = macro_progress.macro_progress("Carbs", 500.0, 250.0, "g")

  let html =
    macro_progress.render_progress_bar(progress)
    |> element.to_string

  // Should show actual percentage
  html
  |> string.contains("200%")
  |> should.be_true

  // But width should be capped at 150% for visual display
  html
  |> string.contains("width: 150%")
  |> should.be_true
}

pub fn fractional_values_test() {
  let progress = macro_progress.macro_progress("Fat", 65.7, 70.3, "g")

  let html =
    macro_progress.render_progress_bar(progress)
    |> element.to_string

  // Should truncate to integers
  html
  |> string.contains("65g / 70g")
  |> should.be_true

  html
  |> string.contains("93%")
  |> should.be_true
}
