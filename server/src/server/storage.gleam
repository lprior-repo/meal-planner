//// SQLite storage module for the web server
//// Provides database operations for recipes, user profiles, and nutrition logs

import gleam/dynamic/decode
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import shared/types.{
  type DailyLog, type FoodLogEntry, type Macros, type Recipe, type UserProfile,
  Active, DailyLog, FoodLogEntry, Gain, High, Ingredient, Lose, Low, Macros,
  Maintain, Medium, Moderate, Recipe, Sedentary, UserProfile,
}
import sqlight

/// Error type for storage operations
pub type StorageError {
  NotFound
  DatabaseError(String)
}

/// Database path for the meal planner
pub const db_path = "meal_planner.db"

/// Open a connection to SQLite database and run a function with it
pub fn with_connection(path: String, f: fn(sqlight.Connection) -> a) -> a {
  sqlight.with_connection(path, f)
}

/// Initialize all database tables
pub fn init_db(conn: sqlight.Connection) -> Result(Nil, StorageError) {
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

  let create_profile_table =
    "CREATE TABLE IF NOT EXISTS user_profile (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      bodyweight REAL NOT NULL,
      activity_level TEXT NOT NULL,
      goal TEXT NOT NULL,
      meals_per_day INTEGER NOT NULL
    )"

  let create_logs_table =
    "CREATE TABLE IF NOT EXISTS food_logs (
      id TEXT PRIMARY KEY,
      date TEXT NOT NULL,
      recipe_id TEXT NOT NULL,
      recipe_name TEXT NOT NULL,
      servings REAL NOT NULL,
      protein REAL NOT NULL,
      fat REAL NOT NULL,
      carbs REAL NOT NULL,
      meal_type TEXT NOT NULL,
      logged_at TEXT NOT NULL
    )"

  let create_logs_index =
    "CREATE INDEX IF NOT EXISTS idx_food_logs_date ON food_logs(date)"

  case sqlight.exec(create_recipes_table, on: conn) {
    Error(e) -> Error(DatabaseError(e.message))
    Ok(Nil) ->
      case sqlight.exec(create_profile_table, on: conn) {
        Error(e) -> Error(DatabaseError(e.message))
        Ok(Nil) ->
          case sqlight.exec(create_logs_table, on: conn) {
            Error(e) -> Error(DatabaseError(e.message))
            Ok(Nil) ->
              case sqlight.exec(create_logs_index, on: conn) {
                Error(e) -> Error(DatabaseError(e.message))
                Ok(Nil) -> Ok(Nil)
              }
          }
      }
  }
}

/// Initialize database with default data if empty
pub fn initialize_database() -> Result(Nil, StorageError) {
  with_connection(db_path, fn(conn) {
    case init_db(conn) {
      Error(e) -> Error(e)
      Ok(Nil) -> {
        // Check if we have any recipes, if not seed with defaults
        case get_all_recipes(conn) {
          Ok([]) -> seed_default_recipes(conn)
          Ok(_) -> Ok(Nil)
          Error(e) -> Error(e)
        }
      }
    }
  })
}

// ============================================================================
// Recipe Storage Functions
// ============================================================================

