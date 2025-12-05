/// Progress Component Test Suite
///
/// Tests for all progress and indicator components:
/// - Progress bars with different values (0%, 50%, 100%)
/// - Macro progress bars and badges
/// - Status badges with all status types
/// - Circular progress indicators
/// - Progress bars with labels
/// - Property tests for valid ranges
/// - Accessibility (ARIA attributes)
/// - Visual states and edge cases
///
import gleam/string
import gleeunit
import gleeunit/should
import lustre/element
import meal_planner/ui/components/progress
import meal_planner/ui/types/ui_types

pub fn main() {
  gleeunit.main()
}

// ===================================================================
// PROGRESS BAR TESTS
// ===================================================================

pub fn progress_bar_zero_percent_test() {
  let result = progress.progress_bar(0.0, 100.0, "primary") |> element.to_string

  // Should render with 0% width
  result
  |> should.equal(
    "<div class=\"progress-bar primary\" role=\"progressbar\" aria-valuenow=\"0\" aria-valuemin=\"0\" aria-valuemax=\"100\" aria-label=\"Progress: 0 percent\"><div class=\"progress-fill\" style=\"width: 0%\"></div><span class=\"progress-text\">0</span></div>",
  )

  // Verify contains essential parts
  result |> string.contains("width: 0%") |> should.be_true
  result |> string.contains("aria-valuenow=\"0\"") |> should.be_true
  result |> string.contains("progress-text\">0</span>") |> should.be_true
}

pub fn progress_bar_fifty_percent_test() {
  let result = progress.progress_bar(50.0, 100.0, "success") |> element.to_string

  // Should render with 50% width
  result |> string.contains("width: 50%") |> should.be_true
  result |> string.contains("aria-valuenow=\"50\"") |> should.be_true
  result |> string.contains("progress-text\">50</span>") |> should.be_true
  result |> string.contains("progress-bar success") |> should.be_true
}

pub fn progress_bar_hundred_percent_test() {
  let result = progress.progress_bar(100.0, 100.0, "warning") |> element.to_string

  // Should render with 100% width
  result |> string.contains("width: 100%") |> should.be_true
  result |> string.contains("aria-valuenow=\"100\"") |> should.be_true
  result |> string.contains("progress-text\">100</span>") |> should.be_true
}

pub fn progress_bar_over_hundred_percent_test() {
  let result = progress.progress_bar(150.0, 100.0, "danger") |> element.to_string

  // Should cap at 100%
  result |> string.contains("width: 100%") |> should.be_true
  result |> string.contains("aria-valuenow=\"100\"") |> should.be_true
}

pub fn progress_bar_fractional_percentage_test() {
  let result = progress.progress_bar(33.7, 100.0, "info") |> element.to_string

  // Should truncate to integer
  result |> string.contains("width: 33%") |> should.be_true
  result |> string.contains("aria-valuenow=\"33\"") |> should.be_true
}

pub fn progress_bar_negative_current_test() {
  let result = progress.progress_bar(-10.0, 100.0, "primary") |> element.to_string

  // Should handle negative values (renders as 0% due to percentage calculation)
  result |> string.contains("width: 0%") |> should.be_true
  result |> string.contains("aria-valuenow=\"0\"") |> should.be_true
}

pub fn progress_bar_zero_target_test() {
  let result = progress.progress_bar(50.0, 0.0, "primary") |> element.to_string

  // Should handle zero target gracefully (returns 0%)
  result |> string.contains("width: 0%") |> should.be_true
  result |> string.contains("aria-valuenow=\"0\"") |> should.be_true
}

pub fn progress_bar_accessibility_attributes_test() {
  let result = progress.progress_bar(75.0, 100.0, "primary") |> element.to_string

  // Should have all required ARIA attributes
  result |> string.contains("role=\"progressbar\"") |> should.be_true
  result |> string.contains("aria-valuenow=\"75\"") |> should.be_true
  result |> string.contains("aria-valuemin=\"0\"") |> should.be_true
  result |> string.contains("aria-valuemax=\"100\"") |> should.be_true
  result
  |> string.contains("aria-label=\"Progress: 75 percent\"")
  |> should.be_true
}

