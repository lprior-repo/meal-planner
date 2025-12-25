//// Generation Engine Types
////
//// Type definitions for the weekly meal plan generation system.
//// Defines requests, results, preparation instructions, and macro summaries.

import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/list
import gleam/option.{None, Some}
import meal_planner/fatsecret/profile/types as fatsecret_profile
import meal_planner/generator/weekly
import meal_planner/grocery_list
import meal_planner/types/json as types_json
import meal_planner/types/macros

// ============================================================================
// Generation Request Types
// ============================================================================

/// Request for generating a weekly meal plan
///
/// Contains all the inputs needed to generate a complete 7-day plan
/// including user constraints, macro targets from FatSecret, and locked meals.
pub type GenerationRequest {
  GenerationRequest(
    /// ISO 8601 date of the week start (e.g., "2025-12-22")
    week_of: String,
    /// User ID for personalization
    user_id: String,
    /// Constraints for meal plan generation (locked meals, travel dates)
    constraints: weekly.Constraints,
    /// User's macro profile from FatSecret (optional goals and metrics)
    macro_profile: fatsecret_profile.Profile,
  )
}

// ============================================================================
// Generation Result Types
// ============================================================================

/// Complete result of meal plan generation
///
/// Contains everything needed for a week: meals, groceries, prep instructions,
/// and macro tracking summaries.
pub type GenerationResult {
  GenerationResult(
    /// The complete 7-day meal plan
    meal_plan: weekly.WeeklyMealPlan,
    /// Aggregated grocery list for the week
    grocery_list: grocery_list.GroceryList,
    /// Consolidated prep instructions for efficient batch cooking
    prep_instructions: List(PrepInstruction),
    /// Weekly macro summary with daily breakdowns
    macro_summary: WeeklyMacros,
  )
}

// ============================================================================
// Preparation Instruction Types
// ============================================================================

/// Preparation instructions for a recipe with batch sizing
///
/// Groups recipes that can be batch-cooked together and provides
/// step-by-step instructions with timing estimates.
pub type PrepInstruction {
  PrepInstruction(
    /// Recipe ID from Tandoor
    recipe_id: Int,
    /// Recipe name for display
    recipe_name: String,
    /// Ordered list of preparation steps
    steps: List(PrepStep),
    /// Total estimated time in minutes (prep + cook)
    total_time_minutes: Int,
    /// Number of servings to prepare (for consolidation)
    batch_size: Int,
  )
}

/// Individual preparation step with ingredients and timing
pub type PrepStep {
  PrepStep(
    /// Step number (1-indexed)
    sequence: Int,
    /// Step description/instruction
    description: String,
    /// Ingredients needed for this step
    ingredients: List(String),
    /// Estimated time for this step in minutes
    time_minutes: Int,
  )
}

// ============================================================================
// Weekly Macro Summary Types
// ============================================================================

/// Weekly macro summary with daily breakdowns
///
/// Provides both aggregate totals for the week and per-day analysis
/// to track adherence to macro targets.
pub type WeeklyMacros {
  WeeklyMacros(
    /// Total macros for the entire week
    weekly_total: macros.Macros,
    /// Average daily macros
    daily_average: macros.Macros,
    /// Daily macro breakdowns with comparison status
    daily_breakdowns: List(DailyMacroBreakdown),
  )
}

/// Daily macro breakdown with target comparison
pub type DailyMacroBreakdown {
  DailyMacroBreakdown(
    /// Day name (Monday, Tuesday, etc.)
    day: String,
    /// Actual macros for the day
    actual: macros.Macros,
    /// Daily target macros
    target: macros.Macros,
    /// Deviation from target (actual - target)
    deviation: macros.Macros,
    /// Total calories for the day
    calories: Float,
  )
}

// ============================================================================
// JSON Encoding
// ============================================================================

/// Encode GenerationRequest to JSON
pub fn generation_request_to_json(req: GenerationRequest) -> Json {
  json.object([
    #("week_of", json.string(req.week_of)),
    #("user_id", json.string(req.user_id)),
    #("constraints", constraints_to_json(req.constraints)),
    #("macro_profile", fatsecret_profile_to_json(req.macro_profile)),
  ])
}

/// Encode Constraints to JSON
fn constraints_to_json(c: weekly.Constraints) -> Json {
  json.object([
    #("locked_meals", json.array(c.locked_meals, locked_meal_to_json)),
    #("travel_dates", json.array(c.travel_dates, json.string)),
  ])
}

/// Encode LockedMeal to JSON
fn locked_meal_to_json(lm: weekly.LockedMeal) -> Json {
  json.object([
    #("day", json.string(lm.day)),
    #("meal_type", json.string(meal_type_to_string(lm.meal_type))),
    #("recipe", types.recipe_to_json(lm.recipe)),
  ])
}

/// Convert MealType to string
fn meal_type_to_string(mt: weekly.MealType) -> String {
  case mt {
    weekly.Breakfast -> "breakfast"
    weekly.Lunch -> "lunch"
    weekly.Dinner -> "dinner"
  }
}

