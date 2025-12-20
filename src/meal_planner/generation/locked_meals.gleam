//// Locked Meal Handling and Validation
////
//// This module provides functionality for applying locked meals to a generated
//// meal plan and validating for conflicts (multiple locks for the same day/meal slot).
////
//// Core functionality:
//// - apply_locked_meals: Replace meals in a plan with locked recipes
//// - check_lock_conflicts: Validate no duplicate locks for same day/meal

import gleam/list
import gleam/result
import meal_planner/generator/weekly.{
  type Constraints, type DayMeals, type MealType, Breakfast, Dinner, Lunch,
}
import meal_planner/types.{type Recipe}

// ============================================================================
// Types
// ============================================================================

/// Error type representing a conflict between two locked meals
pub type LockConflict {
  LockConflict(day: String, meal_type: MealType)
}

// ============================================================================
// Public Functions
// ============================================================================

/// Check if constraints have conflicting locked meals
///
/// Returns Error(LockConflict) if two locks target the same day/meal slot.
/// Returns Ok(Nil) if no conflicts exist.
pub fn check_lock_conflicts(
  constraints: Constraints,
) -> Result(Nil, LockConflict) {
  // Group locks by day and meal_type, looking for duplicates
  let locks = constraints.locked_meals

  // Check each lock against all subsequent locks
  check_locks_recursive(locks, [])
}

/// Recursively check locks for conflicts
fn check_locks_recursive(
  remaining: List(weekly.LockedMeal),
  checked: List(weekly.LockedMeal),
) -> Result(Nil, LockConflict) {
  case remaining {
    [] -> Ok(Nil)
    [current, ..rest] -> {
      // Check if current conflicts with any already checked
      let conflict =
        list.find(checked, fn(lock) {
          lock.day == current.day && lock.meal_type == current.meal_type
        })

      case conflict {
        Ok(_) ->
          Error(LockConflict(day: current.day, meal_type: current.meal_type))
        Error(_) -> check_locks_recursive(rest, [current, ..checked])
      }
    }
  }
}

/// Apply locked meals to a generated plan
///
/// For each locked meal, find the corresponding day in the plan and replace
/// the appropriate meal (breakfast/lunch/dinner) with the locked recipe.
///
/// Returns Error(LockConflict) if there are conflicting locks.
/// Returns Ok(updated_plan) with locked meals applied.
pub fn apply_locked_meals(
  plan: List(DayMeals),
  constraints: Constraints,
) -> Result(List(DayMeals), LockConflict) {
  // First validate no conflicts
  use _ <- result.try(check_lock_conflicts(constraints))

  // Apply each lock to the plan
  let updated_plan =
    list.map(plan, fn(day_meals) {
      apply_locks_to_day(day_meals, constraints.locked_meals)
    })

  Ok(updated_plan)
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Apply all relevant locks to a single day's meals
fn apply_locks_to_day(
  day_meals: DayMeals,
  locks: List(weekly.LockedMeal),
) -> DayMeals {
  // Find locks that apply to this day
  let breakfast_lock = find_lock(locks, day_meals.day, Breakfast)
  let lunch_lock = find_lock(locks, day_meals.day, Lunch)
  let dinner_lock = find_lock(locks, day_meals.day, Dinner)

  // Replace meals with locked recipes where applicable
  weekly.DayMeals(
    day: day_meals.day,
    breakfast: case breakfast_lock {
      Ok(recipe) -> recipe
      Error(_) -> day_meals.breakfast
    },
    lunch: case lunch_lock {
      Ok(recipe) -> recipe
      Error(_) -> day_meals.lunch
    },
    dinner: case dinner_lock {
      Ok(recipe) -> recipe
      Error(_) -> day_meals.dinner
    },
  )
}

/// Find a locked meal for a specific day and meal type
fn find_lock(
  locks: List(weekly.LockedMeal),
  day: String,
  meal_type: MealType,
) -> Result(Recipe, Nil) {
  locks
  |> list.find(fn(lock) { lock.day == day && lock.meal_type == meal_type })
  |> result.map(fn(lock) { lock.recipe })
}
