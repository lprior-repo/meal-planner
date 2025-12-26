/// Tests for Exercise View Screen
///
/// Tests cover:
/// - Model initialization
/// - View state transitions
/// - Search state management
/// - Daily summary calculations
/// - Type construction
import gleam/dict
import gleam/option.{None}
import gleeunit/should
import meal_planner/cli/screens/exercise_view.{
  type ExerciseViewState, ConfirmDelete, DailySummary, DatePicker,
  ExerciseDisplayEntry, ExerciseEditState, ExerciseSearchResult,
  ExerciseSearchState, MainView, QuickAddPopup, SearchPopup,
}
import meal_planner/fatsecret/exercise/types as exercise_types

// ============================================================================
// Test Helpers
// ============================================================================

/// Create a minimal ExerciseEntry for testing
fn test_exercise_entry(
  name: String,
  duration: Int,
  calories: Float,
) -> exercise_types.ExerciseEntry {
  exercise_types.ExerciseEntry(
    exercise_entry_id: exercise_types.exercise_entry_id("entry_1"),
    exercise_id: exercise_types.exercise_id("ex_123"),
    exercise_name: name,
    duration_min: duration,
    calories: calories,
    date_int: 20_000,
  )
}

// ============================================================================
// Initialization Tests
// ============================================================================

pub fn init_creates_valid_model_test() {
  // GIVEN: Today's date as date_int
  let today = 20_000

  // WHEN: Initializing ExerciseModel
  let model = exercise_view.init(today)

  // THEN: Model should have correct initial state
  model.current_date
  |> should.equal(today)

  model.entries
  |> should.equal([])

  model.view_state
  |> should.equal(MainView)

  model.error_message
  |> should.equal(None)

  model.is_loading
  |> should.equal(False)

  // AND: Search state should be empty
  model.search_state.query
  |> should.equal("")

  model.search_state.results
  |> should.equal([])

  model.search_state.selected_index
  |> should.equal(0)

  model.search_state.is_loading
  |> should.equal(False)

  // AND: Edit state should be None
  model.edit_state
  |> should.equal(None)

  // AND: Recent exercises should be empty
  model.recent_exercises
  |> should.equal([])

  // AND: Cache should be empty
  model.exercise_cache
  |> dict.size
  |> should.equal(0)
}

// ============================================================================
// View State Tests
// ============================================================================

pub fn view_state_main_view_test() {
  // GIVEN: MainView state
  let view_state: ExerciseViewState = MainView

  // THEN: Can pattern match without errors
  case view_state {
    MainView -> True
  }
  |> should.be_true
}

pub fn view_state_search_popup_test() {
  // GIVEN: SearchPopup state
  let view_state: ExerciseViewState = SearchPopup

  // THEN: Can pattern match correctly
  case view_state {
    SearchPopup -> True
  }
  |> should.be_true
}

pub fn view_state_date_picker_test() {
  // GIVEN: DatePicker state with input
  let view_state: ExerciseViewState = DatePicker("2025-12-20")

  // THEN: Can pattern match and extract date_input
  case view_state {
    DatePicker(date_input) -> date_input
  }
  |> should.equal("2025-12-20")
}

pub fn view_state_confirm_delete_test() {
  // GIVEN: ConfirmDelete state with entry ID
  let entry_id = exercise_types.exercise_entry_id("12345")
  let view_state: ExerciseViewState = ConfirmDelete(entry_id)

  // THEN: Can pattern match and extract entry_id
  case view_state {
    ConfirmDelete(id) -> exercise_types.exercise_entry_id_to_string(id)
  }
  |> should.equal("12345")
}

pub fn view_state_quick_add_popup_test() {
  // GIVEN: QuickAddPopup state
  let view_state: ExerciseViewState = QuickAddPopup

  // THEN: Can pattern match correctly
  case view_state {
    QuickAddPopup -> True
  }
  |> should.be_true
}

// ============================================================================
// Search State Tests
// ============================================================================

pub fn search_state_initial_test() {
  // GIVEN: Initial model
  let model = exercise_view.init(20_000)

  // THEN: SearchState should be initialized correctly
  model.search_state.query
  |> should.equal("")

  model.search_state.results
  |> should.equal([])

  model.search_state.selected_index
  |> should.equal(0)

  model.search_state.is_loading
  |> should.equal(False)

  model.search_state.error
  |> should.equal(None)
}

pub fn search_state_construction_test() {
  // GIVEN: Search state with data
  let search_state =
    ExerciseSearchState(
      query: "running",
      results: [
        ExerciseSearchResult(
          exercise_id: "1",
          exercise_name: "Running",
          calories_per_hour: 600.0,
          exercise_type: "Cardio",
        ),
      ],
      selected_index: 0,
      is_loading: False,
      error: None,
    )

  // THEN: State should construct correctly
  search_state.query
  |> should.equal("running")

  case search_state.results {
    [result] -> {
      result.exercise_name |> should.equal("Running")
      result.calories_per_hour |> should.equal(600.0)
    }
    _ -> should.fail()
  }
}

// ============================================================================
// Search Result Tests
// ============================================================================

