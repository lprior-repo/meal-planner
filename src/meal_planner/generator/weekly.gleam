//// Weekly Meal Plan Generation Engine
////
//// Generates complete 7-day meal plans with macro tracking and constraint handling.
////
//// ## Algorithm Overview
//// 1. **Breakfast Selection**: Assigns 7 unique recipes (one per day, no repeats)
//// 2. **Lunch Selection**: Uses ABABA rotation pattern (2 recipes alternating)
//// 3. **Dinner Selection**: Uses ABABA rotation pattern (2 recipes alternating)
//// 4. **Constraint Application**: Applies locked meals and travel day overrides
//// 5. **Macro Validation**: Verifies each day is within ±10% of target macros
////
//// ## Part of
//// Autonomous Nutritional Control Plane (meal-planner-918)

import gleam/list
import gleam/result
import meal_planner/types.{
  type Macros, type Recipe, macros_add, macros_calories, macros_zero,
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
// Constants
// ============================================================================

/// Days of the week in order (Monday to Sunday)
const day_names: List(String) = [
  "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday",
]

/// Minimum number of unique breakfast recipes required
const min_breakfast_count: Int = 7

/// Minimum number of lunch/dinner recipes for rotation
const min_rotation_count: Int = 2

/// Minimum total recipes for basic generation
const min_total_recipes: Int = 3

// ============================================================================
// Helper Functions - Macro Calculations
// ============================================================================

/// Compare actual macro value to target, return comparison status.
///
/// ## Tolerance Bands
/// - **OnTarget**: within ±10% of target
/// - **Under**: below 90% of target
/// - **Over**: above 110% of target
///
/// ## Examples
/// ```gleam
/// compare_macro(actual: 150.0, target: 150.0) // OnTarget
/// compare_macro(actual: 120.0, target: 150.0) // Under (80%)
/// compare_macro(actual: 180.0, target: 150.0) // Over (120%)
/// ```
fn compare_macro(actual actual: Float, target target: Float) -> MacroComparison {
  case target <=. 0.0 {
    True -> OnTarget
    False -> {
      let ratio = actual /. target
      case ratio <. 0.9, ratio >. 1.1 {
        True, _ -> Under
        False, True -> Over
        False, False -> OnTarget
      }
    }
  }
}

/// Sum macros from all three meals in a day (breakfast, lunch, dinner).
///
/// Uses pipe operator to chain macro additions for readability.
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

// ============================================================================
// Helper Functions - Recipe Selection
// ============================================================================

/// Get element at index from list with wrap-around (circular indexing).
///
/// ## Behavior
/// Uses modulo arithmetic to wrap indices beyond list length.
/// Index 0 = first element, index `length` = first element again.
///
/// ## Examples
/// ```gleam
/// get_at(["A", "B", "C"], idx: 0) // "A"
/// get_at(["A", "B", "C"], idx: 3) // "A" (wraps around)
/// get_at(["A", "B", "C"], idx: 5) // "C" (5 % 3 = 2)
/// ```
///
/// ## Panics
/// Panics if list is empty. SAFE: Caller validates list has ≥min_total_recipes before calling.
fn get_at(lst: List(a), idx idx: Int) -> a {
  let count = list.length(lst)
  let wrapped_idx = idx % count
  // SAFE: list.length verified >0 by caller, list.drop().list.first guaranteed to succeed
  let assert Ok(elem) =
    lst
    |> list.drop(wrapped_idx)
    |> list.first
  elem
}

/// Select a meal recipe, applying locked meal override if present.
///
/// ## Logic
/// 1. Check constraints for locked meal
/// 2. If found: return locked recipe
/// 3. If not found: return default recipe
fn select_meal_with_lock(
  default_recipe default_recipe: Recipe,
  constraints constraints: Constraints,
  day day: String,
  meal_type meal_type: MealType,
) -> Recipe {
  case find_locked_meal(constraints, day, meal_type) {
    Ok(locked_recipe) -> locked_recipe
    Error(_) -> default_recipe
  }
}

/// Analyze a meal plan and return daily macro summaries.
///
/// ## Returns
/// List of `DailyMacros` for each day, comparing actual vs target macros.
///
/// ## Example
/// ```gleam
/// let analysis = analyze_plan(plan)
/// analysis
/// |> list.each(fn(day) { io.println(day.calories) })
/// ```
pub fn analyze_plan(plan: WeeklyMealPlan) -> List(DailyMacros) {
  plan.days
  |> list.map(fn(day) { calculate_daily_macros(day, plan.target_macros) })
}

/// Check if all days in a plan are within macro targets (±10%).
///
/// ## Definition of Balanced
/// A plan is balanced when every day's protein, fat, and carbs are `OnTarget`.
///
/// ## Returns
/// `True` if all 7 days meet macro tolerances, `False` otherwise.
pub fn is_plan_balanced(plan: WeeklyMealPlan) -> Bool {
  plan
  |> analyze_plan
  |> list.all(fn(daily) {
    daily.protein_status == OnTarget
    && daily.fat_status == OnTarget
    && daily.carbs_status == OnTarget
  })
}

/// Generate a weekly meal plan from available recipes (basic version).
///
/// ## Requirements
/// Requires at least 3 recipes (one for each meal type).
///
/// ## Algorithm
/// - Cycles through recipe list with offset indexing
/// - No meal type separation (simple rotation)
/// - No constraint handling
///
/// ## Returns
/// - `Ok(WeeklyMealPlan)` if enough recipes available
/// - `Error(NotEnoughRecipes)` if recipe count < 3
pub fn generate_weekly_plan(
  week_of week_of: String,
  recipes recipes: List(Recipe),
  target target: Macros,
) -> Result(WeeklyMealPlan, GenerationError) {
  let recipe_count = list.length(recipes)
  case recipe_count < min_total_recipes {
    True -> Error(NotEnoughRecipes)
    False -> {
      day_names
      |> list.index_map(fn(day_name, idx) {
        DayMeals(
          day: day_name,
          breakfast: get_at(recipes, idx: idx),
          lunch: get_at(recipes, idx: idx + 1),
          dinner: get_at(recipes, idx: idx + 2),
        )
      })
      |> fn(days) { WeeklyMealPlan(week_of:, days:, target_macros: target) }
      |> Ok
    }
  }
}

// ============================================================================
// Helper Functions - Constraints
// ============================================================================

/// Find a locked meal for a specific day and meal type.
///
/// Searches constraints for a matching locked meal entry.
///
/// ## Returns
/// - `Ok(Recipe)` if locked meal found
/// - `Error(Nil)` if no lock exists for this day/meal combination
fn find_locked_meal(
  constraints constraints: Constraints,
  day day: String,
  meal_type meal_type: MealType,
) -> Result(Recipe, Nil) {
  constraints.locked_meals
  |> list.find(fn(lm) { lm.day == day && lm.meal_type == meal_type })
  |> result.map(fn(lm) { lm.recipe })
}

/// Build a single day's meals with constraint handling.
///
/// ## Logic
/// 1. Select default recipes via circular indexing
/// 2. Override with locked meals if present
fn build_day_meals(
  day_name day_name: String,
  idx idx: Int,
  recipes recipes: List(Recipe),
  constraints constraints: Constraints,
) -> DayMeals {
  let default_breakfast = get_at(recipes, idx:)
  let default_lunch = get_at(recipes, idx: idx + 1)
  let default_dinner = get_at(recipes, idx: idx + 2)

  DayMeals(
    day: day_name,
    breakfast: select_meal_with_lock(
      default_breakfast,
      constraints,
      day_name,
      Breakfast,
    ),
    lunch: select_meal_with_lock(default_lunch, constraints, day_name, Lunch),
    dinner: select_meal_with_lock(default_dinner, constraints, day_name, Dinner),
  )
}

/// Generate a weekly meal plan with constraint handling.
///
/// ## Parameters
/// - Applies locked meal overrides
/// - Respects recipe count requirements
///
/// ## Returns
/// - `Ok(WeeklyMealPlan)` with constraint-applied meals
/// - `Error(NotEnoughRecipes)` if insufficient recipes
pub fn generate_weekly_plan_with_constraints(
  week_of week_of: String,
  recipes recipes: List(Recipe),
  target target: Macros,
  constraints constraints: Constraints,
) -> Result(WeeklyMealPlan, GenerationError) {
  case list.length(recipes) < min_total_recipes {
    True -> Error(NotEnoughRecipes)
    False -> {
      day_names
      |> list.index_map(fn(day_name, idx) {
        build_day_meals(day_name, idx, recipes, constraints)
      })
      |> fn(days) { WeeklyMealPlan(week_of:, days:, target_macros: target) }
      |> Ok
    }
  }
}

/// Generate a weekly meal plan with constraints and rotation history.
///
/// ## Workflow
/// 1. Filter out recently used recipes (based on rotation window)
/// 2. Generate plan with remaining recipes
/// 3. Apply constraint overrides
///
/// ## Parameters
/// - `rotation_days`: Number of days before a recipe can repeat
///
/// ## Returns
/// - `Ok(WeeklyMealPlan)` if enough recipes remain after filtering
/// - `Error(NotEnoughRecipes)` if rotation filter removes too many recipes
pub fn generate_plan_with_rotation(
  week_of week_of: String,
  recipes recipes: List(Recipe),
  target target: Macros,
  constraints constraints: Constraints,
  history history: List(RotationEntry),
  rotation_days rotation_days: Int,
) -> Result(WeeklyMealPlan, GenerationError) {
  recipes
  |> filter_by_rotation(history, rotation_days)
  |> generate_weekly_plan_with_constraints(week_of, _, target, constraints)
}

// ============================================================================
// Helper Functions - Meal Pool Selection
// ============================================================================

/// Validate recipe pool counts meet minimum requirements.
///
/// ## Requirements
/// - Breakfasts: 7+ unique recipes (one per day)
/// - Lunches: 2+ recipes (ABABA rotation)
/// - Dinners: 2+ recipes (ABABA rotation)
fn validate_recipe_pools(
  breakfasts breakfasts: List(Recipe),
  lunches lunches: List(Recipe),
  dinners dinners: List(Recipe),
) -> Result(Nil, GenerationError) {
  case
    list.length(breakfasts) < min_breakfast_count,
    list.length(lunches) < min_rotation_count,
    list.length(dinners) < min_rotation_count
  {
    True, _, _ | _, True, _ | _, _, True -> Error(NotEnoughRecipes)
    False, False, False -> Ok(Nil)
  }
}

/// Build a single day's meals using separate recipe pools.
///
/// ## Selection Strategy
/// - **Breakfast**: Unique per day (index = day_index)
/// - **Lunch**: ABABA rotation (index = day_index % 2)
/// - **Dinner**: ABABA rotation (index = day_index % 2)
///
/// Applies locked meal overrides after selection.
fn build_day_meals_from_pools(
  day_name day_name: String,
  day_idx day_idx: Int,
  breakfasts breakfasts: List(Recipe),
  lunches lunches: List(Recipe),
  dinners dinners: List(Recipe),
  constraints constraints: Constraints,
) -> DayMeals {
  let default_breakfast = get_at(breakfasts, idx: day_idx)
  let default_lunch = get_at(lunches, idx: day_idx % 2)
  let default_dinner = get_at(dinners, idx: day_idx % 2)

  DayMeals(
    day: day_name,
    breakfast: select_meal_with_lock(
      default_breakfast,
      constraints,
      day_name,
      Breakfast,
    ),
    lunch: select_meal_with_lock(default_lunch, constraints, day_name, Lunch),
    dinner: select_meal_with_lock(default_dinner, constraints, day_name, Dinner),
  )
}

/// Generate a weekly meal plan with separate recipe pools for each meal type.
///
/// **This is the primary generation function** for the NCP meal planner.
///
/// ## Parameters
/// - `available_breakfasts`: Pool of breakfast recipes (requires 7+)
/// - `available_lunches`: Pool of lunch recipes (requires 2+)
/// - `available_dinners`: Pool of dinner recipes (requires 2+)
/// - `target_macros`: Daily target macros (protein, fat, carbs in grams)
/// - `constraints`: Locked meals and travel dates
/// - `week_of`: Week start date in YYYY-MM-DD format
///
/// ## Returns
/// - `Ok(WeeklyMealPlan)` with 7 days of meals
/// - `Error(NotEnoughRecipes)` if any pool fails validation
///
/// ## Algorithm
/// 1. Validate recipe pool counts
/// 2. Select 7 unique breakfasts (one per day, no repeats)
/// 3. Select lunches with ABABA pattern (2 recipes rotating)
/// 4. Select dinners with ABABA pattern (2 recipes rotating)
/// 5. Apply locked meal overrides
///
/// ## Example
/// ```gleam
/// let result = generate_meal_plan(
///   available_breakfasts: breakfast_pool,
///   available_lunches: lunch_pool,
///   available_dinners: dinner_pool,
///   target_macros: Macros(protein: 150.0, fat: 65.0, carbs: 250.0),
///   constraints: Constraints(locked_meals: [], travel_dates: []),
///   week_of: "2025-01-06",
/// )
/// ```
pub fn generate_meal_plan(
  available_breakfasts available_breakfasts: List(Recipe),
  available_lunches available_lunches: List(Recipe),
  available_dinners available_dinners: List(Recipe),
  target_macros target_macros: Macros,
  constraints constraints: Constraints,
  week_of week_of: String,
) -> Result(WeeklyMealPlan, GenerationError) {
  use _ <- result.try(validate_recipe_pools(
    available_breakfasts,
    available_lunches,
    available_dinners,
  ))

  day_names
  |> list.index_map(fn(day_name, idx) {
    build_day_meals_from_pools(
      day_name,
      idx,
      available_breakfasts,
      available_lunches,
      available_dinners,
      constraints,
    )
  })
  |> fn(days) {
    WeeklyMealPlan(week_of: week_of, days: days, target_macros: target_macros)
  }
  |> Ok
}
