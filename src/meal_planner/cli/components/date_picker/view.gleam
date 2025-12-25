/// Date Picker View - Rendering Logic
///
/// Contains view rendering functions for the date picker component.
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import meal_planner/cli/components/date_picker/logic
import meal_planner/cli/components/date_picker/messages.{
  type DatePickerMsg, InputChanged,
}
import meal_planner/cli/components/date_picker/model.{
  type DatePickerModel, EuFormat, IsoFormat, LongFormat, UsFormat,
}
import shore
import shore/style
import shore/ui

// ============================================================================
// Main View
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

// ============================================================================
// Closed State
// ============================================================================

/// Render closed state (just shows selected date)
fn view_closed(
  model: DatePickerModel,
  _on_msg: fn(DatePickerMsg) -> msg,
) -> shore.Node(msg) {
  let date_str =
    logic.date_int_to_string(model.selected_date, model.date_format)
  ui.text("📅 " <> date_str)
}

// ============================================================================
// Open State
// ============================================================================

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

// ============================================================================
// Input Mode
// ============================================================================

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

// ============================================================================
// Calendar Mode
// ============================================================================

/// Render calendar mode
fn view_calendar_mode(
  model: DatePickerModel,
  _on_msg: fn(DatePickerMsg) -> msg,
) -> shore.Node(msg) {
  let #(sel_year, sel_month, sel_day) =
    logic.date_int_to_ymd(model.selected_date)
  let today = logic.get_today_date_int()
  let #(today_year, today_month, today_day) = logic.date_int_to_ymd(today)

  let month_str =
    logic.month_name(model.view_month) <> " " <> int.to_string(model.view_year)

  // Build calendar grid
  let first_day_of_month = case
    logic.ymd_to_date_int(model.view_year, model.view_month, 1)
  {
    Ok(d) -> d
    Error(_) -> model.selected_date
  }
  let first_dow = logic.day_of_week(first_day_of_month)
  let num_days = logic.days_in_month(model.view_year, model.view_month)

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
      "Selected: "
      <> logic.date_int_to_string(model.selected_date, model.date_format),
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

// ============================================================================
// Calendar Grid Rendering
// ============================================================================

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
  logic.chunk_list(all_cells, 7)
  |> list.map(fn(week) { string.join(week, " ") })
}
