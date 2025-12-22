/// Tests for Date Picker Component
///
/// Tests cover:
/// - Initialization and defaults
/// - Date navigation (day, week, month, year)
/// - Input parsing
/// - Constraint validation
/// - Calendar rendering
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/cli/components/date_picker.{
  type DatePickerEffect, type DatePickerModel, type DatePickerMsg, Cancel,
  Cancelled, ClearError, Close, ConfirmSelection, DateSelected, EuFormat,
  GoToToday, InputChanged, IsoFormat, LongFormat, NextDay, NextMonth, NextWeek,
  NextYear, NoEffect, Open, ParseInput, PreviousDay, PreviousMonth, PreviousWeek,
  PreviousYear, SelectDate, ToggleInputMode, UsFormat,
}

// ============================================================================
// Initialization Tests
// ============================================================================

pub fn init_creates_valid_model_test() {
  // GIVEN: A date as days since epoch (e.g., 20000 = ~2024)
  let date_int = 20_000

  // WHEN: Initializing date picker
  let model = date_picker.init(date_int)

  // THEN: Model should have correct initial state
  model.selected_date
  |> should.equal(20_000)

  model.is_open
  |> should.equal(False)

  model.input_mode
  |> should.equal(False)

  model.error
  |> should.equal(None)

  model.min_date
  |> should.equal(None)

  model.max_date
  |> should.equal(None)
}

pub fn init_with_constraints_test() {
  // GIVEN: Date with constraints
  let date_int = 20_000
  let min_date = 19_900
  let max_date = 20_100

  // WHEN: Initializing with constraints
  let model =
    date_picker.init_with_constraints(date_int, Some(min_date), Some(max_date))

  // THEN: Constraints should be set
  model.min_date
  |> should.equal(Some(19_900))

  model.max_date
  |> should.equal(Some(20_100))
}

// ============================================================================
// Navigation Tests
// ============================================================================

pub fn previous_day_navigation_test() {
  // GIVEN: A date picker at day 20000
  let model = date_picker.init(20_000)

  // WHEN: Navigating to previous day
  let #(updated, effect) = date_picker.update(model, PreviousDay)

  // THEN: Date should decrease by 1
  updated.selected_date
  |> should.equal(19_999)

  effect
  |> should.equal(NoEffect)
}

pub fn next_day_navigation_test() {
  // GIVEN: A date picker at day 20000
  let model = date_picker.init(20_000)

  // WHEN: Navigating to next day
  let #(updated, effect) = date_picker.update(model, NextDay)

  // THEN: Date should increase by 1
  updated.selected_date
  |> should.equal(20_001)

  effect
  |> should.equal(NoEffect)
}

pub fn previous_week_navigation_test() {
  // GIVEN: A date picker at day 20000
  let model = date_picker.init(20_000)

  // WHEN: Navigating to previous week
  let #(updated, _effect) = date_picker.update(model, PreviousWeek)

  // THEN: Date should decrease by 7
  updated.selected_date
  |> should.equal(19_993)
}

pub fn next_week_navigation_test() {
  // GIVEN: A date picker at day 20000
  let model = date_picker.init(20_000)

  // WHEN: Navigating to next week
  let #(updated, _effect) = date_picker.update(model, NextWeek)

  // THEN: Date should increase by 7
  updated.selected_date
  |> should.equal(20_007)
}

pub fn previous_month_navigation_test() {
  // GIVEN: A date picker in March
  let model = date_picker.init(20_000)
  let initial_month = model.view_month

  // WHEN: Navigating to previous month
  let #(updated, _effect) = date_picker.update(model, PreviousMonth)

  // THEN: View month should decrease
  // Note: Exact month depends on date calculation
  { updated.view_month < initial_month || updated.view_year < model.view_year }
  |> should.equal(True)
}

pub fn next_month_navigation_test() {
  // GIVEN: A date picker
  let model = date_picker.init(20_000)
  let initial_month = model.view_month
  let initial_year = model.view_year

  // WHEN: Navigating to next month
  let #(updated, _effect) = date_picker.update(model, NextMonth)

  // THEN: View month should increase
  { updated.view_month > initial_month || updated.view_year > initial_year }
  |> should.equal(True)
}

pub fn previous_year_navigation_test() {
  // GIVEN: A date picker
  let model = date_picker.init(20_000)
  let initial_year = model.view_year

  // WHEN: Navigating to previous year
  let #(updated, _effect) = date_picker.update(model, PreviousYear)

  // THEN: View year should decrease by 1
  updated.view_year
  |> should.equal(initial_year - 1)
}

pub fn next_year_navigation_test() {
  // GIVEN: A date picker
  let model = date_picker.init(20_000)
  let initial_year = model.view_year

  // WHEN: Navigating to next year
  let #(updated, _effect) = date_picker.update(model, NextYear)

  // THEN: View year should increase by 1
  updated.view_year
  |> should.equal(initial_year + 1)
}

// ============================================================================
// Constraint Validation Tests
// ============================================================================

