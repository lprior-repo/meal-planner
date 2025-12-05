/// Tests for macro_summary panel components
///
/// Comprehensive TDD tests validating:
/// - Daily macro summary calculations
/// - Weekly macro summary aggregations
/// - Percentage calculations and capping
/// - Color coding logic (under/on-target/over/excess)
/// - Progress bar rendering
/// - Badge rendering
/// - Accessibility attributes
/// - Edge cases (zero targets, extreme values)
import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import lustre/element
import meal_planner/nutrition_constants
import meal_planner/types
import meal_planner/ui/components/macro_summary

pub fn main() {
  gleeunit.main()
}

// ===================================================================
// HELPER FUNCTIONS FOR TEST SETUP
// ===================================================================

/// Create a Macros record for testing
fn create_macros(protein: Float, fat: Float, carbs: Float) -> types.Macros {
  types.Macros(protein: protein, fat: fat, carbs: carbs)
}

/// Create a MacroTargets record for testing
fn create_targets(
  protein: Float,
  fat: Float,
  carbs: Float,
  calories: Float,
) -> macro_summary.MacroTargets {
  macro_summary.MacroTargets(
    protein: protein,
    fat: fat,
    carbs: carbs,
    calories: calories,
  )
}

/// Create a DailyLog for testing
fn create_daily_log(date: String, macros: types.Macros) -> types.DailyLog {
  types.DailyLog(
    date: date,
    entries: [],
    total_macros: macros,
    total_micronutrients: Nil,
  )
}

/// Standard targets used in tests
fn standard_targets() -> macro_summary.MacroTargets {
  create_targets(150.0, 60.0, 200.0, 2000.0)
}

// ===================================================================
// PERCENTAGE CALCULATION TESTS
// ===================================================================

pub fn calculate_percentage_at_target_test() {
  // Exactly 100% of target
  let percentage = macro_summary.calculate_percentage(150.0, 150.0)
  percentage
  |> should.equal(100.0)
}

pub fn calculate_percentage_above_target_test() {
  // 110% of target
  let percentage = macro_summary.calculate_percentage(165.0, 150.0)
  percentage
  |> should.equal(110.0)
}

pub fn calculate_percentage_below_target_test() {
  // 80% of target
  let percentage = macro_summary.calculate_percentage(120.0, 150.0)
  percentage
  |> should.equal(80.0)
}

pub fn calculate_percentage_zero_target_test() {
  // Zero target should return 0.0 (avoid division by zero)
  let percentage = macro_summary.calculate_percentage(100.0, 0.0)
  percentage
  |> should.equal(0.0)
}

pub fn calculate_percentage_caps_at_maximum_test() {
  // 200% exceeds maximum_display_percentage (150%), should cap
  let percentage = macro_summary.calculate_percentage(300.0, 150.0)
  percentage
  |> should.equal(nutrition_constants.maximum_display_percentage)
}

pub fn calculate_percentage_fractional_test() {
  // 123.456% should be returned as float
  let percentage = macro_summary.calculate_percentage(185.18, 150.0)
  percentage
  |> should.be_close_to(123.45, 0.1)
}

pub fn calculate_percentage_small_values_test() {
  // Small values should work correctly
  let percentage = macro_summary.calculate_percentage(0.5, 1.0)
  percentage
  |> should.equal(50.0)
}

// ===================================================================
// COLOR CODING LOGIC TESTS
// ===================================================================

pub fn get_target_color_under_threshold_test() {
  // Below 90% is "under"
  let color = macro_summary.get_target_color(80.0)
  color
  |> should.equal("status-under")
}

pub fn get_target_color_at_under_threshold_test() {
  // Exactly at 90% is "on-target"
  let color = macro_summary.get_target_color(90.0)
  color
  |> should.equal("status-on-target")
}

pub fn get_target_color_in_range_test() {
  // 100% is in target range
  let color = macro_summary.get_target_color(100.0)
  color
  |> should.equal("status-on-target")
}

pub fn get_target_color_at_upper_threshold_test() {
  // Exactly at 110% is "on-target" (upper bound inclusive)
  let color = macro_summary.get_target_color(110.0)
  color
  |> should.equal("status-on-target")
}

pub fn get_target_color_just_above_upper_test() {
  // Just above 110% is "over"
  let color = macro_summary.get_target_color(110.1)
  color
  |> should.equal("status-over")
}