pub fn progress_bar_color_classes_test() {
  let primary = progress.progress_bar(50.0, 100.0, "primary") |> element.to_string
  let success = progress.progress_bar(50.0, 100.0, "success") |> element.to_string
  let warning = progress.progress_bar(50.0, 100.0, "warning") |> element.to_string
  let danger = progress.progress_bar(50.0, 100.0, "danger") |> element.to_string

  primary |> string.contains("progress-bar primary") |> should.be_true
  success |> string.contains("progress-bar success") |> should.be_true
  warning |> string.contains("progress-bar warning") |> should.be_true
  danger |> string.contains("progress-bar danger") |> should.be_true
}

// ===================================================================
// MACRO PROGRESS BAR TESTS
// ===================================================================

pub fn macro_bar_basic_test() {
  let result = progress.macro_bar("Protein", 120.0, 150.0, "protein") |> element.to_string

  // Should render with label and values
  result |> string.contains("<span>Protein</span>") |> should.be_true
  result |> string.contains("<span>120g / 150g</span>") |> should.be_true
  result |> string.contains("width: 80%") |> should.be_true
  result |> string.contains("macro-bar protein") |> should.be_true
}

pub fn macro_bar_zero_progress_test() {
  let result = progress.macro_bar("Carbs", 0.0, 200.0, "carbs") |> element.to_string

  result |> string.contains("<span>0g / 200g</span>") |> should.be_true
  result |> string.contains("width: 0%") |> should.be_true
}

pub fn macro_bar_full_progress_test() {
  let result = progress.macro_bar("Fat", 60.0, 60.0, "fat") |> element.to_string

  result |> string.contains("<span>60g / 60g</span>") |> should.be_true
  result |> string.contains("width: 100%") |> should.be_true
}

pub fn macro_bar_over_target_test() {
  let result = progress.macro_bar("Protein", 180.0, 150.0, "protein") |> element.to_string

  // Should cap at 100% but show actual values
  result |> string.contains("<span>180g / 150g</span>") |> should.be_true
  result |> string.contains("width: 100%") |> should.be_true
}

pub fn macro_bar_accessibility_test() {
  let result = progress.macro_bar("Protein", 120.0, 150.0, "protein") |> element.to_string

  // Should have proper ARIA attributes
  result |> string.contains("role=\"progressbar\"") |> should.be_true
  result |> string.contains("aria-valuenow=\"80\"") |> should.be_true
  result |> string.contains("aria-valuemin=\"0\"") |> should.be_true
  result |> string.contains("aria-valuemax=\"100\"") |> should.be_true
  result
  |> string.contains("aria-label=\"Protein: 120 of 150 grams\"")
  |> should.be_true
}

pub fn macro_bar_fractional_values_test() {
  let result = progress.macro_bar("Fat", 45.7, 60.0, "fat") |> element.to_string

  // Should truncate to integers
  result |> string.contains("<span>45g / 60g</span>") |> should.be_true
  result |> string.contains("width: 76%") |> should.be_true
}

// ===================================================================
// MACRO COLOR CODING TESTS (meal-planner-uzr.2)
// ===================================================================

pub fn macro_bar_protein_color_test() {
  let result = progress.macro_bar("Protein", 120.0, 150.0, "macro-protein") |> element.to_string

  // Should have protein class for blue color
  result |> string.contains("macro-bar macro-protein") |> should.be_true
  result |> string.contains("<span>Protein</span>") |> should.be_true
  result |> string.contains("120g / 150g") |> should.be_true
}

pub fn macro_bar_fat_color_test() {
  let result = progress.macro_bar("Fat", 50.0, 70.0, "macro-fat") |> element.to_string

  // Should have fat class for orange color
  result |> string.contains("macro-bar macro-fat") |> should.be_true
  result |> string.contains("<span>Fat</span>") |> should.be_true
  result |> string.contains("50g / 70g") |> should.be_true
}

