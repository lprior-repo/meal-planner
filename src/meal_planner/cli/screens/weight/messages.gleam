/// Weight Screen Messages - MVC Architecture
///
/// This module contains all message types for the weight tracking screen.
/// Following the Model-View-Controller pattern, these are the messages
/// that flow through the update function.
///
/// MESSAGES:
/// - WeightMsg: All user actions and events
/// - WeightEffect: Side effects to be executed
import meal_planner/cli/screens/weight/model.{
  type Gender, type UserProfile, type WeightGoalType, type WeightGoals,
}
import meal_planner/fatsecret/weight/types as weight_types

// ============================================================================
// Messages
// ============================================================================

/// Messages for the weight screen
pub type WeightMsg {
  // Navigation
  ShowListView
  ShowAddEntry
  ShowEditEntry(entry: weight_types.WeightEntry)
  ShowDeleteConfirm(entry_id: weight_types.WeightEntryId)
  ShowGoals
  ShowStats
  ShowChart
  ShowProfile
  ShowDatePicker
  GoBack
  // Entry Input
  WeightInputChanged(weight: String)
  CommentInputChanged(comment: String)
  DateInputChanged(date: String)
  ConfirmAddEntry
  CancelAddEntry
  // Edit Entry
  EditWeightChanged(weight: String)
  EditCommentChanged(comment: String)
  ConfirmEditEntry
  CancelEditEntry
  // Delete Entry
  ConfirmDelete
  CancelDelete
  // Goals
  SetTargetWeight(weight: Float)
  SetWeeklyTarget(change: Float)
  SetGoalType(goal_type: WeightGoalType)
  SaveGoals
  // Profile
  SetHeight(height_cm: Float)
  SetGender(gender: Gender)
  SaveProfile
  // Data Loading
  GotEntries(Result(List(weight_types.WeightEntry), String))
  GotGoals(Result(WeightGoals, String))
  EntryCreated(Result(weight_types.WeightEntryId, String))
  EntryUpdated(Result(Nil, String))
  EntryDeleted(Result(Nil, String))
  // UI
  DatePrevious
  DateNext
  DateToday
  DateConfirm(date: String)
  DateCancel
  ClearError
  KeyPressed(key: String)
  Refresh
  NoOp
}

// ============================================================================
// Effects
// ============================================================================

/// Effects for the weight screen
pub type WeightEffect {
  NoEffect
  FetchEntries(limit: Int)
  FetchGoals
  CreateEntry(weight_kg: Float, date_int: Int, comment: String)
  UpdateEntry(
    entry_id: weight_types.WeightEntryId,
    weight_kg: Float,
    comment: String,
  )
  DeleteEntry(entry_id: weight_types.WeightEntryId)
  SaveGoalsEffect(goals: WeightGoals)
  SaveProfileEffect(profile: UserProfile)
  BatchEffects(effects: List(WeightEffect))
}
