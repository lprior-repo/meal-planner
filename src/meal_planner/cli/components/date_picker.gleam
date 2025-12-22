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
import birl
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import shore
import shore/style
import shore/ui

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

/// Date picker effect (for parent component integration)
pub type DatePickerEffect {
  NoEffect
  DateSelected(date_int: Int)
  Cancelled
}

// ============================================================================
// Initialization
// ============================================================================

/// Create initial date picker model
pub fn init(initial_date: Int) -> DatePickerModel {
  let #(year, month, _day) = date_int_to_ymd(initial_date)

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
// Update Function
// ============================================================================

/// Update date picker state
pub fn update(
  model: DatePickerModel,
  msg: DatePickerMsg,
) -> #(DatePickerModel, DatePickerEffect) {
  case msg {
    // === Navigation ===
    PreviousDay -> {
      let new_date = model.selected_date - 1
      case is_date_valid(new_date, model.min_date, model.max_date) {
        True -> {
          let updated = set_selected_date(model, new_date)
          #(updated, NoEffect)
        }
        False -> #(model, NoEffect)
      }
    }

    NextDay -> {
      let new_date = model.selected_date + 1
      case is_date_valid(new_date, model.min_date, model.max_date) {
        True -> {
          let updated = set_selected_date(model, new_date)
          #(updated, NoEffect)
        }
        False -> #(model, NoEffect)
      }
    }

    PreviousWeek -> {
      let new_date = model.selected_date - 7
      case is_date_valid(new_date, model.min_date, model.max_date) {
        True -> {
          let updated = set_selected_date(model, new_date)
          #(updated, NoEffect)
        }
        False -> #(model, NoEffect)
      }
    }

    NextWeek -> {
      let new_date = model.selected_date + 7
      case is_date_valid(new_date, model.min_date, model.max_date) {
        True -> {
          let updated = set_selected_date(model, new_date)
          #(updated, NoEffect)
        }
        False -> #(model, NoEffect)
      }
    }

    PreviousMonth -> {
      let #(year, month) = case model.view_month {
        1 -> #(model.view_year - 1, 12)
        m -> #(model.view_year, m - 1)
      }
      let updated = DatePickerModel(..model, view_year: year, view_month: month)
      #(updated, NoEffect)
    }

    NextMonth -> {
      let #(year, month) = case model.view_month {
        12 -> #(model.view_year + 1, 1)
        m -> #(model.view_year, m + 1)
      }
      let updated = DatePickerModel(..model, view_year: year, view_month: month)
      #(updated, NoEffect)
    }

    PreviousYear -> {
      let updated = DatePickerModel(..model, view_year: model.view_year - 1)
      #(updated, NoEffect)
    }

    NextYear -> {
      let updated = DatePickerModel(..model, view_year: model.view_year + 1)
      #(updated, NoEffect)
    }

    GoToToday -> {
      let today = get_today_date_int()
      let updated = set_selected_date(model, today)
      #(updated, NoEffect)
    }

    // === Selection ===
    SelectDate(date_int) -> {
      case is_date_valid(date_int, model.min_date, model.max_date) {
        True -> {
          let updated = set_selected_date(model, date_int)
          #(updated, NoEffect)
        }
        False -> {
          let updated =
            DatePickerModel(..model, error: Some("Date out of range"))
          #(updated, NoEffect)
        }
      }
    }

    ConfirmSelection -> {
      let updated = DatePickerModel(..model, is_open: False)
      #(updated, DateSelected(model.selected_date))
    }

    Cancel -> {
      let updated =
        DatePickerModel(..model, is_open: False, input_mode: False, error: None)
      #(updated, Cancelled)
    }

    // === Input Mode ===
    ToggleInputMode -> {
      let input_text =
        date_int_to_string(model.selected_date, model.date_format)
      let updated =
        DatePickerModel(
          ..model,
          input_mode: !model.input_mode,
          input_text: input_text,
          error: None,
        )
      #(updated, NoEffect)
    }

    InputChanged(text) -> {
      let updated = DatePickerModel(..model, input_text: text, error: None)
      #(updated, NoEffect)
    }

    ParseInput -> {
      case parse_date_input(model.input_text, model.date_format) {
        Ok(date_int) -> {
          case is_date_valid(date_int, model.min_date, model.max_date) {
            True -> {
              let updated =
                set_selected_date(
                  DatePickerModel(..model, input_mode: False),
                  date_int,
                )
              #(updated, NoEffect)
            }
            False -> {
              let updated =
                DatePickerModel(..model, error: Some("Date out of range"))
              #(updated, NoEffect)
            }
          }
        }
        Error(err) -> {
          let updated = DatePickerModel(..model, error: Some(err))
          #(updated, NoEffect)
        }
      }
    }

    // === State ===
    Open -> {
      let updated = DatePickerModel(..model, is_open: True)
      #(updated, NoEffect)
    }

    Close -> {
      let updated = DatePickerModel(..model, is_open: False)
      #(updated, NoEffect)
    }

    ClearError -> {
      let updated = DatePickerModel(..model, error: None)
      #(updated, NoEffect)
    }
  }
}