pub fn macro_bar_carbs_color_test() {
  let result = progress.macro_bar("Carbs", 150.0, 200.0, "macro-carbs") |> element.to_string

  // Should have carbs class for green color
  result |> string.contains("macro-bar macro-carbs") |> should.be_true
  result |> string.contains("<span>Carbs</span>") |> should.be_true
  result |> string.contains("150g / 200g") |> should.be_true
}

pub fn macro_bar_all_three_macros_test() {
  // Test all three macro types together (as they appear on dashboard)
  let protein = progress.macro_bar("Protein", 120.0, 150.0, "macro-protein") |> element.to_string
  let fat = progress.macro_bar("Fat", 50.0, 70.0, "macro-fat") |> element.to_string
  let carbs = progress.macro_bar("Carbs", 150.0, 200.0, "macro-carbs") |> element.to_string

  // Verify all three have correct structure
  protein |> string.contains("macro-protein") |> should.be_true
  fat |> string.contains("macro-fat") |> should.be_true
  carbs |> string.contains("macro-carbs") |> should.be_true

  // All should have progress bars
  protein |> string.contains("progress-bar") |> should.be_true
  fat |> string.contains("progress-bar") |> should.be_true
  carbs |> string.contains("progress-bar") |> should.be_true
}

// ===================================================================
// MACRO BADGE TESTS
// ===================================================================

pub fn macro_badge_basic_test() {
  let result = progress.macro_badge("Protein", 120.0) |> element.to_string

  result
  |> should.equal("<span class=\"macro-badge\">Protein: 120g</span>")
}

pub fn macro_badge_zero_value_test() {
  let result = progress.macro_badge("Carbs", 0.0) |> element.to_string

  result |> should.equal("<span class=\"macro-badge\">Carbs: 0g</span>")
}

pub fn macro_badge_fractional_value_test() {
  let result = progress.macro_badge("Fat", 45.7) |> element.to_string

  // Should truncate to integer
  result |> should.equal("<span class=\"macro-badge\">Fat: 45g</span>")
}

pub fn macro_badge_large_value_test() {
  let result = progress.macro_badge("Calories", 2500.0) |> element.to_string

  result |> should.equal("<span class=\"macro-badge\">Calories: 2500g</span>")
}

pub fn macro_badges_container_test() {
  let result = progress.macro_badges() |> element.to_string

  result |> should.equal("<div class=\"macro-badges\"></div>")
}

// ===================================================================
// STATUS BADGE TESTS
// ===================================================================

pub fn status_badge_success_test() {
  let result = progress.status_badge("Completed", ui_types.StatusSuccess) |> element.to_string

  result
  |> should.equal(
    "<span class=\"status-badge status-success\">Completed</span>",
  )
}

pub fn status_badge_warning_test() {
  let result = progress.status_badge("Low Protein", ui_types.StatusWarning) |> element.to_string

  result
  |> should.equal(
    "<span class=\"status-badge status-warning\">Low Protein</span>",
  )
}

pub fn status_badge_error_test() {
  let result = progress.status_badge("Over Calories", ui_types.StatusError) |> element.to_string

  result
  |> should.equal(
    "<span class=\"status-badge status-error\">Over Calories</span>",
  )
}

pub fn status_badge_info_test() {
  let result = progress.status_badge("On Track", ui_types.StatusInfo) |> element.to_string

  result
  |> should.equal("<span class=\"status-badge status-info\">On Track</span>")
}

pub fn status_badge_all_types_test() {
  // Test all status types are correctly mapped
  let success = progress.status_badge("Success", ui_types.StatusSuccess) |> element.to_string
  let warning = progress.status_badge("Warning", ui_types.StatusWarning) |> element.to_string
  let error = progress.status_badge("Error", ui_types.StatusError) |> element.to_string
  let info = progress.status_badge("Info", ui_types.StatusInfo) |> element.to_string

  success |> string.contains("status-success") |> should.be_true
  warning |> string.contains("status-warning") |> should.be_true
  error |> string.contains("status-error") |> should.be_true
  info |> string.contains("status-info") |> should.be_true
}

