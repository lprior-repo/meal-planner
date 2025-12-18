//// Weekly Meal Plan Generation Engine
////
//// Generates complete 7-day meal plans with macro tracking.
//// Part of the Autonomous Nutritional Control Plane (meal-planner-918).

import gleam/list
import meal_planner/types.{
  type Macros, type Recipe, Macros, macros_add, macros_calories, macros_zero,
}

// ============================================================================
// Core Types
// ============================================================================

/// Comparison status for macros vs target
pub type MacroComparison {
  /// Within ±10% of target
  OnTarget
  /// Below 90% of target
  Under
  /// Above 110% of target
  Over
}

/// A single day's meals (breakfast, lunch, dinner)
pub type DayMeals {
  DayMeals(day: String, breakfast: Recipe, lunch: Recipe, dinner: Recipe)
}

/// Daily macro totals with comparison to targets
pub type DailyMacros {
  DailyMacros(
    actual: Macros,
    calories: Float,
    protein_status: MacroComparison,
    fat_status: MacroComparison,
    carbs_status: MacroComparison,
  )
}

/// Complete 7-day meal plan
pub type WeeklyMealPlan {
  WeeklyMealPlan(week_of: String, days: List(DayMeals), target_macros: Macros)
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Compare actual value to target, return status
/// OnTarget: within ±10%, Under: <90%, Over: >110%
fn compare_macro(actual: Float, target: Float) -> MacroComparison {
  case target <=. 0.0 {
    True -> OnTarget
    False -> {
      let ratio = actual /. target
      case ratio <. 0.9 {
        True -> Under
        False ->
          case ratio >. 1.1 {
            True -> Over
            False -> OnTarget
          }
      }
    }
  }
}

/// Sum macros from all meals in a day
fn sum_day_macros(day: DayMeals) -> Macros {
  day.breakfast.macros
  |> macros_add(day.lunch.macros)
  |> macros_add(day.dinner.macros)
}

// ============================================================================
// Public Functions
// ============================================================================

/// Calculate daily macro totals and comparison status
pub fn calculate_daily_macros(day: DayMeals, target: Macros) -> DailyMacros {
  let actual = sum_day_macros(day)
  let calories = macros_calories(actual)

  DailyMacros(
    actual: actual,
    calories: calories,
    protein_status: compare_macro(actual.protein, target.protein),
    fat_status: compare_macro(actual.fat, target.fat),
    carbs_status: compare_macro(actual.carbs, target.carbs),
  )
}

/// Count the number of days in a meal plan
pub fn days_count(plan: WeeklyMealPlan) -> Int {
  list.length(plan.days)
}

/// Calculate total macros for the entire week
pub fn total_weekly_macros(plan: WeeklyMealPlan) -> Macros {
  plan.days
  |> list.map(sum_day_macros)
  |> list.fold(macros_zero(), macros_add)
}
