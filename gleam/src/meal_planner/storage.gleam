/// SQLite storage module for nutrition data persistence

import gleam/dynamic/decode
import meal_planner/ncp.{type NutritionData, type NutritionGoals, NutritionData, NutritionGoals}
import sqlight

/// Error type for storage operations
pub type StorageError {
  NotFound
  DatabaseError(String)
}

/// Open a connection to a SQLite database and run a function with it
/// Connection is automatically closed after the function completes
pub fn with_connection(path: String, f: fn(sqlight.Connection) -> a) -> a {
  sqlight.with_connection(path, f)
}

/// Initialize the database schema
pub fn init_db(conn: sqlight.Connection) -> Result(Nil, StorageError) {
  let create_nutrition_table =
    "CREATE TABLE IF NOT EXISTS nutrition_state (
      date TEXT PRIMARY KEY,
      protein REAL NOT NULL,
      fat REAL NOT NULL,
      carbs REAL NOT NULL,
      calories REAL NOT NULL
    )"

  let create_goals_table =
    "CREATE TABLE IF NOT EXISTS nutrition_goals (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      daily_protein REAL NOT NULL,
      daily_fat REAL NOT NULL,
      daily_carbs REAL NOT NULL,
      daily_calories REAL NOT NULL
    )"

  case sqlight.exec(create_nutrition_table, on: conn) {
    Error(e) -> Error(DatabaseError(e.message))
    Ok(Nil) ->
      case sqlight.exec(create_goals_table, on: conn) {
        Error(e) -> Error(DatabaseError(e.message))
        Ok(Nil) -> Ok(Nil)
      }
  }
}

/// Save nutrition data for a specific date
/// Uses INSERT OR REPLACE to handle both insert and update
pub fn save_nutrition_state(
  conn: sqlight.Connection,
  date: String,
  data: NutritionData,
) -> Result(Nil, StorageError) {
  let sql =
    "INSERT OR REPLACE INTO nutrition_state (date, protein, fat, carbs, calories)
     VALUES (?, ?, ?, ?, ?)"

  let args = [
    sqlight.text(date),
    sqlight.float(data.protein),
    sqlight.float(data.fat),
    sqlight.float(data.carbs),
    sqlight.float(data.calories),
  ]

  case sqlight.query(sql, on: conn, with: args, expecting: decode.dynamic) {
    Error(e) -> Error(DatabaseError(e.message))
    Ok(_) -> Ok(Nil)
  }
}

/// Get nutrition data for a specific date
pub fn get_nutrition_state(
  conn: sqlight.Connection,
  date: String,
) -> Result(NutritionData, StorageError) {
  let sql =
    "SELECT protein, fat, carbs, calories FROM nutrition_state WHERE date = ?"

  let decoder = {
    use protein <- decode.field(0, decode.float)
    use fat <- decode.field(1, decode.float)
    use carbs <- decode.field(2, decode.float)
    use calories <- decode.field(3, decode.float)
    decode.success(NutritionData(
      protein: protein,
      fat: fat,
      carbs: carbs,
      calories: calories,
    ))
  }

  case sqlight.query(sql, on: conn, with: [sqlight.text(date)], expecting: decoder) {
    Error(e) -> Error(DatabaseError(e.message))
    Ok([]) -> Error(NotFound)
    Ok([data, ..]) -> Ok(data)
  }
}

/// Save nutrition goals (only one row with id=1)
pub fn save_goals(
  conn: sqlight.Connection,
  goals: NutritionGoals,
) -> Result(Nil, StorageError) {
  let sql =
    "INSERT OR REPLACE INTO nutrition_goals (id, daily_protein, daily_fat, daily_carbs, daily_calories)
     VALUES (1, ?, ?, ?, ?)"

  let args = [
    sqlight.float(goals.daily_protein),
    sqlight.float(goals.daily_fat),
    sqlight.float(goals.daily_carbs),
    sqlight.float(goals.daily_calories),
  ]

  case sqlight.query(sql, on: conn, with: args, expecting: decode.dynamic) {
    Error(e) -> Error(DatabaseError(e.message))
    Ok(_) -> Ok(Nil)
  }
}

/// Get nutrition goals
pub fn get_goals(conn: sqlight.Connection) -> Result(NutritionGoals, StorageError) {
  let sql =
    "SELECT daily_protein, daily_fat, daily_carbs, daily_calories FROM nutrition_goals WHERE id = 1"

  let decoder = {
    use daily_protein <- decode.field(0, decode.float)
    use daily_fat <- decode.field(1, decode.float)
    use daily_carbs <- decode.field(2, decode.float)
    use daily_calories <- decode.field(3, decode.float)
    decode.success(NutritionGoals(
      daily_protein: daily_protein,
      daily_fat: daily_fat,
      daily_carbs: daily_carbs,
      daily_calories: daily_calories,
    ))
  }

  case sqlight.query(sql, on: conn, with: [], expecting: decoder) {
    Error(e) -> Error(DatabaseError(e.message))
    Ok([]) -> Error(NotFound)
    Ok([data, ..]) -> Ok(data)
  }
}