pub fn get_target_color_at_over_threshold_test() {
  // Exactly at 130% is "over"
  let color = macro_summary.get_target_color(130.0)
  color
  |> should.equal("status-over")
}

pub fn get_target_color_excess_test() {
  // Above 130% is "excess"
  let color = macro_summary.get_target_color(140.0)
  color
  |> should.equal("status-excess")
}

pub fn get_target_color_zero_test() {
  // 0% is "under"
  let color = macro_summary.get_target_color(0.0)
  color
  |> should.equal("status-under")
}

pub fn get_target_color_extreme_values_test() {
  // Very high percentage is "excess"
  let color = macro_summary.get_target_color(250.0)
  color
  |> should.equal("status-excess")
}

// ===================================================================
// DAILY SUMMARY CREATION TESTS
// ===================================================================

pub fn create_daily_summary_basic_test() {
  let macros = create_macros(140.0, 55.0, 190.0)
  let log = create_daily_log("2025-12-05", macros)
  let targets = standard_targets()

  let summary = macro_summary.create_daily_summary(log, targets)

  summary.date
  |> should.equal("2025-12-05")

  summary.totals.protein
  |> should.equal(140.0)

  summary.totals.fat
  |> should.equal(55.0)

  summary.totals.carbs
  |> should.equal(190.0)
}

pub fn create_daily_summary_calories_calculated_test() {
  // Protein: 150g * 4 = 600
  // Fat: 60g * 9 = 540
  // Carbs: 200g * 4 = 800
  // Total: 1940
  let macros = create_macros(150.0, 60.0, 200.0)
  let log = create_daily_log("2025-12-05", macros)
  let targets = standard_targets()

  let summary = macro_summary.create_daily_summary(log, targets)

  summary.calories
  |> should.equal(1940.0)
}

pub fn create_daily_summary_percentages_calculated_test() {
  let macros = create_macros(150.0, 60.0, 200.0)
  let log = create_daily_log("2025-12-05", macros)
  let targets = standard_targets()

  let summary = macro_summary.create_daily_summary(log, targets)

  // All at 100% target
  summary.protein_percentage
  |> should.equal(100.0)

  summary.fat_percentage
  |> should.equal(100.0)

  summary.carbs_percentage
  |> should.equal(100.0)

  summary.calories_percentage
  |> should.equal(97.0)
}

pub fn create_daily_summary_under_target_test() {
  let macros = create_macros(120.0, 48.0, 150.0)
  let log = create_daily_log("2025-12-05", macros)
  let targets = standard_targets()

  let summary = macro_summary.create_daily_summary(log, targets)

  summary.protein_percentage
  |> should.equal(80.0)

  summary.fat_percentage
  |> should.equal(80.0)

  summary.carbs_percentage
  |> should.equal(75.0)
}

pub fn create_daily_summary_over_target_test() {
  let macros = create_macros(180.0, 72.0, 240.0)
  let log = create_daily_log("2025-12-05", macros)
  let targets = standard_targets()

  let summary = macro_summary.create_daily_summary(log, targets)

  summary.protein_percentage
  |> should.equal(120.0)

  summary.fat_percentage
  |> should.equal(120.0)

  summary.carbs_percentage
  |> should.equal(120.0)
}

pub fn create_daily_summary_zero_macros_test() {
  let macros = create_macros(0.0, 0.0, 0.0)
  let log = create_daily_log("2025-12-05", macros)
  let targets = standard_targets()

  let summary = macro_summary.create_daily_summary(log, targets)

  summary.calories
  |> should.equal(0.0)

  summary.protein_percentage
  |> should.equal(0.0)
}

pub fn create_daily_summary_stores_targets_test() {
  let macros = create_macros(150.0, 60.0, 200.0)
  let log = create_daily_log("2025-12-05", macros)
  let targets = standard_targets()

  let summary = macro_summary.create_daily_summary(log, targets)

  summary.targets.protein
  |> should.equal(150.0)

  summary.targets.fat
  |> should.equal(60.0)

  summary.targets.carbs
  |> should.equal(200.0)

  summary.targets.calories
  |> should.equal(2000.0)
}

// ===================================================================
// WEEKLY SUMMARY CREATION TESTS
// ===================================================================

