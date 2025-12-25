/// Date Picker Component - Reusable TUI Date Selection
///
/// This module provides a reusable date picker component for Shore TUI
/// following Elm Architecture patterns.
///
/// FEATURES:
/// - Month/year calendar view
/// - Keyboard navigation (arrows, vim keys)
/// - Today shortcut
/// - Quick month/year navigation
/// - Date range validation
/// - Multiple date formats
///
/// ARCHITECTURE:
/// - model.gleam: Type definitions
/// - messages.gleam: Message types
/// - logic.gleam: Date calculations and validation
/// - update.gleam: State update logic
/// - view.gleam: Rendering functions
import gleam/option.{type Option, None, Some}
import meal_planner/cli/components/date_picker/logic
import meal_planner/cli/components/date_picker/model.{
  type DateFormat, type DatePickerEffect, type DatePickerModel, Cancelled,
  DatePickerModel, DateSelected, EuFormat, IsoFormat, LongFormat, NoEffect,
  UsFormat,
}
import meal_planner/cli/components/date_picker/update
import meal_planner/cli/components/date_picker/view
import shore

// ============================================================================
// Re-exports
// ============================================================================

// Types
pub type DatePickerModel {
  DatePickerModel(
    selected_date: Int,
    view_year: Int,
    view_month: Int,
    is_open: Bool,
    input_mode: Bool,
    input_text: String,
    error: Option(String),
    min_date: Option(Int),
    max_date: Option(Int),
    date_format: DateFormat,
  )
}

pub type DateFormat {
  IsoFormat
  UsFormat
  EuFormat
  LongFormat
}

pub type DatePickerEffect {
  NoEffect
  DateSelected(date_int: Int)
  Cancelled
}

// Messages - imported from messages module
import meal_planner/cli/components/date_picker/messages.{
  type DatePickerMsg, Cancel, ClearError, Close, ConfirmSelection, GoToToday,
  InputChanged, NextDay, NextMonth, NextWeek, NextYear, Open, ParseInput,
  PreviousDay, PreviousMonth, PreviousWeek, PreviousYear, SelectDate,
  ToggleInputMode,
}

// ============================================================================
// Initialization
// ============================================================================

/// Create initial date picker model
pub fn init(initial_date: Int) -> DatePickerModel {
  let #(year, month, _day) = logic.date_int_to_ymd(initial_date)

  DatePickerModel(
    selected_date: initial_date,
    view_year: year,
    view_month: month,
    is_open: False,
    input_mode: False,
    input_text: "",
    error: None,
    min_date: None,
    max_date: None,
    date_format: IsoFormat,
  )
}

/// Initialize with constraints
pub fn init_with_constraints(
  initial_date: Int,
  min_date: Option(Int),
  max_date: Option(Int),
) -> DatePickerModel {
  let model = init(initial_date)
  DatePickerModel(..model, min_date: min_date, max_date: max_date)
}

// ============================================================================
// Update Function (delegated to update module)
// ============================================================================

/// Update date picker state
pub fn update(
  model: DatePickerModel,
  msg: DatePickerMsg,
) -> #(DatePickerModel, DatePickerEffect) {
  update.update(model, msg)
}

/// Handle keyboard input for date picker
pub fn handle_key(
  model: DatePickerModel,
  key: String,
) -> #(DatePickerModel, DatePickerEffect) {
  update.handle_key(model, key)
}

// ============================================================================
// View Function (delegated to view module)
// ============================================================================

/// Render the date picker
pub fn view(
  model: DatePickerModel,
  on_msg: fn(DatePickerMsg) -> msg,
) -> shore.Node(msg) {
  view.view(model, on_msg)
}

// ============================================================================
// Public API
// ============================================================================

/// Get selected date from model
pub fn get_selected_date(model: DatePickerModel) -> Int {
  model.selected_date
}

/// Get selected date as string
pub fn get_selected_date_string(model: DatePickerModel) -> String {
  logic.date_int_to_string(model.selected_date, model.date_format)
}

/// Set date format
pub fn set_format(model: DatePickerModel, format: DateFormat) -> DatePickerModel {
  DatePickerModel(..model, date_format: format)
}

/// Set min date constraint
pub fn set_min_date(model: DatePickerModel, min_date: Int) -> DatePickerModel {
  DatePickerModel(..model, min_date: Some(min_date))
}

/// Set max date constraint
pub fn set_max_date(model: DatePickerModel, max_date: Int) -> DatePickerModel {
  DatePickerModel(..model, max_date: Some(max_date))
}

/// Open the date picker
pub fn open(model: DatePickerModel) -> DatePickerModel {
  DatePickerModel(..model, is_open: True)
}

/// Close the date picker
pub fn close(model: DatePickerModel) -> DatePickerModel {
  DatePickerModel(..model, is_open: False)
}
