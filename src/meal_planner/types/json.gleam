//// JSON encoding and decoding for meal planner types.
////
//// This module contains all JSON serialization and deserialization functions
//// for the core meal planner domain types. It includes:
//// - encode_* functions for converting domain types to JSON
//// - decode_* functions for parsing JSON into domain types
//// - helper functions for string conversion and formatting

import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import gleam/string
import meal_planner/email/command.{
  type CommandExecutionResult, type DayOfWeek, type EmailCommand,
  type RegenerationScope,
} as cmd
import meal_planner/id
import meal_planner/types/custom_food.{type CustomFood, CustomFood}
import meal_planner/types/food.{
  type DailyLog, type FoodLogEntry, type MealType, Breakfast, DailyLog, Dinner,
  FoodLogEntry, Lunch, Snack,
}
import meal_planner/types/macros.{type Macros, Macros}
import meal_planner/types/micronutrients.{type Micronutrients} as micros
import meal_planner/types/recipe.{
  type FodmapLevel, type Ingredient, type Recipe, High, Ingredient, Low, Medium,
  Recipe,
}
import meal_planner/types/user_profile.{
  type ActivityLevel, type Goal, type UserProfile, Active, Gain, Lose, Maintain,
  Moderate, Sedentary,
} as user

// ============================================================================
// Macros JSON
// ============================================================================

/// Encode Macros to JSON
pub fn macros_to_json(m: Macros) -> Json {
  json.object([
    #("protein", json.float(m.protein)),
    #("fat", json.float(m.fat)),
    #("carbs", json.float(m.carbs)),
    #("calories", json.float(macros.calories(m))),
  ])
}

/// Decode Macros from JSON
pub fn macros_decoder() -> Decoder(Macros) {
  use protein <- decode.field("protein", decode.float)
  use fat <- decode.field("fat", decode.float)
  use carbs <- decode.field("carbs", decode.float)
  decode.success(Macros(protein: protein, fat: fat, carbs: carbs))
}

// ============================================================================
// Micronutrients JSON
// ============================================================================

/// Encode Micronutrients to JSON
pub fn micronutrients_to_json(m: Micronutrients) -> Json {
  micros.to_json(m)
}

/// Decode Micronutrients from JSON
pub fn micronutrients_decoder() -> Decoder(Micronutrients) {
  micros.decoder()
}

// ============================================================================
// Ingredient JSON
// ============================================================================

/// Encode Ingredient to JSON
pub fn ingredient_to_json(i: Ingredient) -> Json {
  json.object([
    #("name", json.string(i.name)),
    #("quantity", json.string(i.quantity)),
  ])
}

/// Decode Ingredient from JSON
pub fn ingredient_decoder() -> Decoder(Ingredient) {
  use name <- decode.field("name", decode.string)
  use quantity <- decode.field("quantity", decode.string)
  decode.success(Ingredient(name: name, quantity: quantity))
}

// ============================================================================
// FODMAP Level Conversion
// ============================================================================

/// Convert FodmapLevel to JSON-friendly string
pub fn fodmap_level_to_string(f: FodmapLevel) -> String {
  case f {
    Low -> "low"
    Medium -> "medium"
    High -> "high"
  }
}

/// Decode FodmapLevel from string
pub fn fodmap_level_decoder() -> Decoder(FodmapLevel) {
  use s <- decode.then(decode.string)
  case s {
    "low" -> decode.success(Low)
    "medium" -> decode.success(Medium)
    "high" -> decode.success(High)
    _ -> decode.failure(Low, "FodmapLevel")
  }
}

// ============================================================================
// Recipe JSON
// ============================================================================

/// Encode Recipe to JSON
pub fn recipe_to_json(r: Recipe) -> Json {
  json.object([
    #("id", id.recipe_id_to_json(r.id)),
    #("name", json.string(r.name)),
    #("ingredients", json.array(r.ingredients, ingredient_to_json)),
    #("instructions", json.array(r.instructions, json.string)),
    #("macros", macros_to_json(r.macros)),
    #("servings", json.int(r.servings)),
    #("category", json.string(r.category)),
    #("fodmap_level", json.string(fodmap_level_to_string(r.fodmap_level))),
    #("vertical_compliant", json.bool(r.vertical_compliant)),
  ])
}

