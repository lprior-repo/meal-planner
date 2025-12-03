/// Progress Component Tests
///
/// This module defines tests that verify progress components render correct HTML and percentages.

import gleeunit
import gleeunit/should
import gleam/string
import meal_planner/ui/components/progress
import meal_planner/ui/types/ui_types

pub fn main() {
  gleeunit.main()
}

// Custom assertion for string containment
fn assert_contains(haystack: String, needle: String) -> Nil {
  case string.contains(haystack, needle) {
    True -> Nil
    False -> {
      let _msg = string.concat([
        "\n",
        haystack,
        "\nshould contain\n",
        needle,
      ])
      should.fail()
    }
  }
}

// ===================================================================
// PROGRESS BAR TESTS
// ===================================================================

pub fn progress_bar_renders_container_test() {
  progress.progress_bar(50.0, 100.0, "primary")
  |> assert_contains("progress-bar")
}

pub fn progress_bar_contains_div_element_test() {
  progress.progress_bar(50.0, 100.0, "primary")
  |> assert_contains("<div")
}

pub fn progress_bar_renders_percentage_test() {
  progress.progress_bar(50.0, 100.0, "primary")
  |> assert_contains("50")
}

pub fn progress_bar_with_zero_progress_test() {
  progress.progress_bar(0.0, 100.0, "primary")
  |> assert_contains("0")
}

pub fn progress_bar_with_full_progress_test() {
  progress.progress_bar(100.0, 100.0, "success")
  |> assert_contains("100")
}

pub fn progress_bar_with_color_test() {
  progress.progress_bar(75.0, 100.0, "warning")
  |> assert_contains("warning")
}

pub fn progress_bar_decimal_percentage_test() {
  progress.progress_bar(33.33, 100.0, "primary")
  |> assert_contains("33")
}

// ===================================================================
// MACRO BAR TESTS
// ===================================================================

pub fn macro_bar_renders_label_test() {
  progress.macro_bar("Protein", 150.0, 200.0, "success")
  |> assert_contains("Protein")
}

pub fn macro_bar_renders_percentage_test() {
  progress.macro_bar("Carbs", 200.0, 300.0, "primary")
  |> assert_contains("66")
}

pub fn macro_bar_contains_macro_bar_class_test() {
  progress.macro_bar("Fat", 50.0, 75.0, "info")
  |> assert_contains("macro-bar")
}

pub fn macro_bar_with_color_test() {
  progress.macro_bar("Protein", 100.0, 150.0, "danger")
  |> assert_contains("danger")
}

pub fn macro_bar_over_target_test() {
  progress.macro_bar("Calories", 150.0, 100.0, "warning")
  |> assert_contains("150")
}

// ===================================================================
// MACRO BADGE TESTS
// ===================================================================

pub fn macro_badge_renders_label_test() {
  progress.macro_badge("Protein", 150.0)
  |> assert_contains("Protein")
}

pub fn macro_badge_renders_value_test() {
  progress.macro_badge("Carbs", 250.0)
  |> assert_contains("250")
}

pub fn macro_badge_contains_macro_badge_class_test() {
  progress.macro_badge("Fat", 75.0)
  |> assert_contains("macro-badge")
}

pub fn macro_badge_with_zero_value_test() {
  progress.macro_badge("Sodium", 0.0)
  |> assert_contains("0")
}

// ===================================================================
// MACRO BADGES GROUP TESTS
// ===================================================================

pub fn macro_badges_test() {
  progress.macro_badges()
  |> assert_contains("macro-badges")
}

// ===================================================================
// STATUS BADGE TESTS
// ===================================================================

pub fn status_badge_success_renders_test() {
  progress.status_badge("Complete", ui_types.StatusSuccess)
  |> assert_contains("Complete")
}

pub fn status_badge_warning_renders_test() {
  progress.status_badge("Pending", ui_types.StatusWarning)
  |> assert_contains("Pending")
}

pub fn status_badge_error_renders_test() {
  progress.status_badge("Failed", ui_types.StatusError)
  |> assert_contains("Failed")
}

pub fn status_badge_info_renders_test() {
  progress.status_badge("Info", ui_types.StatusInfo)
  |> assert_contains("Info")
}

pub fn status_badge_contains_status_badge_class_test() {
  progress.status_badge("Active", ui_types.StatusSuccess)
  |> assert_contains("status-badge")
}

pub fn status_badge_contains_status_type_class_test() {
  progress.status_badge("Error State", ui_types.StatusError)
  |> assert_contains("status-error")
}

// ===================================================================
// CIRCULAR PROGRESS TESTS
// ===================================================================

pub fn progress_circle_renders_percentage_test() {
  progress.progress_circle(75.0, "Progress")
  |> assert_contains("75")
}

pub fn progress_circle_renders_label_test() {
  progress.progress_circle(50.0, "Halfway")
  |> assert_contains("Halfway")
}

pub fn progress_circle_contains_circle_class_test() {
  progress.progress_circle(100.0, "Complete")
  |> assert_contains("progress-circle")
}

pub fn progress_circle_zero_percent_test() {
  progress.progress_circle(0.0, "Not Started")
  |> assert_contains("0")
}

pub fn progress_circle_full_percent_test() {
  progress.progress_circle(100.0, "Done")
  |> assert_contains("100")
}

// ===================================================================
// PROGRESS WITH LABEL TESTS
// ===================================================================

pub fn progress_with_label_renders_label_test() {
  progress.progress_with_label(60.0, 100.0, "Daily Goal")
  |> assert_contains("Daily Goal")
}

pub fn progress_with_label_renders_percentage_test() {
  progress.progress_with_label(45.0, 100.0, "Progress")
  |> assert_contains("45")
}

pub fn progress_with_label_contains_class_test() {
  progress.progress_with_label(80.0, 100.0, "Status")
  |> assert_contains("progress-with-label")
}

pub fn progress_with_label_decimal_current_test() {
  progress.progress_with_label(33.33, 100.0, "Metric")
  |> assert_contains("33")
}

pub fn progress_with_label_exceeds_target_test() {
  progress.progress_with_label(120.0, 100.0, "Over")
  |> assert_contains("120")
}
