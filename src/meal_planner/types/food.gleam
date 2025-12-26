//// Food and food log types for the meal planner application.
////
//// This module contains:
//// - CustomFood: User-defined foods (defined in custom_food.gleam, but referenced here)
//// - FoodSource: Type-safe food source tracking
//// - FoodSearchResult/Response/Error/Filter: Food search functionality
//// - MealType: Meal type enumeration (breakfast, lunch, dinner, snack)
//// - FoodLogEntry: Individual food log entries
//// - DailyLog: Daily aggregate food logs

import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import meal_planner/id.{
  type CustomFoodId, type FdcId, type LogEntryId, type RecipeId, type UserId,
  log_entry_id_decoder, log_entry_id_to_json, recipe_id_decoder,
  recipe_id_to_json,
}
import meal_planner/types/custom_food.{type CustomFood}
import meal_planner/types/macros.{
  type Macros, decoder as macros_decoder, to_json as macros_to_json,
}
import meal_planner/types/micronutrients.{
  type Micronutrients, decoder as micronutrients_decoder,
  to_json as micronutrients_to_json,
}

// ============================================================================
// Food Source Types
// ============================================================================

/// Type-safe food source tracking for food logs
/// Prevents mismatched source_type and source_id through compile-time checking
pub type FoodSource {
  /// Food from recipe database
  RecipeSource(recipe_id: RecipeId)
  /// Food from custom_foods table (includes user_id for authorization)
  CustomFoodSource(custom_food_id: CustomFoodId, user_id: UserId)
  /// Food from USDA database (foods/food_nutrients tables)
  UsdaFoodSource(fdc_id: FdcId)
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
    fdc_id: FdcId,
    description: String,
    data_type: String,
    category: String,
    serving_size: String,
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
// Meal Type
// ============================================================================

/// Meal type for food logging
pub type MealType {
  Breakfast
  Lunch
  Dinner
  Snack
}

// ============================================================================
// Food Log Types
// ============================================================================

/// A single food log entry
pub type FoodLogEntry {
  FoodLogEntry(
    id: LogEntryId,
    recipe_id: RecipeId,
    recipe_name: String,
    servings: Float,
    macros: Macros,
    micronutrients: Option(Micronutrients),
    meal_type: MealType,
    logged_at: String,
    // Source tracking (from schema 006)
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
    #("id", log_entry_id_to_json(e.id)),
    #("recipe_id", recipe_id_to_json(e.recipe_id)),
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

// ============================================================================
// JSON Decoding
// ============================================================================

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

/// Decoder for FoodLogEntry
pub fn food_log_entry_decoder() -> Decoder(FoodLogEntry) {
  use log_id <- decode.field("id", log_entry_id_decoder())
  use recipe_id <- decode.field("recipe_id", recipe_id_decoder())
  use recipe_name <- decode.field("recipe_name", decode.string)
  use servings <- decode.field("servings", decode.float)
  use macros_val <- decode.field("macros", macros_decoder())
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
    macros: macros_val,
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
