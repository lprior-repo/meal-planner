/// SQLite storage module for nutrition data persistence
import gleam/dynamic/decode
import gleam/list
import gleam/string
import meal_planner/ncp
import meal_planner/types.{
  type Recipe, type UserProfile, Active, Gain, High, Ingredient, Lose, Low,
  Macros, Maintain, Medium, Moderate, Recipe, Sedentary, UserProfile,
}
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
      calories REAL NOT NULL,
      synced_at TEXT NOT NULL DEFAULT ''
    )"

  let create_goals_table =
    "CREATE TABLE IF NOT EXISTS nutrition_goals (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      daily_protein REAL NOT NULL,
      daily_fat REAL NOT NULL,
      daily_carbs REAL NOT NULL,
      daily_calories REAL NOT NULL
    )"

  let create_profile_table =
    "CREATE TABLE IF NOT EXISTS user_profile (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      bodyweight REAL NOT NULL,
      activity_level TEXT NOT NULL,
      goal TEXT NOT NULL,
      meals_per_day INTEGER NOT NULL
    )"

  case sqlight.exec(create_nutrition_table, on: conn) {
    Error(e) -> Error(DatabaseError(e.message))
    Ok(Nil) ->
      case sqlight.exec(create_goals_table, on: conn) {
        Error(e) -> Error(DatabaseError(e.message))
        Ok(Nil) ->
          case sqlight.exec(create_profile_table, on: conn) {
            Error(e) -> Error(DatabaseError(e.message))
            Ok(Nil) -> Ok(Nil)
          }
      }
  }
}

// ============================================================================
// Nutrition State Storage Functions
// ============================================================================

/// Save nutrition state for a specific date
pub fn save_nutrition_state(
  conn: sqlight.Connection,
  state: ncp.NutritionState,
) -> Result(Nil, StorageError) {
  let sql =
    "INSERT OR REPLACE INTO nutrition_state (date, protein, fat, carbs, calories, synced_at)
     VALUES (?, ?, ?, ?, ?, ?)"

  let args = [
    sqlight.text(state.date),
    sqlight.float(state.consumed.protein),
    sqlight.float(state.consumed.fat),
    sqlight.float(state.consumed.carbs),
    sqlight.float(state.consumed.calories),
    sqlight.text(state.synced_at),
  ]

  case sqlight.query(sql, on: conn, with: args, expecting: decode.dynamic) {
    Error(e) -> Error(DatabaseError(e.message))
    Ok(_) -> Ok(Nil)
  }
}

/// Get nutrition state for a specific date
pub fn get_nutrition_state(
  conn: sqlight.Connection,
  date: String,
) -> Result(ncp.NutritionState, StorageError) {
  let sql =
    "SELECT date, protein, fat, carbs, calories, synced_at FROM nutrition_state WHERE date = ?"

  let decoder = {
    use date <- decode.field(0, decode.string)
    use protein <- decode.field(1, decode.float)
    use fat <- decode.field(2, decode.float)
    use carbs <- decode.field(3, decode.float)
    use calories <- decode.field(4, decode.float)
    use synced_at <- decode.field(5, decode.string)
    decode.success(ncp.NutritionState(
      date: date,
      consumed: ncp.NutritionData(
        protein: protein,
        fat: fat,
        carbs: carbs,
        calories: calories,
      ),
      synced_at: synced_at,
    ))
  }

  case
    sqlight.query(sql, on: conn, with: [sqlight.text(date)], expecting: decoder)
  {
    Error(e) -> Error(DatabaseError(e.message))
    Ok([]) -> Error(NotFound)
    Ok([data, ..]) -> Ok(data)
  }
}

