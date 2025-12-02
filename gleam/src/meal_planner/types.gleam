//// Core types for the meal planner application.
//// All types, encoders, and decoders consolidated here.

import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/list

// ============================================================================
// Core Nutrition Types
// ============================================================================

/// Macronutrient values (protein, fat, carbs in grams)
pub type Macros {
  Macros(protein: Float, fat: Float, carbs: Float)
}

/// Calculate total calories from macros
/// Uses: 4cal/g protein, 9cal/g fat, 4cal/g carbs
pub fn macros_calories(m: Macros) -> Float {
  { m.protein *. 4.0 } +. { m.fat *. 9.0 } +. { m.carbs *. 4.0 }
}

/// Add two Macros together
pub fn macros_add(a: Macros, b: Macros) -> Macros {
  Macros(
    protein: a.protein +. b.protein,
    fat: a.fat +. b.fat,
    carbs: a.carbs +. b.carbs,
  )
}

/// Scale macros by a factor
pub fn macros_scale(m: Macros, factor: Float) -> Macros {
  Macros(
    protein: m.protein *. factor,
    fat: m.fat *. factor,
    carbs: m.carbs *. factor,
  )
}

/// Empty macros (zero values)
pub fn macros_zero() -> Macros {
  Macros(protein: 0.0, fat: 0.0, carbs: 0.0)
}

/// Sum a list of macros
pub fn macros_sum(macros: List(Macros)) -> Macros {
  list.fold(macros, macros_zero(), macros_add)
}

// ============================================================================
// Recipe Types
// ============================================================================

/// Ingredient with name and quantity description
pub type Ingredient {
  Ingredient(name: String, quantity: String)
}

/// FODMAP level for digestive health tracking
pub type FodmapLevel {
  Low
  Medium
  High
}

/// Recipe with all nutritional and dietary information
pub type Recipe {
  Recipe(
    id: String,
    name: String,
    ingredients: List(Ingredient),
    instructions: List(String),
    macros: Macros,
    servings: Int,
    category: String,
    fodmap_level: FodmapLevel,
    vertical_compliant: Bool,
  )
}

/// Check if recipe meets Vertical Diet requirements
/// Must be explicitly marked compliant and have low FODMAP
pub fn is_vertical_diet_compliant(recipe: Recipe) -> Bool {
  recipe.vertical_compliant && recipe.fodmap_level == Low
}

/// Returns macros per serving (macros are already stored per serving)
pub fn macros_per_serving(recipe: Recipe) -> Macros {
  recipe.macros
}

/// Returns total macros for all servings
pub fn total_macros(recipe: Recipe) -> Macros {
  let servings = case recipe.servings {
    s if s <= 0 -> 1
    s -> s
  }
  macros_scale(recipe.macros, int_to_float(servings))
}

@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float

// ============================================================================
// User Profile Types
// ============================================================================

/// Activity level for calorie/macro calculations
pub type ActivityLevel {
  Sedentary
  Moderate
  Active
}

/// Fitness goal for calorie adjustments
pub type Goal {
  Gain
  Maintain
  Lose
}

/// User profile for personalized nutrition targets
pub type UserProfile {
  UserProfile(
    id: String,
    bodyweight: Float,
    activity_level: ActivityLevel,
    goal: Goal,
    meals_per_day: Int,
  )
}

/// Calculate daily protein target (0.8-1g per lb bodyweight)
/// Higher end for active/gain, lower for sedentary/lose
pub fn daily_protein_target(u: UserProfile) -> Float {
  let multiplier = case u.activity_level, u.goal {
    Active, _ -> 1.0
    _, Gain -> 1.0
    Sedentary, _ -> 0.8
    _, Lose -> 0.8
    _, _ -> 0.9
  }
  u.bodyweight *. multiplier
}

/// Calculate daily fat target (0.3g per lb bodyweight)
pub fn daily_fat_target(u: UserProfile) -> Float {
  u.bodyweight *. 0.3
}