pub fn create_weekly_summary_single_day_test() {
  let macros = create_macros(150.0, 60.0, 200.0)
  let log = create_daily_log("2025-12-05", macros)
  let targets = standard_targets()

  let summary = macro_summary.create_weekly_summary([log], targets)

  list.length(summary.daily_summaries)
  |> should.equal(1)

  summary.avg_protein
  |> should.equal(150.0)

  summary.avg_fat
  |> should.equal(60.0)

  summary.avg_carbs
  |> should.equal(200.0)

  summary.avg_calories
  |> should.equal(1940.0)
}

pub fn create_weekly_summary_seven_days_test() {
  let macros = create_macros(150.0, 60.0, 200.0)
  let logs = [
    create_daily_log("2025-11-29", macros),
    create_daily_log("2025-11-30", macros),
    create_daily_log("2025-12-01", macros),
    create_daily_log("2025-12-02", macros),
    create_daily_log("2025-12-03", macros),
    create_daily_log("2025-12-04", macros),
    create_daily_log("2025-12-05", macros),
  ]
  let targets = standard_targets()

  let summary = macro_summary.create_weekly_summary(logs, targets)

  list.length(summary.daily_summaries)
  |> should.equal(7)

  summary.avg_protein
  |> should.equal(150.0)

  summary.avg_fat
  |> should.equal(60.0)

  summary.avg_carbs
  |> should.equal(200.0)
}

pub fn create_weekly_summary_varying_macros_test() {
  let logs = [
    create_daily_log("2025-12-01", create_macros(100.0, 50.0, 150.0)),
    create_daily_log("2025-12-02", create_macros(150.0, 60.0, 200.0)),
    create_daily_log("2025-12-03", create_macros(200.0, 70.0, 250.0)),
  ]
  let targets = standard_targets()

  let summary = macro_summary.create_weekly_summary(logs, targets)

  // Average of [100, 150, 200]
  summary.avg_protein
  |> should.equal(150.0)

  // Average of [50, 60, 70]
  summary.avg_fat
  |> should.equal(60.0)

  // Average of [150, 200, 250]
  summary.avg_carbs
  |> should.equal(200.0)
}

pub fn create_weekly_summary_empty_logs_test() {
  let targets = standard_targets()
  let summary = macro_summary.create_weekly_summary([], targets)

  list.length(summary.daily_summaries)
  |> should.equal(0)

  summary.avg_protein
  |> should.equal(0.0)

  summary.avg_fat
  |> should.equal(0.0)

  summary.avg_carbs
  |> should.equal(0.0)

  summary.avg_calories
  |> should.equal(0.0)
}

pub fn create_weekly_summary_accumulates_correctly_test() {
  let logs = [
    create_daily_log("2025-12-01", create_macros(120.0, 55.0, 190.0)),
    create_daily_log("2025-12-02", create_macros(130.0, 58.0, 195.0)),
    create_daily_log("2025-12-03", create_macros(140.0, 62.0, 205.0)),
    create_daily_log("2025-12-04", create_macros(150.0, 60.0, 200.0)),
  ]
  let targets = standard_targets()

  let summary = macro_summary.create_weekly_summary(logs, targets)

  // (120 + 130 + 140 + 150) / 4 = 135
  summary.avg_protein
  |> should.equal(135.0)

  // (55 + 58 + 62 + 60) / 4 = 58.75
  summary.avg_fat
  |> should.be_close_to(58.75, 0.01)

  // (190 + 195 + 205 + 200) / 4 = 197.5
  summary.avg_carbs
  |> should.equal(197.5)
}

// ===================================================================
// RENDERING TESTS - Daily Macro Summary Panel
// ===================================================================

pub fn daily_macro_summary_panel_renders_test() {
  let macros = create_macros(150.0, 60.0, 200.0)
  let log = create_daily_log("2025-12-05", macros)
  let targets = standard_targets()
  let summary = macro_summary.create_daily_summary(log, targets)

  let html =
    macro_summary.daily_macro_summary_panel(summary)
    |> element.to_string

  html
  |> string.contains("macro-summary-panel daily")
  |> should.be_true
}