/// Get nutrition history for the last N days
pub fn get_nutrition_history(
  conn: sqlight.Connection,
  limit: Int,
) -> Result(List(ncp.NutritionState), StorageError) {
  let sql =
    "SELECT date, protein, fat, carbs, calories, synced_at
     FROM nutrition_state ORDER BY date DESC LIMIT ?"

  let decoder = {
    use date <- decode.field(0, decode.string)
    use protein <- decode.field(1, decode.float)
    use fat <- decode.field(2, decode.float)
    use carbs <- decode.field(3, decode.float)
    use calories <- decode.field(4, decode.float)
    use synced_at <- decode.field(5, decode.string)
    decode.success(ncp.NutritionState(
      date: date,
      consumed: ncp.NutritionData(
        protein: protein,
        fat: fat,
        carbs: carbs,
        calories: calories,
      ),
      synced_at: synced_at,
    ))
  }

  case
    sqlight.query(sql, on: conn, with: [sqlight.int(limit)], expecting: decoder)
  {
    Error(e) -> Error(DatabaseError(e.message))
    Ok(states) -> Ok(states)
  }
}

// ============================================================================
// Nutrition Goals Storage Functions
// ============================================================================

/// Save nutrition goals
pub fn save_goals(
  conn: sqlight.Connection,
  goals: ncp.NutritionGoals,
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
pub fn get_goals(
  conn: sqlight.Connection,
) -> Result(ncp.NutritionGoals, StorageError) {
  let sql =
    "SELECT daily_protein, daily_fat, daily_carbs, daily_calories FROM nutrition_goals WHERE id = 1"

  let decoder = {
    use daily_protein <- decode.field(0, decode.float)
    use daily_fat <- decode.field(1, decode.float)
    use daily_carbs <- decode.field(2, decode.float)
    use daily_calories <- decode.field(3, decode.float)
    decode.success(ncp.NutritionGoals(
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

// ============================================================================
// User Profile Storage Functions
// ============================================================================

/// Save user profile
pub fn save_user_profile(
  conn: sqlight.Connection,
  profile: UserProfile,
) -> Result(Nil, StorageError) {
  let sql =
    "INSERT OR REPLACE INTO user_profile (id, bodyweight, activity_level, goal, meals_per_day)
     VALUES (1, ?, ?, ?, ?)"

  let activity_str = case profile.activity_level {
    Sedentary -> "sedentary"
    Moderate -> "moderate"
    Active -> "active"
  }

  let goal_str = case profile.goal {
    Gain -> "gain"
    Maintain -> "maintain"
    Lose -> "lose"
  }

  let args = [
    sqlight.float(profile.bodyweight),
    sqlight.text(activity_str),
    sqlight.text(goal_str),
    sqlight.int(profile.meals_per_day),
  ]

  case sqlight.query(sql, on: conn, with: args, expecting: decode.dynamic) {
    Error(e) -> Error(DatabaseError(e.message))
    Ok(_) -> Ok(Nil)
  }
}

/// Get user profile
pub fn get_user_profile(
  conn: sqlight.Connection,
) -> Result(UserProfile, StorageError) {
  let sql =
    "SELECT bodyweight, activity_level, goal, meals_per_day FROM user_profile WHERE id = 1"

  let decoder = {
    use bodyweight <- decode.field(0, decode.float)
    use activity_str <- decode.field(1, decode.string)
    use goal_str <- decode.field(2, decode.string)
    use meals_per_day <- decode.field(3, decode.int)

    let activity_level = case activity_str {
      "sedentary" -> Sedentary
      "moderate" -> Moderate
      "active" -> Active
      _ -> Moderate
    }

    let goal = case goal_str {
      "gain" -> Gain
      "maintain" -> Maintain
      "lose" -> Lose
      _ -> Maintain
    }

    decode.success(UserProfile(
      bodyweight: bodyweight,
      activity_level: activity_level,
      goal: goal,
      meals_per_day: meals_per_day,
    ))
  }

  case sqlight.query(sql, on: conn, with: [], expecting: decoder) {
    Error(e) -> Error(DatabaseError(e.message))
    Ok([]) -> Error(NotFound)
    Ok([profile, ..]) -> Ok(profile)
  }
}

// ============================================================================
// Recipe Storage Functions
// ============================================================================

/// Initialize recipe tables in the database
pub fn init_recipe_tables(conn: sqlight.Connection) -> Result(Nil, StorageError) {
  let create_recipes_table =
    "CREATE TABLE IF NOT EXISTS recipes (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      ingredients TEXT NOT NULL,
      instructions TEXT NOT NULL,
      protein REAL NOT NULL,
      fat REAL NOT NULL,
      carbs REAL NOT NULL,
      servings INTEGER NOT NULL,
      category TEXT NOT NULL,
      fodmap_level TEXT NOT NULL,
      vertical_compliant INTEGER NOT NULL
    )"

  case sqlight.exec(create_recipes_table, on: conn) {
    Error(e) -> Error(DatabaseError(e.message))
    Ok(Nil) -> Ok(Nil)
  }
}

/// Save a recipe to the database
pub fn save_recipe(
  conn: sqlight.Connection,
  recipe: Recipe,
) -> Result(Nil, StorageError) {
  let sql =
    "INSERT OR REPLACE INTO recipes 
     (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"

  let ingredients_json =
    string.join(
      list.map(recipe.ingredients, fn(i) { i.name <> ":" <> i.quantity }),
      "|",
    )

  let instructions_json = string.join(recipe.instructions, "|")

  let fodmap_string = case recipe.fodmap_level {
    Low -> "low"
    Medium -> "medium"
    High -> "high"
  }

  let args = [
    sqlight.text(recipe.id),
    sqlight.text(recipe.name),
    sqlight.text(ingredients_json),
    sqlight.text(instructions_json),
    sqlight.float(recipe.macros.protein),
    sqlight.float(recipe.macros.fat),
    sqlight.float(recipe.macros.carbs),
    sqlight.int(recipe.servings),
    sqlight.text(recipe.category),
    sqlight.text(fodmap_string),
    sqlight.int(case recipe.vertical_compliant {
      True -> 1
      False -> 0
    }),
  ]

  case sqlight.query(sql, on: conn, with: args, expecting: decode.dynamic) {
    Error(e) -> Error(DatabaseError(e.message))
    Ok(_) -> Ok(Nil)
  }
}

/// Get all recipes from the database
pub fn get_all_recipes(
  conn: sqlight.Connection,
) -> Result(List(Recipe), StorageError) {
  let sql =
    "SELECT id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant
     FROM recipes ORDER BY name"

  let decoder = {
    use id <- decode.field(0, decode.string)
    use name <- decode.field(1, decode.string)
    use ingredients_str <- decode.field(2, decode.string)
    use instructions_str <- decode.field(3, decode.string)
    use protein <- decode.field(4, decode.float)
    use fat <- decode.field(5, decode.float)
    use carbs <- decode.field(6, decode.float)
    use servings <- decode.field(7, decode.int)
    use category <- decode.field(8, decode.string)
    use fodmap_str <- decode.field(9, decode.string)
    use vertical_int <- decode.field(10, decode.int)

    let ingredients =
      string.split(ingredients_str, "|")
      |> list.map(fn(pair) {
        case string.split(pair, ":") {
          [name, quantity] -> Ingredient(name, quantity)
          _ -> Ingredient(pair, "")
        }
      })

    let instructions = string.split(instructions_str, "|")

    let fodmap_level = case fodmap_str {
      "low" -> Low
      "medium" -> Medium
      "high" -> High
      _ -> Low
    }

    let vertical_compliant = case vertical_int {
      1 -> True
      _ -> False
    }

    decode.success(Recipe(
      id: id,
      name: name,
      ingredients: ingredients,
      instructions: instructions,
      macros: Macros(protein: protein, fat: fat, carbs: carbs),
      servings: servings,
      category: category,
      fodmap_level: fodmap_level,
      vertical_compliant: vertical_compliant,
    ))
  }

  case sqlight.query(sql, on: conn, with: [], expecting: decoder) {
    Error(e) -> Error(DatabaseError(e.message))
    Ok(recipes) -> Ok(recipes)
  }
}

/// Get a specific recipe by ID
pub fn get_recipe_by_id(
  conn: sqlight.Connection,
  recipe_id: String,
) -> Result(Recipe, StorageError) {
  let sql =
    "SELECT id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant
     FROM recipes WHERE id = ?"

  let decoder = {
    use id <- decode.field(0, decode.string)
    use name <- decode.field(1, decode.string)
    use ingredients_str <- decode.field(2, decode.string)
    use instructions_str <- decode.field(3, decode.string)
    use protein <- decode.field(4, decode.float)
    use fat <- decode.field(5, decode.float)
    use carbs <- decode.field(6, decode.float)
    use servings <- decode.field(7, decode.int)
    use category <- decode.field(8, decode.string)
    use fodmap_str <- decode.field(9, decode.string)
    use vertical_int <- decode.field(10, decode.int)

    let ingredients =
      string.split(ingredients_str, "|")
      |> list.map(fn(pair) {
        case string.split(pair, ":") {
          [name, quantity] -> Ingredient(name, quantity)
          _ -> Ingredient(pair, "")
        }
      })

    let instructions = string.split(instructions_str, "|")

    let fodmap_level = case fodmap_str {
      "low" -> Low
      "medium" -> Medium
      "high" -> High
      _ -> Low
    }

    let vertical_compliant = case vertical_int {
      1 -> True
      _ -> False
    }

    decode.success(Recipe(
      id: id,
      name: name,
      ingredients: ingredients,
      instructions: instructions,
      macros: Macros(protein: protein, fat: fat, carbs: carbs),
      servings: servings,
      category: category,
      fodmap_level: fodmap_level,
      vertical_compliant: vertical_compliant,
    ))
  }

  case
    sqlight.query(
      sql,
      on: conn,
      with: [sqlight.text(recipe_id)],
      expecting: decoder,
    )
  {
    Error(e) -> Error(DatabaseError(e.message))
    Ok([]) -> Error(NotFound)
    Ok([recipe, ..]) -> Ok(recipe)
  }
}

/// Get recipes by category
pub fn get_recipes_by_category(
  conn: sqlight.Connection,
  category: String,
) -> Result(List(Recipe), StorageError) {
  let sql =
    "SELECT id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant
     FROM recipes WHERE category = ? ORDER BY name"

  let decoder = {
    use id <- decode.field(0, decode.string)
    use name <- decode.field(1, decode.string)
    use ingredients_str <- decode.field(2, decode.string)
    use instructions_str <- decode.field(3, decode.string)
    use protein <- decode.field(4, decode.float)
    use fat <- decode.field(5, decode.float)
    use carbs <- decode.field(6, decode.float)
    use servings <- decode.field(7, decode.int)
    use category <- decode.field(8, decode.string)
    use fodmap_str <- decode.field(9, decode.string)
    use vertical_int <- decode.field(10, decode.int)

    let ingredients =
      string.split(ingredients_str, "|")
      |> list.map(fn(pair) {
        case string.split(pair, ":") {
          [name, quantity] -> Ingredient(name, quantity)
          _ -> Ingredient(pair, "")
        }
      })

    let instructions = string.split(instructions_str, "|")

    let fodmap_level = case fodmap_str {
      "low" -> Low
      "medium" -> Medium
      "high" -> High
      _ -> Low
    }

    let vertical_compliant = case vertical_int {
      1 -> True
      _ -> False
    }

    decode.success(Recipe(
      id: id,
      name: name,
      ingredients: ingredients,
      instructions: instructions,
      macros: Macros(protein: protein, fat: fat, carbs: carbs),
      servings: servings,
      category: category,
      fodmap_level: fodmap_level,
      vertical_compliant: vertical_compliant,
    ))
  }

  case
    sqlight.query(
      sql,
      on: conn,
      with: [sqlight.text(category)],
      expecting: decoder,
    )
  {
    Error(e) -> Error(DatabaseError(e.message))
    Ok(recipes) -> Ok(recipes)
  }
}

/// Initialize database with all required tables
pub fn initialize_database() -> Result(Nil, String) {
  with_connection("meal_planner.db", fn(conn) {
    case init_db(conn) {
      Ok(_) ->
        case init_recipe_tables(conn) {
          Ok(_) -> Ok(Nil)
          Error(_) -> Error("Failed to initialize recipe tables")
        }
      Error(_) -> Error("Failed to initialize database")
    }
  })
}
