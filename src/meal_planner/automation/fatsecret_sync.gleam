/// FatSecret Sync Automation - Diary to Meal Plan Matching
///
/// Matches FatSecret diary entries to Tandoor meal plans based on:
/// - Nutrition profile similarity
/// - Name matching
/// - Meal type alignment
import gleam/float
import gleam/list
import gleam/option.{type Option, None}
import gleam/result
import gleam/string
import meal_planner/fatsecret/diary/types.{
  type FoodEntry, type MealType, Breakfast, Dinner, Lunch, Snack,
}
import meal_planner/tandoor/mealplan.{type MealPlan}

pub type SyncResult {
  SyncResult(
    matched: List(MatchedEntry),
    unmatched_diary: List(FoodEntry),
    unmatched_plan: List(MealPlan),
  )
}

pub type MatchedEntry {
  MatchedEntry(diary_entry: FoodEntry, plan_entry: MealPlan, confidence: Float)
}

pub type MatchCriteria {
  MatchCriteria(
    calorie_tolerance: Float,
    macro_tolerance: Float,
    name_similarity_threshold: Float,
  )
}

pub fn default_criteria() -> MatchCriteria {
  MatchCriteria(
    calorie_tolerance: 0.15,
    macro_tolerance: 0.2,
    name_similarity_threshold: 0.6,
  )
}

pub fn sync_diary_to_plan(
  diary_entries: List(FoodEntry),
  meal_plans: List(MealPlan),
  _criteria: MatchCriteria,
) -> SyncResult {
  // Minimal implementation - no matching logic yet
  SyncResult(
    matched: [],
    unmatched_diary: diary_entries,
    unmatched_plan: meal_plans,
  )
}

pub fn calculate_match_confidence(
  _diary_entry: FoodEntry,
  _meal_plan: MealPlan,
  _criteria: MatchCriteria,
) -> Float {
  0.0
}
