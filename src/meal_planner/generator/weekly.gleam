//// Weekly Meal Plan Generation Engine
////
//// Generates complete 7-day meal plans with macro tracking.
//// Part of the Autonomous Nutritional Control Plane (meal-planner-918).

import gleam/list
import gleam/result
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

/// Errors that can occur during meal plan generation
pub type GenerationError {
  /// Not enough recipes to fill all meals
  NotEnoughRecipes
}

/// Meal type for locked meals
pub type MealType {
  Breakfast
  Lunch
  Dinner
}

/// A locked meal constraint
pub type LockedMeal {
  LockedMeal(day: String, meal_type: MealType, recipe: Recipe)
}

/// Constraints for meal plan generation
pub type Constraints {
  Constraints(locked_meals: List(LockedMeal), travel_dates: List(String))
}

/// Rotation history entry tracking recipe usage
pub type RotationEntry {
  RotationEntry(recipe_name: String, days_ago: Int)
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

/// Check if a day is a travel day
pub fn is_travel_day(day: String, constraints: Constraints) -> Bool {
  list.contains(constraints.travel_dates, day)
}

/// Filter recipes by rotation history
/// Excludes recipes used within the rotation_days window
pub fn filter_by_rotation(
  recipes: List(Recipe),
  history: List(RotationEntry),
  rotation_days: Int,
) -> List(Recipe) {
  recipes
  |> list.filter(fn(recipe) {
    // Check if this recipe is in the recent history
    let recent_use =
      history
      |> list.find(fn(entry) {
        entry.recipe_name == recipe.name && entry.days_ago < rotation_days
      })
    // Keep recipe only if NOT found in recent history
    case recent_use {
      Ok(_) -> False
      Error(_) -> True
    }
  })
}

/// Get element at index from list (wrapping around if needed)
fn get_at(lst: List(a), idx: Int) -> a {
  let count = list.length(lst)
  let wrapped_idx = idx % count
  let assert Ok(elem) =
    lst
    |> list.drop(wrapped_idx)
    |> list.first
  elem
}

/// Analyze a meal plan and return daily macro summaries
pub fn analyze_plan(plan: WeeklyMealPlan) -> List(DailyMacros) {
  plan.days
  |> list.map(fn(day) { calculate_daily_macros(day, plan.target_macros) })
}

/// Check if all days in a plan are within macro targets (±10%)
pub fn is_plan_balanced(plan: WeeklyMealPlan) -> Bool {
  let analysis = analyze_plan(plan)
  list.all(analysis, fn(daily) {
    daily.protein_status == OnTarget
    && daily.fat_status == OnTarget
    && daily.carbs_status == OnTarget
  })
}

/// Generate a weekly meal plan from available recipes
/// Requires at least 3 recipes (one for each meal type)
pub fn generate_weekly_plan(
  week_of: String,
  recipes: List(Recipe),
  target: Macros,
) -> Result(WeeklyMealPlan, GenerationError) {
  let recipe_count = list.length(recipes)
  case recipe_count < 3 {
    True -> Error(NotEnoughRecipes)
    False -> {
      let day_names = [
        "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday",
        "Sunday",
      ]
      let days =
        day_names
        |> list.index_map(fn(day_name, idx) {
          // Cycle through recipes for variety
          let breakfast = get_at(recipes, idx)
          let lunch = get_at(recipes, idx + 1)
          let dinner = get_at(recipes, idx + 2)
          DayMeals(
            day: day_name,
            breakfast: breakfast,
            lunch: lunch,
            dinner: dinner,
          )
        })
      Ok(WeeklyMealPlan(week_of: week_of, days: days, target_macros: target))
    }
  }
}

/// Find a locked meal for a specific day and meal type
fn find_locked_meal(
  constraints: Constraints,
  day: String,
  meal_type: MealType,
) -> Result(Recipe, Nil) {
  constraints.locked_meals
  |> list.find(fn(lm) { lm.day == day && lm.meal_type == meal_type })
  |> result.map(fn(lm) { lm.recipe })
}

/// Generate a weekly meal plan with constraints
pub fn generate_weekly_plan_with_constraints(
  week_of: String,
  recipes: List(Recipe),
  target: Macros,
  constraints: Constraints,
) -> Result(WeeklyMealPlan, GenerationError) {
  let recipe_count = list.length(recipes)
  case recipe_count < 3 {
    True -> Error(NotEnoughRecipes)
    False -> {
      let day_names = [
        "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday",
        "Sunday",
      ]
      let days =
        day_names
        |> list.index_map(fn(day_name, idx) {
          // Check for locked meals, otherwise use default
          let breakfast = case
            find_locked_meal(constraints, day_name, Breakfast)
          {
            Ok(recipe) -> recipe
            Error(_) -> get_at(recipes, idx)
          }
          let lunch = case find_locked_meal(constraints, day_name, Lunch) {
            Ok(recipe) -> recipe
            Error(_) -> get_at(recipes, idx + 1)
          }
          let dinner = case find_locked_meal(constraints, day_name, Dinner) {
            Ok(recipe) -> recipe
            Error(_) -> get_at(recipes, idx + 2)
          }
          DayMeals(
            day: day_name,
            breakfast: breakfast,
            lunch: lunch,
            dinner: dinner,
          )
        })
      Ok(WeeklyMealPlan(week_of: week_of, days: days, target_macros: target))
    }
  }
}

/// Generate a weekly meal plan with constraints and rotation history
/// Filters out recently used recipes before generating
pub fn generate_plan_with_rotation(
  week_of: String,
  recipes: List(Recipe),
  target: Macros,
  constraints: Constraints,
  history: List(RotationEntry),
  rotation_days: Int,
) -> Result(WeeklyMealPlan, GenerationError) {
  // Filter out recently used recipes
  let available_recipes = filter_by_rotation(recipes, history, rotation_days)
  // Generate plan with filtered recipes
  generate_weekly_plan_with_constraints(
    week_of,
    available_recipes,
    target,
    constraints,
  )
}
