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
import meal_planner/id
import meal_planner/types.{
  type ActivityLevel, type CustomFood, type DailyLog, type FodmapLevel,
  type FoodLogEntry, type Ingredient, type Macros, type MealType,
  type Micronutrients, type UserProfile, Active, Breakfast, Gain, High, Lose,
  Low, Lunch, Maintain, Moderate, Sedentary, Snack,
}

// ============================================================================
// Macros JSON
// ============================================================================

/// Encode Macros to JSON
pub fn macros_to_json(m: Macros) -> Json {
  json.object([
    #("protein", json.float(m.protein)),
    #("fat", json.float(m.fat)),
    #("carbs", json.float(m.carbs)),
    #("calories", json.float(types.macros_calories(m))),
  ])
}

/// Decode Macros from JSON
pub fn macros_decoder() -> Decoder(Macros) {
  use protein <- decode.field("protein", decode.float)
  use fat <- decode.field("fat", decode.float)
  use carbs <- decode.field("carbs", decode.float)
  decode.success(types.Macros(protein: protein, fat: fat, carbs: carbs))
}

// ============================================================================
// Micronutrients JSON
// ============================================================================

/// Helper to convert Option(Float) to Json
fn optional_float(opt: Option(Float)) -> Json {
  case opt {
    Some(v) -> json.float(v)
    None -> json.null()
  }
}

/// Encode Micronutrients to JSON
pub fn micronutrients_to_json(m: Micronutrients) -> Json {
  json.object([
    #("fiber", optional_float(m.fiber)),
    #("sugar", optional_float(m.sugar)),
    #("sodium", optional_float(m.sodium)),
    #("cholesterol", optional_float(m.cholesterol)),
    #("vitamin_a", optional_float(m.vitamin_a)),
    #("vitamin_c", optional_float(m.vitamin_c)),
    #("vitamin_d", optional_float(m.vitamin_d)),
    #("vitamin_e", optional_float(m.vitamin_e)),
    #("vitamin_k", optional_float(m.vitamin_k)),
    #("vitamin_b6", optional_float(m.vitamin_b6)),
    #("vitamin_b12", optional_float(m.vitamin_b12)),
    #("folate", optional_float(m.folate)),
    #("thiamin", optional_float(m.thiamin)),
    #("riboflavin", optional_float(m.riboflavin)),
    #("niacin", optional_float(m.niacin)),
    #("calcium", optional_float(m.calcium)),
    #("iron", optional_float(m.iron)),
    #("magnesium", optional_float(m.magnesium)),
    #("phosphorus", optional_float(m.phosphorus)),
    #("potassium", optional_float(m.potassium)),
    #("zinc", optional_float(m.zinc)),
  ])
}

/// Decode Micronutrients from JSON
pub fn micronutrients_decoder() -> Decoder(Micronutrients) {
  use fiber <- decode.optional_field(
    "fiber",
    None,
    decode.optional(decode.float),
  )
  use sugar <- decode.optional_field(
    "sugar",
    None,
    decode.optional(decode.float),
  )
  use sodium <- decode.optional_field(
    "sodium",
    None,
    decode.optional(decode.float),
  )
  use cholesterol <- decode.optional_field(
    "cholesterol",
    None,
    decode.optional(decode.float),
  )
  use vitamin_a <- decode.optional_field(
    "vitamin_a",
    None,
    decode.optional(decode.float),
  )
  use vitamin_c <- decode.optional_field(
    "vitamin_c",
    None,
    decode.optional(decode.float),
  )
  use vitamin_d <- decode.optional_field(
    "vitamin_d",
    None,
    decode.optional(decode.float),
  )
  use vitamin_e <- decode.optional_field(
    "vitamin_e",
    None,
    decode.optional(decode.float),
  )
  use vitamin_k <- decode.optional_field(
    "vitamin_k",
    None,
    decode.optional(decode.float),
  )
  use vitamin_b6 <- decode.optional_field(
    "vitamin_b6",
    None,
    decode.optional(decode.float),
  )
  use vitamin_b12 <- decode.optional_field(
    "vitamin_b12",
    None,
    decode.optional(decode.float),
  )
  use folate <- decode.optional_field(
    "folate",
    None,
    decode.optional(decode.float),
  )
  use thiamin <- decode.optional_field(
    "thiamin",
    None,
    decode.optional(decode.float),
  )
  use riboflavin <- decode.optional_field(
    "riboflavin",
    None,
    decode.optional(decode.float),
  )
  use niacin <- decode.optional_field(
    "niacin",
    None,
    decode.optional(decode.float),
  )
  use calcium <- decode.optional_field(
    "calcium",
    None,
    decode.optional(decode.float),
  )
  use iron <- decode.optional_field("iron", None, decode.optional(decode.float))
  use magnesium <- decode.optional_field(
    "magnesium",
    None,
    decode.optional(decode.float),
  )
  use phosphorus <- decode.optional_field(
    "phosphorus",
    None,
    decode.optional(decode.float),
  )
  use potassium <- decode.optional_field(
    "potassium",
    None,
    decode.optional(decode.float),
  )
  use zinc <- decode.optional_field("zinc", None, decode.optional(decode.float))
  decode.success(types.Micronutrients(
    fiber: fiber,
    sugar: sugar,
    sodium: sodium,
    cholesterol: cholesterol,
    vitamin_a: vitamin_a,
    vitamin_c: vitamin_c,
    vitamin_d: vitamin_d,
    vitamin_e: vitamin_e,
    vitamin_k: vitamin_k,
    vitamin_b6: vitamin_b6,
    vitamin_b12: vitamin_b12,
    folate: folate,
    thiamin: thiamin,
    riboflavin: riboflavin,
    niacin: niacin,
    calcium: calcium,
    iron: iron,
    magnesium: magnesium,
    phosphorus: phosphorus,
    potassium: potassium,
    zinc: zinc,
  ))
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
  decode.success(types.Ingredient(name: name, quantity: quantity))
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
    "medium" -> decode.success(types.Medium)
    "high" -> decode.success(High)
    _ -> decode.failure(Low, "FodmapLevel")
  }
}

