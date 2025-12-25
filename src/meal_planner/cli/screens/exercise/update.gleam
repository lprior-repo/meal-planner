/// Exercise View Update Logic
///
/// Handles all state transitions and business logic for the exercise screen.
import gleam/list
import gleam/option.{None, Some}
import meal_planner/cli/screens/exercise/helpers
import meal_planner/cli/screens/exercise/messages.{
  type ExerciseEffect, type ExerciseMsg, AddExerciseStart, CancelAddExercise,
  ClearError, CloseDetails, ConfirmAddExercise, CreateEntry, DateCancelPicker,
  DateConfirmPicker, DateNext, DatePrevious, DateShowPicker, DateToday,
  DeleteCancel, DeleteConfirm, DeleteEntry, DeleteExerciseStart,
  EditCaloriesChanged, EditCancel, EditConfirm, EditDurationChanged,
  EditExerciseStart, EntryCreated, EntryDeleted, EntryUpdated, ExerciseSelected,
  FetchEntries, GotDailyEntries, GotSearchResults, KeyPressed, NoEffect, NoOp,
  QuickAddCancel, QuickAddSelect, QuickAddStart, Refresh, SearchExercises,
  SearchQueryChanged, SearchStarted, UpdateEntry, ViewDetails,
}
import meal_planner/cli/screens/exercise/model.{
  type ExerciseEntryInput, type ExerciseEntryUpdate, type ExerciseModel,
  ConfirmDelete, DatePicker, DetailsView, EditEntry, ExerciseEditState,
  ExerciseEntryInput, ExerciseEntryUpdate, ExerciseModel, ExerciseSearchState,
  MainView, QuickAddPopup, SearchPopup,
}
import meal_planner/fatsecret/exercise/types as exercise_types

// ============================================================================
// Update Function
// ============================================================================