pub fn daily_macro_summary_panel_has_header_test() {
  let macros = create_macros(150.0, 60.0, 200.0)
  let log = create_daily_log("2025-12-05", macros)
  let targets = standard_targets()
  let summary = macro_summary.create_daily_summary(log, targets)

  let html =
    macro_summary.daily_macro_summary_panel(summary)
    |> element.to_string

  html
  |> string.contains("summary-header")
  |> should.be_true

  html
  |> string.contains("summary-title")
  |> should.be_true

  html
  |> string.contains("Daily Macros")
  |> should.be_true

  html
  |> string.contains("2025-12-05")
  |> should.be_true
}

pub fn daily_macro_summary_panel_displays_all_macros_test() {
  let macros = create_macros(150.0, 60.0, 200.0)
  let log = create_daily_log("2025-12-05", macros)
  let targets = standard_targets()
  let summary = macro_summary.create_daily_summary(log, targets)

  let html =
    macro_summary.daily_macro_summary_panel(summary)
    |> element.to_string

  // Check for macro names
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
}

pub fn daily_macro_summary_panel_displays_values_test() {
  let macros = create_macros(140.0, 55.0, 190.0)
  let log = create_daily_log("2025-12-05", macros)
  let targets = standard_targets()
  let summary = macro_summary.create_daily_summary(log, targets)

  let html =
    macro_summary.daily_macro_summary_panel(summary)
    |> element.to_string

  // Check that values are displayed
  html
  |> string.contains("140g / 150g")
  |> should.be_true

  html
  |> string.contains("55g / 60g")
  |> should.be_true

  html
  |> string.contains("190g / 200g")
  |> should.be_true
}

pub fn daily_macro_summary_panel_displays_percentages_test() {
  let macros = create_macros(150.0, 60.0, 200.0)
  let log = create_daily_log("2025-12-05", macros)
  let targets = standard_targets()
  let summary = macro_summary.create_daily_summary(log, targets)

  let html =
    macro_summary.daily_macro_summary_panel(summary)
    |> element.to_string

  // Should show percentages
  html
  |> string.contains("100%")
  |> should.be_true
}

pub fn daily_macro_summary_panel_color_codes_test() {
  let macros = create_macros(150.0, 60.0, 200.0)
  let log = create_daily_log("2025-12-05", macros)
  let targets = standard_targets()
  let summary = macro_summary.create_daily_summary(log, targets)

  let html =
    macro_summary.daily_macro_summary_panel(summary)
    |> element.to_string

  // When at target, should have status-on-target
  html
  |> string.contains("status-on-target")
  |> should.be_true
}

pub fn daily_macro_summary_panel_under_target_coloring_test() {
  let macros = create_macros(120.0, 48.0, 150.0)
  let log = create_daily_log("2025-12-05", macros)
  let targets = standard_targets()
  let summary = macro_summary.create_daily_summary(log, targets)

  let html =
    macro_summary.daily_macro_summary_panel(summary)
    |> element.to_string

  // When under 90%, should have status-under
  html
  |> string.contains("status-under")
  |> should.be_true
}

pub fn daily_macro_summary_panel_over_target_coloring_test() {
  let macros = create_macros(180.0, 72.0, 240.0)
  let log = create_daily_log("2025-12-05", macros)
  let targets = standard_targets()
  let summary = macro_summary.create_daily_summary(log, targets)

  let html =
    macro_summary.daily_macro_summary_panel(summary)
    |> element.to_string

  // When over 130%, should have status-excess or status-over
  let has_over_or_excess =
    string.contains(html, "status-over")
    || string.contains(html, "status-excess")

  has_over_or_excess
  |> should.be_true
}

pub fn daily_macro_summary_panel_progress_bars_test() {
  let macros = create_macros(150.0, 60.0, 200.0)
  let log = create_daily_log("2025-12-05", macros)
  let targets = standard_targets()
  let summary = macro_summary.create_daily_summary(log, targets)

  let html =
    macro_summary.daily_macro_summary_panel(summary)
    |> element.to_string

  // Check for progress bar elements
  html
  |> string.contains("progress-bar")
  |> should.be_true

  html
  |> string.contains("progress-fill")
  |> should.be_true
}

