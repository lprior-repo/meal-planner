//// Utility functions for web handlers - helper functions for database operations,
//// conversions, and common operations used across multiple handlers

import gleam/float
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None}
import meal_planner/storage
import meal_planner/storage_optimized
import meal_planner/types.{
  type DailyLog, type FoodLogEntry, type Macros, type MealType, type Recipe,
  type SearchFilters, type UserProfile, Active, Breakfast, DailyLog, Dinner,
  Gain, Lose, Lunch, Macros, Maintain, Moderate, Sedentary, Snack, UserProfile,
}
import pog

// ============================================================================
// Database Operations
// ============================================================================

/// Load all recipes from storage
pub fn load_recipes(db: pog.Connection) -> List(Recipe) {
  case storage.get_all_recipes(db) {
    Ok([]) -> []
    Ok(recipes) -> recipes
    Error(_) -> []
  }
}

/// Load recipe by ID
pub fn load_recipe_by_id(db: pog.Connection, id: String) -> Result(Recipe, Nil) {
  case storage.get_recipe_by_id(db, id) {
    Ok(recipe) -> Ok(recipe)
    Error(_) -> Error(Nil)
  }
}

/// Load user profile from database
pub fn load_profile(db: pog.Connection) -> UserProfile {
  case storage.get_user_profile(db) {
    Ok(profile) -> profile
    Error(_) -> default_profile()
  }
}

/// Create default user profile
pub fn default_profile() -> UserProfile {
  UserProfile(
    id: "1",
    bodyweight: 154.0,
    activity_level: Moderate,
    goal: Maintain,
    meals_per_day: 3,
    micronutrient_goals: None,
  )
}

/// Search foods in database with filters
pub fn search_foods_filtered(
  db: pog.Connection,
  cache: storage_optimized.SearchCache,
  query: String,
  _filters: SearchFilters,
  limit: Int,
) -> #(
  storage_optimized.SearchCache,
  Result(List(storage.UsdaFood), storage.StorageError),
) {
  // Use the main search function - filtering is handled in storage_optimized
  storage_optimized.search_foods_cached(db, cache, query, limit)
}

/// Load food by FDC ID
pub fn load_food_by_id(
  db: pog.Connection,
  fdc_id: Int,
) -> Result(storage.UsdaFood, Nil) {
  case storage.get_food_by_id(db, fdc_id) {
    Ok(food) -> Ok(food)
    Error(_) -> Error(Nil)
  }
}

/// Load nutrients for a specific food
pub fn load_food_nutrients(
  db: pog.Connection,
  fdc_id: Int,
) -> List(storage.FoodNutrientValue) {
  case storage.get_food_nutrients(db, fdc_id) {
    Ok(nutrients) -> nutrients
    Error(_) -> []
  }
}

/// Get total count of foods in database
pub fn get_foods_count(db: pog.Connection) -> Int {
  case storage.get_foods_count(db) {
    Ok(count) -> count
    Error(_) -> 0
  }
}

/// Load daily log for a specific date
pub fn load_daily_log(db: pog.Connection, date: String) -> DailyLog {
  case storage.get_daily_log(db, date) {
    Ok(log) -> log
    Error(_) ->
      DailyLog(
        date: date,
        entries: [],
        total_macros: Macros(protein: 0.0, fat: 0.0, carbs: 0.0),
        total_micronutrients: option.None,
      )
  }
}

// ============================================================================
// JSON Conversions
// ============================================================================

/// Convert Macros to JSON
pub fn macros_to_json(m: Macros) -> json.Json {
  json.object([
    #("protein", json.float(m.protein)),
    #("fat", json.float(m.fat)),
    #("carbs", json.float(m.carbs)),
    #("calories", json.float(types.macros_calories(m))),
  ])
}

/// Convert Recipe to JSON
pub fn recipe_to_json(r: Recipe) -> json.Json {
  json.object([
    #("id", json.string(r.id)),
    #("name", json.string(r.name)),
    #(
      "ingredients",
      json.array(r.ingredients, fn(i) {
        json.object([
          #("name", json.string(i.name)),
          #("quantity", json.string(i.quantity)),
        ])
      }),
    ),
    #("instructions", json.array(r.instructions, json.string)),
    #("macros", macros_to_json(r.macros)),
    #("servings", json.int(r.servings)),
    #("category", json.string(r.category)),
  ])
}