/// Decode Recipe from JSON
pub fn recipe_decoder() -> Decoder(Recipe) {
  use recipe_id <- decode.field("id", id.recipe_id_decoder())
  use name <- decode.field("name", decode.string)
  use ingredients <- decode.field(
    "ingredients",
    decode.list(ingredient_decoder()),
  )
  use instructions <- decode.field("instructions", decode.list(decode.string))
  use macros <- decode.field("macros", macros_decoder())
  use servings <- decode.field("servings", decode.int)
  use category <- decode.field("category", decode.string)
  use fodmap_level <- decode.field("fodmap_level", fodmap_level_decoder())
  use vertical_compliant <- decode.field("vertical_compliant", decode.bool)
  decode.success(Recipe(
    id: recipe_id,
    name: name,
    ingredients: ingredients,
    instructions: instructions,
    macros: macros,
    servings: servings,
    category: category,
    fodmap_level: fodmap_level,
    vertical_compliant: vertical_compliant,
  ))
}

// ============================================================================
// Activity Level Conversion
// ============================================================================

/// Convert ActivityLevel to JSON-friendly string
pub fn activity_level_to_string(a: ActivityLevel) -> String {
  case a {
    Sedentary -> "sedentary"
    Moderate -> "moderate"
    Active -> "active"
  }
}

/// Decode ActivityLevel from string
pub fn activity_level_decoder() -> Decoder(ActivityLevel) {
  use s <- decode.then(decode.string)
  case s {
    "sedentary" -> decode.success(Sedentary)
    "moderate" -> decode.success(Moderate)
    "active" -> decode.success(Active)
    _ -> decode.failure(Sedentary, "ActivityLevel")
  }
}

// ============================================================================
// Goal Conversion
// ============================================================================

/// Convert Goal to JSON-friendly string
pub fn goal_to_string(g: Goal) -> String {
  case g {
    Gain -> "gain"
    Maintain -> "maintain"
    Lose -> "lose"
  }
}

/// Decode Goal from string
pub fn goal_decoder() -> Decoder(Goal) {
  use s <- decode.then(decode.string)
  case s {
    "gain" -> decode.success(Gain)
    "maintain" -> decode.success(Maintain)
    "lose" -> decode.success(Lose)
    _ -> decode.failure(Maintain, "Goal")
  }
}

// ============================================================================
// User Profile JSON
// ============================================================================

/// Encode UserProfile to JSON
pub fn user_profile_to_json(u: UserProfile) -> Json {
  user.to_json(u)
}

/// Decode UserProfile from JSON
pub fn user_profile_decoder() -> Decoder(UserProfile) {
  user.decoder()
}

// ============================================================================
// Meal Type Conversion
// ============================================================================

/// Convert MealType to JSON-friendly string
pub fn meal_type_to_string(m: MealType) -> String {
  case m {
    Breakfast -> "breakfast"
    Lunch -> "lunch"
    Dinner -> "dinner"
    Snack -> "snack"
  }
}

/// Decode MealType from string
pub fn meal_type_decoder() -> Decoder(MealType) {
  use s <- decode.then(decode.string)
  case s {
    "breakfast" -> decode.success(Breakfast)
    "lunch" -> decode.success(Lunch)
    "dinner" -> decode.success(Dinner)
    "snack" -> decode.success(Snack)
    _ -> decode.failure(Snack, "MealType")
  }
}

// ============================================================================
// Custom Food JSON
// ============================================================================