pub fn daily_macro_summary_panel_accessibility_test() {
  let macros = create_macros(150.0, 60.0, 200.0)
  let log = create_daily_log("2025-12-05", macros)
  let targets = standard_targets()
  let summary = macro_summary.create_daily_summary(log, targets)

  let html =
    macro_summary.daily_macro_summary_panel(summary)
    |> element.to_string

  // Check for accessibility attributes
  html
  |> string.contains("role=\"progressbar\"")
  |> should.be_true

  html
  |> string.contains("aria-valuenow")
  |> should.be_true

  html
  |> string.contains("aria-valuemin=\"0\"")
  |> should.be_true

  html
  |> string.contains("aria-valuemax=\"100\"")
  |> should.be_true

  html
  |> string.contains("aria-label")
  |> should.be_true
}

// ===================================================================
// RENDERING TESTS - Weekly Macro Summary Panel
// ===================================================================

pub fn weekly_macro_summary_panel_renders_test() {
  let logs = [
    create_daily_log("2025-12-01", create_macros(150.0, 60.0, 200.0)),
    create_daily_log("2025-12-02", create_macros(150.0, 60.0, 200.0)),
    create_daily_log("2025-12-03", create_macros(150.0, 60.0, 200.0)),
  ]
  let targets = standard_targets()
  let summary = macro_summary.create_weekly_summary(logs, targets)

  let html =
    macro_summary.weekly_macro_summary_panel(summary)
    |> element.to_string

  html
  |> string.contains("macro-summary-panel weekly")
  |> should.be_true
}

pub fn weekly_macro_summary_panel_header_test() {
  let logs = [
    create_daily_log("2025-12-01", create_macros(150.0, 60.0, 200.0)),
    create_daily_log("2025-12-02", create_macros(150.0, 60.0, 200.0)),
    create_daily_log("2025-12-03", create_macros(150.0, 60.0, 200.0)),
  ]
  let targets = standard_targets()
  let summary = macro_summary.create_weekly_summary(logs, targets)

  let html =
    macro_summary.weekly_macro_summary_panel(summary)
    |> element.to_string

  html
  |> string.contains("Weekly Average")
  |> should.be_true

  html
  |> string.contains("3 days")
  |> should.be_true
}

pub fn weekly_macro_summary_panel_displays_averages_test() {
  let logs = [
    create_daily_log("2025-12-01", create_macros(120.0, 55.0, 190.0)),
    create_daily_log("2025-12-02", create_macros(150.0, 60.0, 200.0)),
    create_daily_log("2025-12-03", create_macros(180.0, 65.0, 210.0)),
  ]
  let targets = standard_targets()
  let summary = macro_summary.create_weekly_summary(logs, targets)

  let html =
    macro_summary.weekly_macro_summary_panel(summary)
    |> element.to_string

  html
  |> string.contains("Avg Protein")
  |> should.be_true

  html
  |> string.contains("Avg Fat")
  |> should.be_true

  html
  |> string.contains("Avg Carbs")
  |> should.be_true

  html
  |> string.contains("Calories")
  |> should.be_true
}

pub fn weekly_macro_summary_panel_single_day_test() {
  let logs = [create_daily_log("2025-12-05", create_macros(150.0, 60.0, 200.0))]
  let targets = standard_targets()
  let summary = macro_summary.create_weekly_summary(logs, targets)

  let html =
    macro_summary.weekly_macro_summary_panel(summary)
    |> element.to_string

  html
  |> string.contains("1 days")
  |> should.be_true
}

pub fn weekly_macro_summary_panel_empty_test() {
  let targets = standard_targets()
  let summary = macro_summary.create_weekly_summary([], targets)

  let html =
    macro_summary.weekly_macro_summary_panel(summary)
    |> element.to_string

  html
  |> string.contains("0 days")
  |> should.be_true
}

// ===================================================================
// RENDERING TESTS - Macro Summary Badge
// ===================================================================

pub fn macro_summary_badge_renders_test() {
  let macros = create_macros(150.0, 60.0, 200.0)
  let targets = standard_targets()

  let html =
    macro_summary.macro_summary_badge(macros, targets)
    |> element.to_string

  html
  |> string.contains("macro-badge")
  |> should.be_true
}

pub fn macro_summary_badge_displays_macros_test() {
  let macros = create_macros(150.0, 60.0, 200.0)
  let targets = standard_targets()

  let html =
    macro_summary.macro_summary_badge(macros, targets)
    |> element.to_string

  html
  |> string.contains("P:150")
  |> should.be_true

  html
  |> string.contains("F:60")
  |> should.be_true

  html
  |> string.contains("C:200")
  |> should.be_true
}