/// Encode FatSecret Profile to JSON
fn fatsecret_profile_to_json(p: fatsecret_profile.Profile) -> Json {
  let optional_float = fn(opt) {
    case opt {
      Some(v) -> json.float(v)
      None -> json.null()
    }
  }
  let optional_int = fn(opt) {
    case opt {
      Some(v) -> json.int(v)
      None -> json.null()
    }
  }
  let optional_string = fn(opt) {
    case opt {
      Some(v) -> json.string(v)
      None -> json.null()
    }
  }

  json.object([
    #("goal_weight_kg", optional_float(p.goal_weight_kg)),
    #("last_weight_kg", optional_float(p.last_weight_kg)),
    #("last_weight_date_int", optional_int(p.last_weight_date_int)),
    #("last_weight_comment", optional_string(p.last_weight_comment)),
    #("height_cm", optional_float(p.height_cm)),
    #("calorie_goal", optional_int(p.calorie_goal)),
    #("weight_measure", optional_string(p.weight_measure)),
    #("height_measure", optional_string(p.height_measure)),
  ])
}

/// Encode GenerationResult to JSON
pub fn generation_result_to_json(result: GenerationResult) -> Json {
  json.object([
    #("meal_plan", weekly_meal_plan_to_json(result.meal_plan)),
    #("grocery_list", grocery_list_to_json(result.grocery_list)),
    #(
      "prep_instructions",
      json.array(result.prep_instructions, prep_instruction_to_json),
    ),
    #("macro_summary", weekly_macros_to_json(result.macro_summary)),
  ])
}

/// Encode WeeklyMealPlan to JSON
fn weekly_meal_plan_to_json(plan: weekly.WeeklyMealPlan) -> Json {
  json.object([
    #("week_of", json.string(plan.week_of)),
    #("days", json.array(plan.days, day_meals_to_json)),
    #("target_macros", types.macros_to_json(plan.target_macros)),
  ])
}

/// Encode DayMeals to JSON
fn day_meals_to_json(day: weekly.DayMeals) -> Json {
  json.object([
    #("day", json.string(day.day)),
    #("breakfast", types.recipe_to_json(day.breakfast)),
    #("lunch", types.recipe_to_json(day.lunch)),
    #("dinner", types.recipe_to_json(day.dinner)),
  ])
}

/// Encode GroceryList to JSON
fn grocery_list_to_json(list: grocery_list.GroceryList) -> Json {
  json.object([
    #("items", json.array(list.all_items, grocery_item_to_json)),
    #("total_items", json.int(list.all_items |> list.length)),
  ])
}

/// Encode GroceryItem to JSON
fn grocery_item_to_json(item: grocery_list.GroceryItem) -> Json {
  json.object([
    #("name", json.string(item.name)),
    #("quantity", json.float(item.quantity)),
    #("unit", json.string(item.unit)),
    #("category", json.string(item.category)),
  ])
}

/// Encode PrepInstruction to JSON
pub fn prep_instruction_to_json(prep: PrepInstruction) -> Json {
  json.object([
    #("recipe_id", json.int(prep.recipe_id)),
    #("recipe_name", json.string(prep.recipe_name)),
    #("steps", json.array(prep.steps, prep_step_to_json)),
    #("total_time_minutes", json.int(prep.total_time_minutes)),
    #("batch_size", json.int(prep.batch_size)),
  ])
}

/// Encode PrepStep to JSON
fn prep_step_to_json(step: PrepStep) -> Json {
  json.object([
    #("sequence", json.int(step.sequence)),
    #("description", json.string(step.description)),
    #("ingredients", json.array(step.ingredients, json.string)),
    #("time_minutes", json.int(step.time_minutes)),
  ])
}

/// Encode WeeklyMacros to JSON
pub fn weekly_macros_to_json(wm: WeeklyMacros) -> Json {
  json.object([
    #("weekly_total", types.macros_to_json(wm.weekly_total)),
    #("daily_average", types.macros_to_json(wm.daily_average)),
    #(
      "daily_breakdowns",
      json.array(wm.daily_breakdowns, daily_macro_breakdown_to_json),
    ),
  ])
}

/// Encode DailyMacroBreakdown to JSON
fn daily_macro_breakdown_to_json(dmb: DailyMacroBreakdown) -> Json {
  json.object([
    #("day", json.string(dmb.day)),
    #("actual", types.macros_to_json(dmb.actual)),
    #("target", types.macros_to_json(dmb.target)),
    #("deviation", types.macros_to_json(dmb.deviation)),
    #("calories", json.float(dmb.calories)),
  ])
}

// ============================================================================
// JSON Decoding
// ============================================================================

/// Decoder for GenerationRequest
pub fn generation_request_decoder() -> Decoder(GenerationRequest) {
  use week_of <- decode.field("week_of", decode.string)
  use user_id <- decode.field("user_id", decode.string)
  use constraints <- decode.field("constraints", constraints_decoder())
  use macro_profile <- decode.field(
    "macro_profile",
    fatsecret_profile_decoder(),
  )
  decode.success(GenerationRequest(
    week_of: week_of,
    user_id: user_id,
    constraints: constraints,
    macro_profile: macro_profile,
  ))
}