/// Handle keyboard input for date picker
pub fn handle_key(
  model: DatePickerModel,
  key: String,
) -> #(DatePickerModel, DatePickerEffect) {
  case model.input_mode {
    True -> {
      case key {
        "\r" -> update(model, ParseInput)
        "\u{001B}" -> update(model, ToggleInputMode)
        _ -> #(model, NoEffect)
      }
    }
    False -> {
      case key {
        "h" | "\u{001B}[D" -> update(model, PreviousDay)
        "l" | "\u{001B}[C" -> update(model, NextDay)
        "k" | "\u{001B}[A" -> update(model, PreviousWeek)
        "j" | "\u{001B}[B" -> update(model, NextWeek)
        "H" -> update(model, PreviousMonth)
        "L" -> update(model, NextMonth)
        "[" -> update(model, PreviousYear)
        "]" -> update(model, NextYear)
        "t" -> update(model, GoToToday)
        "i" -> update(model, ToggleInputMode)
        "\r" -> update(model, ConfirmSelection)
        "\u{001B}" -> update(model, Cancel)
        _ -> #(model, NoEffect)
      }
    }
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Set selected date and update view
fn set_selected_date(model: DatePickerModel, date_int: Int) -> DatePickerModel {
  let #(year, month, _day) = date_int_to_ymd(date_int)
  DatePickerModel(
    ..model,
    selected_date: date_int,
    view_year: year,
    view_month: month,
    error: None,
  )
}

/// Check if date is within valid range
fn is_date_valid(
  date_int: Int,
  min_date: Option(Int),
  max_date: Option(Int),
) -> Bool {
  let min_ok = case min_date {
    Some(min) -> date_int >= min
    None -> True
  }
  let max_ok = case max_date {
    Some(max) -> date_int <= max
    None -> True
  }
  min_ok && max_ok
}

/// Get today's date as days since epoch
fn get_today_date_int() -> Int {
  let now = birl.now()
  let today_seconds = birl.to_unix(now)
  today_seconds / 86_400
}

/// Convert date_int to year, month, day
fn date_int_to_ymd(date_int: Int) -> #(Int, Int, Int) {
  let seconds = date_int * 86_400
  let date = birl.from_unix(seconds)
  let iso = birl.to_iso8601(date)
  // Parse YYYY-MM-DD from ISO string
  let parts = string.slice(iso, 0, 10) |> string.split("-")
  case parts {
    [y_str, m_str, d_str] -> {
      let year = result.unwrap(int.parse(y_str), 2000)
      let month = result.unwrap(int.parse(m_str), 1)
      let day = result.unwrap(int.parse(d_str), 1)
      #(year, month, day)
    }
    _ -> #(2000, 1, 1)
  }
}

/// Convert year, month, day to date_int
fn ymd_to_date_int(year: Int, month: Int, day: Int) -> Result(Int, String) {
  let date_str =
    string.pad_start(int.to_string(year), 4, "0")
    <> "-"
    <> string.pad_start(int.to_string(month), 2, "0")
    <> "-"
    <> string.pad_start(int.to_string(day), 2, "0")
    <> "T00:00:00"

  case birl.from_naive(date_str) {
    Ok(dt) -> {
      let seconds = birl.to_unix(dt)
      Ok(seconds / 86_400)
    }
    Error(_) -> Error("Invalid date")
  }
}

/// Convert date_int to display string
fn date_int_to_string(date_int: Int, format: DateFormat) -> String {
  let #(year, month, day) = date_int_to_ymd(date_int)
  case format {
    IsoFormat ->
      string.pad_start(int.to_string(year), 4, "0")
      <> "-"
      <> string.pad_start(int.to_string(month), 2, "0")
      <> "-"
      <> string.pad_start(int.to_string(day), 2, "0")
    UsFormat ->
      string.pad_start(int.to_string(month), 2, "0")
      <> "/"
      <> string.pad_start(int.to_string(day), 2, "0")
      <> "/"
      <> int.to_string(year)
    EuFormat ->
      string.pad_start(int.to_string(day), 2, "0")
      <> "/"
      <> string.pad_start(int.to_string(month), 2, "0")
      <> "/"
      <> int.to_string(year)
    LongFormat ->
      month_name(month)
      <> " "
      <> int.to_string(day)
      <> ", "
      <> int.to_string(year)
  }
}

