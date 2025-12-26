/// Date Picker Messages - User Actions
///
/// Contains all message types for the date picker component.
// ============================================================================
// Messages
// ============================================================================

/// Date picker messages
pub type DatePickerMsg {
  // Navigation
  PreviousDay
  NextDay
  PreviousWeek
  NextWeek
  PreviousMonth
  NextMonth
  PreviousYear
  NextYear
  GoToToday

  // Selection
  SelectDate(date_int: Int)
  ConfirmSelection
  Cancel

  // Input mode
  ToggleInputMode
  InputChanged(text: String)
  ParseInput

  // State
  Open
  Close
  ClearError
}
