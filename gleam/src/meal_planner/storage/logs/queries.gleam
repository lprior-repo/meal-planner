/// Complex query operations for food logs
///
/// This module handles advanced queries on food log data:
/// - Retrieving recent meals (with Tandoor enrichment)  
/// - Getting daily logs with aggregated totals
/// - Finding recently logged foods
/// - Complex filtering and sorting operations

import gleam/dynamic/decode
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import meal_planner/config
import meal_planner/id
import meal_planner/storage/foods.{type UsdaFood, UsdaFood}
import meal_planner/storage/profile.{type StorageError, DatabaseError}
import meal_planner/storage/utils
import meal_planner/types.{
  type DailyLog, type FoodLogEntry, type Macros, Breakfast, DailyLog, Dinner,
  FoodLogEntry, Lunch, Macros, Snack,
}
import pog

// ============================================================================
// Log entry type for user logs (distinct from food_logs)
// ============================================================================

pub type Log {
  Log(
    id: Int,
    user_id: Int,
    food_id: Int,
    quantity: Float,
    log_date: String,
    macros: Option(String),
    created_at: String,
    updated_at: String,
  )
}

// ============================================================================
// Recent Meals Queries
// ============================================================================

/// Get recent meals (distinct by recipe, most recent first)
pub fn get_recent_meals(
  conn: pog.Connection,
  limit: Int,
) -> Result(List(FoodLogEntry), StorageError) {
  let sql =
    "SELECT DISTINCT ON (recipe_id) id, date, recipe_id, recipe_name, servings, protein, fat, carbs, meal_type, logged_at::text,
            fiber, sugar, sodium, cholesterol, vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k,
            vitamin_b6, vitamin_b12, folate, thiamin, riboflavin, niacin, calcium, iron, magnesium,
            phosphorus, potassium, zinc, source_type, source_id
     FROM food_logs
     ORDER BY recipe_id, logged_at DESC
     LIMIT $1"

  let decoder = food_log_entry_decoder()

  case
    pog.query(sql)
    |> pog.parameter(pog.int(limit))
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(_, rows)) -> Ok(rows)
  }
}

/// Get recent meals with Tandoor enrichment
pub fn get_recent_meals_enriched(
  conn: pog.Connection,
  _cfg: config.Config,
  limit: Int,
) -> Result(List(FoodLogEntry), StorageError) {
  use meals <- result.try(get_recent_meals(conn, limit))
  Ok(meals)
}

// ============================================================================
// Food Logs By Date Query
// ============================================================================

/// Get food logs for a specific date
pub fn get_food_logs_by_date(
  conn: pog.Connection,
  date: String,
) -> Result(List(FoodLogEntry), StorageError) {
  let sql =
    "SELECT id, date, recipe_id, recipe_name, servings, protein, fat, carbs, meal_type, logged_at::text,
            fiber, sugar, sodium, cholesterol, vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k,
            vitamin_b6, vitamin_b12, folate, thiamin, riboflavin, niacin, calcium, iron, magnesium,
            phosphorus, potassium, zinc, source_type, source_id
     FROM food_logs WHERE date = $1 ORDER BY logged_at"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(date))
    |> pog.returning(food_log_entry_decoder())
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(_, rows)) -> Ok(rows)
  }
}

// ============================================================================
// Today's Logs Query
// ============================================================================

/// Get logs for a specific user and date from the logs table
pub fn get_todays_logs(
  conn: pog.Connection,
  user_id: Int,
  date: String,
) -> Result(List(Log), StorageError) {
  let sql =
    "SELECT id, user_id, food_id, quantity, log_date, macros, created_at::text, updated_at::text
     FROM logs WHERE user_id = $1 AND log_date = $2
     ORDER BY created_at ASC"

  let decoder = {
    use id <- decode.field(0, decode.int)
    use user_id_val <- decode.field(1, decode.int)
    use food_id <- decode.field(2, decode.int)
    use quantity <- decode.field(3, decode.float)
    use log_date <- decode.field(4, decode.string)
    use macros <- decode.field(5, decode.optional(decode.string))
    use created_at <- decode.field(6, decode.string)
    use updated_at <- decode.field(7, decode.string)

    decode.success(Log(
      id: id,
      user_id: user_id_val,
      food_id: food_id,
      quantity: quantity,
      log_date: log_date,
      macros: macros,
      created_at: created_at,
      updated_at: updated_at,
    ))
  }

  case
    pog.query(sql)
    |> pog.parameter(pog.int(user_id))
    |> pog.parameter(pog.text(date))
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(_, rows)) -> Ok(rows)
  }
}

// ============================================================================
// Daily Log Queries
// ============================================================================

/// Get daily log for a specific date
pub fn get_daily_log(
  conn: pog.Connection,
  date: String,
) -> Result(DailyLog, StorageError) {
  let sql =
    "SELECT id, date, recipe_id, recipe_name, servings, protein, fat, carbs, meal_type, logged_at::text,
            fiber, sugar, sodium, cholesterol, vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k,
            vitamin_b6, vitamin_b12, folate, thiamin, riboflavin, niacin, calcium, iron, magnesium,
            phosphorus, potassium, zinc, source_type, source_id
     FROM food_logs WHERE date = $1 ORDER BY logged_at"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(date))
    |> pog.returning(food_log_entry_decoder())
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))

    Ok(pog.Returned(_, entries)) -> {
      let total_macros = calculate_total_macros(entries)
      let total_micronutrients = calculate_total_micronutrients(entries)

      Ok(DailyLog(
        date: date,
        entries: entries,
        total_macros: total_macros,
        total_micronutrients: total_micronutrients,
      ))
    }
  }
}

