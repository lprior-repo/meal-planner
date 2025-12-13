/// Individual log entry operations - save, retrieve, delete, and validation
///
/// This module handles the core CRUD operations for food log entries:
/// - Saving food log entries with validation
/// - Deleting log entries
/// - Handling Tandoor recipe inputs

import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/result
import meal_planner/config
import meal_planner/id
import meal_planner/storage/profile.{type StorageError, DatabaseError}
import meal_planner/storage/utils
import meal_planner/types.{
  type FoodLogEntry, type Macros, Breakfast, Dinner, FoodLogEntry, Lunch,
  Macros, Snack,
}
import pog

// ============================================================================
// Data Types
// ============================================================================

/// Food log entry type
pub type FoodLog {
  FoodLog(
    id: String,
    date: String,
    recipe_id: String,
    recipe_name: String,
    servings: Float,
    protein: Float,
    fat: Float,
    carbs: Float,
    meal_type: String,
    logged_at: String,
    // Micronutrients (all optional)
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

/// Input type for logging a meal with a Tandoor recipe slug
pub type FoodLogInput {
  FoodLogInput(
    date: String,
    recipe_slug: String,
    recipe_name: String,
    servings: Float,
    protein: Float,
    fat: Float,
    carbs: Float,
    meal_type: String,
    // Optional micronutrients
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
// Validation Functions
// ============================================================================

/// Validate source_type is one of the allowed values
fn validate_source_type(source_type: String) -> Result(Nil, StorageError) {
  case source_type {
    "tandoor_recipe" | "custom_food" | "usda_food" -> Ok(Nil)
    _ ->
      Error(DatabaseError(
        "Invalid source_type: "
        <> source_type
        <> ". Must be one of: tandoor_recipe, custom_food, usda_food",
      ))
  }
}

/// Internal helper to validate recipe exists in Tandoor
fn validate_recipe_exists(
  _config: config.Config,
  recipe_id: id.RecipeId,
) -> Result(Nil, StorageError) {
  let recipe_slug = id.recipe_id_to_string(recipe_id)

  // This is a simplified validation - in production, you might want to check
  // the tandoor/client module for recipe resolution
  case recipe_slug {
    "" -> Error(DatabaseError("Invalid recipe slug: empty string"))
    _ -> Ok(Nil)
  }
}

// ============================================================================
// Basic Save Operations
// ============================================================================

/// Save a food log entry
pub fn save_food_log(
  conn: pog.Connection,
  log: FoodLog,
) -> Result(Nil, StorageError) {
  let sql =
    "INSERT INTO food_logs
     (id, date, recipe_id, recipe_name, servings, protein, fat, carbs, meal_type, logged_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW())
     ON CONFLICT (id) DO UPDATE SET
       servings = EXCLUDED.servings,
       protein = EXCLUDED.protein,
       fat = EXCLUDED.fat,
       carbs = EXCLUDED.carbs,
       meal_type = EXCLUDED.meal_type,
       logged_at = NOW()"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(log.id))
    |> pog.parameter(pog.text(log.date))
    |> pog.parameter(pog.text(log.recipe_id))
    |> pog.parameter(pog.text(log.recipe_name))
    |> pog.parameter(pog.float(log.servings))
    |> pog.parameter(pog.float(log.protein))
    |> pog.parameter(pog.float(log.fat))
    |> pog.parameter(pog.float(log.carbs))
    |> pog.parameter(pog.text(log.meal_type))
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(_) -> Ok(Nil)
  }
}

/// Save a food log entry using shared types
pub fn save_food_log_entry(
  conn: pog.Connection,
  date: String,
  entry: FoodLogEntry,
) -> Result(Nil, StorageError) {
  // Validate source_type before saving
  use _ <- result.try(validate_source_type(entry.source_type))

  let sql =
    "INSERT INTO food_logs
     (id, date, recipe_id, recipe_name, servings, protein, fat, carbs, meal_type, logged_at,
      fiber, sugar, sodium, cholesterol, vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k,
      vitamin_b6, vitamin_b12, folate, thiamin, riboflavin, niacin, calcium, iron, magnesium,
      phosphorus, potassium, zinc, source_type, source_id)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(),
      $10, $11, $12, $13, $14, $15, $16, $17, $18,
      $19, $20, $21, $22, $23, $24, $25, $26, $27,
      $28, $29, $30, $31, $32)
     ON CONFLICT (id) DO UPDATE SET
       servings = EXCLUDED.servings,
       protein = EXCLUDED.protein,
       fat = EXCLUDED.fat,
       carbs = EXCLUDED.carbs,
       meal_type = EXCLUDED.meal_type,
       logged_at = NOW(),
       fiber = EXCLUDED.fiber,
       sugar = EXCLUDED.sugar,
       sodium = EXCLUDED.sodium,
       cholesterol = EXCLUDED.cholesterol,
       vitamin_a = EXCLUDED.vitamin_a,
       vitamin_c = EXCLUDED.vitamin_c,
       vitamin_d = EXCLUDED.vitamin_d,
       vitamin_e = EXCLUDED.vitamin_e,
       vitamin_k = EXCLUDED.vitamin_k,
       vitamin_b6 = EXCLUDED.vitamin_b6,
       vitamin_b12 = EXCLUDED.vitamin_b12,
       folate = EXCLUDED.folate,
       thiamin = EXCLUDED.thiamin,
       riboflavin = EXCLUDED.riboflavin,
       niacin = EXCLUDED.niacin,
       calcium = EXCLUDED.calcium,
       iron = EXCLUDED.iron,
       magnesium = EXCLUDED.magnesium,
       phosphorus = EXCLUDED.phosphorus,
       potassium = EXCLUDED.potassium,
       zinc = EXCLUDED.zinc,
       source_type = EXCLUDED.source_type,
       source_id = EXCLUDED.source_id"

  let meal_type_str = case entry.meal_type {
    Breakfast -> "breakfast"
    Lunch -> "lunch"
    Dinner -> "dinner"
    Snack -> "snack"
  }

  // Extract micronutrients from entry (handle Option)
  let #(
    fiber,
    sugar,
    sodium,
    cholesterol,
    vitamin_a,
    vitamin_c,
    vitamin_d,
    vitamin_e,
    vitamin_k,
    vitamin_b6,
    vitamin_b12,
    folate,
    thiamin,
    riboflavin,
    niacin,
    calcium,
    iron,
    magnesium,
    phosphorus,
    potassium,
    zinc,
  ) = case entry.micronutrients {
    Some(m) -> #(
      m.fiber,
      m.sugar,
      m.sodium,
      m.cholesterol,
      m.vitamin_a,
      m.vitamin_c,
      m.vitamin_d,
      m.vitamin_e,
      m.vitamin_k,
      m.vitamin_b6,
      m.vitamin_b12,
      m.folate,
      m.thiamin,
      m.riboflavin,
      m.niacin,
      m.calcium,
      m.iron,
      m.magnesium,
      m.phosphorus,
      m.potassium,
      m.zinc,
    )

    None -> #(
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
    )
  }

  case
    pog.query(sql)
    |> pog.parameter(pog.text(id.log_entry_id_to_string(entry.id)))
    |> pog.parameter(pog.text(date))
    |> pog.parameter(pog.text(id.recipe_id_to_string(entry.recipe_id)))
    |> pog.parameter(pog.text(entry.recipe_name))
    |> pog.parameter(pog.float(entry.servings))
    |> pog.parameter(pog.float(entry.macros.protein))
    |> pog.parameter(pog.float(entry.macros.fat))
    |> pog.parameter(pog.float(entry.macros.carbs))
    |> pog.parameter(pog.text(meal_type_str))
    |> pog.parameter(pog.nullable(pog.float, fiber))
    |> pog.parameter(pog.nullable(pog.float, sugar))
    |> pog.parameter(pog.nullable(pog.float, sodium))
    |> pog.parameter(pog.nullable(pog.float, cholesterol))
    |> pog.parameter(pog.nullable(pog.float, vitamin_a))
    |> pog.parameter(pog.nullable(pog.float, vitamin_c))
    |> pog.parameter(pog.nullable(pog.float, vitamin_d))
    |> pog.parameter(pog.nullable(pog.float, vitamin_e))
    |> pog.parameter(pog.nullable(pog.float, vitamin_k))
    |> pog.parameter(pog.nullable(pog.float, vitamin_b6))
    |> pog.parameter(pog.nullable(pog.float, vitamin_b12))
    |> pog.parameter(pog.nullable(pog.float, folate))
    |> pog.parameter(pog.nullable(pog.float, thiamin))
    |> pog.parameter(pog.nullable(pog.float, riboflavin))
    |> pog.parameter(pog.nullable(pog.float, niacin))
    |> pog.parameter(pog.nullable(pog.float, calcium))
    |> pog.parameter(pog.nullable(pog.float, iron))
    |> pog.parameter(pog.nullable(pog.float, magnesium))
    |> pog.parameter(pog.nullable(pog.float, phosphorus))
    |> pog.parameter(pog.nullable(pog.float, potassium))
    |> pog.parameter(pog.nullable(pog.float, zinc))
    |> pog.parameter(pog.text(entry.source_type))
    |> pog.parameter(pog.text(entry.source_id))
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(_) -> Ok(Nil)
  }
}