pub fn navigation_respects_min_date_test() {
  // GIVEN: A date picker at min date
  let min_date = 20_000
  let model = date_picker.init_with_constraints(min_date, Some(min_date), None)

  // WHEN: Trying to navigate before min date
  let #(updated, _effect) = date_picker.update(model, PreviousDay)

  // THEN: Date should not change (stays at min)
  updated.selected_date
  |> should.equal(min_date)
}

pub fn navigation_respects_max_date_test() {
  // GIVEN: A date picker at max date
  let max_date = 20_000
  let model = date_picker.init_with_constraints(max_date, None, Some(max_date))

  // WHEN: Trying to navigate after max date
  let #(updated, _effect) = date_picker.update(model, NextDay)

  // THEN: Date should not change (stays at max)
  updated.selected_date
  |> should.equal(max_date)
}

pub fn select_date_validates_constraints_test() {
  // GIVEN: A date picker with constraints
  let model =
    date_picker.init_with_constraints(20_000, Some(19_900), Some(20_100))

  // WHEN: Selecting a date outside constraints
  let #(updated, _effect) = date_picker.update(model, SelectDate(25_000))

  // THEN: Error should be set
  updated.error
  |> should.equal(Some("Date out of range"))

  // AND: Date should not change
  updated.selected_date
  |> should.equal(20_000)
}

// ============================================================================
// Input Mode Tests
// ============================================================================

pub fn toggle_input_mode_test() {
  // GIVEN: A date picker not in input mode
  let model = date_picker.init(20_000)

  // WHEN: Toggling input mode
  let #(updated, _effect) = date_picker.update(model, ToggleInputMode)

  // THEN: Input mode should be enabled
  updated.input_mode
  |> should.equal(True)

  // AND: Input text should contain current date
  { updated.input_text != "" }
  |> should.equal(True)
}

pub fn input_changed_updates_text_test() {
  // GIVEN: A date picker in input mode
  let model = date_picker.init(20_000)
  let #(model2, _) = date_picker.update(model, ToggleInputMode)

  // WHEN: Changing input text
  let #(updated, _effect) =
    date_picker.update(model2, InputChanged("2025-01-15"))

  // THEN: Input text should be updated
  updated.input_text
  |> should.equal("2025-01-15")

  // AND: Error should be cleared
  updated.error
  |> should.equal(None)
}

pub fn parse_input_valid_iso_format_test() {
  // GIVEN: A date picker with valid ISO input
  let model = date_picker.init(20_000)
  let #(model2, _) = date_picker.update(model, ToggleInputMode)
  let #(model3, _) = date_picker.update(model2, InputChanged("2025-01-15"))

  // WHEN: Parsing input
  let #(updated, _effect) = date_picker.update(model3, ParseInput)

  // THEN: Input mode should be disabled
  updated.input_mode
  |> should.equal(False)

  // AND: Date should be updated (specific value depends on epoch calculation)
  { updated.selected_date != 20_000 }
  |> should.equal(True)
}

pub fn parse_input_invalid_format_test() {
  // GIVEN: A date picker with invalid input
  let model = date_picker.init(20_000)
  let #(model2, _) = date_picker.update(model, ToggleInputMode)
  let #(model3, _) = date_picker.update(model2, InputChanged("invalid-date"))

  // WHEN: Parsing input
  let #(updated, _effect) = date_picker.update(model3, ParseInput)

  // THEN: Error should be set
  case updated.error {
    Some(_) -> True
    None -> False
  }
  |> should.equal(True)
}

// ============================================================================
// State Tests
// ============================================================================

pub fn open_sets_is_open_test() {
  // GIVEN: A closed date picker
  let model = date_picker.init(20_000)

  // WHEN: Opening
  let #(updated, _effect) = date_picker.update(model, Open)

  // THEN: is_open should be True
  updated.is_open
  |> should.equal(True)
}

pub fn close_sets_is_open_test() {
  // GIVEN: An open date picker
  let model = date_picker.init(20_000)
  let #(model2, _) = date_picker.update(model, Open)

  // WHEN: Closing
  let #(updated, _effect) = date_picker.update(model2, Close)

  // THEN: is_open should be False
  updated.is_open
  |> should.equal(False)
}

pub fn confirm_selection_returns_date_selected_effect_test() {
  // GIVEN: An open date picker with a selected date
  let model = date_picker.init(20_000)
  let #(model2, _) = date_picker.update(model, Open)

  // WHEN: Confirming selection
  let #(updated, effect) = date_picker.update(model2, ConfirmSelection)

  // THEN: Should close and return DateSelected effect
  updated.is_open
  |> should.equal(False)

  case effect {
    DateSelected(date) -> date |> should.equal(20_000)
    _ -> should.fail()
  }
}

