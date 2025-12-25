/// Exercise View Rendering
///
/// Handles all UI rendering for the exercise tracking screen.
import gleam/float
import gleam/int
import gleam/list
import meal_planner/cli/screens/exercise/helpers
import meal_planner/cli/screens/exercise/messages.{
  type ExerciseMsg, DateConfirmPicker, EditCaloriesChanged, EditDurationChanged,
  NoOp, SearchQueryChanged,
}
import meal_planner/cli/screens/exercise/model.{
  type ExerciseDisplayEntry, type ExerciseEditState, type ExerciseModel,
  ConfirmDelete, DatePicker, DetailsView, EditEntry, MainView, QuickAddPopup,
  SearchPopup,
}
import meal_planner/fatsecret/exercise/types as exercise_types
import shore
import shore/style
import shore/ui

// ============================================================================
// Main View Router
// ============================================================================

/// Render the exercise view screen
pub fn exercise_view(model: ExerciseModel) -> shore.Node(ExerciseMsg) {
  case model.view_state {
    MainView -> view_main_exercise(model)
    SearchPopup -> view_search_popup(model)
    DatePicker(date_input) -> view_date_picker(model, date_input)
    ConfirmDelete(entry_id) -> view_delete_confirm(model, entry_id)
    EditEntry(edit_state) -> view_edit_entry(model, edit_state)
    QuickAddPopup -> view_quick_add(model)
    DetailsView(entry) -> view_details(model, entry)
  }
}

// ============================================================================
// Main View
// ============================================================================

/// Render main exercise view
fn view_main_exercise(model: ExerciseModel) -> shore.Node(ExerciseMsg) {
  let date_str = helpers.date_int_to_string(model.current_date)
  let summary = model.daily_summary

  let header_section = [
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("🏃 Exercise Log - " <> date_str, Some(style.Green), None),
    ),
    ui.hr_styled(style.Green),
  ]

  let error_section = case model.error_message {
    Some(err) -> [ui.br(), ui.text_styled("⚠ " <> err, Some(style.Red), None)]
    None -> []
  }

  let nav_section = [
    ui.br(),
    ui.text_styled(
      "[<-] Prev  [->] Next  [t] Today  [g] Go to  [a] Add  [q] Quick Add",
      Some(style.Cyan),
      None,
    ),
    ui.hr(),
  ]

  let summary_section = [
    ui.br(),
    ui.text_styled("Daily Summary:", Some(style.Yellow), None),
    ui.text(
      "  Sessions: "
      <> int.to_string(summary.session_count)
      <> " | Duration: "
      <> int.to_string(summary.total_duration)
      <> " min"
      <> " | Calories: "
      <> helpers.float_to_string(summary.total_calories),
    ),
    ui.br(),
  ]

  let loading_section = case model.is_loading {
    True -> [ui.text_styled("Loading...", Some(style.Yellow), None)]
    False -> []
  }

  let divider_section = [ui.hr(), ui.br()]

  let entries_section = case model.entries {
    [] -> [ui.text("No exercises logged for this date.")]
    entries -> list.map(entries, render_exercise_entry)
  }

  let footer_section = [
    ui.br(),
    ui.text_styled(
      "Press [e] to edit, [d] to delete, [Enter] for details",
      Some(style.Cyan),
      None,
    ),
  ]

  ui.col(
    list.flatten([
      header_section,
      error_section,
      nav_section,
      summary_section,
      loading_section,
      divider_section,
      entries_section,
      footer_section,
    ]),
  )
}

/// Render a single exercise entry
fn render_exercise_entry(entry: ExerciseDisplayEntry) -> shore.Node(ExerciseMsg) {
  ui.text("  • " <> entry.summary_line)
}

// ============================================================================
// Search Popup
// ============================================================================

/// Render search popup
fn view_search_popup(model: ExerciseModel) -> shore.Node(ExerciseMsg) {
  let search = model.search_state

  let header_section = [
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("🔍 Search Exercises", Some(style.Green), None),
    ),
    ui.hr_styled(style.Green),
    ui.br(),
  ]

  let input_section = [
    ui.input("Search:", search.query, style.Pct(80), fn(q) {
      SearchQueryChanged(q)
    }),
    ui.br(),
  ]

  let loading_section = case search.is_loading {
    True -> [ui.text_styled("Searching...", Some(style.Yellow), None)]
    False -> []
  }

  let error_section = case search.error {
    Some(err) -> [ui.text_styled("Error: " <> err, Some(style.Red), None)]
    None -> []
  }

  let results_section =
    render_search_results(search.results, search.selected_index)

  let footer_section = [
    ui.hr(),
    ui.text_styled(
      "[Enter] Search  [↑/↓] Navigate  [Esc] Cancel",
      Some(style.Cyan),
      None,
    ),
  ]

  ui.col(
    list.flatten([
      header_section,
      input_section,
      loading_section,
      error_section,
      [ui.br()],
      results_section,
      footer_section,
    ]),
  )
}

/// Render search results
fn render_search_results(
  results: List(model.ExerciseSearchResult),
  selected_index: Int,
) -> List(shore.Node(ExerciseMsg)) {
  case results {
    [] -> [ui.text("No results. Type and press Enter to search.")]
    _ -> {
      results
      |> list.index_map(fn(result, idx) {
        let prefix = case idx == selected_index {
          True -> "► "
          False -> "  "
        }
        ui.text(
          prefix
          <> int.to_string(idx + 1)
          <> ". "
          <> result.exercise_name
          <> " ("
          <> helpers.float_to_string(result.calories_per_hour)
          <> " cal/hr)",
        )
      })
    }
  }
}

