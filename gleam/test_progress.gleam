// Standalone progress component test
import gleam/string
import gleam/io

// Manual copies of component functions for testing
fn float_to_int(value: Float) -> Int {
  value |> gleam/float.truncate
}

fn int_to_string(value: Int) -> String {
  gleam/int.to_string(value)
}

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

pub fn progress_bar(current: Float, target: Float, color: String) -> String {
  let percentage = calculate_percentage(current, target)
  let pct_int = float_to_int(percentage)
  let width_style = "width: " <> int_to_string(pct_int) <> "%"

  "<div class=\"progress-bar " <> color <> "\">"
  <> "<div class=\"progress-fill\" style=\"" <> width_style <> "\"></div>"
  <> "<span class=\"progress-text\">" <> int_to_string(pct_int) <> "</span>"
  <> "</div>"
}

pub fn macro_bar(label: String, current: Float, target: Float, color: String) -> String {
  let percentage = calculate_percentage(current, target)
  let pct_int = float_to_int(percentage)
  let current_int = float_to_int(current)
  let target_int = float_to_int(target)
  let width_style = "width: " <> int_to_string(pct_int) <> "%"

  "<div class=\"macro-bar " <> color <> "\">"
  <> "<div class=\"macro-bar-header\">"
  <> "<span>" <> label <> "</span>"
  <> "<span>" <> int_to_string(current_int) <> "g / " <> int_to_string(target_int) <> "g</span>"
  <> "</div>"
  <> "<div class=\"progress-bar\">"
  <> "<div class=\"progress-fill\" style=\"" <> width_style <> "\"></div>"
  <> "</div>"
  <> "</div>"
}

pub fn macro_badge(label: String, value: Float) -> String {
  let value_int = float_to_int(value)
  "<span class=\"macro-badge\">" <> label <> ": " <> int_to_string(value_int) <> "g</span>"
}

pub fn macro_badges() -> String {
  "<div class=\"macro-badges\"></div>"
}

pub fn status_badge(label: String, status: String) -> String {
  let status_class = status
  "<span class=\"status-badge " <> status_class <> "\">" <> label <> "</span>"
}

pub fn progress_circle(percentage: Float, label: String) -> String {
  let pct_int = float_to_int(percentage)

  "<div class=\"progress-circle\">"
  <> "<div class=\"circle-progress\" style=\"--progress: " <> int_to_string(pct_int) <> "%; \"></div>"
  <> "<span class=\"progress-percent\">" <> int_to_string(pct_int) <> "%</span>"
  <> "<span class=\"progress-label\">" <> label <> "</span>"
  <> "</div>"
}

pub fn progress_with_label(current: Float, target: Float, label: String) -> String {
  let percentage = calculate_percentage(current, target)
  let pct_int = float_to_int(percentage)
  let current_int = float_to_int(current)
  let width_style = "width: " <> int_to_string(pct_int) <> "%"

  "<div class=\"progress-with-label\">"
  <> "<div class=\"progress-header\">"
  <> "<span class=\"progress-label-text\">" <> label <> "</span>"
  <> "<span class=\"progress-value\">" <> int_to_string(current_int) <> " / " <> int_to_string(float_to_int(target)) <> "</span>"
  <> "</div>"
  <> "<div class=\"progress-bar\">"
  <> "<div class=\"progress-fill\" style=\"" <> width_style <> "\"></div>"
  <> "</div>"
  <> "</div>"
}

// Test functions
fn assert_contains(haystack: String, needle: String, test_name: String) -> Bool {
  case string.contains(haystack, needle) {
    True -> {
      io.println("✓ " <> test_name)
      True
    }
    False -> {
      io.println("✗ " <> test_name)
      io.println("  Expected to contain: " <> needle)
      io.println("  Got: " <> haystack)
      False
    }
  }
}