/// Encode CustomFood to JSON
pub fn custom_food_to_json(f: CustomFood) -> Json {
  let fields = [
    #("id", id.custom_food_id_to_json(f.id)),
    #("user_id", id.user_id_to_json(f.user_id)),
    #("name", json.string(f.name)),
    #("serving_size", json.float(f.serving_size)),
    #("serving_unit", json.string(f.serving_unit)),
    #("macros", macros_to_json(f.macros)),
    #("calories", json.float(f.calories)),
  ]

  let fields = case f.brand {
    Some(brand) -> [#("brand", json.string(brand)), ..fields]
    None -> fields
  }

  let fields = case f.description {
    Some(desc) -> [#("description", json.string(desc)), ..fields]
    None -> fields
  }

  let fields = case f.micronutrients {
    Some(micros) -> [
      #("micronutrients", micronutrients_to_json(micros)),
      ..fields
    ]
    None -> fields
  }

  json.object(fields)
}

/// Decode CustomFood from JSON
pub fn custom_food_decoder() -> Decoder(CustomFood) {
  use food_id <- decode.field("id", id.custom_food_id_decoder())
  use user_id <- decode.field("user_id", id.user_id_decoder())
  use name <- decode.field("name", decode.string)
  use brand <- decode.field("brand", decode.optional(decode.string))
  use description <- decode.field("description", decode.optional(decode.string))
  use serving_size <- decode.field("serving_size", decode.float)
  use serving_unit <- decode.field("serving_unit", decode.string)
  use macros <- decode.field("macros", macros_decoder())
  use calories <- decode.field("calories", decode.float)
  use micronutrients <- decode.field(
    "micronutrients",
    decode.optional(micronutrients_decoder()),
  )
  decode.success(CustomFood(
    id: food_id,
    user_id: user_id,
    name: name,
    brand: brand,
    description: description,
    serving_size: serving_size,
    serving_unit: serving_unit,
    macros: macros,
    calories: calories,
    micronutrients: micronutrients,
  ))
}

// ============================================================================
// FoodLogEntry JSON
// ============================================================================

/// Encode FoodLogEntry to JSON
pub fn food_log_entry_to_json(e: FoodLogEntry) -> Json {
  let fields = [
    #("id", id.log_entry_id_to_json(e.id)),
    #("recipe_id", id.recipe_id_to_json(e.recipe_id)),
    #("recipe_name", json.string(e.recipe_name)),
    #("servings", json.float(e.servings)),
    #("macros", macros_to_json(e.macros)),
    #("meal_type", json.string(meal_type_to_string(e.meal_type))),
    #("logged_at", json.string(e.logged_at)),
  ]

  let fields = case e.micronutrients {
    Some(micros) -> [
      #("micronutrients", micronutrients_to_json(micros)),
      ..fields
    ]
    None -> fields
  }

  json.object(fields)
}

/// Decode FoodLogEntry from JSON
pub fn food_log_entry_decoder() -> Decoder(FoodLogEntry) {
  use log_id <- decode.field("id", id.log_entry_id_decoder())
  use recipe_id <- decode.field("recipe_id", id.recipe_id_decoder())
  use recipe_name <- decode.field("recipe_name", decode.string)
  use servings <- decode.field("servings", decode.float)
  use macros <- decode.field("macros", macros_decoder())
  use micronutrients <- decode.field(
    "micronutrients",
    decode.optional(micronutrients_decoder()),
  )
  use meal_type <- decode.field("meal_type", meal_type_decoder())
  use logged_at <- decode.field("logged_at", decode.string)
  use source_type <- decode.field("source_type", decode.string)
  use source_id <- decode.field("source_id", decode.string)
  decode.success(FoodLogEntry(
    id: log_id,
    recipe_id: recipe_id,
    recipe_name: recipe_name,
    servings: servings,
    macros: macros,
    micronutrients: micronutrients,
    meal_type: meal_type,
    logged_at: logged_at,
    source_type: source_type,
    source_id: source_id,
  ))
}

// ============================================================================
// DailyLog JSON
// ============================================================================

/// Encode DailyLog to JSON
pub fn daily_log_to_json(d: DailyLog) -> Json {
  let fields = [
    #("date", json.string(d.date)),
    #("entries", json.array(d.entries, food_log_entry_to_json)),
    #("total_macros", macros_to_json(d.total_macros)),
  ]

  let fields = case d.total_micronutrients {
    Some(micros) -> [
      #("total_micronutrients", micronutrients_to_json(micros)),
      ..fields
    ]
    None -> fields
  }

  json.object(fields)
}

/// Decode DailyLog from JSON
pub fn daily_log_decoder() -> Decoder(DailyLog) {
  use date <- decode.field("date", decode.string)
  use entries <- decode.field("entries", decode.list(food_log_entry_decoder()))
  use total_macros <- decode.field("total_macros", macros_decoder())
  use total_micronutrients <- decode.field(
    "total_micronutrients",
    decode.optional(micronutrients_decoder()),
  )
  decode.success(DailyLog(
    date: date,
    entries: entries,
    total_macros: total_macros,
    total_micronutrients: total_micronutrients,
  ))
}

// ============================================================================
// Email Command JSON (converted string functions only)
// ============================================================================

/// Convert DayOfWeek to string
pub fn day_of_week_to_string(day: DayOfWeek) -> String {
  case day {
    cmd.Monday -> "Monday"
    cmd.Tuesday -> "Tuesday"
    cmd.Wednesday -> "Wednesday"
    cmd.Thursday -> "Thursday"
    cmd.Friday -> "Friday"
    cmd.Saturday -> "Saturday"
    cmd.Sunday -> "Sunday"
  }
}

/// Parse DayOfWeek from string
pub fn day_of_week_from_string(s: String) -> Option(DayOfWeek) {
  case string.lowercase(s) {
    "monday" -> Some(cmd.Monday)
    "tuesday" -> Some(cmd.Tuesday)
    "wednesday" -> Some(cmd.Wednesday)
    "thursday" -> Some(cmd.Thursday)
    "friday" -> Some(cmd.Friday)
    "saturday" -> Some(cmd.Saturday)
    "sunday" -> Some(cmd.Sunday)
    _ -> None
  }
}

/// Convert RegenerationScope to string
pub fn regeneration_scope_to_string(scope: RegenerationScope) -> String {
  case scope {
    cmd.SingleMeal(day: _, meal: _) -> "single_meal"
    cmd.SingleDay(day: _) -> "single_day"
    cmd.FullWeek -> "full_week"
  }
}

/// Encode EmailCommand to JSON
pub fn email_command_to_json(cmd: EmailCommand) -> Json {
  case cmd {
    cmd.AdjustMeal(day, meal_type, recipe_id) ->
      json.object([
        #("type", json.string("adjust_meal")),
        #("day", json.string(day_of_week_to_string(day))),
        #("meal_type", json.string(cmd.meal_type_to_string(meal_type))),
        #("recipe_id", json.string(id.recipe_id_to_string(recipe_id))),
      ])
    cmd.AddPreference(pref) ->
      json.object([
        #("type", json.string("add_preference")),
        #("preference", json.string(pref)),
      ])
    cmd.RemoveDislike(food) ->
      json.object([
        #("type", json.string("remove_dislike")),
        #("food_name", json.string(food)),
      ])
    cmd.RegeneratePlan(scope, constraints) ->
      json.object([
        #("type", json.string("regenerate_plan")),
        #("scope", json.string(regeneration_scope_to_string(scope))),
        #("constraints", case constraints {
          Some(c) -> json.string(c)
          None -> json.null()
        }),
      ])
    cmd.SkipMeal(day, meal_type) ->
      json.object([
        #("type", json.string("skip_meal")),
        #("day", json.string(day_of_week_to_string(day))),
        #("meal_type", json.string(cmd.meal_type_to_string(meal_type))),
      ])
  }
}

/// Encode CommandExecutionResult to JSON
pub fn command_execution_result_to_json(result: CommandExecutionResult) -> Json {
  json.object([
    #("success", json.bool(result.success)),
    #("message", json.string(result.message)),
    #("command", case result.command {
      Some(cmd) -> email_command_to_json(cmd)
      None -> json.null()
    }),
  ])
}
