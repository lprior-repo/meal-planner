/// Progress Component Tests
///
/// This module defines failing tests that establish contracts for progress components.
/// Tests verify that progress bars and indicators render correct HTML and percentages.
///
/// All tests are expected to FAIL until the progress component functions are implemented.

import gleeunit
import gleeunit/should
import meal_planner/ui/components/progress
import meal_planner/ui/types/ui_types

pub fn main() {
  gleeunit.main()
}

// ===================================================================
// PROGRESS BAR TESTS
// ===================================================================

pub fn progress_bar_renders_container_test() {
  progress.progress_bar(50.0, 100.0, "primary")
  |> should.contain("progress-bar")
}

pub fn progress_bar_contains_div_element_test() {
  progress.progress_bar(50.0, 100.0, "primary")
  |> should.contain("<div")
}

pub fn progress_bar_renders_percentage_test() {
  progress.progress_bar(50.0, 100.0, "primary")
  |> should.contain("50")
}

pub fn progress_bar_with_zero_progress_test() {
  progress.progress_bar(0.0, 100.0, "primary")
  |> should.contain("0")
}

pub fn progress_bar_with_full_progress_test() {
  progress.progress_bar(100.0, 100.0, "success")
  |> should.contain("100")
}

pub fn progress_bar_with_color_test() {
  progress.progress_bar(75.0, 100.0, "warning")
  |> should.contain("warning")
}

pub fn progress_bar_decimal_percentage_test() {
  progress.progress_bar(33.33, 100.0, "primary")
  |> should.contain("33")
}

// ===================================================================
// MACRO BAR TESTS
// ===================================================================

pub fn macro_bar_renders_label_test() {
  progress.macro_bar("Protein", 150.0, 200.0, "success")
  |> should.contain("Protein")
}

pub fn macro_bar_renders_percentage_test() {
  progress.macro_bar("Carbs", 200.0, 300.0, "primary")
  |> should.contain("66")
}

pub fn macro_bar_contains_macro_bar_class_test() {
  progress.macro_bar("Fat", 50.0, 75.0, "info")
  |> should.contain("macro-bar")
}

pub fn macro_bar_with_color_test() {
  progress.macro_bar("Protein", 100.0, 150.0, "danger")
  |> should.contain("danger")
}

pub fn macro_bar_over_target_test() {
  progress.macro_bar("Calories", 150.0, 100.0, "warning")
  |> should.contain("150")
}

// ===================================================================
// MACRO BADGE TESTS
// ===================================================================

pub fn macro_badge_renders_label_test() {
  progress.macro_badge("Protein", 150.0)
  |> should.contain("Protein")
}

pub fn macro_badge_renders_value_test() {
  progress.macro_badge("Carbs", 250.0)
  |> should.contain("250")
}

pub fn macro_badge_contains_macro_badge_class_test() {
  progress.macro_badge("Fat", 75.0)
  |> should.contain("macro-badge")
}

pub fn macro_badge_with_zero_value_test() {
  progress.macro_badge("Sodium", 0.0)
  |> should.contain("0")
}

// ===================================================================
// MACRO BADGES GROUP TESTS
// ===================================================================

pub fn macro_badges_test() {
  // Note: Macros type needs to be imported from shared types
  // This is a placeholder test - will need to update when Macros type is available
  progress.macro_badges()
  |> should.contain("macro-badges")
}

// ===================================================================
// STATUS BADGE TESTS
// ===================================================================

pub fn status_badge_success_renders_test() {
  progress.status_badge("Complete", ui_types.Success)
  |> should.contain("Complete")
}

pub fn status_badge_warning_renders_test() {
  progress.status_badge("Pending", ui_types.Warning)
  |> should.contain("Pending")
}

pub fn status_badge_error_renders_test() {
  progress.status_badge("Failed", ui_types.Error)
  |> should.contain("Failed")
}

pub fn status_badge_info_renders_test() {
  progress.status_badge("Info", ui_types.Info)
  |> should.contain("Info")
}

pub fn status_badge_contains_status_badge_class_test() {
  progress.status_badge("Active", ui_types.Success)
  |> should.contain("status-badge")
}

pub fn status_badge_contains_status_type_class_test() {
  progress.status_badge("Error State", ui_types.Error)
  |> should.contain("status-error")
}

// ===================================================================
// CIRCULAR PROGRESS TESTS
// ===================================================================

pub fn progress_circle_renders_percentage_test() {
  progress.progress_circle(75.0, "Progress")
  |> should.contain("75")
}

pub fn progress_circle_renders_label_test() {
  progress.progress_circle(50.0, "Halfway")
  |> should.contain("Halfway")
}

pub fn progress_circle_contains_circle_class_test() {
  progress.progress_circle(100.0, "Complete")
  |> should.contain("progress-circle")
}

pub fn progress_circle_zero_percent_test() {
  progress.progress_circle(0.0, "Not Started")
  |> should.contain("0")
}

pub fn progress_circle_full_percent_test() {
  progress.progress_circle(100.0, "Done")
  |> should.contain("100")
}

// ===================================================================
// PROGRESS WITH LABEL TESTS
// ===================================================================

pub fn progress_with_label_renders_label_test() {
  progress.progress_with_label(60.0, 100.0, "Daily Goal")
  |> should.contain("Daily Goal")
}

pub fn progress_with_label_renders_percentage_test() {
  progress.progress_with_label(45.0, 100.0, "Progress")
  |> should.contain("45")
}

pub fn progress_with_label_contains_class_test() {
  progress.progress_with_label(80.0, 100.0, "Status")
  |> should.contain("progress-with-label")
}

pub fn progress_with_label_decimal_current_test() {
  progress.progress_with_label(33.33, 100.0, "Metric")
  |> should.contain("33")
}

pub fn progress_with_label_exceeds_target_test() {
  progress.progress_with_label(120.0, 100.0, "Over")
  |> should.contain("120")
}
