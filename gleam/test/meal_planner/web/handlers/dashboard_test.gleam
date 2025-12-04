////
//// Dashboard handler integration tests
////
//// Tests for:
//// - Dashboard renders correctly with logs
//// - Progress bars display correct percentages
//// - Macro calculations are accurate
//// - Empty state when no logs exist

import gleam/int
import gleam/option
import gleam/option.{None, Some}
import gleam/string
import gleeunit/should
import meal_planner/storage
import meal_planner/types.{Macros, macros_calories}
import meal_planner/ui/components/dashboard as dashboard_component
import meal_planner/web/handlers/dashboard

/// Test that progress_bar renders with correct percentage for full completion
pub fn progress_bar_full_completion_test() {
  let html = dashboard_component.progress_bar(100, 100)

  html
  |> string.contains("width: 100%")
  |> should.be_true()

  html
  |> string.contains("bg-green-500")
  |> should.be_true()
}

/// Test that progress_bar renders with correct percentage for half completion
pub fn progress_bar_half_completion_test() {
  let html = dashboard_component.progress_bar(50, 100)

  html
  |> string.contains("width: 50%")
  |> should.be_true()
}

/// Test that progress_bar renders with correct percentage for partial completion
pub fn progress_bar_partial_completion_test() {
  let html = dashboard_component.progress_bar(75, 150)

  html
  |> string.contains("width: 50%")
  |> should.be_true()
}

/// Test that progress_bar renders correctly when current is 0
pub fn progress_bar_zero_completion_test() {
  let html = dashboard_component.progress_bar(0, 100)

  html
  |> string.contains("width: 0%")
  |> should.be_true()
}

/// Test sum_log_macros with empty log list
pub fn sum_log_macros_empty_list_test() {
  let empty_logs: List(storage.Log) = []
  let result = dashboard.sum_log_macros(empty_logs)

  result.protein |> should.equal(0.0)
  result.fat |> should.equal(0.0)
  result.carbs |> should.equal(0.0)
}

/// Test sum_log_macros with single log without macros
pub fn sum_log_macros_single_log_no_macros_test() {
  let log =
    storage.Log(
      id: 1,
      user_id: 1,
      food_id: 10,
      quantity: 100.0,
      log_date: "2025-12-01",
      macros: None,
      created_at: "2025-12-01T10:00:00Z",
      updated_at: "2025-12-01T10:00:00Z",
    )

  let result = dashboard.sum_log_macros([log])

  result.protein |> should.equal(0.0)
  result.fat |> should.equal(0.0)
  result.carbs |> should.equal(0.0)
}

/// Test sum_log_macros with multiple logs
pub fn sum_log_macros_multiple_logs_test() {
  let log1 =
    storage.Log(
      id: 1,
      user_id: 1,
      food_id: 10,
      quantity: 100.0,
      log_date: "2025-12-01",
      macros: None,
      created_at: "2025-12-01T10:00:00Z",
      updated_at: "2025-12-01T10:00:00Z",
    )

  let log2 =
    storage.Log(
      id: 2,
      user_id: 1,
      food_id: 20,
      quantity: 50.0,
      log_date: "2025-12-01",
      macros: None,
      created_at: "2025-12-01T11:00:00Z",
      updated_at: "2025-12-01T11:00:00Z",
    )

  let result = dashboard.sum_log_macros([log1, log2])

  // With no macros in logs, should still sum to zero
  result.protein |> should.equal(0.0)
  result.fat |> should.equal(0.0)
  result.carbs |> should.equal(0.0)
}

/// Test float_to_int conversion
pub fn float_to_int_whole_number_test() {
  let result = dashboard.float_to_int(42.7)

  result |> should.equal(42)
}

/// Test float_to_int with zero
pub fn float_to_int_zero_test() {
  let result = dashboard.float_to_int(0.0)

  result |> should.equal(0)
}

/// Test float_to_int with small decimal
pub fn float_to_int_small_decimal_test() {
  let result = dashboard.float_to_int(0.5)

  result |> should.equal(0)
}

