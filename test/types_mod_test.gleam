// Test to verify types/mod.gleam successfully aggregates all type exports

import gleam/option.{None}
import meal_planner/id
import meal_planner/types.{
  type ActivityLevel, type Cursor, type CustomFood, type DailyLog,
  type DailyMacros, type DayMeals, type FoodLogEntry, type FoodSource, type Goal,
  type GroceryItem, type GroceryList, type Macros, type MealPlan, type PageInfo,
  type PaginationParams, type UserProfile, Breakfast, Dinner, Gain, Lunch,
  Sedentary, Snack, add, calories, daily_macro_targets, daily_macros_actual,
  day_meals_breakfast, meal_plan_days, new_daily_macros, new_day_meals,
  new_meal_plan, new_user_profile, protein_ratio, zero,
}

pub fn test_macros_import() -> Macros {
  Macros(protein: 30.0, fat: 15.0, carbs: 45.0)
}

pub fn test_macros_operations() -> Float {
  let m = test_macros_import()
  calories(m)
}

pub fn test_user_profile_creation() {
  let user_id = id.user_id("test-user")
  case
    new_user_profile(
      id: user_id,
      bodyweight: 80.0,
      activity_level: Sedentary,
      goal: Gain,
      meals_per_day: 3,
      micronutrient_goals: None,
    )
  {
    Ok(_profile) -> "Profile created"
    Error(_) -> "Profile error"
  }
}

pub fn test_meal_type_import() {
  case Breakfast {
    Breakfast -> "breakfast"
    Lunch -> "lunch"
    Dinner -> "dinner"
    Snack -> "snack"
  }
}
