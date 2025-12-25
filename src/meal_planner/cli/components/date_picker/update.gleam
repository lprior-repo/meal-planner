/// Date Picker Update - State Update Logic
///
/// Contains update function and keyboard handling.
import gleam/option.{None, Some}
import meal_planner/cli/components/date_picker/logic
import meal_planner/cli/components/date_picker/messages.{
  type DatePickerMsg, Cancel, ClearError, Close, ConfirmSelection, GoToToday,
  InputChanged, NextDay, NextMonth, NextWeek, NextYear, Open, ParseInput,
  PreviousDay, PreviousMonth, PreviousWeek, PreviousYear, SelectDate,
  ToggleInputMode,
}
import meal_planner/cli/components/date_picker/model.{
  type DatePickerEffect, type DatePickerModel, Cancelled, DatePickerModel,
  DateSelected, NoEffect,
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
      case logic.is_date_valid(new_date, model.min_date, model.max_date) {
        True -> {
          let updated = logic.set_selected_date(model, new_date)
          #(updated, NoEffect)
        }
        False -> #(model, NoEffect)
      }
    }

    NextDay -> {
      let new_date = model.selected_date + 1
      case logic.is_date_valid(new_date, model.min_date, model.max_date) {
        True -> {
          let updated = logic.set_selected_date(model, new_date)
          #(updated, NoEffect)
        }
        False -> #(model, NoEffect)
      }
    }

    PreviousWeek -> {
      let new_date = model.selected_date - 7
      case logic.is_date_valid(new_date, model.min_date, model.max_date) {
        True -> {
          let updated = logic.set_selected_date(model, new_date)
          #(updated, NoEffect)
        }
        False -> #(model, NoEffect)
      }
    }

    NextWeek -> {
      let new_date = model.selected_date + 7
      case logic.is_date_valid(new_date, model.min_date, model.max_date) {
        True -> {
          let updated = logic.set_selected_date(model, new_date)
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
      let today = logic.get_today_date_int()
      let updated = logic.set_selected_date(model, today)
      #(updated, NoEffect)
    }

    // === Selection ===
    SelectDate(date_int) -> {
      case logic.is_date_valid(date_int, model.min_date, model.max_date) {
        True -> {
          let updated = logic.set_selected_date(model, date_int)
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
        logic.date_int_to_string(model.selected_date, model.date_format)
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
      case logic.parse_date_input(model.input_text, model.date_format) {
        Ok(date_int) -> {
          case logic.is_date_valid(date_int, model.min_date, model.max_date) {
            True -> {
              let updated =
                logic.set_selected_date(
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

// ============================================================================
// Keyboard Handling
// ============================================================================

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