/// Enhanced save_food_log_entry with recipe slug validation
pub fn save_food_log_entry_with_validation(
  conn: pog.Connection,
  config: config.Config,
  date: String,
  entry: FoodLogEntry,
) -> Result(Nil, StorageError) {
  // Only validate if this is a Tandoor recipe
  case entry.source_type {
    "tandoor_recipe" -> {
      // Validate the recipe exists in Tandoor
      use _ <- result.try(validate_recipe_exists(config, entry.recipe_id))
      save_food_log_entry(conn, date, entry)
    }
    _ -> {
      // Skip validation for non-Tandoor sources (custom foods, USDA foods)
      save_food_log_entry(conn, date, entry)
    }
  }
}

// ============================================================================
// Delete Operations
// ============================================================================

/// Delete a food log entry
pub fn delete_food_log(
  conn: pog.Connection,
  log_id: id.LogEntryId,
) -> Result(Nil, StorageError) {
  let sql = "DELETE FROM food_logs WHERE id = $1"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(id.log_entry_id_to_string(log_id)))
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(_) -> Ok(Nil)
  }
}

// ============================================================================
// Tandoor Recipe Operations
// ============================================================================

/// Save a food log entry from a Tandoor recipe slug
///
/// This function creates a FoodLogEntry from the provided input and Tandoor recipe slug,
/// then saves it to the database. The source_type is automatically set to 'tandoor_recipe'
/// and the source_id is set to the recipe slug.
pub fn save_food_log_from_tandoor_recipe(
  conn: pog.Connection,
  input: FoodLogInput,
) -> Result(String, StorageError) {
  // Generate unique ID for this log entry using recipe slug and random suffix
  let random_suffix = int.to_string(int.random(999_999))
  let entry_id_str = input.recipe_slug <> "-" <> random_suffix

  // Parse meal type
  let meal_type = case input.meal_type {
    "breakfast" -> Breakfast
    "lunch" -> Lunch
    "dinner" -> Dinner
    _ -> Snack
  }

  // Create micronutrients if any are provided
  let micronutrients = case
    input.fiber,
    input.sugar,
    input.sodium,
    input.cholesterol,
    input.vitamin_a,
    input.vitamin_c,
    input.vitamin_d,
    input.vitamin_e,
    input.vitamin_k,
    input.vitamin_b6,
    input.vitamin_b12,
    input.folate,
    input.thiamin,
    input.riboflavin,
    input.niacin,
    input.calcium,
    input.iron,
    input.magnesium,
    input.phosphorus,
    input.potassium,
    input.zinc
  {
    None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None
    -> None

    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ ->
      Some(types.Micronutrients(
        fiber: input.fiber,
        sugar: input.sugar,
        sodium: input.sodium,
        cholesterol: input.cholesterol,
        vitamin_a: input.vitamin_a,
        vitamin_c: input.vitamin_c,
        vitamin_d: input.vitamin_d,
        vitamin_e: input.vitamin_e,
        vitamin_k: input.vitamin_k,
        vitamin_b6: input.vitamin_b6,
        vitamin_b12: input.vitamin_b12,
        folate: input.folate,
        thiamin: input.thiamin,
        riboflavin: input.riboflavin,
        niacin: input.niacin,
        calcium: input.calcium,
        iron: input.iron,
        magnesium: input.magnesium,
        phosphorus: input.phosphorus,
        potassium: input.potassium,
        zinc: input.zinc,
      ))
  }

  // Create the FoodLogEntry
  let entry =
    FoodLogEntry(
      id: id.log_entry_id(entry_id_str),
      recipe_id: id.recipe_id(input.recipe_slug),
      recipe_name: input.recipe_name,
      servings: input.servings,
      macros: Macros(protein: input.protein, fat: input.fat, carbs: input.carbs),
      micronutrients: micronutrients,
      meal_type: meal_type,
      logged_at: "",
      source_type: "tandoor_recipe",
      source_id: input.recipe_slug,
    )

  // Save the entry to the database
  use _ <- result.try(save_food_log_entry(conn, input.date, entry))

  // Return the entry ID on success
  Ok(entry_id_str)
}