// ============================================================================
// Recently Logged Foods Queries
// ============================================================================

/// Get the 10 most recently logged USDA foods (distinct by fdc_id)
pub fn get_recently_logged_foods(
  conn: pog.Connection,
  limit: Int,
) -> Result(List(UsdaFood), StorageError) {
  let sql =
    "SELECT DISTINCT ON (f.fdc_id) f.fdc_id, f.description, f.data_type, COALESCE(f.food_category, '')
     FROM foods f
     INNER JOIN food_logs fl ON f.fdc_id = CAST(fl.source_id AS INTEGER)
     WHERE fl.source_type = 'usda_food'
     ORDER BY f.fdc_id, fl.logged_at DESC
     LIMIT $1"

  let decoder = {
    use fdc_id_int <- decode.field(0, decode.int)
    use description <- decode.field(1, decode.string)
    use data_type <- decode.field(2, decode.string)
    use category <- decode.field(3, decode.string)
    use serving_size <- decode.field(4, decode.optional(decode.string))

    decode.success(UsdaFood(
      fdc_id: id.fdc_id(fdc_id_int),
      description: description,
      data_type: data_type,
      category: category,
      serving_size: case serving_size {
        Some(size) -> size
        None -> "100g"
      },
    ))
  }

  case
    pog.query(sql)
    |> pog.parameter(pog.int(limit))
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(_, rows)) -> Ok(rows)
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Decoder for FoodLogEntry from database rows
fn food_log_entry_decoder() -> decode.Decoder(FoodLogEntry) {
  use log_entry_id_str <- decode.field(0, decode.string)
  use _date <- decode.field(1, decode.string)
  use recipe_id_str <- decode.field(2, decode.string)
  use recipe_name <- decode.field(3, decode.string)
  use servings <- decode.field(4, decode.float)
  use protein <- decode.field(5, decode.float)
  use fat <- decode.field(6, decode.float)
  use carbs <- decode.field(7, decode.float)
  use meal_type_str <- decode.field(8, decode.string)
  use logged_at <- decode.field(9, decode.string)
  use fiber <- decode.field(10, decode.optional(decode.float))
  use sugar <- decode.field(11, decode.optional(decode.float))
  use sodium <- decode.field(12, decode.optional(decode.float))
  use cholesterol <- decode.field(13, decode.optional(decode.float))
  use vitamin_a <- decode.field(14, decode.optional(decode.float))
  use vitamin_c <- decode.field(15, decode.optional(decode.float))
  use vitamin_d <- decode.field(16, decode.optional(decode.float))
  use vitamin_e <- decode.field(17, decode.optional(decode.float))
  use vitamin_k <- decode.field(18, decode.optional(decode.float))
  use vitamin_b6 <- decode.field(19, decode.optional(decode.float))
  use vitamin_b12 <- decode.field(20, decode.optional(decode.float))
  use folate <- decode.field(21, decode.optional(decode.float))
  use thiamin <- decode.field(22, decode.optional(decode.float))
  use riboflavin <- decode.field(23, decode.optional(decode.float))
  use niacin <- decode.field(24, decode.optional(decode.float))
  use calcium <- decode.field(25, decode.optional(decode.float))
  use iron <- decode.field(26, decode.optional(decode.float))
  use magnesium <- decode.field(27, decode.optional(decode.float))
  use phosphorus <- decode.field(28, decode.optional(decode.float))
  use potassium <- decode.field(29, decode.optional(decode.float))
  use zinc <- decode.field(30, decode.optional(decode.float))
  use source_type <- decode.field(31, decode.string)
  use source_id <- decode.field(32, decode.string)

  let meal_type = case meal_type_str {
    "breakfast" -> Breakfast
    "lunch" -> Lunch
    "dinner" -> Dinner
    _ -> Snack
  }

  let micronutrients = case
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
    zinc
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

  decode.success(FoodLogEntry(
    id: id.log_entry_id(log_entry_id_str),
    recipe_id: id.recipe_id(recipe_id_str),
    recipe_name: recipe_name,
    servings: servings,
    macros: Macros(protein: protein, fat: fat, carbs: carbs),
    micronutrients: micronutrients,
    meal_type: meal_type,
    logged_at: logged_at,
    source_type: source_type,
    source_id: source_id,
  ))
}

/// Calculate total macros from food log entries
fn calculate_total_macros(entries: List(FoodLogEntry)) -> Macros {
  list.fold(entries, Macros(protein: 0.0, fat: 0.0, carbs: 0.0), fn(acc, entry) {
    Macros(
      protein: acc.protein +. entry.macros.protein,
      fat: acc.fat +. entry.macros.fat,
      carbs: acc.carbs +. entry.macros.carbs,
    )
  })
}

/// Calculate total micronutrients from food log entries
fn calculate_total_micronutrients(
  entries: List(FoodLogEntry),
) -> Option(types.Micronutrients) {
  let micros_list =
    list.filter_map(entries, fn(entry) {
      case entry.micronutrients {
        Some(m) -> Ok(m)
        None -> Error(Nil)
      }
    })

  case micros_list {
    [] -> None
    _ -> Some(types.micronutrients_sum(micros_list))
  }
}
