/// Date Picker Model - Type Definitions
///
/// Contains all type definitions for the date picker component.
import gleam/option.{type Option}

// ============================================================================
// Types
// ============================================================================

/// Date picker model
pub type DatePickerModel {
  DatePickerModel(
    /// Currently selected date (days since epoch)
    selected_date: Int,
    /// Currently viewed month (for calendar display)
    view_year: Int,
    view_month: Int,
    /// Whether picker is open
    is_open: Bool,
    /// Text input mode (for manual entry)
    input_mode: Bool,
    input_text: String,
    /// Error message
    error: Option(String),
    /// Date constraints
    min_date: Option(Int),
    max_date: Option(Int),
    /// Display format
    date_format: DateFormat,
  )
}

/// Date format options
pub type DateFormat {
  /// YYYY-MM-DD
  IsoFormat
  /// MM/DD/YYYY
  UsFormat
  /// DD/MM/YYYY
  EuFormat
  /// Month DD, YYYY
  LongFormat
}

/// Date picker effect (for parent component integration)
pub type DatePickerEffect {
  NoEffect
  DateSelected(date_int: Int)
  Cancelled
}