pub fn macro_summary_badge_color_codes_on_target_test() {
  let macros = create_macros(150.0, 60.0, 200.0)
  let targets = standard_targets()

  let html =
    macro_summary.macro_summary_badge(macros, targets)
    |> element.to_string

  html
  |> string.contains("status-on-target")
  |> should.be_true
}

pub fn macro_summary_badge_color_codes_under_test() {
  let macros = create_macros(120.0, 48.0, 150.0)
  let targets = standard_targets()

  let html =
    macro_summary.macro_summary_badge(macros, targets)
    |> element.to_string

  html
  |> string.contains("status-under")
  |> should.be_true
}

pub fn macro_summary_badge_color_codes_over_test() {
  let macros = create_macros(180.0, 72.0, 240.0)
  let targets = standard_targets()

  let html =
    macro_summary.macro_summary_badge(macros, targets)
    |> element.to_string

  let has_over_or_excess =
    string.contains(html, "status-over")
    || string.contains(html, "status-excess")

  has_over_or_excess
  |> should.be_true
}

pub fn macro_summary_badge_truncates_values_test() {
  let macros = create_macros(150.7, 60.3, 200.9)
  let targets = standard_targets()

  let html =
    macro_summary.macro_summary_badge(macros, targets)
    |> element.to_string

  html
  |> string.contains("P:150")
  |> should.be_true

  html
  |> string.contains("F:60")
  |> should.be_true

  html
  |> string.contains("C:200")
  |> should.be_true
}

pub fn macro_summary_badge_zero_macros_test() {
  let macros = create_macros(0.0, 0.0, 0.0)
  let targets = standard_targets()

  let html =
    macro_summary.macro_summary_badge(macros, targets)
    |> element.to_string

  html
  |> string.contains("P:0")
  |> should.be_true

  html
  |> string.contains("F:0")
  |> should.be_true

  html
  |> string.contains("C:0")
  |> should.be_true
}

// ===================================================================
// EDGE CASES AND BOUNDARY TESTS
// ===================================================================

pub fn zero_target_protein_test() {
  let macros = create_macros(100.0, 60.0, 200.0)
  let log = create_daily_log("2025-12-05", macros)
  let targets = create_targets(0.0, 60.0, 200.0, 2000.0)

  let summary = macro_summary.create_daily_summary(log, targets)

  summary.protein_percentage
  |> should.equal(0.0)
}

pub fn extreme_percentage_capping_test() {
  // 300% should cap at 150%
  let macros = create_macros(450.0, 60.0, 200.0)
  let log = create_daily_log("2025-12-05", macros)
  let targets = standard_targets()

  let summary = macro_summary.create_daily_summary(log, targets)

  summary.protein_percentage
  |> should.equal(nutrition_constants.maximum_display_percentage)
}

pub fn very_small_target_test() {
  let macros = create_macros(5.0, 5.0, 5.0)
  let log = create_daily_log("2025-12-05", macros)
  let targets = create_targets(1.0, 1.0, 1.0, 40.0)

  let summary = macro_summary.create_daily_summary(log, targets)

  summary.protein_percentage
  |> should.equal(nutrition_constants.maximum_display_percentage)
}

pub fn negative_values_handled_test() {
  // Negative values might occur in data, should still calculate
  let macros = create_macros(-50.0, 60.0, 200.0)
  let log = create_daily_log("2025-12-05", macros)
  let targets = standard_targets()

  let summary = macro_summary.create_daily_summary(log, targets)

  // Should still calculate, even with negative
  summary.protein_percentage
  |> should.be_close_to(-33.33, 0.5)
}

pub fn very_large_macros_test() {
  let macros = create_macros(10_000.0, 10_000.0, 10_000.0)
  let log = create_daily_log("2025-12-05", macros)
  let targets = standard_targets()

  let summary = macro_summary.create_daily_summary(log, targets)

  // Very large values should cap at maximum display percentage
  summary.protein_percentage
  |> should.equal(nutrition_constants.maximum_display_percentage)

  summary.fat_percentage
  |> should.equal(nutrition_constants.maximum_display_percentage)

  summary.carbs_percentage
  |> should.equal(nutrition_constants.maximum_display_percentage)
}