/// Get all recipes from the database
pub fn get_all_recipes(
  conn: sqlight.Connection,
) -> Result(List(Recipe), StorageError) {
  let sql =
    "SELECT id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant
     FROM recipes ORDER BY name"

  let decoder = recipe_row_decoder()

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

  let decoder = recipe_row_decoder()

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

/// Save a recipe to the database
pub fn save_recipe(
  conn: sqlight.Connection,
  recipe: Recipe,
) -> Result(Nil, StorageError) {
  let sql =
    "INSERT OR REPLACE INTO recipes
     (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"

  let ingredients_str =
    string.join(
      list.map(recipe.ingredients, fn(i) { i.name <> ":" <> i.quantity }),
      "|",
    )

  let instructions_str = string.join(recipe.instructions, "|")

  let fodmap_string = case recipe.fodmap_level {
    Low -> "low"
    Medium -> "medium"
    High -> "high"
  }

  let args = [
    sqlight.text(recipe.id),
    sqlight.text(recipe.name),
    sqlight.text(ingredients_str),
    sqlight.text(instructions_str),
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

/// Delete a recipe from the database
pub fn delete_recipe(
  conn: sqlight.Connection,
  recipe_id: String,
) -> Result(Nil, StorageError) {
  let sql = "DELETE FROM recipes WHERE id = ?"

  case
    sqlight.query(
      sql,
      on: conn,
      with: [sqlight.text(recipe_id)],
      expecting: decode.dynamic,
    )
  {
    Error(e) -> Error(DatabaseError(e.message))
    Ok(_) -> Ok(Nil)
  }
}

fn recipe_row_decoder() -> decode.Decoder(Recipe) {
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
    |> list.filter(fn(s) { s != "" })
    |> list.map(fn(pair) {
      case string.split(pair, ":") {
        [name, quantity] -> Ingredient(name, quantity)
        _ -> Ingredient(pair, "")
      }
    })

  let instructions =
    string.split(instructions_str, "|")
    |> list.filter(fn(s) { s != "" })

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

// ============================================================================
// User Profile Storage Functions
// ============================================================================

/// Get user profile from database
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
      id: "user-1",
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

/// Save user profile to database
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

/// Get user profile or return default if not found
pub fn get_user_profile_or_default(conn: sqlight.Connection) -> UserProfile {
  case get_user_profile(conn) {
    Ok(profile) -> profile
    Error(_) -> default_user_profile()
  }
}

fn default_user_profile() -> UserProfile {
  UserProfile(
    id: "user-1",
    bodyweight: 180.0,
    activity_level: Moderate,
    goal: Maintain,
    meals_per_day: 3,
  )
}

// ============================================================================
// Food Log Storage Functions
// ============================================================================

/// Get food log entries for a specific date
pub fn get_daily_log(
  conn: sqlight.Connection,
  date: String,
) -> Result(DailyLog, StorageError) {
  let sql =
    "SELECT id, date, recipe_id, recipe_name, servings, protein, fat, carbs, meal_type, logged_at
     FROM food_logs WHERE date = ? ORDER BY logged_at"

  let decoder = food_log_entry_decoder()

  case
    sqlight.query(sql, on: conn, with: [sqlight.text(date)], expecting: decoder)
  {
    Error(e) -> Error(DatabaseError(e.message))
    Ok(entries) -> {
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

/// Save a food log entry
pub fn save_food_log_entry(
  conn: sqlight.Connection,
  date: String,
  entry: FoodLogEntry,
) -> Result(Nil, StorageError) {
  let sql =
    "INSERT OR REPLACE INTO food_logs
     (id, date, recipe_id, recipe_name, servings, protein, fat, carbs, meal_type, logged_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"

  let meal_type_str = case entry.meal_type {
    types.Breakfast -> "breakfast"
    types.Lunch -> "lunch"
    types.Dinner -> "dinner"
    types.Snack -> "snack"
  }

  let args = [
    sqlight.text(entry.id),
    sqlight.text(date),
    sqlight.text(entry.recipe_id),
    sqlight.text(entry.recipe_name),
    sqlight.float(entry.servings),
    sqlight.float(entry.macros.protein),
    sqlight.float(entry.macros.fat),
    sqlight.float(entry.macros.carbs),
    sqlight.text(meal_type_str),
    sqlight.text(entry.logged_at),
  ]

  case sqlight.query(sql, on: conn, with: args, expecting: decode.dynamic) {
    Error(e) -> Error(DatabaseError(e.message))
    Ok(_) -> Ok(Nil)
  }
}

/// Delete a food log entry
pub fn delete_food_log_entry(
  conn: sqlight.Connection,
  entry_id: String,
) -> Result(Nil, StorageError) {
  let sql = "DELETE FROM food_logs WHERE id = ?"

  case
    sqlight.query(
      sql,
      on: conn,
      with: [sqlight.text(entry_id)],
      expecting: decode.dynamic,
    )
  {
    Error(e) -> Error(DatabaseError(e.message))
    Ok(_) -> Ok(Nil)
  }
}

fn food_log_entry_decoder() -> decode.Decoder(FoodLogEntry) {
  use id <- decode.field(0, decode.string)
  use _date <- decode.field(1, decode.string)
  use recipe_id <- decode.field(2, decode.string)
  use recipe_name <- decode.field(3, decode.string)
  use servings <- decode.field(4, decode.float)
  use protein <- decode.field(5, decode.float)
  use fat <- decode.field(6, decode.float)
  use carbs <- decode.field(7, decode.float)
  use meal_type_str <- decode.field(8, decode.string)
  use logged_at <- decode.field(9, decode.string)
  use source_type <- decode.field(10, decode.string)
  use source_id <- decode.field(11, decode.string)

  let meal_type = case meal_type_str {
    "breakfast" -> types.Breakfast
    "lunch" -> types.Lunch
    "dinner" -> types.Dinner
    "snack" -> types.Snack
    _ -> types.Snack
  }

  decode.success(FoodLogEntry(
    id: id,
    recipe_id: recipe_id,
    recipe_name: recipe_name,
    servings: servings,
    macros: Macros(protein: protein, fat: fat, carbs: carbs),
    micronutrients: None,
    meal_type: meal_type,
    logged_at: logged_at,
    source_type: source_type,
    source_id: source_id,
  ))
}

/// Calculate total micronutrients from food log entries
fn calculate_total_micronutrients(
  entries: List(FoodLogEntry),
) -> option.Option(types.Micronutrients) {
  let micros_list =
    list.filter_map(entries, fn(entry) {
      case entry.micronutrients {
        Some(m) -> Ok(m)
        None -> Error(Nil)
      }
    })
  case list.is_empty(micros_list) {
    True -> option.None
    False -> option.Some(types.micronutrients_sum(micros_list))
  }
}

fn calculate_total_macros(entries: List(FoodLogEntry)) -> Macros {
  list.fold(entries, types.macros_zero(), fn(acc, entry) {
    types.macros_add(acc, entry.macros)
  })
}

/// Get a single food log entry by ID
pub fn get_food_log_entry(
  conn: sqlight.Connection,
  entry_id: String,
) -> Result(FoodLogEntry, StorageError) {
  let sql =
    "SELECT id, date, recipe_id, recipe_name, servings, protein, fat, carbs, meal_type, logged_at
     FROM food_logs WHERE id = ?"

  let decoder = food_log_entry_decoder()

  case
    sqlight.query(
      sql,
      on: conn,
      with: [sqlight.text(entry_id)],
      expecting: decoder,
    )
  {
    Error(e) -> Error(DatabaseError(e.message))
    Ok([]) -> Error(NotFound)
    Ok([entry, ..]) -> Ok(entry)
  }
}

/// Update a food log entry (for editing servings/meal type)
pub fn update_food_log_entry(
  conn: sqlight.Connection,
  entry_id: String,
  servings: Float,
  macros: Macros,
  meal_type: types.MealType,
) -> Result(Nil, StorageError) {
  let sql =
    "UPDATE food_logs
     SET servings = ?, protein = ?, fat = ?, carbs = ?, meal_type = ?
     WHERE id = ?"

  let meal_type_str = case meal_type {
    types.Breakfast -> "breakfast"
    types.Lunch -> "lunch"
    types.Dinner -> "dinner"
    types.Snack -> "snack"
  }

  let args = [
    sqlight.float(servings),
    sqlight.float(macros.protein),
    sqlight.float(macros.fat),
    sqlight.float(macros.carbs),
    sqlight.text(meal_type_str),
    sqlight.text(entry_id),
  ]

  case sqlight.query(sql, on: conn, with: args, expecting: decode.dynamic) {
    Error(e) -> Error(DatabaseError(e.message))
    Ok(_) -> Ok(Nil)
  }
}

/// Get most recent meals (for quick re-log)
/// Returns distinct meals ordered by most recently logged
pub fn get_recent_meals(
  conn: sqlight.Connection,
  limit: Int,
) -> Result(List(FoodLogEntry), StorageError) {
  // Get distinct recent meals by recipe_id, taking the most recent serving size
  let sql =
    "SELECT id, date, recipe_id, recipe_name, servings, protein, fat, carbs, meal_type, logged_at
     FROM food_logs
     WHERE id IN (
       SELECT MAX(id) FROM food_logs GROUP BY recipe_id
     )
     ORDER BY logged_at DESC
     LIMIT ?"

  let decoder = food_log_entry_decoder()

  case
    sqlight.query(sql, on: conn, with: [sqlight.int(limit)], expecting: decoder)
  {
    Error(e) -> Error(DatabaseError(e.message))
    Ok(entries) -> Ok(entries)
  }
}

// ============================================================================
// Seed Data
// ============================================================================

fn seed_default_recipes(conn: sqlight.Connection) -> Result(Nil, StorageError) {
  let recipes = [
    Recipe(
      id: "chicken-rice",
      name: "Chicken and Rice",
      ingredients: [
        Ingredient(name: "Chicken breast", quantity: "8 oz"),
        Ingredient(name: "White rice", quantity: "1 cup"),
        Ingredient(name: "Olive oil", quantity: "1 tbsp"),
      ],
      instructions: [
        "Cook rice according to package",
        "Season and grill chicken breast",
        "Serve chicken over rice",
      ],
      macros: Macros(protein: 45.0, fat: 8.0, carbs: 45.0),
      servings: 1,
      category: "chicken",
      fodmap_level: Low,
      vertical_compliant: True,
    ),
    Recipe(
      id: "beef-potatoes",
      name: "Beef and Potatoes",
      ingredients: [
        Ingredient(name: "Ground beef (90% lean)", quantity: "6 oz"),
        Ingredient(name: "Russet potatoes", quantity: "200g"),
        Ingredient(name: "Butter", quantity: "1 tbsp"),
      ],
      instructions: [
        "Boil potatoes until tender",
        "Brown the ground beef",
        "Combine and season to taste",
      ],
      macros: Macros(protein: 40.0, fat: 20.0, carbs: 35.0),
      servings: 1,
      category: "beef",
      fodmap_level: Low,
      vertical_compliant: True,
    ),
    Recipe(
      id: "salmon-veggies",
      name: "Salmon with Vegetables",
      ingredients: [
        Ingredient(name: "Salmon fillet", quantity: "6 oz"),
        Ingredient(name: "Broccoli", quantity: "1 cup"),
        Ingredient(name: "Olive oil", quantity: "1 tbsp"),
      ],
      instructions: [
        "Preheat oven to 400F",
        "Season and roast salmon for 15 minutes",
        "Steam broccoli and serve alongside",
      ],
      macros: Macros(protein: 35.0, fat: 18.0, carbs: 8.0),
      servings: 1,
      category: "seafood",
      fodmap_level: Low,
      vertical_compliant: True,
    ),
    Recipe(
      id: "egg-oatmeal",
      name: "Eggs and Oatmeal",
      ingredients: [
        Ingredient(name: "Eggs", quantity: "3 large"),
        Ingredient(name: "Oatmeal", quantity: "1/2 cup dry"),
        Ingredient(name: "Butter", quantity: "1 tbsp"),
      ],
      instructions: [
        "Cook oatmeal with water",
        "Scramble eggs in butter",
        "Serve together",
      ],
      macros: Macros(protein: 24.0, fat: 18.0, carbs: 27.0),
      servings: 1,
      category: "breakfast",
      fodmap_level: Low,
      vertical_compliant: True,
    ),
    Recipe(
      id: "steak-sweet-potato",
      name: "Steak with Sweet Potato",
      ingredients: [
        Ingredient(name: "NY Strip steak", quantity: "8 oz"),
        Ingredient(name: "Sweet potato", quantity: "1 medium"),
        Ingredient(name: "Butter", quantity: "1 tbsp"),
      ],
      instructions: [
        "Bake sweet potato at 400F for 45 minutes",
        "Season and pan-sear steak to desired doneness",
        "Top sweet potato with butter",
      ],
      macros: Macros(protein: 50.0, fat: 22.0, carbs: 26.0),
      servings: 1,
      category: "beef",
      fodmap_level: Low,
      vertical_compliant: True,
    ),
  ]

  list.try_fold(recipes, Nil, fn(_, recipe) { save_recipe(conn, recipe) })
}