pub fn exercise_search_result_construction_test() {
  // GIVEN: Exercise search result data
  let result =
    ExerciseSearchResult(
      exercise_id: "ex_123",
      exercise_name: "Swimming",
      calories_per_hour: 500.0,
      exercise_type: "Cardio",
    )

  // THEN: Result should construct correctly
  result.exercise_id
  |> should.equal("ex_123")

  result.exercise_name
  |> should.equal("Swimming")

  result.calories_per_hour
  |> should.equal(500.0)

  result.exercise_type
  |> should.equal("Cardio")
}

// ============================================================================
// Edit State Tests
// ============================================================================

pub fn exercise_edit_state_construction_test() {
  // GIVEN: Exercise entry for editing
  let entry = test_exercise_entry("Running", 30, 300.0)

  // WHEN: Creating edit state
  let edit_state =
    ExerciseEditState(
      entry: entry,
      new_duration: 45,
      new_calories: 450.0,
      original_duration: 30,
      original_calories: 300.0,
    )

  // THEN: Edit state should have correct values
  edit_state.new_duration
  |> should.equal(45)

  edit_state.new_calories
  |> should.equal(450.0)

  edit_state.original_duration
  |> should.equal(30)

  edit_state.original_calories
  |> should.equal(300.0)
}

// ============================================================================
// Display Entry Tests
// ============================================================================

pub fn exercise_display_entry_construction_test() {
  // GIVEN: Exercise entry and display data
  let entry = test_exercise_entry("Running", 30, 300.0)

  // WHEN: Creating display entry
  let display_entry =
    ExerciseDisplayEntry(
      entry: entry,
      name_display: "Running",
      duration_display: "30 min",
      calories_display: "300 cal",
      summary_line: "Running - 30 min - 300 cal",
    )

  // THEN: Display entry should have correct values
  display_entry.name_display
  |> should.equal("Running")

  display_entry.duration_display
  |> should.equal("30 min")

  display_entry.calories_display
  |> should.equal("300 cal")

  display_entry.summary_line
  |> should.equal("Running - 30 min - 300 cal")
}

// ============================================================================
// Daily Summary Tests
// ============================================================================

pub fn daily_summary_construction_test() {
  // GIVEN: Daily summary data
  let summary =
    DailySummary(
      total_calories: 500.0,
      total_duration: 60,
      session_count: 2,
      avg_calories_per_session: 250.0,
    )

  // THEN: Summary should have correct values
  summary.total_calories
  |> should.equal(500.0)

  summary.total_duration
  |> should.equal(60)

  summary.session_count
  |> should.equal(2)

  summary.avg_calories_per_session
  |> should.equal(250.0)
}

pub fn daily_summary_initial_test() {
  // GIVEN: Initial model
  let model = exercise_view.init(20_000)

  // THEN: Daily summary should be zeroed
  model.daily_summary.total_calories
  |> should.equal(0.0)

  model.daily_summary.total_duration
  |> should.equal(0)

  model.daily_summary.session_count
  |> should.equal(0)

  model.daily_summary.avg_calories_per_session
  |> should.equal(0.0)
}

// ============================================================================
// Model Field Tests
// ============================================================================

pub fn model_entries_empty_initially_test() {
  // GIVEN: Initial model
  let model = exercise_view.init(20_000)

  // THEN: Entries should be empty
  model.entries
  |> should.equal([])
}

pub fn model_cache_empty_initially_test() {
  // GIVEN: Initial model
  let model = exercise_view.init(20_000)

  // THEN: Cache should be empty
  model.exercise_cache
  |> dict.size
  |> should.equal(0)
}

pub fn model_recent_exercises_empty_initially_test() {
  // GIVEN: Initial model
  let model = exercise_view.init(20_000)

  // THEN: Recent exercises should be empty
  model.recent_exercises
  |> should.equal([])
}

// ============================================================================
// Message Variant Tests
// ============================================================================

pub fn exercise_msg_all_variants_compile_test() {
  // This test verifies all ExerciseMsg variants can be constructed
  // Compilation success = type system is complete

  let _msgs = [
    // Date navigation
    exercise_view.DatePrevious,
    exercise_view.DateNext,
    exercise_view.DateToday,
    exercise_view.DateShowPicker,
    exercise_view.DateConfirmPicker("2025-12-20"),
    exercise_view.DateCancelPicker,
    // Search
    exercise_view.AddExerciseStart,
    exercise_view.SearchQueryChanged("running"),
    exercise_view.GotSearchResults(Ok([])),
    exercise_view.CancelAddExercise,
    // Quick add
    exercise_view.QuickAddStart,
    exercise_view.QuickAddCancel,
    // Edit
    exercise_view.EditDurationChanged(30),
    exercise_view.EditCaloriesChanged(300.0),
    exercise_view.EditConfirm,
    exercise_view.EditCancel,
    // Delete
    exercise_view.DeleteConfirm,
    exercise_view.DeleteCancel,
    // UI
    exercise_view.ClearError,
  ]

  // If we reach here, all variants compile
  True
  |> should.be_true
}

// ============================================================================
// Effect Variant Tests
// ============================================================================

pub fn exercise_effect_all_variants_compile_test() {
  // This test verifies all ExerciseEffect variants can be constructed

  let _effects = [
    exercise_view.NoEffect,
    exercise_view.FetchEntries(20_000),
    exercise_view.SearchExercises("running"),
  ]

  // If we reach here, all variants compile
  True
  |> should.be_true
}
