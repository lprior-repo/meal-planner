/// Exercise View Model
///
/// Contains all state types for the exercise tracking screen.
import gleam/dict.{type Dict}
import gleam/option.{type Option}
import meal_planner/fatsecret/exercise/types as exercise_types

// ============================================================================
// Model Types
// ============================================================================

/// Root state for the Exercise TUI screen
pub type ExerciseModel {
  ExerciseModel(
    /// Current date being viewed (days since Unix epoch)
    current_date: Int,
    /// Exercise entries for current date
    entries: List(ExerciseDisplayEntry),
    /// Current UI view mode
    view_state: ExerciseViewState,
    /// Search state for adding exercises
    search_state: ExerciseSearchState,
    /// Edit state for modifying entries
    edit_state: Option(ExerciseEditState),
    /// Current error message
    error_message: Option(String),
    /// Loading state
    is_loading: Bool,
    /// Daily summary stats
    daily_summary: DailySummary,
    /// Recently used exercises (for quick add)
    recent_exercises: List(exercise_types.ExerciseEntry),
    /// Cache for exercise details
    exercise_cache: Dict(String, CachedExercise),
  )
}

/// UI view state machine
pub type ExerciseViewState {
  /// Normal exercise list view
  MainView
  /// Search popup for adding exercise
  SearchPopup
  /// Date picker modal
  DatePicker(date_input: String)
  /// Confirmation dialog for deletion
  ConfirmDelete(entry_id: exercise_types.ExerciseEntryId)
  /// Edit dialog for modifying entry
  EditEntry(edit_state: ExerciseEditState)
  /// Quick add from recent exercises
  QuickAddPopup
  /// Exercise details view
  DetailsView(entry: exercise_types.ExerciseEntry)
}

/// Search state for exercise search popup
pub type ExerciseSearchState {
  ExerciseSearchState(
    /// Current search query
    query: String,
    /// Search results
    results: List(ExerciseSearchResult),
    /// Currently selected index
    selected_index: Int,
    /// Loading state
    is_loading: Bool,
    /// Error message
    error: Option(String),
  )
}

/// Exercise search result
pub type ExerciseSearchResult {
  ExerciseSearchResult(
    exercise_id: String,
    exercise_name: String,
    calories_per_hour: Float,
    exercise_type: String,
  )
}

/// Edit state for modifying exercise entry
pub type ExerciseEditState {
  ExerciseEditState(
    /// Entry being edited
    entry: exercise_types.ExerciseEntry,
    /// New duration in minutes
    new_duration: Int,
    /// New calories burned
    new_calories: Float,
    /// Original duration for cancel
    original_duration: Int,
    /// Original calories for cancel
    original_calories: Float,
  )
}

/// Display entry with formatted strings
pub type ExerciseDisplayEntry {
  ExerciseDisplayEntry(
    /// Original entry
    entry: exercise_types.ExerciseEntry,
    /// Formatted name display
    name_display: String,
    /// Formatted duration display
    duration_display: String,
    /// Formatted calories display
    calories_display: String,
    /// Full summary line
    summary_line: String,
  )
}

/// Daily exercise summary
pub type DailySummary {
  DailySummary(
    /// Total calories burned
    total_calories: Float,
    /// Total exercise duration in minutes
    total_duration: Int,
    /// Number of exercise sessions
    session_count: Int,
    /// Average calories per session
    avg_calories_per_session: Float,
  )
}

/// Cached exercise data
pub type CachedExercise {
  CachedExercise(exercise: ExerciseSearchResult, cached_at: Int)
}

/// Input for creating exercise entry
pub type ExerciseEntryInput {
  ExerciseEntryInput(
    exercise_id: String,
    exercise_name: String,
    duration_min: Int,
    calories: Float,
    date_int: Int,
  )
}

/// Update for modifying exercise entry
pub type ExerciseEntryUpdate {
  ExerciseEntryUpdate(duration_min: Option(Int), calories: Option(Float))
}

// ============================================================================
// Initialization
// ============================================================================

/// Create initial ExerciseModel for today's date
pub fn init(today_date_int: Int) -> ExerciseModel {
  ExerciseModel(
    current_date: today_date_int,
    entries: [],
    view_state: MainView,
    search_state: ExerciseSearchState(
      query: "",
      results: [],
      selected_index: 0,
      is_loading: False,
      error: option.None,
    ),
    edit_state: option.None,
    error_message: option.None,
    is_loading: False,
    daily_summary: DailySummary(
      total_calories: 0.0,
      total_duration: 0,
      session_count: 0,
      avg_calories_per_session: 0.0,
    ),
    recent_exercises: [],
    exercise_cache: dict.new(),
  )
}
