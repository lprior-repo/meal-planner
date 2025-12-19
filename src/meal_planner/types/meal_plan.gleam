//// Meal Plan Core Types
////
//// Defines the core types for the autonomous meal planning system.
////
//// This module provides opaque types for meal plans with:
//// - DailyMacros: Tracks actual macros vs target with status (OnTarget/Over/Under)
//// - DayMeals: A single day's meals (breakfast, lunch, dinner) with macro totals
//// - MealPlan: Complete 7-day meal plan with weekly macro tracking
////
//// ## Example
////
//// ```gleam
//// import meal_planner/types/meal_plan
//// import meal_planner/types/macros
////
//// let target = macros.new(protein: 150.0, fat: 60.0, carbs: 200.0)
//// let breakfast = // ... create MealPlanRecipe
//// let lunch = // ... create MealPlanRecipe
//// let dinner = // ... create MealPlanRecipe
////
//// // Create a day's meals
//// let day_result = meal_plan.new_day_meals(
////   day: "Monday",
////   breakfast: breakfast,
////   lunch: lunch,
////   dinner: dinner,
////   target_macros: target,
//// )
////
//// // Create a full week plan
//// let week_result = meal_plan.new_meal_plan(
////   week_of: "2025-01-01",
////   days: [monday, tuesday, ...],
////   target_macros: target,
//// )
//// ```
////
//// Part of NORTH STAR epic (meal-planner-918).

import gleam/dynamic/decode.{type Decoder}
import gleam/float
import gleam/json.{type Json}
import gleam/list
import meal_planner/types/macros.{
  type MacroComparison, type Macros, OnTarget, Over, Under,
}
import meal_planner/types/recipe.{type MealPlanRecipe}

// ============================================================================
// Core Types
// ============================================================================

/// Daily macro totals with comparison to targets.
///
/// Opaque type that tracks actual macros consumed vs target macros,
/// calculating status for each macro (protein, fat, carbs) to show
/// whether you're OnTarget, Over, or Under the goal.
///
/// Use `new_daily_macros()` to construct with automatic status calculation.
pub opaque type DailyMacros {
  DailyMacros(
    actual: Macros,
    calories: Float,
    protein_status: MacroComparison,
    fat_status: MacroComparison,
    carbs_status: MacroComparison,
  )
}

/// Constructor for DailyMacros with validation.
///
/// Creates a DailyMacros instance by comparing actual macros to target macros.
/// Automatically calculates calories and macro status (OnTarget/Over/Under).
///
/// ## Example
///
/// ```gleam
/// let target = macros.new(protein: 150.0, fat: 60.0, carbs: 200.0)
/// let actual = macros.new(protein: 145.0, fat: 58.0, carbs: 210.0)
///
/// let daily_result = new_daily_macros(actual, target)
/// // Returns DailyMacros with status for each macro
/// ```
pub fn new_daily_macros(
  actual: Macros,
  target: Macros,
) -> Result(DailyMacros, String) {
  let calories = macros.calories(actual)

  Ok(DailyMacros(
    actual: actual,
    calories: calories,
    protein_status: macros.compare_to_target(actual.protein, target.protein),
    fat_status: macros.compare_to_target(actual.fat, target.fat),
    carbs_status: macros.compare_to_target(actual.carbs, target.carbs),
  ))
}

/// Get the actual macros from a DailyMacros
pub fn daily_macros_actual(dm: DailyMacros) -> Macros {
  dm.actual
}

/// Get calories from DailyMacros
pub fn daily_macros_calories(dm: DailyMacros) -> Float {
  dm.calories
}

/// Get protein status from DailyMacros
pub fn daily_macros_protein_status(dm: DailyMacros) -> MacroComparison {
  dm.protein_status
}

/// Get fat status from DailyMacros
pub fn daily_macros_fat_status(dm: DailyMacros) -> MacroComparison {
  dm.fat_status
}

/// Get carbs status from DailyMacros
pub fn daily_macros_carbs_status(dm: DailyMacros) -> MacroComparison {
  dm.carbs_status
}

/// A single day's meals (breakfast, lunch, dinner).
///
/// Opaque type representing all meals for a single day with automatic
/// macro calculation and tracking. Validates that macros are calculated
/// correctly by summing all three meals and comparing to daily targets.
///
/// Use `new_day_meals()` to construct with automatic macro totaling.
pub opaque type DayMeals {
  DayMeals(
    day: String,
    breakfast: MealPlanRecipe,
    lunch: MealPlanRecipe,
    dinner: MealPlanRecipe,
    macros: DailyMacros,
  )
}

