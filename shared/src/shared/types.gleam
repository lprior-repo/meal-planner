//// Shared types for the meal planner application.
//// These types work on both JavaScript (client) and Erlang (server) targets.

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
// Micronutrients Types
// ============================================================================

/// Micronutrient values (vitamins and minerals)
/// All fields are optional as not all foods have complete micronutrient data
pub type Micronutrients {
  Micronutrients(
    fiber: Option(Float),
    sugar: Option(Float),
    sodium: Option(Float),
    cholesterol: Option(Float),
    vitamin_a: Option(Float),
    vitamin_c: Option(Float),
    vitamin_d: Option(Float),
    vitamin_e: Option(Float),
    vitamin_k: Option(Float),
    vitamin_b6: Option(Float),
    vitamin_b12: Option(Float),
    folate: Option(Float),
    thiamin: Option(Float),
    riboflavin: Option(Float),
    niacin: Option(Float),
    calcium: Option(Float),
    iron: Option(Float),
    magnesium: Option(Float),
    phosphorus: Option(Float),
    potassium: Option(Float),
    zinc: Option(Float),
  )
}

// ============================================================================
// Custom Food Types
// ============================================================================

/// User-defined custom food with complete nutritional information
pub type CustomFood {
  CustomFood(
    id: String,
    user_id: String,
    name: String,
    brand: Option(String),
    description: Option(String),
    serving_size: Float,
    serving_unit: String,
    macros: Macros,
    calories: Float,
    micronutrients: Option(Micronutrients),
  )
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

/// Calculate daily macro targets for a user profile
pub fn daily_macro_targets(u: UserProfile) -> Macros {
  let protein = calculate_protein_target(u)
  let fat = calculate_fat_target(u)
  let calories = calculate_calorie_target(u)
  let carbs = calculate_carb_target(calories, protein, fat)

  Macros(protein: protein, fat: fat, carbs: carbs)
}

fn calculate_protein_target(u: UserProfile) -> Float {
  let multiplier = case u.activity_level, u.goal {
    Active, _ -> 1.0
    _, Gain -> 1.0
    Sedentary, _ -> 0.8
    _, Lose -> 0.8
    _, _ -> 0.9
  }
  u.bodyweight *. multiplier
}

fn calculate_fat_target(u: UserProfile) -> Float {
  u.bodyweight *. 0.3
}

fn calculate_calorie_target(u: UserProfile) -> Float {
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

fn calculate_carb_target(calories: Float, protein: Float, fat: Float) -> Float {
  let protein_calories = protein *. 4.0
  let fat_calories = fat *. 9.0
  let remaining = calories -. protein_calories -. fat_calories
  case remaining <. 0.0 {
    True -> 0.0
    False -> remaining /. 4.0
  }
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

pub fn micronutrients_to_json(m: Micronutrients) -> Json {
  let fields = []

  // Fiber
  let fields = case m.fiber {
    Some(v) -> [#("fiber", json.float(v)), ..fields]
    None -> fields
  }

  // Sugar
  let fields = case m.sugar {
    Some(v) -> [#("sugar", json.float(v)), ..fields]
    None -> fields
  }

  // Sodium
  let fields = case m.sodium {
    Some(v) -> [#("sodium", json.float(v)), ..fields]
    None -> fields
  }

  // Cholesterol
  let fields = case m.cholesterol {
    Some(v) -> [#("cholesterol", json.float(v)), ..fields]
    None -> fields
  }

  // Vitamin A
  let fields = case m.vitamin_a {
    Some(v) -> [#("vitamin_a", json.float(v)), ..fields]
    None -> fields
  }

  // Vitamin C
  let fields = case m.vitamin_c {
    Some(v) -> [#("vitamin_c", json.float(v)), ..fields]
    None -> fields
  }

  // Vitamin D
  let fields = case m.vitamin_d {
    Some(v) -> [#("vitamin_d", json.float(v)), ..fields]
    None -> fields
  }

  // Vitamin E
  let fields = case m.vitamin_e {
    Some(v) -> [#("vitamin_e", json.float(v)), ..fields]
    None -> fields
  }

  // Vitamin K
  let fields = case m.vitamin_k {
    Some(v) -> [#("vitamin_k", json.float(v)), ..fields]
    None -> fields
  }

  // Vitamin B6
  let fields = case m.vitamin_b6 {
    Some(v) -> [#("vitamin_b6", json.float(v)), ..fields]
    None -> fields
  }

  // Vitamin B12
  let fields = case m.vitamin_b12 {
    Some(v) -> [#("vitamin_b12", json.float(v)), ..fields]
    None -> fields
  }

  // Folate
  let fields = case m.folate {
    Some(v) -> [#("folate", json.float(v)), ..fields]
    None -> fields
  }

  // Thiamin
  let fields = case m.thiamin {
    Some(v) -> [#("thiamin", json.float(v)), ..fields]
    None -> fields
  }

  // Riboflavin
  let fields = case m.riboflavin {
    Some(v) -> [#("riboflavin", json.float(v)), ..fields]
    None -> fields
  }

  // Niacin
  let fields = case m.niacin {
    Some(v) -> [#("niacin", json.float(v)), ..fields]
    None -> fields
  }

  // Calcium
  let fields = case m.calcium {
    Some(v) -> [#("calcium", json.float(v)), ..fields]
    None -> fields
  }

  // Iron
  let fields = case m.iron {
    Some(v) -> [#("iron", json.float(v)), ..fields]
    None -> fields
  }

  // Magnesium
  let fields = case m.magnesium {
    Some(v) -> [#("magnesium", json.float(v)), ..fields]
    None -> fields
  }

  // Phosphorus
  let fields = case m.phosphorus {
    Some(v) -> [#("phosphorus", json.float(v)), ..fields]
    None -> fields
  }

  // Potassium
  let fields = case m.potassium {
    Some(v) -> [#("potassium", json.float(v)), ..fields]
    None -> fields
  }

  // Zinc
  let fields = case m.zinc {
    Some(v) -> [#("zinc", json.float(v)), ..fields]
    None -> fields
  }

  json.object(fields)
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

/// Decoder for Micronutrients
pub fn micronutrients_decoder() -> Decoder(Micronutrients) {
  use fiber <- decode.field("fiber", decode.optional(decode.float))
  use sugar <- decode.field("sugar", decode.optional(decode.float))
  use sodium <- decode.field("sodium", decode.optional(decode.float))
  use cholesterol <- decode.field("cholesterol", decode.optional(decode.float))
  use vitamin_a <- decode.field("vitamin_a", decode.optional(decode.float))
  use vitamin_c <- decode.field("vitamin_c", decode.optional(decode.float))
  use vitamin_d <- decode.field("vitamin_d", decode.optional(decode.float))
  use vitamin_e <- decode.field("vitamin_e", decode.optional(decode.float))
  use vitamin_k <- decode.field("vitamin_k", decode.optional(decode.float))
  use vitamin_b6 <- decode.field("vitamin_b6", decode.optional(decode.float))
  use vitamin_b12 <- decode.field("vitamin_b12", decode.optional(decode.float))
  use folate <- decode.field("folate", decode.optional(decode.float))
  use thiamin <- decode.field("thiamin", decode.optional(decode.float))
  use riboflavin <- decode.field("riboflavin", decode.optional(decode.float))
  use niacin <- decode.field("niacin", decode.optional(decode.float))
  use calcium <- decode.field("calcium", decode.optional(decode.float))
  use iron <- decode.field("iron", decode.optional(decode.float))
  use magnesium <- decode.field("magnesium", decode.optional(decode.float))
  use phosphorus <- decode.field("phosphorus", decode.optional(decode.float))
  use potassium <- decode.field("potassium", decode.optional(decode.float))
  use zinc <- decode.field("zinc", decode.optional(decode.float))
  decode.success(Micronutrients(
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

/// Decoder for CustomFood
pub fn custom_food_decoder() -> Decoder(CustomFood) {
  use id <- decode.field("id", decode.string)
  use user_id <- decode.field("user_id", decode.string)
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
    id: id,
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