// ===================================================================
// CIRCULAR PROGRESS TESTS
// ===================================================================

pub fn progress_circle_zero_percent_test() {
  let result = progress.progress_circle(0.0, "Daily Goal") |> element.to_string

  result |> string.contains("--progress: 0%;") |> should.be_true
  result
  |> string.contains("<span class=\"progress-percent\">0%</span>")
  |> should.be_true
  result
  |> string.contains("<span class=\"progress-label\">Daily Goal</span>")
  |> should.be_true
}

pub fn progress_circle_fifty_percent_test() {
  let result = progress.progress_circle(50.0, "Halfway") |> element.to_string

  result |> string.contains("--progress: 50%;") |> should.be_true
  result
  |> string.contains("<span class=\"progress-percent\">50%</span>")
  |> should.be_true
}

pub fn progress_circle_hundred_percent_test() {
  let result = progress.progress_circle(100.0, "Complete") |> element.to_string

  result |> string.contains("--progress: 100%;") |> should.be_true
  result
  |> string.contains("<span class=\"progress-percent\">100%</span>")
  |> should.be_true
}

pub fn progress_circle_fractional_test() {
  let result = progress.progress_circle(75.5, "Almost Done") |> element.to_string

  // Should truncate to integer
  result |> string.contains("--progress: 75%;") |> should.be_true
  result
  |> string.contains("<span class=\"progress-percent\">75%</span>")
  |> should.be_true
}

pub fn progress_circle_accessibility_test() {
  let result = progress.progress_circle(75.0, "Daily Calories") |> element.to_string

  // Should have proper ARIA attributes
  result |> string.contains("role=\"progressbar\"") |> should.be_true
  result |> string.contains("aria-valuenow=\"75\"") |> should.be_true
  result |> string.contains("aria-valuemin=\"0\"") |> should.be_true
  result |> string.contains("aria-valuemax=\"100\"") |> should.be_true
  result
  |> string.contains("aria-label=\"Daily Calories: 75 percent\"")
  |> should.be_true
}

// ===================================================================
// PROGRESS WITH LABEL TESTS
// ===================================================================

pub fn progress_with_label_basic_test() {
  let result = progress.progress_with_label(1850.0, 2100.0, "Calories") |> element.to_string

  result
  |> string.contains("<span class=\"progress-label-text\">Calories</span>")
  |> should.be_true
  result
  |> string.contains("<span class=\"progress-value\">1850 / 2100</span>")
  |> should.be_true
  result |> string.contains("width: 88%") |> should.be_true
}

pub fn progress_with_label_zero_test() {
  let result = progress.progress_with_label(0.0, 2000.0, "Steps") |> element.to_string

  result
  |> string.contains("<span class=\"progress-value\">0 / 2000</span>")
  |> should.be_true
  result |> string.contains("width: 0%") |> should.be_true
}

pub fn progress_with_label_complete_test() {
  let result = progress.progress_with_label(2000.0, 2000.0, "Water") |> element.to_string

  result
  |> string.contains("<span class=\"progress-value\">2000 / 2000</span>")
  |> should.be_true
  result |> string.contains("width: 100%") |> should.be_true
}

pub fn progress_with_label_over_target_test() {
  let result = progress.progress_with_label(2500.0, 2000.0, "Calories") |> element.to_string

  // Should cap at 100% but show actual values
  result
  |> string.contains("<span class=\"progress-value\">2500 / 2000</span>")
  |> should.be_true
  result |> string.contains("width: 100%") |> should.be_true
}

pub fn progress_with_label_accessibility_test() {
  let result = progress.progress_with_label(1500.0, 2000.0, "Protein") |> element.to_string

  result |> string.contains("role=\"progressbar\"") |> should.be_true
  result |> string.contains("aria-valuenow=\"75\"") |> should.be_true
  result |> string.contains("aria-valuemin=\"0\"") |> should.be_true
  result |> string.contains("aria-valuemax=\"100\"") |> should.be_true
  result
  |> string.contains("aria-label=\"Protein: 1500 of 2000\"")
  |> should.be_true
}