/// Constructor for DayMeals with validation.
///
/// Creates a DayMeals instance by combining breakfast, lunch, and dinner.
/// Automatically calculates total daily macros and compares to target.
///
/// ## Example
///
/// ```gleam
/// let target = macros.new(protein: 150.0, fat: 60.0, carbs: 200.0)
///
/// let day_result = new_day_meals(
///   day: "Monday",
///   breakfast: breakfast_recipe,
///   lunch: lunch_recipe,
///   dinner: dinner_recipe,
///   target_macros: target,
/// )
/// // Returns Result(DayMeals, String)
/// ```
pub fn new_day_meals(
  day day: String,
  breakfast breakfast: MealPlanRecipe,
  lunch lunch: MealPlanRecipe,
  dinner dinner: MealPlanRecipe,
  target_macros target_macros: Macros,
) -> Result(DayMeals, String) {
  // Calculate total macros for the day
  let total_macros =
    recipe.recipe_macros_per_serving(breakfast)
    |> macros.add(recipe.recipe_macros_per_serving(lunch))
    |> macros.add(recipe.recipe_macros_per_serving(dinner))

  // Calculate daily macro status
  use daily_macros <- result.try(new_daily_macros(total_macros, target_macros))

  Ok(DayMeals(
    day: day,
    breakfast: breakfast,
    lunch: lunch,
    dinner: dinner,
    macros: daily_macros,
  ))
}

/// Get the day name from DayMeals
pub fn day_meals_day(dm: DayMeals) -> String {
  dm.day
}

/// Get breakfast recipe from DayMeals
pub fn day_meals_breakfast(dm: DayMeals) -> MealPlanRecipe {
  dm.breakfast
}

/// Get lunch recipe from DayMeals
pub fn day_meals_lunch(dm: DayMeals) -> MealPlanRecipe {
  dm.lunch
}

/// Get dinner recipe from DayMeals
pub fn day_meals_dinner(dm: DayMeals) -> MealPlanRecipe {
  dm.dinner
}

/// Get daily macros from DayMeals
pub fn day_meals_macros(dm: DayMeals) -> DailyMacros {
  dm.macros
}

/// Complete 7-day meal plan with weekly macro tracking.
///
/// Opaque type representing a full week of meals (exactly 7 days).
/// Validates day count and automatically calculates weekly macro totals.
///
/// Use `new_meal_plan()` to construct with automatic validation.
pub opaque type MealPlan {
  MealPlan(
    week_of: String,
    days: List(DayMeals),
    target_macros: Macros,
    total_macros: Macros,
  )
}

/// Constructor for MealPlan with validation.
///
/// Creates a MealPlan instance from a list of DayMeals. Validates that
/// exactly 7 days are provided and calculates total weekly macros.
///
/// ## Example
///
/// ```gleam
/// let target = macros.new(protein: 150.0, fat: 60.0, carbs: 200.0)
/// let days = [monday, tuesday, wednesday, thursday, friday, saturday, sunday]
///
/// let plan_result = new_meal_plan(
///   week_of: "2025-01-06",
///   days: days,
///   target_macros: target,
/// )
///
/// case plan_result {
///   Ok(plan) -> // 7-day plan created successfully
///   Error(msg) -> // "MealPlan must have exactly 7 days, got N"
/// }
/// ```
pub fn new_meal_plan(
  week_of week_of: String,
  days days: List(DayMeals),
  target_macros target_macros: Macros,
) -> Result(MealPlan, String) {
  // Validate we have exactly 7 days
  case list.length(days) {
    7 -> {
      // Calculate total macros for the week
      let total_macros =
        days
        |> list.map(fn(day) { day.macros.actual })
        |> list.fold(macros.zero(), macros.add)

      Ok(MealPlan(
        week_of: week_of,
        days: days,
        target_macros: target_macros,
        total_macros: total_macros,
      ))
    }
    n -> Error("MealPlan must have exactly 7 days, got " <> int.to_string(n))
  }
}

/// Get week_of from MealPlan
pub fn meal_plan_week_of(plan: MealPlan) -> String {
  plan.week_of
}

/// Get days from MealPlan
pub fn meal_plan_days(plan: MealPlan) -> List(DayMeals) {
  plan.days
}

/// Get target macros from MealPlan
pub fn meal_plan_target_macros(plan: MealPlan) -> Macros {
  plan.target_macros
}

/// Get total macros from MealPlan
pub fn meal_plan_total_macros(plan: MealPlan) -> Macros {
  plan.total_macros
}