pub fn fractional_calories_test() {
  // Protein: 145g * 4 = 580
  // Fat: 65.5g * 9 = 589.5
  // Carbs: 205.3g * 4 = 821.2
  // Total: 1990.7
  let macros = create_macros(145.0, 65.5, 205.3)
  let log = create_daily_log("2025-12-05", macros)
  let targets = standard_targets()

  let summary = macro_summary.create_daily_summary(log, targets)

  summary.calories
  |> should.be_close_to(1990.7, 0.01)
}

pub fn daily_summary_maintains_immutability_test() {
  let macros = create_macros(150.0, 60.0, 200.0)
  let log = create_daily_log("2025-12-05", macros)
  let targets = standard_targets()

  let summary1 = macro_summary.create_daily_summary(log, targets)
  let summary2 = macro_summary.create_daily_summary(log, targets)

  summary1.date
  |> should.equal(summary2.date)

  summary1.protein_percentage
  |> should.equal(summary2.protein_percentage)
}

pub fn weekly_summary_maintains_immutability_test() {
  let logs = [
    create_daily_log("2025-12-01", create_macros(150.0, 60.0, 200.0)),
    create_daily_log("2025-12-02", create_macros(150.0, 60.0, 200.0)),
  ]
  let targets = standard_targets()

  let summary1 = macro_summary.create_weekly_summary(logs, targets)
  let summary2 = macro_summary.create_weekly_summary(logs, targets)

  summary1.avg_protein
  |> should.equal(summary2.avg_protein)

  list.length(summary1.daily_summaries)
  |> should.equal(list.length(summary2.daily_summaries))
}

pub fn color_boundary_89_percent_test() {
  // 89% is just under threshold (90%), should be "under"
  let color = macro_summary.get_target_color(89.0)
  color
  |> should.equal("status-under")
}

pub fn color_boundary_90_percent_test() {
  // 90% is at threshold, should be "on-target"
  let color = macro_summary.get_target_color(90.0)
  color
  |> should.equal("status-on-target")
}

pub fn color_boundary_110_percent_test() {
  // 110% is at upper bound, should be "on-target"
  let color = macro_summary.get_target_color(110.0)
  color
  |> should.equal("status-on-target")
}

pub fn color_boundary_110_1_percent_test() {
  // 110.1% is just above upper, should be "over"
  let color = macro_summary.get_target_color(110.1)
  color
  |> should.equal("status-over")
}

pub fn color_boundary_130_percent_test() {
  // 130% is at excess threshold, should be "over"
  let color = macro_summary.get_target_color(130.0)
  color
  |> should.equal("status-over")
}

pub fn color_boundary_130_1_percent_test() {
  // 130.1% is just above excess threshold, should be "excess"
  let color = macro_summary.get_target_color(130.1)
  color
  |> should.equal("status-excess")
}

// ===================================================================
// INTEGRATION TESTS
// ===================================================================

pub fn daily_to_weekly_consistency_test() {
  let logs = [
    create_daily_log("2025-12-01", create_macros(150.0, 60.0, 200.0)),
    create_daily_log("2025-12-02", create_macros(150.0, 60.0, 200.0)),
    create_daily_log("2025-12-03", create_macros(150.0, 60.0, 200.0)),
  ]
  let targets = standard_targets()

  let weekly = macro_summary.create_weekly_summary(logs, targets)

  // All daily summaries should exist
  list.length(weekly.daily_summaries)
  |> should.equal(3)

  // Each should have the same percentage
  let first_daily = list.first(weekly.daily_summaries)

  case first_daily {
    Ok(daily) -> {
      daily.protein_percentage
      |> should.equal(100.0)
    }
    Error(_) -> should.fail()
  }
}

pub fn panel_rendering_consistency_test() {
  let macros = create_macros(150.0, 60.0, 200.0)
  let log = create_daily_log("2025-12-05", macros)
  let targets = standard_targets()
  let summary = macro_summary.create_daily_summary(log, targets)

  let html1 =
    macro_summary.daily_macro_summary_panel(summary)
    |> element.to_string

  let html2 =
    macro_summary.daily_macro_summary_panel(summary)
    |> element.to_string

  html1
  |> should.equal(html2)
}