pub fn cancel_returns_cancelled_effect_test() {
  // GIVEN: An open date picker
  let model = date_picker.init(20_000)
  let #(model2, _) = date_picker.update(model, Open)

  // WHEN: Cancelling
  let #(updated, effect) = date_picker.update(model2, Cancel)

  // THEN: Should close and return Cancelled effect
  updated.is_open
  |> should.equal(False)

  effect
  |> should.equal(Cancelled)
}

pub fn clear_error_removes_error_test() {
  // GIVEN: A date picker with an error
  let model = date_picker.init(20_000)
  let model2 = date_picker.DatePickerModel(..model, error: Some("Test error"))

  // WHEN: Clearing error
  let #(updated, _effect) = date_picker.update(model2, ClearError)

  // THEN: Error should be None
  updated.error
  |> should.equal(None)
}

// ============================================================================
// Keyboard Handling Tests
// ============================================================================

pub fn key_h_navigates_previous_day_test() {
  // GIVEN: A date picker
  let model = date_picker.init(20_000)

  // WHEN: Pressing 'h' key
  let #(updated, _effect) = date_picker.handle_key(model, "h")

  // THEN: Date should decrease by 1
  updated.selected_date
  |> should.equal(19_999)
}

pub fn key_l_navigates_next_day_test() {
  // GIVEN: A date picker
  let model = date_picker.init(20_000)

  // WHEN: Pressing 'l' key
  let #(updated, _effect) = date_picker.handle_key(model, "l")

  // THEN: Date should increase by 1
  updated.selected_date
  |> should.equal(20_001)
}

pub fn key_t_goes_to_today_test() {
  // GIVEN: A date picker at a past date
  let model = date_picker.init(10_000)

  // WHEN: Pressing 't' key
  let #(updated, _effect) = date_picker.handle_key(model, "t")

  // THEN: Date should be updated to today (greater than 10000)
  { updated.selected_date > 10_000 }
  |> should.equal(True)
}

pub fn key_enter_confirms_selection_test() {
  // GIVEN: A date picker
  let model = date_picker.init(20_000)

  // WHEN: Pressing Enter
  let #(_updated, effect) = date_picker.handle_key(model, "\r")

  // THEN: Should return DateSelected effect
  case effect {
    DateSelected(date) -> date |> should.equal(20_000)
    _ -> should.fail()
  }
}

pub fn key_escape_cancels_test() {
  // GIVEN: A date picker
  let model = date_picker.init(20_000)

  // WHEN: Pressing Escape
  let #(_updated, effect) = date_picker.handle_key(model, "\u{001B}")

  // THEN: Should return Cancelled effect
  effect
  |> should.equal(Cancelled)
}

// ============================================================================
// Format Tests
// ============================================================================

pub fn set_format_changes_format_test() {
  // GIVEN: A date picker with default format
  let model = date_picker.init(20_000)

  // WHEN: Setting different formats
  let us_model = date_picker.set_format(model, UsFormat)
  let eu_model = date_picker.set_format(model, EuFormat)
  let long_model = date_picker.set_format(model, LongFormat)

  // THEN: Formats should be set correctly
  us_model.date_format |> should.equal(UsFormat)
  eu_model.date_format |> should.equal(EuFormat)
  long_model.date_format |> should.equal(LongFormat)
}

// ============================================================================
// Public API Tests
// ============================================================================

pub fn get_selected_date_returns_date_test() {
  // GIVEN: A date picker with selected date
  let model = date_picker.init(20_000)

  // WHEN: Getting selected date
  let date = date_picker.get_selected_date(model)

  // THEN: Should return correct date
  date
  |> should.equal(20_000)
}

pub fn get_selected_date_string_returns_formatted_test() {
  // GIVEN: A date picker
  let model = date_picker.init(20_000)

  // WHEN: Getting date as string
  let date_str = date_picker.get_selected_date_string(model)

  // THEN: Should return non-empty string
  { date_str != "" }
  |> should.equal(True)
}

pub fn open_function_opens_picker_test() {
  // GIVEN: A closed date picker
  let model = date_picker.init(20_000)

  // WHEN: Using open function
  let updated = date_picker.open(model)

  // THEN: Picker should be open
  updated.is_open
  |> should.equal(True)
}

pub fn close_function_closes_picker_test() {
  // GIVEN: An open date picker
  let model = date_picker.open(date_picker.init(20_000))

  // WHEN: Using close function
  let updated = date_picker.close(model)

  // THEN: Picker should be closed
  updated.is_open
  |> should.equal(False)
}

pub fn set_min_date_sets_constraint_test() {
  // GIVEN: A date picker
  let model = date_picker.init(20_000)

  // WHEN: Setting min date
  let updated = date_picker.set_min_date(model, 19_000)

  // THEN: Min date should be set
  updated.min_date
  |> should.equal(Some(19_000))
}

pub fn set_max_date_sets_constraint_test() {
  // GIVEN: A date picker
  let model = date_picker.init(20_000)

  // WHEN: Setting max date
  let updated = date_picker.set_max_date(model, 21_000)

  // THEN: Max date should be set
  updated.max_date
  |> should.equal(Some(21_000))
}