/// Calculate daily calorie target based on activity and goal
pub fn daily_calorie_target(u: UserProfile) -> Float {
  let base_multiplier = case u.activity_level {
    Sedentary -> 12.0
    Moderate -> 15.0
    Active -> 18.0
  }
  let base = u.bodyweight *. base_multiplier
  case u.goal {
    Gain -> base *. 1.15
    Lose -> base *. 0.85
    Maintain -> base
  }
}

/// Calculate daily carb target based on remaining calories
/// After protein (4cal/g) and fat (9cal/g), fill rest with carbs (4cal/g)
pub fn daily_carb_target(u: UserProfile) -> Float {
  let total_calories = daily_calorie_target(u)
  let protein_calories = daily_protein_target(u) *. 4.0
  let fat_calories = daily_fat_target(u) *. 9.0
  let remaining = total_calories -. protein_calories -. fat_calories
  case remaining <. 0.0 {
    True -> 0.0
    False -> remaining /. 4.0
  }
}

/// Calculate complete daily macro targets
pub fn daily_macro_targets(u: UserProfile) -> Macros {
  Macros(
    protein: daily_protein_target(u),
    fat: daily_fat_target(u),
    carbs: daily_carb_target(u),
  )
}

// ============================================================================
// Food Log Types
// ============================================================================

/// Meal type for food logging
pub type MealType {
  Breakfast
  Lunch
  Dinner
  Snack
}

/// A single food log entry
pub type FoodLogEntry {
  FoodLogEntry(
    id: String,
    recipe_id: String,
    recipe_name: String,
    servings: Float,
    macros: Macros,
    meal_type: MealType,
    logged_at: String,
  )
}

/// Daily food log with all entries
pub type DailyLog {
  DailyLog(date: String, entries: List(FoodLogEntry), total_macros: Macros)
}

// ============================================================================
// JSON Encoding
// ============================================================================

pub fn macros_to_json(m: Macros) -> Json {
  json.object([
    #("protein", json.float(m.protein)),
    #("fat", json.float(m.fat)),
    #("carbs", json.float(m.carbs)),
    #("calories", json.float(macros_calories(m))),
  ])
}

pub fn ingredient_to_json(i: Ingredient) -> Json {
  json.object([
    #("name", json.string(i.name)),
    #("quantity", json.string(i.quantity)),
  ])
}

pub fn fodmap_level_to_string(f: FodmapLevel) -> String {
  case f {
    Low -> "low"
    Medium -> "medium"
    High -> "high"
  }
}