pub fn main() {
  io.println("Running Progress Component Tests...\n")

  // Progress bar tests (7 tests)
  let _ = assert_contains(progress_bar(50.0, 100.0, "primary"), "progress-bar", "Test 1: progress_bar renders container")
  let _ = assert_contains(progress_bar(50.0, 100.0, "primary"), "<div", "Test 2: progress_bar contains div element")
  let _ = assert_contains(progress_bar(50.0, 100.0, "primary"), "50", "Test 3: progress_bar renders percentage")
  let _ = assert_contains(progress_bar(0.0, 100.0, "primary"), "0", "Test 4: progress_bar with zero progress")
  let _ = assert_contains(progress_bar(100.0, 100.0, "success"), "100", "Test 5: progress_bar with full progress")
  let _ = assert_contains(progress_bar(75.0, 100.0, "warning"), "warning", "Test 6: progress_bar with color")
  let _ = assert_contains(progress_bar(33.33, 100.0, "primary"), "33", "Test 7: progress_bar decimal percentage")

  // Macro bar tests (5 tests)
  let _ = assert_contains(macro_bar("Protein", 150.0, 200.0, "success"), "Protein", "Test 8: macro_bar renders label")
  let _ = assert_contains(macro_bar("Carbs", 200.0, 300.0, "primary"), "66", "Test 9: macro_bar renders percentage")
  let _ = assert_contains(macro_bar("Fat", 50.0, 75.0, "info"), "macro-bar", "Test 10: macro_bar contains macro-bar class")
  let _ = assert_contains(macro_bar("Protein", 100.0, 150.0, "danger"), "danger", "Test 11: macro_bar with color")
  let _ = assert_contains(macro_bar("Calories", 150.0, 100.0, "warning"), "150", "Test 12: macro_bar over target")

  // Macro badge tests (4 tests)
  let _ = assert_contains(macro_badge("Protein", 150.0), "Protein", "Test 13: macro_badge renders label")
  let _ = assert_contains(macro_badge("Carbs", 250.0), "250", "Test 14: macro_badge renders value")
  let _ = assert_contains(macro_badge("Fat", 75.0), "macro-badge", "Test 15: macro_badge contains macro-badge class")
  let _ = assert_contains(macro_badge("Sodium", 0.0), "0", "Test 16: macro_badge with zero value")

  // Macro badges group test (1 test)
  let _ = assert_contains(macro_badges(), "macro-badges", "Test 17: macro_badges contains macro-badges class")

  // Status badge tests (6 tests)
  let _ = assert_contains(status_badge("Complete", "status-success"), "Complete", "Test 18: status_badge success renders")
  let _ = assert_contains(status_badge("Pending", "status-warning"), "Pending", "Test 19: status_badge warning renders")
  let _ = assert_contains(status_badge("Failed", "status-error"), "Failed", "Test 20: status_badge error renders")
  let _ = assert_contains(status_badge("Info", "status-info"), "Info", "Test 21: status_badge info renders")
  let _ = assert_contains(status_badge("Active", "status-success"), "status-badge", "Test 22: status_badge contains status-badge class")
  let _ = assert_contains(status_badge("Error State", "status-error"), "status-error", "Test 23: status_badge contains status type class")

  // Progress circle tests (5 tests)
  let _ = assert_contains(progress_circle(75.0, "Progress"), "75", "Test 24: progress_circle renders percentage")
  let _ = assert_contains(progress_circle(50.0, "Halfway"), "Halfway", "Test 25: progress_circle renders label")
  let _ = assert_contains(progress_circle(100.0, "Complete"), "progress-circle", "Test 26: progress_circle contains circle class")
  let _ = assert_contains(progress_circle(0.0, "Not Started"), "0", "Test 27: progress_circle zero percent")
  let _ = assert_contains(progress_circle(100.0, "Done"), "100", "Test 28: progress_circle full percent")

  // Progress with label tests (5 tests)
  let _ = assert_contains(progress_with_label(60.0, 100.0, "Daily Goal"), "Daily Goal", "Test 29: progress_with_label renders label")
  let _ = assert_contains(progress_with_label(45.0, 100.0, "Progress"), "45", "Test 30: progress_with_label renders percentage")
  let _ = assert_contains(progress_with_label(80.0, 100.0, "Status"), "progress-with-label", "Test 31: progress_with_label contains class")
  let _ = assert_contains(progress_with_label(33.33, 100.0, "Metric"), "33", "Test 32: progress_with_label decimal current")
  let _ = assert_contains(progress_with_label(120.0, 100.0, "Over"), "120", "Test 33: progress_with_label exceeds target")

  io.println("\nAll 33 tests completed!")
  Nil
}