/// Convert UserProfile to JSON
pub fn profile_to_json(p: UserProfile) -> json.Json {
  json.object([
    #("id", json.string(p.id)),
    #("bodyweight", json.float(p.bodyweight)),
    #("meals_per_day", json.int(p.meals_per_day)),
    #("activity_level", json.string(activity_level_to_string(p))),
    #("goal", json.string(goal_to_string(p))),
  ])
}

/// Convert USDA food to JSON
pub fn food_to_json(f: storage.UsdaFood) -> json.Json {
  json.object([
    #("fdc_id", json.int(f.fdc_id)),
    #("description", json.string(f.description)),
    #("data_type", json.string(f.data_type)),
    #("category", json.string(f.category)),
  ])
}

// ============================================================================
// String Conversions
// ============================================================================

/// Convert float to string with appropriate precision
pub fn float_to_string(f: Float) -> String {
  float.to_string(f)
}

/// Convert activity level to string
pub fn activity_level_to_string(p: UserProfile) -> String {
  case p.activity_level {
    Sedentary -> "sedentary"
    Moderate -> "moderate"
    Active -> "active"
  }
}

/// Convert goal to string
pub fn goal_to_string(p: UserProfile) -> String {
  case p.goal {
    Lose -> "lose"
    Maintain -> "maintain"
    Gain -> "gain"
  }
}

/// Convert meal type to string
pub fn meal_type_to_string(meal_type: MealType) -> String {
  case meal_type {
    Breakfast -> "breakfast"
    Lunch -> "lunch"
    Dinner -> "dinner"
    Snack -> "snack"
  }
}

/// Convert string to meal type
pub fn string_to_meal_type(s: String) -> MealType {
  case s {
    "breakfast" -> Breakfast
    "lunch" -> Lunch
    "dinner" -> Dinner
    "snack" -> Snack
    _ -> Lunch
  }
}

/// Convert integer to string
pub fn int_to_string(i: Int) -> String {
  int.to_string(i)
}

// ============================================================================
// ID Generation
// ============================================================================

/// Generate unique entry ID
pub fn generate_entry_id() -> String {
  let timestamp = current_timestamp()
  "entry-" <> timestamp
}

/// Get current timestamp as string
pub fn current_timestamp() -> String {
  let #(#(year, month, day), #(hour, minute, second)) = erlang_localtime()

  int_to_string(year)
  <> "-"
  <> pad_two(month)
  <> "-"
  <> pad_two(day)
  <> "T"
  <> pad_two(hour)
  <> ":"
  <> pad_two(minute)
  <> ":"
  <> pad_two(second)
}

/// Pad integer to two digits
fn pad_two(n: Int) -> String {
  case n < 10 {
    True -> "0" <> int_to_string(n)
    False -> int_to_string(n)
  }
}

@external(erlang, "calendar", "local_time")
fn erlang_localtime() -> #(#(Int, Int, Int), #(Int, Int, Int))

// ============================================================================
// Date/Time Utilities
// ============================================================================

/// Get today's date in YYYY-MM-DD format
pub fn get_today_date() -> String {
  let #(#(year, month, day), _) = erlang_localtime()

  int_to_string(year) <> "-" <> pad_two(month) <> "-" <> pad_two(day)
}

// ============================================================================
// Nutrient Utilities
// ============================================================================

/// Find specific nutrient by name
pub fn find_nutrient(
  nutrients: List(storage.FoodNutrientValue),
  name: String,
) -> Option(storage.FoodNutrientValue) {
  list.find(nutrients, fn(n) { n.nutrient_name == name })
  |> option.from_result
}

/// Format nutrient value with unit
pub fn format_nutrient(n: Option(storage.FoodNutrientValue)) -> String {
  case n {
    option.Some(nutrient) ->
      float_to_string(nutrient.amount) <> " " <> nutrient.unit
    option.None -> "N/A"
  }
}

/// Format calories (special case - no unit)
pub fn format_calories(n: Option(storage.FoodNutrientValue)) -> String {
  case n {
    option.Some(nutrient) -> float_to_string(nutrient.amount)
    option.None -> "0"
  }
}

// ============================================================================
// Macro Utilities
// ============================================================================

/// Sum macros from multiple food log entries
pub fn sum_macros(entries: List(FoodLogEntry)) -> Macros {
  list.fold(entries, Macros(protein: 0.0, fat: 0.0, carbs: 0.0), fn(acc, e) {
    Macros(
      protein: acc.protein +. e.macros.protein,
      fat: acc.fat +. e.macros.fat,
      carbs: acc.carbs +. e.macros.carbs,
    )
  })
}
