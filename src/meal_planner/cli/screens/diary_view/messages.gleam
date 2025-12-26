/// Diary View Messages - Message Types
///
/// This module re-exports message types from fatsecret_diary.gleam.
/// All message handling logic is centralized in the core type definitions.
import meal_planner/cli/screens/fatsecret_diary

// ============================================================================
// Re-exports
// ============================================================================

/// All possible messages/events in the Diary screen
pub type DiaryMsg =
  fatsecret_diary.DiaryMsg

/// Effects returned from update function
pub type DiaryEffect =
  fatsecret_diary.DiaryEffect
