/// Exercise View Messages
///
/// Contains all message and effect types for the exercise screen.
import meal_planner/cli/screens/exercise/model.{
  type ExerciseEntryInput, type ExerciseEntryUpdate, type ExerciseSearchResult,
}
import meal_planner/fatsecret/exercise/types as exercise_types

// ============================================================================
// Messages
// ============================================================================

/// Messages for the exercise screen
pub type ExerciseMsg {
  // Date Navigation
  DatePrevious
  DateNext
  DateToday
  DateShowPicker
  DateConfirmPicker(date_input: String)
  DateCancelPicker

  // Add Exercise
  AddExerciseStart
  SearchQueryChanged(query: String)
  SearchStarted
  GotSearchResults(Result(List(ExerciseSearchResult), String))
  ExerciseSelected(result: ExerciseSearchResult)
  ConfirmAddExercise(duration: Int, calories: Float)
  CancelAddExercise

  // Quick Add
  QuickAddStart
  QuickAddSelect(entry: exercise_types.ExerciseEntry)
  QuickAddCancel

  // Edit Exercise
  EditExerciseStart(entry: exercise_types.ExerciseEntry)
  EditDurationChanged(duration: Int)
  EditCaloriesChanged(calories: Float)
  EditConfirm
  EditCancel

  // Delete Exercise
  DeleteExerciseStart(entry_id: exercise_types.ExerciseEntryId)
  DeleteConfirm
  DeleteCancel

  // View Details
  ViewDetails(entry: exercise_types.ExerciseEntry)
  CloseDetails

  // Server Responses
  GotDailyEntries(Result(List(exercise_types.ExerciseEntry), String))
  EntryCreated(Result(exercise_types.ExerciseEntryId, String))
  EntryUpdated(Result(Nil, String))
  EntryDeleted(Result(Nil, String))

  // UI
  ClearError
  KeyPressed(key: String)
  Refresh
  NoOp
}

// ============================================================================
// Effects
// ============================================================================

/// Effects for the exercise screen
pub type ExerciseEffect {
  NoEffect
  FetchEntries(date_int: Int)
  SearchExercises(query: String)
  CreateEntry(input: ExerciseEntryInput)
  UpdateEntry(
    entry_id: exercise_types.ExerciseEntryId,
    update: ExerciseEntryUpdate,
  )
  DeleteEntry(entry_id: exercise_types.ExerciseEntryId)
  BatchEffects(effects: List(ExerciseEffect))
}