/// Parse date input string
fn parse_date_input(input: String, format: DateFormat) -> Result(Int, String) {
  case format {
    IsoFormat -> {
      case string.split(input, "-") {
        [y, m, d] -> {
          case int.parse(y), int.parse(m), int.parse(d) {
            Ok(year), Ok(month), Ok(day) -> ymd_to_date_int(year, month, day)
            _, _, _ -> Error("Invalid date format (YYYY-MM-DD)")
          }
        }
        _ -> Error("Invalid date format (YYYY-MM-DD)")
      }
    }
    UsFormat -> {
      case string.split(input, "/") {
        [m, d, y] -> {
          case int.parse(m), int.parse(d), int.parse(y) {
            Ok(month), Ok(day), Ok(year) -> ymd_to_date_int(year, month, day)
            _, _, _ -> Error("Invalid date format (MM/DD/YYYY)")
          }
        }
        _ -> Error("Invalid date format (MM/DD/YYYY)")
      }
    }
    EuFormat -> {
      case string.split(input, "/") {
        [d, m, y] -> {
          case int.parse(d), int.parse(m), int.parse(y) {
            Ok(day), Ok(month), Ok(year) -> ymd_to_date_int(year, month, day)
            _, _, _ -> Error("Invalid date format (DD/MM/YYYY)")
          }
        }
        _ -> Error("Invalid date format (DD/MM/YYYY)")
      }
    }
    LongFormat -> Error("Long format input not supported")
  }
}

/// Get month name
fn month_name(month: Int) -> String {
  case month {
    1 -> "January"
    2 -> "February"
    3 -> "March"
    4 -> "April"
    5 -> "May"
    6 -> "June"
    7 -> "July"
    8 -> "August"
    9 -> "September"
    10 -> "October"
    11 -> "November"
    12 -> "December"
    _ -> "Unknown"
  }
}

/// Get short month name
fn month_short(month: Int) -> String {
  case month {
    1 -> "Jan"
    2 -> "Feb"
    3 -> "Mar"
    4 -> "Apr"
    5 -> "May"
    6 -> "Jun"
    7 -> "Jul"
    8 -> "Aug"
    9 -> "Sep"
    10 -> "Oct"
    11 -> "Nov"
    12 -> "Dec"
    _ -> "???"
  }
}

/// Get day of week (0 = Sunday, 6 = Saturday)
fn day_of_week(date_int: Int) -> Int {
  // Unix epoch (Jan 1, 1970) was a Thursday (4)
  { date_int + 4 } % 7
}

/// Get number of days in month
fn days_in_month(year: Int, month: Int) -> Int {
  case month {
    1 | 3 | 5 | 7 | 8 | 10 | 12 -> 31
    4 | 6 | 9 | 11 -> 30
    2 -> {
      case is_leap_year(year) {
        True -> 29
        False -> 28
      }
    }
    _ -> 30
  }
}

/// Check if year is leap year
fn is_leap_year(year: Int) -> Bool {
  case year % 400 == 0 {
    True -> True
    False ->
      case year % 100 == 0 {
        True -> False
        False -> year % 4 == 0
      }
  }
}

// ============================================================================
// View Functions
// ============================================================================

/// Render the date picker
pub fn view(
  model: DatePickerModel,
  on_msg: fn(DatePickerMsg) -> msg,
) -> shore.Node(msg) {
  case model.is_open {
    False -> view_closed(model, on_msg)
    True -> view_open(model, on_msg)
  }
}

/// Render closed state (just shows selected date)
fn view_closed(
  model: DatePickerModel,
  on_msg: fn(DatePickerMsg) -> msg,
) -> shore.Node(msg) {
  let date_str = date_int_to_string(model.selected_date, model.date_format)
  ui.text("📅 " <> date_str)
}

/// Render open state (full calendar)
fn view_open(
  model: DatePickerModel,
  on_msg: fn(DatePickerMsg) -> msg,
) -> shore.Node(msg) {
  case model.input_mode {
    True -> view_input_mode(model, on_msg)
    False -> view_calendar_mode(model, on_msg)
  }
}