// ============================================================================
// Recipe JSON
// ============================================================================

/// Encode Recipe to JSON
pub fn recipe_to_json(r: types.Recipe) -> Json {
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
pub fn recipe_decoder() -> Decoder(types.Recipe) {
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
  decode.success(types.Recipe(
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
pub fn goal_to_string(g: types.Goal) -> String {
  case g {
    Gain -> "gain"
    Maintain -> "maintain"
    Lose -> "lose"
  }
}

/// Decode Goal from string
pub fn goal_decoder() -> Decoder(types.Goal) {
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
  let targets = types.daily_macro_targets(u)
  let base_fields = [
    #("id", id.user_id_to_json(u.id)),
    #("bodyweight", json.float(u.bodyweight)),
    #("activity_level", json.string(activity_level_to_string(u.activity_level))),
    #("goal", json.string(goal_to_string(u.goal))),
    #("meals_per_day", json.int(u.meals_per_day)),
    #("daily_targets", macros_to_json(targets)),
  ]

  let fields = case u.micronutrient_goals {
    Some(goals) -> [
      #("micronutrient_goals", micronutrients_to_json(goals)),
      ..base_fields
    ]
    None -> base_fields
  }

  json.object(fields)
}

/// Decode UserProfile from JSON
pub fn user_profile_decoder() -> Decoder(UserProfile) {
  use user_id <- decode.field("id", id.user_id_decoder())
  use bodyweight <- decode.field("bodyweight", decode.float)
  use activity_level <- decode.field("activity_level", activity_level_decoder())
  use goal <- decode.field("goal", goal_decoder())
  use meals_per_day <- decode.field("meals_per_day", decode.int)
  use micronutrient_goals <- decode.field(
    "micronutrient_goals",
    decode.optional(micronutrients_decoder()),
  )
  decode.success(types.UserProfile(
    id: user_id,
    bodyweight: bodyweight,
    activity_level: activity_level,
    goal: goal,
    meals_per_day: meals_per_day,
    micronutrient_goals: micronutrient_goals,
  ))
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
  decode.success(types.CustomFood(
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
  decode.success(types.FoodLogEntry(
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
  decode.success(types.DailyLog(
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
pub fn day_of_week_to_string(day: types.DayOfWeek) -> String {
  case day {
    types.Monday -> "Monday"
    types.Tuesday -> "Tuesday"
    types.Wednesday -> "Wednesday"
    types.Thursday -> "Thursday"
    types.Friday -> "Friday"
    types.Saturday -> "Saturday"
    types.Sunday -> "Sunday"
  }
}

/// Parse DayOfWeek from string
pub fn day_of_week_from_string(s: String) -> Option(types.DayOfWeek) {
  case string.lowercase(s) {
    "monday" -> Some(types.Monday)
    "tuesday" -> Some(types.Tuesday)
    "wednesday" -> Some(types.Wednesday)
    "thursday" -> Some(types.Thursday)
    "friday" -> Some(types.Friday)
    "saturday" -> Some(types.Saturday)
    "sunday" -> Some(types.Sunday)
    _ -> None
  }
}

/// Convert RegenerationScope to string
pub fn regeneration_scope_to_string(scope: types.RegenerationScope) -> String {
  case scope {
    types.SingleMeal -> "single_meal"
    types.SingleDay -> "single_day"
    types.FullWeek -> "full_week"
  }
}

/// Encode EmailCommand to JSON
pub fn email_command_to_json(cmd: types.EmailCommand) -> Json {
  case cmd {
    types.AdjustMeal(day, meal_type, recipe_id) ->
      json.object([
        #("type", json.string("adjust_meal")),
        #("day", json.string(day_of_week_to_string(day))),
        #("meal_type", json.string(meal_type_to_string(meal_type))),
        #("recipe_id", json.string(id.recipe_id_to_string(recipe_id))),
      ])
    types.AddPreference(pref) ->
      json.object([
        #("type", json.string("add_preference")),
        #("preference", json.string(pref)),
      ])
    types.RemoveDislike(food) ->
      json.object([
        #("type", json.string("remove_dislike")),
        #("food_name", json.string(food)),
      ])
    types.RegeneratePlan(scope, constraints) ->
      json.object([
        #("type", json.string("regenerate_plan")),
        #("scope", json.string(regeneration_scope_to_string(scope))),
        #("constraints", case constraints {
          Some(c) -> json.string(c)
          None -> json.null()
        }),
      ])
    types.SkipMeal(day, meal_type) ->
      json.object([
        #("type", json.string("skip_meal")),
        #("day", json.string(day_of_week_to_string(day))),
        #("meal_type", json.string(meal_type_to_string(meal_type))),
      ])
  }
}

/// Encode CommandExecutionResult to JSON
pub fn command_execution_result_to_json(
  result: types.CommandExecutionResult,
) -> Json {
  json.object([
    #("success", json.bool(result.success)),
    #("message", json.string(result.message)),
    #("command", case result.command {
      Some(cmd) -> email_command_to_json(cmd)
      None -> json.null()
    }),
  ])
}
