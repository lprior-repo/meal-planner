//// Shared types for the meal planner application.
//// These types work on both JavaScript (client) and Erlang (server) targets.

import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}

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

/// Empty micronutrients (all None)
pub fn micronutrients_zero() -> Micronutrients {
  Micronutrients(
    fiber: None,
    sugar: None,
    sodium: None,
    cholesterol: None,
    vitamin_a: None,
    vitamin_c: None,
    vitamin_d: None,
    vitamin_e: None,
    vitamin_k: None,
    vitamin_b6: None,
    vitamin_b12: None,
    folate: None,
    thiamin: None,
    riboflavin: None,
    niacin: None,
    calcium: None,
    iron: None,
    magnesium: None,
    phosphorus: None,
    potassium: None,
    zinc: None,
  )
}

/// Helper to add optional floats
fn add_optional(a: Option(Float), b: Option(Float)) -> Option(Float) {
  case a, b {
    Some(x), Some(y) -> Some(x +. y)
    Some(x), None -> Some(x)
    None, Some(y) -> Some(y)
    None, None -> None
  }
}

/// Helper to scale optional floats
fn scale_optional(v: Option(Float), factor: Float) -> Option(Float) {
  case v {
    Some(x) -> Some(x *. factor)
    None -> None
  }
}

/// Add two Micronutrients together
pub fn micronutrients_add(
  a: Micronutrients,
  b: Micronutrients,
) -> Micronutrients {
  Micronutrients(
    fiber: add_optional(a.fiber, b.fiber),
    sugar: add_optional(a.sugar, b.sugar),
    sodium: add_optional(a.sodium, b.sodium),
    cholesterol: add_optional(a.cholesterol, b.cholesterol),
    vitamin_a: add_optional(a.vitamin_a, b.vitamin_a),
    vitamin_c: add_optional(a.vitamin_c, b.vitamin_c),
    vitamin_d: add_optional(a.vitamin_d, b.vitamin_d),
    vitamin_e: add_optional(a.vitamin_e, b.vitamin_e),
    vitamin_k: add_optional(a.vitamin_k, b.vitamin_k),
    vitamin_b6: add_optional(a.vitamin_b6, b.vitamin_b6),
    vitamin_b12: add_optional(a.vitamin_b12, b.vitamin_b12),
    folate: add_optional(a.folate, b.folate),
    thiamin: add_optional(a.thiamin, b.thiamin),
    riboflavin: add_optional(a.riboflavin, b.riboflavin),
    niacin: add_optional(a.niacin, b.niacin),
    calcium: add_optional(a.calcium, b.calcium),
    iron: add_optional(a.iron, b.iron),
    magnesium: add_optional(a.magnesium, b.magnesium),
    phosphorus: add_optional(a.phosphorus, b.phosphorus),
    potassium: add_optional(a.potassium, b.potassium),
    zinc: add_optional(a.zinc, b.zinc),
  )
}

/// Scale micronutrients by a factor
pub fn micronutrients_scale(m: Micronutrients, factor: Float) -> Micronutrients {
  Micronutrients(
    fiber: scale_optional(m.fiber, factor),
    sugar: scale_optional(m.sugar, factor),
    sodium: scale_optional(m.sodium, factor),
    cholesterol: scale_optional(m.cholesterol, factor),
    vitamin_a: scale_optional(m.vitamin_a, factor),
    vitamin_c: scale_optional(m.vitamin_c, factor),
    vitamin_d: scale_optional(m.vitamin_d, factor),
    vitamin_e: scale_optional(m.vitamin_e, factor),
    vitamin_k: scale_optional(m.vitamin_k, factor),
    vitamin_b6: scale_optional(m.vitamin_b6, factor),
    vitamin_b12: scale_optional(m.vitamin_b12, factor),
    folate: scale_optional(m.folate, factor),
    thiamin: scale_optional(m.thiamin, factor),
    riboflavin: scale_optional(m.riboflavin, factor),
    niacin: scale_optional(m.niacin, factor),
    calcium: scale_optional(m.calcium, factor),
    iron: scale_optional(m.iron, factor),
    magnesium: scale_optional(m.magnesium, factor),
    phosphorus: scale_optional(m.phosphorus, factor),
    potassium: scale_optional(m.potassium, factor),
    zinc: scale_optional(m.zinc, factor),
  )
}