pub fn recipe_to_json(r: Recipe) -> Json {
  json.object([
    #("id", json.string(r.id)),
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

pub fn activity_level_to_string(a: ActivityLevel) -> String {
  case a {
    Sedentary -> "sedentary"
    Moderate -> "moderate"
    Active -> "active"
  }
}

pub fn goal_to_string(g: Goal) -> String {
  case g {
    Gain -> "gain"
    Maintain -> "maintain"
    Lose -> "lose"
  }
}

pub fn user_profile_to_json(u: UserProfile) -> Json {
  let targets = daily_macro_targets(u)
  json.object([
    #("id", json.string(u.id)),
    #("bodyweight", json.float(u.bodyweight)),
    #("activity_level", json.string(activity_level_to_string(u.activity_level))),
    #("goal", json.string(goal_to_string(u.goal))),
    #("meals_per_day", json.int(u.meals_per_day)),
    #("daily_targets", macros_to_json(targets)),
  ])
}

pub fn meal_type_to_string(m: MealType) -> String {
  case m {
    Breakfast -> "breakfast"
    Lunch -> "lunch"
    Dinner -> "dinner"
    Snack -> "snack"
  }
}

pub fn food_log_entry_to_json(e: FoodLogEntry) -> Json {
  json.object([
    #("id", json.string(e.id)),
    #("recipe_id", json.string(e.recipe_id)),
    #("recipe_name", json.string(e.recipe_name)),
    #("servings", json.float(e.servings)),
    #("macros", macros_to_json(e.macros)),
    #("meal_type", json.string(meal_type_to_string(e.meal_type))),
    #("logged_at", json.string(e.logged_at)),
  ])
}

pub fn daily_log_to_json(d: DailyLog) -> Json {
  json.object([
    #("date", json.string(d.date)),
    #("entries", json.array(d.entries, food_log_entry_to_json)),
    #("total_macros", macros_to_json(d.total_macros)),
  ])
}

// ============================================================================
// JSON Decoding
// ============================================================================

/// Decoder for Macros
pub fn macros_decoder() -> Decoder(Macros) {
  use protein <- decode.field("protein", decode.float)
  use fat <- decode.field("fat", decode.float)
  use carbs <- decode.field("carbs", decode.float)
  decode.success(Macros(protein: protein, fat: fat, carbs: carbs))
}

/// Decoder for Ingredient
pub fn ingredient_decoder() -> Decoder(Ingredient) {
  use name <- decode.field("name", decode.string)
  use quantity <- decode.field("quantity", decode.string)
  decode.success(Ingredient(name: name, quantity: quantity))
}

/// Decoder for FodmapLevel
pub fn fodmap_level_decoder() -> Decoder(FodmapLevel) {
  use s <- decode.then(decode.string)
  case s {
    "low" -> decode.success(Low)
    "medium" -> decode.success(Medium)
    "high" -> decode.success(High)
    _ -> decode.failure(Low, "FodmapLevel")
  }
}

/// Decoder for ActivityLevel
pub fn activity_level_decoder() -> Decoder(ActivityLevel) {
  use s <- decode.then(decode.string)
  case s {
    "sedentary" -> decode.success(Sedentary)
    "moderate" -> decode.success(Moderate)
    "active" -> decode.success(Active)
    _ -> decode.failure(Sedentary, "ActivityLevel")
  }
}

/// Decoder for Goal
pub fn goal_decoder() -> Decoder(Goal) {
  use s <- decode.then(decode.string)
  case s {
    "gain" -> decode.success(Gain)
    "maintain" -> decode.success(Maintain)
    "lose" -> decode.success(Lose)
    _ -> decode.failure(Maintain, "Goal")
  }
}

/// Decoder for MealType
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

/// Decoder for Recipe
pub fn recipe_decoder() -> Decoder(Recipe) {
  use id <- decode.field("id", decode.string)
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
    id: id,
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

/// Decoder for UserProfile
pub fn user_profile_decoder() -> Decoder(UserProfile) {
  use id <- decode.field("id", decode.string)
  use bodyweight <- decode.field("bodyweight", decode.float)
  use activity_level <- decode.field("activity_level", activity_level_decoder())
  use goal <- decode.field("goal", goal_decoder())
  use meals_per_day <- decode.field("meals_per_day", decode.int)
  decode.success(UserProfile(
    id: id,
    bodyweight: bodyweight,
    activity_level: activity_level,
    goal: goal,
    meals_per_day: meals_per_day,
  ))
}

/// Decoder for FoodLogEntry
pub fn food_log_entry_decoder() -> Decoder(FoodLogEntry) {
  use id <- decode.field("id", decode.string)
  use recipe_id <- decode.field("recipe_id", decode.string)
  use recipe_name <- decode.field("recipe_name", decode.string)
  use servings <- decode.field("servings", decode.float)
  use macros <- decode.field("macros", macros_decoder())
  use meal_type <- decode.field("meal_type", meal_type_decoder())
  use logged_at <- decode.field("logged_at", decode.string)
  decode.success(FoodLogEntry(
    id: id,
    recipe_id: recipe_id,
    recipe_name: recipe_name,
    servings: servings,
    macros: macros,
    meal_type: meal_type,
    logged_at: logged_at,
  ))
}

/// Decoder for DailyLog
pub fn daily_log_decoder() -> Decoder(DailyLog) {
  use date <- decode.field("date", decode.string)
  use entries <- decode.field("entries", decode.list(food_log_entry_decoder()))
  use total_macros <- decode.field("total_macros", macros_decoder())
  decode.success(DailyLog(
    date: date,
    entries: entries,
    total_macros: total_macros,
  ))
}