/// Decoder for Constraints
fn constraints_decoder() -> Decoder(weekly.Constraints) {
  use locked_meals <- decode.field(
    "locked_meals",
    decode.list(locked_meal_decoder()),
  )
  use travel_dates <- decode.field("travel_dates", decode.list(decode.string))
  decode.success(weekly.Constraints(
    locked_meals: locked_meals,
    travel_dates: travel_dates,
  ))
}

/// Decoder for LockedMeal
fn locked_meal_decoder() -> Decoder(weekly.LockedMeal) {
  use day <- decode.field("day", decode.string)
  use meal_type <- decode.field("meal_type", meal_type_decoder())
  use recipe <- decode.field("recipe", types.recipe_decoder())
  decode.success(weekly.LockedMeal(
    day: day,
    meal_type: meal_type,
    recipe: recipe,
  ))
}

/// Decoder for MealType
fn meal_type_decoder() -> Decoder(weekly.MealType) {
  use s <- decode.then(decode.string)
  case s {
    "breakfast" -> decode.success(weekly.Breakfast)
    "lunch" -> decode.success(weekly.Lunch)
    "dinner" -> decode.success(weekly.Dinner)
    _ -> decode.failure(weekly.Breakfast, "MealType")
  }
}

/// Decoder for FatSecret Profile
fn fatsecret_profile_decoder() -> Decoder(fatsecret_profile.Profile) {
  use goal_weight_kg <- decode.optional_field(
    "goal_weight_kg",
    None,
    decode.optional(decode.float),
  )
  use last_weight_kg <- decode.optional_field(
    "last_weight_kg",
    None,
    decode.optional(decode.float),
  )
  use last_weight_date_int <- decode.optional_field(
    "last_weight_date_int",
    None,
    decode.optional(decode.int),
  )
  use last_weight_comment <- decode.optional_field(
    "last_weight_comment",
    None,
    decode.optional(decode.string),
  )
  use height_cm <- decode.optional_field(
    "height_cm",
    None,
    decode.optional(decode.float),
  )
  use calorie_goal <- decode.optional_field(
    "calorie_goal",
    None,
    decode.optional(decode.int),
  )
  use weight_measure <- decode.optional_field(
    "weight_measure",
    None,
    decode.optional(decode.string),
  )
  use height_measure <- decode.optional_field(
    "height_measure",
    None,
    decode.optional(decode.string),
  )
  decode.success(fatsecret_profile.Profile(
    goal_weight_kg: goal_weight_kg,
    last_weight_kg: last_weight_kg,
    last_weight_date_int: last_weight_date_int,
    last_weight_comment: last_weight_comment,
    height_cm: height_cm,
    calorie_goal: calorie_goal,
    weight_measure: weight_measure,
    height_measure: height_measure,
  ))
}

/// Decoder for PrepInstruction
pub fn prep_instruction_decoder() -> Decoder(PrepInstruction) {
  use recipe_id <- decode.field("recipe_id", decode.int)
  use recipe_name <- decode.field("recipe_name", decode.string)
  use steps <- decode.field("steps", decode.list(prep_step_decoder()))
  use total_time_minutes <- decode.field("total_time_minutes", decode.int)
  use batch_size <- decode.field("batch_size", decode.int)
  decode.success(PrepInstruction(
    recipe_id: recipe_id,
    recipe_name: recipe_name,
    steps: steps,
    total_time_minutes: total_time_minutes,
    batch_size: batch_size,
  ))
}

/// Decoder for PrepStep
fn prep_step_decoder() -> Decoder(PrepStep) {
  use sequence <- decode.field("sequence", decode.int)
  use description <- decode.field("description", decode.string)
  use ingredients <- decode.field("ingredients", decode.list(decode.string))
  use time_minutes <- decode.field("time_minutes", decode.int)
  decode.success(PrepStep(
    sequence: sequence,
    description: description,
    ingredients: ingredients,
    time_minutes: time_minutes,
  ))
}

/// Decoder for WeeklyMacros
pub fn weekly_macros_decoder() -> Decoder(WeeklyMacros) {
  use weekly_total <- decode.field("weekly_total", types_json.macros_decoder())
  use daily_average <- decode.field("daily_average", types_json.macros_decoder())
  use daily_breakdowns <- decode.field(
    "daily_breakdowns",
    decode.list(daily_macro_breakdown_decoder()),
  )
  decode.success(WeeklyMacros(
    weekly_total: weekly_total,
    daily_average: daily_average,
    daily_breakdowns: daily_breakdowns,
  ))
}

/// Decoder for DailyMacroBreakdown
fn daily_macro_breakdown_decoder() -> Decoder(DailyMacroBreakdown) {
  use day <- decode.field("day", decode.string)
  use actual <- decode.field("actual", types_json.macros_decoder())
  use target <- decode.field("target", types_json.macros_decoder())
  use deviation <- decode.field("deviation", types_json.macros_decoder())
  use calories <- decode.field("calories", decode.float)
  decode.success(DailyMacroBreakdown(
    day: day,
    actual: actual,
    target: target,
    deviation: deviation,
    calories: calories,
  ))
}
