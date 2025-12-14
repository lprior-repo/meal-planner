/// Food log types and operations
///
/// Tracks user's food consumption with meal type and nutritional data.

import gleam/dynamic/decode.{type Decoder}
import gleam/json
import gleam/json.{type Json}
import gleam/option
import gleam/option.{type Option}
import meal_planner/id
import meal_planner/id.{type LogEntryId, type RecipeId}
import meal_planner/types/macros
import meal_planner/types/macros.{type Macros}
import meal_planner/types/micronutrients
import meal_planner/types/micronutrients.{type Micronutrients}

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
    id: LogEntryId,
    recipe_id: RecipeId,
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
// JSON Serialization
// ============================================================================

fn meal_type_to_string(m: MealType) -> String {
  case m {
    Breakfast -> "breakfast"
    Lunch -> "lunch"
    Dinner -> "dinner"
    Snack -> "snack"
  }
}

pub fn food_log_entry_to_json(e: FoodLogEntry) -> Json {
  let fields = [
    #("id", id.log_entry_id_to_json(e.id)),
    #("recipe_id", id.recipe_id_to_json(e.recipe_id)),
    #("recipe_name", json.string(e.recipe_name)),
    #("servings", json.float(e.servings)),
    #("macros", macros.to_json(e.macros)),
    #("meal_type", json.string(meal_type_to_string(e.meal_type))),
    #("logged_at", json.string(e.logged_at)),
  ]

  let fields = case e.micronutrients {
    Some(micros) -> [
      #("micronutrients", micronutrients.to_json(micros)),
      ..fields
    ]
    option.None -> fields
  }

  json.object(fields)
}

pub fn daily_log_to_json(d: DailyLog) -> Json {
  let fields = [
    #("date", json.string(d.date)),
    #("entries", json.array(d.entries, food_log_entry_to_json)),
    #("total_macros", macros.to_json(d.total_macros)),
  ]

  let fields = case d.total_micronutrients {
    Some(micros) -> [
      #("total_micronutrients", micronutrients.to_json(micros)),
      ..fields
    ]
    option.None -> fields
  }

  json.object(fields)
}

// ============================================================================
// JSON Deserialization
// ============================================================================

fn meal_type_decoder() -> Decoder(MealType) {
  use s <- decode.then(decode.string)
  case s {
    "breakfast" -> decode.success(Breakfast)
    "lunch" -> decode.success(Lunch)
    "dinner" -> decode.success(Dinner)
    "snack" -> decode.success(Snack)
    _ -> decode.failure(Snack, "MealType")
  }
}

pub fn food_log_entry_decoder() -> Decoder(FoodLogEntry) {
  use log_id <- decode.field("id", id.log_entry_id_decoder())
  use recipe_id <- decode.field("recipe_id", id.recipe_id_decoder())
  use recipe_name <- decode.field("recipe_name", decode.string)
  use servings <- decode.field("servings", decode.float)
  use macros_val <- decode.field("macros", macros.decoder())
  use micronutrients <- decode.field(
    "micronutrients",
    decode.optional(micronutrients.decoder()),
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

pub fn daily_log_decoder() -> Decoder(DailyLog) {
  use date <- decode.field("date", decode.string)
  use entries <- decode.field("entries", decode.list(food_log_entry_decoder()))
  use total_macros <- decode.field("total_macros", macros.decoder())
  use total_micronutrients <- decode.field(
    "total_micronutrients",
    decode.optional(micronutrients.decoder()),
  )
  decode.success(DailyLog(
    date: date,
    entries: entries,
    total_macros: total_macros,
    total_micronutrients: total_micronutrients,
  ))
}