/// Main update function for exercise view
pub fn exercise_update(
  model: ExerciseModel,
  msg: ExerciseMsg,
) -> #(ExerciseModel, ExerciseEffect) {
  case msg {
    // === Date Navigation ===
    DatePrevious -> {
      let new_date = model.current_date - 1
      let updated =
        ExerciseModel(..model, current_date: new_date, is_loading: True)
      #(updated, FetchEntries(new_date))
    }

    DateNext -> {
      let new_date = model.current_date + 1
      let updated =
        ExerciseModel(..model, current_date: new_date, is_loading: True)
      #(updated, FetchEntries(new_date))
    }

    DateToday -> {
      let today = helpers.get_today_date_int()
      let updated =
        ExerciseModel(..model, current_date: today, is_loading: True)
      #(updated, FetchEntries(today))
    }

    DateShowPicker -> {
      let date_str = helpers.date_int_to_string(model.current_date)
      let updated = ExerciseModel(..model, view_state: DatePicker(date_str))
      #(updated, NoEffect)
    }

    DateConfirmPicker(date_input) -> {
      case helpers.parse_date_string(date_input) {
        Ok(date_int) -> {
          let updated =
            ExerciseModel(
              ..model,
              current_date: date_int,
              view_state: MainView,
              is_loading: True,
            )
          #(updated, FetchEntries(date_int))
        }
        Error(err) -> {
          let updated =
            ExerciseModel(
              ..model,
              error_message: Some(err),
              view_state: MainView,
            )
          #(updated, NoEffect)
        }
      }
    }

    DateCancelPicker -> {
      let updated = ExerciseModel(..model, view_state: MainView)
      #(updated, NoEffect)
    }

    // === Add Exercise ===
    AddExerciseStart -> {
      let updated =
        ExerciseModel(
          ..model,
          view_state: SearchPopup,
          search_state: ExerciseSearchState(
            query: "",
            results: [],
            selected_index: 0,
            is_loading: False,
            error: None,
          ),
        )
      #(updated, NoEffect)
    }

    SearchQueryChanged(query) -> {
      let search = ExerciseSearchState(..model.search_state, query: query)
      let updated = ExerciseModel(..model, search_state: search)
      #(updated, NoEffect)
    }

    SearchStarted -> {
      let search =
        ExerciseSearchState(..model.search_state, is_loading: True, error: None)
      let updated = ExerciseModel(..model, search_state: search)
      #(updated, SearchExercises(model.search_state.query))
    }

    GotSearchResults(result) -> {
      case result {
        Ok(results) -> {
          let search =
            ExerciseSearchState(
              ..model.search_state,
              results: results,
              is_loading: False,
              selected_index: 0,
            )
          let updated = ExerciseModel(..model, search_state: search)
          #(updated, NoEffect)
        }
        Error(err) -> {
          let search =
            ExerciseSearchState(
              ..model.search_state,
              is_loading: False,
              error: Some(err),
            )
          let updated = ExerciseModel(..model, search_state: search)
          #(updated, NoEffect)
        }
      }
    }

    ExerciseSelected(_result) -> {
      // For now, just close popup - in full impl would show duration picker
      let updated = ExerciseModel(..model, view_state: MainView)
      #(updated, NoEffect)
    }

    ConfirmAddExercise(duration, calories) -> {
      let input =
        ExerciseEntryInput(
          exercise_id: "placeholder",
          exercise_name: "Exercise",
          duration_min: duration,
          calories: calories,
          date_int: model.current_date,
        )
      let updated = ExerciseModel(..model, view_state: MainView)
      #(updated, CreateEntry(input))
    }

    CancelAddExercise -> {
      let updated =
        ExerciseModel(
          ..model,
          view_state: MainView,
          search_state: ExerciseSearchState(
            query: "",
            results: [],
            selected_index: 0,
            is_loading: False,
            error: None,
          ),
        )
      #(updated, NoEffect)
    }

    // === Quick Add ===
    QuickAddStart -> {
      let updated = ExerciseModel(..model, view_state: QuickAddPopup)
      #(updated, NoEffect)
    }

    QuickAddSelect(entry) -> {
      // Clone the entry for today
      let input =
        ExerciseEntryInput(
          exercise_id: exercise_types.exercise_entry_id_to_string(
            entry.exercise_entry_id,
          ),
          exercise_name: entry.exercise_name,
          duration_min: entry.duration_min,
          calories: entry.calories,
          date_int: model.current_date,
        )
      let updated = ExerciseModel(..model, view_state: MainView)
      #(updated, CreateEntry(input))
    }

    QuickAddCancel -> {
      let updated = ExerciseModel(..model, view_state: MainView)
      #(updated, NoEffect)
    }

    // === Edit Exercise ===
    EditExerciseStart(entry) -> {
      let edit_state =
        ExerciseEditState(
          entry: entry,
          new_duration: entry.duration_min,
          new_calories: entry.calories,
          original_duration: entry.duration_min,
          original_calories: entry.calories,
        )
      let updated =
        ExerciseModel(
          ..model,
          view_state: EditEntry(edit_state),
          edit_state: Some(edit_state),
        )
      #(updated, NoEffect)
    }

    EditDurationChanged(duration) -> {
      case model.edit_state {
        Some(edit) -> {
          let new_edit = ExerciseEditState(..edit, new_duration: duration)
          let updated =
            ExerciseModel(
              ..model,
              edit_state: Some(new_edit),
              view_state: EditEntry(new_edit),
            )
          #(updated, NoEffect)
        }
        None -> #(model, NoEffect)
      }
    }

    EditCaloriesChanged(calories) -> {
      case model.edit_state {
        Some(edit) -> {
          let new_edit = ExerciseEditState(..edit, new_calories: calories)
          let updated =
            ExerciseModel(
              ..model,
              edit_state: Some(new_edit),
              view_state: EditEntry(new_edit),
            )
          #(updated, NoEffect)
        }
        None -> #(model, NoEffect)
      }
    }

    EditConfirm -> {
      case model.edit_state {
        Some(edit) -> {
          let update =
            ExerciseEntryUpdate(
              duration_min: Some(edit.new_duration),
              calories: Some(edit.new_calories),
            )
          let effect = UpdateEntry(edit.entry.exercise_entry_id, update)
          let updated =
            ExerciseModel(..model, view_state: MainView, edit_state: None)
          #(updated, effect)
        }
        None -> #(ExerciseModel(..model, view_state: MainView), NoEffect)
      }
    }

    EditCancel -> {
      let updated =
        ExerciseModel(..model, view_state: MainView, edit_state: None)
      #(updated, NoEffect)
    }

    // === Delete Exercise ===
    DeleteExerciseStart(entry_id) -> {
      let updated = ExerciseModel(..model, view_state: ConfirmDelete(entry_id))
      #(updated, NoEffect)
    }

    DeleteConfirm -> {
      case model.view_state {
        ConfirmDelete(entry_id) -> {
          let updated = ExerciseModel(..model, view_state: MainView)
          #(updated, DeleteEntry(entry_id))
        }
        _ -> #(model, NoEffect)
      }
    }

    DeleteCancel -> {
      let updated = ExerciseModel(..model, view_state: MainView)
      #(updated, NoEffect)
    }

    // === View Details ===
    ViewDetails(entry) -> {
      let updated = ExerciseModel(..model, view_state: DetailsView(entry))
      #(updated, NoEffect)
    }

    CloseDetails -> {
      let updated = ExerciseModel(..model, view_state: MainView)
      #(updated, NoEffect)
    }

    // === Server Responses ===
    GotDailyEntries(result) -> {
      case result {
        Ok(entries) -> {
          let display_entries = list.map(entries, helpers.format_exercise_entry)
          let summary = helpers.calculate_daily_summary(entries)
          let updated =
            ExerciseModel(
              ..model,
              entries: display_entries,
              daily_summary: summary,
              is_loading: False,
              error_message: None,
            )
          #(updated, NoEffect)
        }
        Error(err) -> {
          let updated =
            ExerciseModel(..model, is_loading: False, error_message: Some(err))
          #(updated, NoEffect)
        }
      }
    }

    EntryCreated(result) -> {
      case result {
        Ok(_id) -> #(model, FetchEntries(model.current_date))
        Error(err) -> {
          let updated = ExerciseModel(..model, error_message: Some(err))
          #(updated, NoEffect)
        }
      }
    }

    EntryUpdated(result) -> {
      case result {
        Ok(_) -> #(model, FetchEntries(model.current_date))
        Error(err) -> {
          let updated = ExerciseModel(..model, error_message: Some(err))
          #(updated, NoEffect)
        }
      }
    }

    EntryDeleted(result) -> {
      case result {
        Ok(_) -> #(model, FetchEntries(model.current_date))
        Error(err) -> {
          let updated = ExerciseModel(..model, error_message: Some(err))
          #(updated, NoEffect)
        }
      }
    }

    // === UI ===
    ClearError -> {
      let updated = ExerciseModel(..model, error_message: None)
      #(updated, NoEffect)
    }

    KeyPressed(key_str) -> {
      handle_key_press(model, key_str)
    }

    Refresh -> {
      let updated = ExerciseModel(..model, is_loading: True)
      #(updated, FetchEntries(model.current_date))
    }

    NoOp -> #(model, NoEffect)
  }
}