/// Calculate average daily macros for the week.
///
/// Divides total weekly macros by number of days (usually 7).
/// Useful for analyzing whether weekly nutrition is balanced.
///
/// ## Example
///
/// ```gleam
/// let avg = meal_plan_avg_daily_macros(plan)
/// // Returns Macros with average protein, fat, carbs per day
/// ```
pub fn meal_plan_avg_daily_macros(plan: MealPlan) -> Macros {
  let days_count = list.length(plan.days) |> int.to_float
  case days_count >. 0.0 {
    True -> macros.scale(plan.total_macros, 1.0 /. days_count)
    False -> macros.zero()
  }
}

// ============================================================================
// JSON Serialization
// ============================================================================

/// Encode DailyMacros to JSON
pub fn daily_macros_to_json(dm: DailyMacros) -> Json {
  json.object([
    #("actual", macros.to_json(dm.actual)),
    #("calories", json.float(dm.calories)),
    #("protein_status", macros.macro_comparison_to_json(dm.protein_status)),
    #("fat_status", macros.macro_comparison_to_json(dm.fat_status)),
    #("carbs_status", macros.macro_comparison_to_json(dm.carbs_status)),
  ])
}

/// Encode DayMeals to JSON
pub fn day_meals_to_json(dm: DayMeals) -> Json {
  json.object([
    #("day", json.string(dm.day)),
    #("breakfast", recipe.meal_plan_recipe_to_json(dm.breakfast)),
    #("lunch", recipe.meal_plan_recipe_to_json(dm.lunch)),
    #("dinner", recipe.meal_plan_recipe_to_json(dm.dinner)),
    #("macros", daily_macros_to_json(dm.macros)),
  ])
}

/// Encode MealPlan to JSON
pub fn meal_plan_to_json(plan: MealPlan) -> Json {
  json.object([
    #("week_of", json.string(plan.week_of)),
    #("days", json.array(plan.days, day_meals_to_json)),
    #("target_macros", macros.to_json(plan.target_macros)),
    #("total_macros", macros.to_json(plan.total_macros)),
  ])
}

// ============================================================================
// JSON Deserialization
// ============================================================================

/// Decode DailyMacros from JSON
pub fn daily_macros_decoder() -> Decoder(DailyMacros) {
  use actual <- decode.field("actual", macros.decoder())
  use calories <- decode.field("calories", decode.float)
  use protein_status <- decode.field(
    "protein_status",
    macros.macro_comparison_decoder(),
  )
  use fat_status <- decode.field(
    "fat_status",
    macros.macro_comparison_decoder(),
  )
  use carbs_status <- decode.field(
    "carbs_status",
    macros.macro_comparison_decoder(),
  )

  decode.success(DailyMacros(
    actual: actual,
    calories: calories,
    protein_status: protein_status,
    fat_status: fat_status,
    carbs_status: carbs_status,
  ))
}

/// Decode DayMeals from JSON
pub fn day_meals_decoder() -> Decoder(DayMeals) {
  use day <- decode.field("day", decode.string)
  use breakfast <- decode.field("breakfast", recipe.meal_plan_recipe_decoder())
  use lunch <- decode.field("lunch", recipe.meal_plan_recipe_decoder())
  use dinner <- decode.field("dinner", recipe.meal_plan_recipe_decoder())
  use macros <- decode.field("macros", daily_macros_decoder())

  decode.success(DayMeals(
    day: day,
    breakfast: breakfast,
    lunch: lunch,
    dinner: dinner,
    macros: macros,
  ))
}

/// Decode MealPlan from JSON
pub fn meal_plan_decoder() -> Decoder(MealPlan) {
  use week_of <- decode.field("week_of", decode.string)
  use days <- decode.field("days", decode.list(day_meals_decoder()))
  use target_macros <- decode.field("target_macros", macros.decoder())
  use total_macros <- decode.field("total_macros", macros.decoder())

  decode.success(MealPlan(
    week_of: week_of,
    days: days,
    target_macros: target_macros,
    total_macros: total_macros,
  ))
}

// ============================================================================
// Display Formatting
// ============================================================================

/// Format DailyMacros as readable string
pub fn daily_macros_to_string(dm: DailyMacros) -> String {
  "Calories: "
  <> float.to_string(dm.calories)
  <> " | Protein: "
  <> macros.macro_comparison_to_string(dm.protein_status)
  <> " | Fat: "
  <> macros.macro_comparison_to_string(dm.fat_status)
  <> " | Carbs: "
  <> macros.macro_comparison_to_string(dm.carbs_status)
}

import gleam/int
import gleam/result