/// Sum a list of micronutrients
pub fn micronutrients_sum(micros: List(Micronutrients)) -> Micronutrients {
  list.fold(micros, micronutrients_zero(), micronutrients_add)
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

/// Type-safe food source tracking for food logs
/// Prevents mismatched source_type and source_id through compile-time checking
pub type FoodSource {
  /// Food from recipes table
  RecipeSource(recipe_id: String)
  /// Food from custom_foods table (includes user_id for authorization)
  CustomFoodSource(custom_food_id: String, user_id: String)
  /// Food from USDA database (foods/food_nutrients tables)
  UsdaFoodSource(fdc_id: Int)
}

// ============================================================================
// Food Search Types
// ============================================================================

/// Unified search result with source identification
pub type FoodSearchResult {
  /// Custom food result (user-created)
  CustomFoodResult(food: CustomFood)
  /// USDA food result (from national database)
  UsdaFoodResult(
    fdc_id: Int,
    description: String,
    data_type: String,
    category: String,
  )
}

/// Search response wrapper with metadata
pub type FoodSearchResponse {
  FoodSearchResponse(
    results: List(FoodSearchResult),
    total_count: Int,
    custom_count: Int,
    usda_count: Int,
  )
}

/// Search error types
pub type FoodSearchError {
  DatabaseError(String)
  InvalidQuery(String)
}

/// Search filter options
pub type SearchFilters {
  SearchFilters(
    verified_only: Bool,
    // Show only verified USDA foundation/SR legacy foods
    branded_only: Bool,
    // Show only branded commercial foods
    category: Option(String),
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
    micronutrients: Option(Micronutrients),
    meal_type: MealType,
    logged_at: String,
    // Source tracking (from migration 006)
    source_type: String,
    source_id: String,
  )
}

/// Daily food log with all entries
pub type DailyLog {
  DailyLog(
    date: String,
    entries: List(FoodLogEntry),
    total_macros: Macros,
    total_micronutrients: Option(Micronutrients),
  )
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
  // Helper to convert Option(Float) to Json
  let optional_float = fn(opt) {
    case opt {
      Some(v) -> json.float(v)
      None -> json.null()
    }
  }

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
  let fields = [
    #("id", json.string(e.id)),
    #("recipe_id", json.string(e.recipe_id)),
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

pub fn custom_food_to_json(f: CustomFood) -> Json {
  let fields = [
    #("id", json.string(f.id)),
    #("user_id", json.string(f.user_id)),
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

pub fn food_search_result_to_json(r: FoodSearchResult) -> Json {
  case r {
    CustomFoodResult(food) ->
      json.object([
        #("type", json.string("custom")),
        #("data", custom_food_to_json(food)),
      ])
    UsdaFoodResult(fdc_id, description, data_type, category) ->
      json.object([
        #("type", json.string("usda")),
        #(
          "data",
          json.object([
            #("fdc_id", json.int(fdc_id)),
            #("description", json.string(description)),
            #("data_type", json.string(data_type)),
            #("category", json.string(category)),
          ]),
        ),
      ])
  }
}

pub fn food_search_response_to_json(resp: FoodSearchResponse) -> Json {
  json.object([
    #("results", json.array(resp.results, food_search_result_to_json)),
    #("total_count", json.int(resp.total_count)),
    #("custom_count", json.int(resp.custom_count)),
    #("usda_count", json.int(resp.usda_count)),
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
  use fiber <- decode.optional_field("fiber", decode.float)
  use sugar <- decode.optional_field("sugar", decode.float)
  use sodium <- decode.optional_field("sodium", decode.float)
  use cholesterol <- decode.optional_field("cholesterol", decode.float)
  use vitamin_a <- decode.optional_field("vitamin_a", decode.float)
  use vitamin_c <- decode.optional_field("vitamin_c", decode.float)
  use vitamin_d <- decode.optional_field("vitamin_d", decode.float)
  use vitamin_e <- decode.optional_field("vitamin_e", decode.float)
  use vitamin_k <- decode.optional_field("vitamin_k", decode.float)
  use vitamin_b6 <- decode.optional_field("vitamin_b6", decode.float)
  use vitamin_b12 <- decode.optional_field("vitamin_b12", decode.float)
  use folate <- decode.optional_field("folate", decode.float)
  use thiamin <- decode.optional_field("thiamin", decode.float)
  use riboflavin <- decode.optional_field("riboflavin", decode.float)
  use niacin <- decode.optional_field("niacin", decode.float)
  use calcium <- decode.optional_field("calcium", decode.float)
  use iron <- decode.optional_field("iron", decode.float)
  use magnesium <- decode.optional_field("magnesium", decode.float)
  use phosphorus <- decode.optional_field("phosphorus", decode.float)
  use potassium <- decode.optional_field("potassium", decode.float)
  use zinc <- decode.optional_field("zinc", decode.float)
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
  use micronutrients <- decode.field(
    "micronutrients",
    decode.optional(micronutrients_decoder()),
  )
  use meal_type <- decode.field("meal_type", meal_type_decoder())
  use logged_at <- decode.field("logged_at", decode.string)
  use source_type <- decode.field("source_type", decode.string)
  use source_id <- decode.field("source_id", decode.string)
  decode.success(FoodLogEntry(
    id: id,
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

/// Decoder for DailyLog
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