pub fn progress_with_label_fractional_values_test() {
  let result = progress.progress_with_label(1234.5, 2000.0, "Calories") |> element.to_string

  // Should truncate to integers
  result
  |> string.contains("<span class=\"progress-value\">1234 / 2000</span>")
  |> should.be_true
  result |> string.contains("width: 61%") |> should.be_true
}

// ===================================================================
// PROPERTY TESTS (Range Validation)
// ===================================================================

pub fn progress_bar_valid_range_property_test() {
  // Test various valid percentages
  let test_cases = [
    #(0.0, 100.0),
    #(25.0, 100.0),
    #(50.0, 100.0),
    #(75.0, 100.0),
    #(100.0, 100.0),
  ]

  test_cases
  |> list_for_each(fn(test_case) {
    let #(current, target) = test_case
    let result = progress.progress_bar(current, target, "primary") |> element.to_string

    // All results should contain valid HTML structure
    result |> string.contains("progress-bar") |> should.be_true
    result |> string.contains("progress-fill") |> should.be_true
    result |> string.contains("role=\"progressbar\"") |> should.be_true
  })
}

pub fn macro_bar_valid_range_property_test() {
  // Test various macro values
  let test_cases = [
    #("Protein", 0.0, 150.0),
    #("Carbs", 100.0, 200.0),
    #("Fat", 60.0, 60.0),
    #("Fiber", 25.0, 30.0),
  ]

  test_cases
  |> list_for_each(fn(test_case) {
    let #(label, current, target) = test_case
    let result = progress.macro_bar(label, current, target, "macro") |> element.to_string

    // All results should contain valid structure
    result |> string.contains("macro-bar") |> should.be_true
    result |> string.contains("macro-bar-header") |> should.be_true
    result |> string.contains(label) |> should.be_true
  })
}

pub fn progress_circle_valid_range_property_test() {
  // Test various percentages
  let test_cases = [0.0, 10.0, 25.0, 50.0, 75.0, 90.0, 100.0]

  test_cases
  |> list_for_each(fn(pct) {
    let result = progress.progress_circle(pct, "Test") |> element.to_string

    // All results should contain valid structure
    result |> string.contains("progress-circle") |> should.be_true
    result |> string.contains("circle-progress") |> should.be_true
    result |> string.contains("progress-percent") |> should.be_true
  })
}

// ===================================================================
// EDGE CASES
// ===================================================================

pub fn edge_case_very_large_numbers_test() {
  let result = progress.progress_bar(999_999.0, 1_000_000.0, "primary") |> element.to_string

  // Should handle large numbers
  result |> string.contains("width: 99%") |> should.be_true
}

pub fn edge_case_very_small_numbers_test() {
  let result = progress.progress_bar(0.001, 1.0, "primary") |> element.to_string

  // Should handle very small numbers (rounds to 0%)
  result |> string.contains("width: 0%") |> should.be_true
}

pub fn edge_case_equal_current_and_target_test() {
  let result = progress.progress_bar(100.0, 100.0, "primary") |> element.to_string

  // Should show exactly 100%
  result |> string.contains("width: 100%") |> should.be_true
  result |> string.contains("aria-valuenow=\"100\"") |> should.be_true
}

pub fn edge_case_empty_label_test() {
  let result = progress.macro_bar("", 50.0, 100.0, "macro") |> element.to_string

  // Should render with empty label
  result |> string.contains("<span></span>") |> should.be_true
}

pub fn edge_case_special_characters_in_label_test() {
  let result = progress.progress_with_label(50.0, 100.0, "Protein & Carbs (g)") |> element.to_string

  // Should preserve special characters
  result |> string.contains("Protein & Carbs (g)") |> should.be_true
}

// ===================================================================
// HELPER FUNCTIONS
// ===================================================================

fn list_for_each(list: List(a), func: fn(a) -> b) -> Nil {
  case list {
    [] -> Nil
    [head, ..tail] -> {
      let _ = func(head)
      list_for_each(tail, func)
    }
  }
}