/// Render input mode
fn view_input_mode(
  model: DatePickerModel,
  on_msg: fn(DatePickerMsg) -> msg,
) -> shore.Node(msg) {
  let format_hint = case model.date_format {
    IsoFormat -> "YYYY-MM-DD"
    UsFormat -> "MM/DD/YYYY"
    EuFormat -> "DD/MM/YYYY"
    LongFormat -> "YYYY-MM-DD"
  }

  let error_section = case model.error {
    Some(err) -> [
      ui.br(),
      ui.text_styled("Error: " <> err, Some(style.Red), None),
    ]
    None -> []
  }

  let footer_section = [
    ui.br(),
    ui.text_styled("[Enter] Parse  [Esc] Cancel", Some(style.Cyan), None),
  ]

  ui.col(
    list.flatten([
      [
        ui.br(),
        ui.text_styled("📅 Enter Date", Some(style.Green), None),
        ui.hr(),
        ui.br(),
        ui.text("Format: " <> format_hint),
        ui.br(),
        ui.input("Date:", model.input_text, style.Pct(50), fn(text) {
          on_msg(InputChanged(text))
        }),
      ],
      error_section,
      footer_section,
    ]),
  )
}

/// Render calendar mode
fn view_calendar_mode(
  model: DatePickerModel,
  on_msg: fn(DatePickerMsg) -> msg,
) -> shore.Node(msg) {
  let #(sel_year, sel_month, sel_day) = date_int_to_ymd(model.selected_date)
  let today = get_today_date_int()
  let #(today_year, today_month, today_day) = date_int_to_ymd(today)

  let month_str =
    month_name(model.view_month) <> " " <> int.to_string(model.view_year)

  // Build calendar grid
  let first_day_of_month = case
    ymd_to_date_int(model.view_year, model.view_month, 1)
  {
    Ok(d) -> d
    Error(_) -> model.selected_date
  }
  let first_dow = day_of_week(first_day_of_month)
  let num_days = days_in_month(model.view_year, model.view_month)

  // Build rows (6 rows max for calendar)
  let calendar_rows =
    build_calendar_rows(
      model.view_year,
      model.view_month,
      first_dow,
      num_days,
      sel_year,
      sel_month,
      sel_day,
      today_year,
      today_month,
      today_day,
    )

  let header_section = [
    ui.br(),
    ui.align(style.Center, ui.text_styled(month_str, Some(style.Green), None)),
    ui.hr(),
    ui.br(),
    ui.text("  Su  Mo  Tu  We  Th  Fr  Sa"),
  ]

  let calendar_section = list.map(calendar_rows, fn(row) { ui.text(row) })

  let error_section = case model.error {
    Some(err) -> [ui.text_styled("Error: " <> err, Some(style.Red), None)]
    None -> []
  }

  let footer_section = [
    ui.br(),
    ui.text(
      "Selected: " <> date_int_to_string(model.selected_date, model.date_format),
    ),
  ]

  let help_section = [
    ui.br(),
    ui.hr(),
    ui.text_styled(
      "[←→] Day  [↑↓] Week  [H/L] Month  [t] Today  [i] Input  [Enter] Select",
      Some(style.Cyan),
      None,
    ),
  ]

  ui.col(
    list.flatten([
      header_section,
      calendar_section,
      footer_section,
      error_section,
      help_section,
    ]),
  )
}

/// Build calendar row strings
fn build_calendar_rows(
  view_year: Int,
  view_month: Int,
  first_dow: Int,
  num_days: Int,
  sel_year: Int,
  sel_month: Int,
  sel_day: Int,
  today_year: Int,
  today_month: Int,
  today_day: Int,
) -> List(String) {
  // Build day numbers with padding for first week
  let padding = list.repeat("   ", first_dow)

  let days =
    list.range(1, num_days)
    |> list.map(fn(day) {
      let is_selected =
        view_year == sel_year && view_month == sel_month && day == sel_day
      let is_today =
        view_year == today_year && view_month == today_month && day == today_day

      let day_str = string.pad_start(int.to_string(day), 2, " ")
      case is_selected, is_today {
        True, _ -> "[" <> day_str <> "]"
        False, True -> "(" <> day_str <> ")"
        False, False -> " " <> day_str <> " "
      }
    })

  let all_cells = list.append(padding, days)

  // Chunk into weeks (7 days each)
  chunk_list(all_cells, 7)
  |> list.map(fn(week) { string.join(week, " ") })
}

/// Chunk a list into sublists of given size
fn chunk_list(items: List(a), size: Int) -> List(List(a)) {
  case items {
    [] -> []
    _ -> {
      let chunk = list.take(items, size)
      let rest = list.drop(items, size)
      [chunk, ..chunk_list(rest, size)]
    }
  }
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
  date_int_to_string(model.selected_date, model.date_format)
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