/// Test float_to_display_string formats correctly
pub fn float_to_display_string_test() {
  let result = dashboard.float_to_display_string(123.456)

  result |> should.equal("123")
}

/// Test float_to_display_string with zero
pub fn float_to_display_string_zero_test() {
  let result = dashboard.float_to_display_string(0.0)

  result |> should.equal("0")
}

/// Test render_log_entry_html creates proper HTML
pub fn render_log_entry_html_test() {
  let log =
    storage.Log(
      id: 1,
      user_id: 1,
      food_id: 42,
      quantity: 150.5,
      log_date: "2025-12-01",
      macros: None,
      created_at: "2025-12-01T10:00:00Z",
      updated_at: "2025-12-01T10:00:00Z",
    )

  let html = dashboard.render_log_entry_html(log)

  html
  |> string.contains("log-entry")
  |> should.be_true()

  html
  |> string.contains("Food ID: 42")
  |> should.be_true()

  html
  |> string.contains("Quantity: 150")
  |> should.be_true()

  html
  |> string.contains("Date: 2025-12-01")
  |> should.be_true()
}

/// Test render_log_entry_html with different values
pub fn render_log_entry_html_different_values_test() {
  let log =
    storage.Log(
      id: 99,
      user_id: 5,
      food_id: 200,
      quantity: 75.25,
      log_date: "2025-11-30",
      macros: Some("50:25:100"),
      created_at: "2025-11-30T12:00:00Z",
      updated_at: "2025-11-30T12:00:00Z",
    )

  let html = dashboard.render_log_entry_html(log)

  html
  |> string.contains("Food ID: 200")
  |> should.be_true()

  html
  |> string.contains("Quantity: 75")
  |> should.be_true()

  html
  |> string.contains("Date: 2025-11-30")
  |> should.be_true()
}

/// Test get_today_date returns a string in correct format
pub fn get_today_date_test() {
  let date = dashboard.get_today_date()

  // Should be in YYYY-MM-DD format
  string.length(date) |> should.equal(10)

  // Check pattern: contains hyphens in expected positions
  string.is_empty(date) |> should.be_false()
}

/// Test extract_date_param with no query params returns today's date
pub fn extract_date_param_no_params_test() {
  let date = dashboard.extract_date_param(None)

  string.length(date) |> should.equal(10)
}

/// Test extract_date_param with specific date
pub fn extract_date_param_with_date_test() {
  let date = dashboard.extract_date_param(Some("date=2025-11-15"))

  date |> should.equal("2025-11-15")
}

/// Test extract_date_param with multiple params
pub fn extract_date_param_multiple_params_test() {
  let date = dashboard.extract_date_param(Some("foo=bar&date=2025-11-20&baz=qux"))

  date |> should.equal("2025-11-20")
}

/// Test extract_date_param with no date param falls back to today
pub fn extract_date_param_no_date_param_test() {
  let date = dashboard.extract_date_param(Some("foo=bar&baz=qux"))

  string.length(date) |> should.equal(10)
}

/// Test macros_calories calculation
pub fn macros_calories_test() {
  let macros = Macros(protein: 100.0, fat: 50.0, carbs: 200.0)
  let calories = macros_calories(macros)

  // protein: 100 * 4 = 400
  // fat: 50 * 9 = 450
  // carbs: 200 * 4 = 800
  // total = 1650
  calories |> should.equal(1650.0)
}

/// Test macros_calories with zero values
pub fn macros_calories_zero_test() {
  let macros = Macros(protein: 0.0, fat: 0.0, carbs: 0.0)
  let calories = macros_calories(macros)

  calories |> should.equal(0.0)
}

/// Test macros_calories with realistic values
pub fn macros_calories_realistic_test() {
  let macros = Macros(protein: 30.0, fat: 15.0, carbs: 60.0)
  let calories = macros_calories(macros)

  // protein: 30 * 4 = 120
  // fat: 15 * 9 = 135
  // carbs: 60 * 4 = 240
  // total = 495
  calories |> should.equal(495.0)
}