// ============================================================================
// Keyboard Handling
// ============================================================================

/// Handle keyboard input for exercise view
fn handle_key_press(
  model: ExerciseModel,
  key_str: String,
) -> #(ExerciseModel, ExerciseEffect) {
  case model.view_state {
    MainView -> {
      case key_str {
        "[" -> exercise_update(model, DatePrevious)
        "]" -> exercise_update(model, DateNext)
        "t" -> exercise_update(model, DateToday)
        "g" -> exercise_update(model, DateShowPicker)
        "a" -> exercise_update(model, AddExerciseStart)
        "q" -> exercise_update(model, QuickAddStart)
        "r" -> exercise_update(model, Refresh)
        _ -> #(model, NoEffect)
      }
    }

    SearchPopup -> {
      case key_str {
        "\u{001B}" -> exercise_update(model, CancelAddExercise)
        "\r" -> exercise_update(model, SearchStarted)
        _ -> #(model, NoEffect)
      }
    }

    DatePicker(_) -> {
      case key_str {
        "\u{001B}" -> exercise_update(model, DateCancelPicker)
        _ -> #(model, NoEffect)
      }
    }

    ConfirmDelete(_) -> {
      case key_str {
        "y" -> exercise_update(model, DeleteConfirm)
        "n" -> exercise_update(model, DeleteCancel)
        "\u{001B}" -> exercise_update(model, DeleteCancel)
        _ -> #(model, NoEffect)
      }
    }

    EditEntry(_) -> {
      case key_str {
        "\u{001B}" -> exercise_update(model, EditCancel)
        "\r" -> exercise_update(model, EditConfirm)
        _ -> #(model, NoEffect)
      }
    }

    QuickAddPopup -> {
      case key_str {
        "\u{001B}" -> exercise_update(model, QuickAddCancel)
        _ -> #(model, NoEffect)
      }
    }

    DetailsView(_) -> {
      case key_str {
        "\u{001B}" -> exercise_update(model, CloseDetails)
        _ -> #(model, NoEffect)
      }
    }
  }
}