// ============================================================================
// Date Picker
// ============================================================================

/// Render date picker
fn view_date_picker(
  model: ExerciseModel,
  date_input: String,
) -> shore.Node(ExerciseMsg) {
  ui.col([
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("📅 Go to Date", Some(style.Green), None),
    ),
    ui.hr_styled(style.Green),
    ui.br(),
    ui.text("Enter date (YYYY-MM-DD):"),
    ui.br(),
    ui.input("Date:", date_input, style.Pct(50), fn(d) { DateConfirmPicker(d) }),
    ui.br(),
    ui.text_styled(
      "Current: " <> helpers.date_int_to_string(model.current_date),
      Some(style.Cyan),
      None,
    ),
    ui.hr(),
    ui.text_styled("[Enter] Confirm  [Esc] Cancel", Some(style.Cyan), None),
  ])
}

// ============================================================================
// Delete Confirmation
// ============================================================================

/// Render delete confirmation
fn view_delete_confirm(
  _model: ExerciseModel,
  entry_id: exercise_types.ExerciseEntryId,
) -> shore.Node(ExerciseMsg) {
  let id_str = exercise_types.exercise_entry_id_to_string(entry_id)

  ui.col([
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("⚠ Confirm Delete", Some(style.Red), None),
    ),
    ui.hr_styled(style.Red),
    ui.br(),
    ui.text("Delete this exercise entry?"),
    ui.br(),
    ui.text("Entry ID: " <> id_str),
    ui.br(),
    ui.text_styled("[y] Yes  [n] No", Some(style.Yellow), None),
  ])
}

// ============================================================================
// Edit Entry
// ============================================================================

/// Render edit entry dialog
fn view_edit_entry(
  _model: ExerciseModel,
  edit_state: ExerciseEditState,
) -> shore.Node(ExerciseMsg) {
  let entry = edit_state.entry

  ui.col([
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("✏ Edit Exercise", Some(style.Green), None),
    ),
    ui.hr_styled(style.Green),
    ui.br(),
    ui.text("Exercise: " <> entry.exercise_name),
    ui.br(),
    ui.input(
      "Duration (min):",
      int.to_string(edit_state.new_duration),
      style.Pct(30),
      fn(s) {
        case int.parse(s) {
          Ok(d) -> EditDurationChanged(d)
          Error(_) -> NoOp
        }
      },
    ),
    ui.br(),
    ui.input(
      "Calories:",
      helpers.float_to_string(edit_state.new_calories),
      style.Pct(30),
      fn(s) {
        case float.parse(s) {
          Ok(c) -> EditCaloriesChanged(c)
          Error(_) -> NoOp
        }
      },
    ),
    ui.br(),
    ui.text_styled("[Enter] Save  [Esc] Cancel", Some(style.Cyan), None),
  ])
}

// ============================================================================
// Quick Add Popup
// ============================================================================

/// Render quick add popup
fn view_quick_add(model: ExerciseModel) -> shore.Node(ExerciseMsg) {
  let header_section = [
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("⚡ Quick Add", Some(style.Green), None),
    ),
    ui.hr_styled(style.Green),
    ui.br(),
    ui.text("Recent exercises:"),
    ui.br(),
  ]

  let exercises_section = case model.recent_exercises {
    [] -> [ui.text("No recent exercises available.")]
    exercises -> {
      exercises
      |> list.index_map(fn(entry, idx) {
        let duration = int.to_string(entry.duration_min)
        let calories = helpers.float_to_string(entry.calories)
        ui.text(
          "  "
          <> int.to_string(idx + 1)
          <> ". "
          <> entry.exercise_name
          <> " - "
          <> duration
          <> " min - "
          <> calories
          <> " cal",
        )
      })
    }
  }

  let footer_section = [
    ui.hr(),
    ui.text_styled("[1-9] Select  [Esc] Cancel", Some(style.Cyan), None),
  ]

  ui.col(list.flatten([header_section, exercises_section, footer_section]))
}

// ============================================================================
// Details View
// ============================================================================

/// Render details view
fn view_details(
  _model: ExerciseModel,
  entry: exercise_types.ExerciseEntry,
) -> shore.Node(ExerciseMsg) {
  ui.col([
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("📋 Exercise Details", Some(style.Green), None),
    ),
    ui.hr_styled(style.Green),
    ui.br(),
    ui.text("Name: " <> entry.exercise_name),
    ui.br(),
    ui.text("Duration: " <> int.to_string(entry.duration_min) <> " minutes"),
    ui.br(),
    ui.text("Calories Burned: " <> helpers.float_to_string(entry.calories)),
    ui.br(),
    ui.text("Date: " <> int.to_string(entry.date_int)),
    ui.br(),
    ui.text(
      "Entry ID: "
      <> exercise_types.exercise_entry_id_to_string(entry.exercise_entry_id),
    ),
    ui.br(),
    ui.hr(),
    ui.text_styled("[e] Edit  [d] Delete  [Esc] Back", Some(style.Cyan), None),
  ])
}
