/// Exercise Screen Module
///
/// This module provides the exercise tracking screen for the CLI application.
/// It follows the Model-View-Update (MVU) architecture pattern.
///
/// # Module Structure
///
/// - `model`: State types and initialization
/// - `messages`: Message and effect types
/// - `update`: State transition logic
/// - `view`: UI rendering
/// - `helpers`: Utility functions
///
/// # Public API
///
/// The main exports are:
/// - `init/1`: Create initial model
/// - `exercise_update/2`: Handle state transitions
/// - `exercise_view/1`: Render UI
///
/// # Example
///
/// ```gleam
/// import meal_planner/cli/screens/exercise/mod as exercise
///
/// let model = exercise.init(today_date_int)
/// let #(new_model, effect) = exercise.exercise_update(model, msg)
/// let view = exercise.exercise_view(model)
/// ```
import meal_planner/cli/screens/exercise/messages
import meal_planner/cli/screens/exercise/model
import meal_planner/cli/screens/exercise/update
import meal_planner/cli/screens/exercise/view

// Re-export model types and functions

pub type ExerciseModel =
  model.ExerciseModel

pub type ExerciseViewState =
  model.ExerciseViewState

pub type ExerciseSearchState =
  model.ExerciseSearchState

pub type ExerciseSearchResult =
  model.ExerciseSearchResult

pub type ExerciseEditState =
  model.ExerciseEditState

pub type ExerciseDisplayEntry =
  model.ExerciseDisplayEntry

pub type DailySummary =
  model.DailySummary

pub type CachedExercise =
  model.CachedExercise

pub type ExerciseEntryInput =
  model.ExerciseEntryInput

pub type ExerciseEntryUpdate =
  model.ExerciseEntryUpdate

// Re-export message types
pub type ExerciseMsg =
  messages.ExerciseMsg

pub type ExerciseEffect =
  messages.ExerciseEffect

// Re-export main functions

pub const init = model.init

pub const exercise_update = update.exercise_update

pub const exercise_view = view.exercise_view
