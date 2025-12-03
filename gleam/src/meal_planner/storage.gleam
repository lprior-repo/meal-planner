/// PostgreSQL storage module for nutrition data persistence
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/string
import meal_planner/ncp
import shared/types.{
  type DailyLog, type FoodLogEntry, type Macros, type Recipe, type UserProfile,
  Active, Breakfast, DailyLog, Dinner, FoodLogEntry, Gain, High, Ingredient,
  Lose, Low, Lunch, Macros, Maintain, Medium, Moderate, Recipe, Sedentary,
  Snack, UserProfile,
}
import pog

/// Error type for storage operations
pub type StorageError {
  NotFound
  DatabaseError(String)
}

/// Database configuration
pub type DbConfig {
  DbConfig(
    host: String,
    port: Int,
    database: String,
    user: String,
    password: Option(String),
    pool_size: Int,
  )
}

/// Default configuration for development
pub fn default_config() -> DbConfig {
  DbConfig(
    host: "localhost",
    port: 5432,
    database: "meal_planner",
    user: "postgres",
    password: Some("postgres"),
    pool_size: 10,
  )
}

/// Convert DbConfig to pog.Config
fn to_pog_config(config: DbConfig) -> pog.Config {
  let pool_name = process.new_name(prefix: "meal_planner_db")
  let base =
    pog.default_config(pool_name: pool_name)
    |> pog.host(config.host)
    |> pog.port(config.port)
    |> pog.database(config.database)
    |> pog.user(config.user)
    |> pog.pool_size(config.pool_size)

  case config.password {
    Some(pw) -> pog.password(base, Some(pw))
    None -> base
  }
}

/// Start the database connection pool
pub fn start_pool(config: DbConfig) -> Result(pog.Connection, String) {
  let pog_config = to_pog_config(config)
  case pog.start(pog_config) {
    Ok(started) -> {
      let actor.Started(_pid, conn) = started
      Ok(conn)
    }
    Error(actor.InitTimeout) -> Error("Database connection timeout")
    Error(actor.InitFailed(reason)) ->
      Error("Database connection failed: " <> reason)
    Error(actor.InitExited(_)) -> Error("Database process exited unexpectedly")
  }
}

// ============================================================================
// Nutrition State Storage Functions
// ============================================================================

/// Save nutrition state for a specific date
pub fn save_nutrition_state(
  conn: pog.Connection,
  state: ncp.NutritionState,
) -> Result(Nil, StorageError) {
  let sql =
    "INSERT INTO nutrition_state (date, protein, fat, carbs, calories, synced_at)
     VALUES ($1, $2, $3, $4, $5, NOW())
     ON CONFLICT (date) DO UPDATE SET
       protein = EXCLUDED.protein,
       fat = EXCLUDED.fat,
       carbs = EXCLUDED.carbs,
       calories = EXCLUDED.calories,
       synced_at = NOW()"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(state.date))
    |> pog.parameter(pog.float(state.consumed.protein))
    |> pog.parameter(pog.float(state.consumed.fat))
    |> pog.parameter(pog.float(state.consumed.carbs))
    |> pog.parameter(pog.float(state.consumed.calories))
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(format_pog_error(e)))
    Ok(_) -> Ok(Nil)
  }
}

/// Get nutrition state for a specific date
pub fn get_nutrition_state(
  conn: pog.Connection,
  date: String,
) -> Result(ncp.NutritionState, StorageError) {
  let sql =
    "SELECT date, protein, fat, carbs, calories, synced_at::text
     FROM nutrition_state WHERE date = $1"

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
    pog.query(sql)
    |> pog.parameter(pog.text(date))
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(format_pog_error(e)))
    Ok(pog.Returned(0, _)) -> Error(NotFound)
    Ok(pog.Returned(_, [])) -> Error(NotFound)
    Ok(pog.Returned(_, [row, ..])) -> Ok(row)
  }
}

/// Get nutrition history for the last N days
pub fn get_nutrition_history(
  conn: pog.Connection,
  limit: Int,
) -> Result(List(ncp.NutritionState), StorageError) {
  let sql =
    "SELECT date, protein, fat, carbs, calories, synced_at::text
     FROM nutrition_state ORDER BY date DESC LIMIT $1"

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
    pog.query(sql)
    |> pog.parameter(pog.int(limit))
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(format_pog_error(e)))
    Ok(pog.Returned(_, rows)) -> Ok(rows)
  }
}

// ============================================================================
// Nutrition Goals Storage Functions
// ============================================================================

/// Save nutrition goals
pub fn save_goals(
  conn: pog.Connection,
  goals: ncp.NutritionGoals,
) -> Result(Nil, StorageError) {
  let sql =
    "INSERT INTO nutrition_goals (id, daily_protein, daily_fat, daily_carbs, daily_calories)
     VALUES (1, $1, $2, $3, $4)
     ON CONFLICT (id) DO UPDATE SET
       daily_protein = EXCLUDED.daily_protein,
       daily_fat = EXCLUDED.daily_fat,
       daily_carbs = EXCLUDED.daily_carbs,
       daily_calories = EXCLUDED.daily_calories"

  case
    pog.query(sql)
    |> pog.parameter(pog.float(goals.daily_protein))
    |> pog.parameter(pog.float(goals.daily_fat))
    |> pog.parameter(pog.float(goals.daily_carbs))
    |> pog.parameter(pog.float(goals.daily_calories))
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(format_pog_error(e)))
    Ok(_) -> Ok(Nil)
  }
}

/// Get nutrition goals
pub fn get_goals(conn: pog.Connection) -> Result(ncp.NutritionGoals, StorageError) {
  let sql =
    "SELECT daily_protein, daily_fat, daily_carbs, daily_calories
     FROM nutrition_goals WHERE id = 1"

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

  case
    pog.query(sql)
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(format_pog_error(e)))
    Ok(pog.Returned(0, _)) -> Error(NotFound)
    Ok(pog.Returned(_, [])) -> Error(NotFound)
    Ok(pog.Returned(_, [row, ..])) -> Ok(row)
  }
}

// ============================================================================
// User Profile Storage Functions
// ============================================================================

/// Save user profile
pub fn save_user_profile(
  conn: pog.Connection,
  profile: UserProfile,
) -> Result(Nil, StorageError) {
  let sql =
    "INSERT INTO user_profile (id, bodyweight, activity_level, goal, meals_per_day)
     VALUES (1, $1, $2, $3, $4)
     ON CONFLICT (id) DO UPDATE SET
       bodyweight = EXCLUDED.bodyweight,
       activity_level = EXCLUDED.activity_level,
       goal = EXCLUDED.goal,
       meals_per_day = EXCLUDED.meals_per_day"

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

  case
    pog.query(sql)
    |> pog.parameter(pog.float(profile.bodyweight))
    |> pog.parameter(pog.text(activity_str))
    |> pog.parameter(pog.text(goal_str))
    |> pog.parameter(pog.int(profile.meals_per_day))
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(format_pog_error(e)))
    Ok(_) -> Ok(Nil)
  }
}

/// Get user profile
pub fn get_user_profile(conn: pog.Connection) -> Result(UserProfile, StorageError) {
  let sql =
    "SELECT id, bodyweight, activity_level, goal, meals_per_day
     FROM user_profile WHERE id = 1"

  let decoder = {
    use id <- decode.field(0, decode.int)
    use bodyweight <- decode.field(1, decode.float)
    use activity_str <- decode.field(2, decode.string)
    use goal_str <- decode.field(3, decode.string)
    use meals_per_day <- decode.field(4, decode.int)

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
      id: int.to_string(id),
      bodyweight: bodyweight,
      activity_level: activity_level,
      goal: goal,
      meals_per_day: meals_per_day,
    ))
  }

  case
    pog.query(sql)
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(format_pog_error(e)))
    Ok(pog.Returned(0, _)) -> Error(NotFound)
    Ok(pog.Returned(_, [])) -> Error(NotFound)
    Ok(pog.Returned(_, [row, ..])) -> Ok(row)
  }
}

// ============================================================================
// Recipe Storage Functions
// ============================================================================

/// Save a recipe to the database
pub fn save_recipe(
  conn: pog.Connection,
  recipe: Recipe,
) -> Result(Nil, StorageError) {
  let sql =
    "INSERT INTO recipes
     (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
     ON CONFLICT (id) DO UPDATE SET
       name = EXCLUDED.name,
       ingredients = EXCLUDED.ingredients,
       instructions = EXCLUDED.instructions,
       protein = EXCLUDED.protein,
       fat = EXCLUDED.fat,
       carbs = EXCLUDED.carbs,
       servings = EXCLUDED.servings,
       category = EXCLUDED.category,
       fodmap_level = EXCLUDED.fodmap_level,
       vertical_compliant = EXCLUDED.vertical_compliant"

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

  case
    pog.query(sql)
    |> pog.parameter(pog.text(recipe.id))
    |> pog.parameter(pog.text(recipe.name))
    |> pog.parameter(pog.text(ingredients_json))
    |> pog.parameter(pog.text(instructions_json))
    |> pog.parameter(pog.float(recipe.macros.protein))
    |> pog.parameter(pog.float(recipe.macros.fat))
    |> pog.parameter(pog.float(recipe.macros.carbs))
    |> pog.parameter(pog.int(recipe.servings))
    |> pog.parameter(pog.text(recipe.category))
    |> pog.parameter(pog.text(fodmap_string))
    |> pog.parameter(pog.bool(recipe.vertical_compliant))
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(format_pog_error(e)))
    Ok(_) -> Ok(Nil)
  }
}

/// Get all recipes from the database
pub fn get_all_recipes(conn: pog.Connection) -> Result(List(Recipe), StorageError) {
  let sql =
    "SELECT id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant
     FROM recipes ORDER BY name"

  case
    pog.query(sql)
    |> pog.returning(recipe_decoder())
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(format_pog_error(e)))
    Ok(pog.Returned(_, rows)) -> Ok(rows)
  }
}

/// Get a specific recipe by ID
pub fn get_recipe_by_id(
  conn: pog.Connection,
  recipe_id: String,
) -> Result(Recipe, StorageError) {
  let sql =
    "SELECT id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant
     FROM recipes WHERE id = $1"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(recipe_id))
    |> pog.returning(recipe_decoder())
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(format_pog_error(e)))
    Ok(pog.Returned(0, _)) -> Error(NotFound)
    Ok(pog.Returned(_, [])) -> Error(NotFound)
    Ok(pog.Returned(_, [row, ..])) -> Ok(row)
  }
}

/// Delete a recipe
pub fn delete_recipe(
  conn: pog.Connection,
  recipe_id: String,
) -> Result(Nil, StorageError) {
  let sql = "DELETE FROM recipes WHERE id = $1"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(recipe_id))
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(format_pog_error(e)))
    Ok(_) -> Ok(Nil)
  }
}

/// Get recipes by category
pub fn get_recipes_by_category(
  conn: pog.Connection,
  category: String,
) -> Result(List(Recipe), StorageError) {
  let sql =
    "SELECT id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant
     FROM recipes WHERE category = $1 ORDER BY name"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(category))
    |> pog.returning(recipe_decoder())
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(format_pog_error(e)))
    Ok(pog.Returned(_, rows)) -> Ok(rows)
  }
}

/// Recipe decoder helper
fn recipe_decoder() -> decode.Decoder(Recipe) {
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
  use vertical_compliant <- decode.field(10, decode.bool)

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
// USDA Food Search Functions
// ============================================================================

/// A food item from the USDA database
pub type UsdaFood {
  UsdaFood(
    fdc_id: Int,
    description: String,
    data_type: String,
    category: String,
  )
}

/// Nutrient value for a food
pub type FoodNutrientValue {
  FoodNutrientValue(nutrient_name: String, amount: Float, unit: String)
}

/// Search for foods by description using PostgreSQL full-text search
pub fn search_foods(
  conn: pog.Connection,
  query: String,
  limit: Int,
) -> Result(List(UsdaFood), StorageError) {
  // Use PostgreSQL full-text search for better performance
  let sql =
    "SELECT fdc_id, description, data_type, COALESCE(food_category, '')
     FROM foods
     WHERE to_tsvector('english', description) @@ plainto_tsquery('english', $1)
        OR description ILIKE $2
     ORDER BY
       CASE data_type
         WHEN 'sr_legacy_food' THEN 1
         WHEN 'foundation_food' THEN 2
         WHEN 'survey_fndds_food' THEN 3
         ELSE 4
       END,
       description
     LIMIT $3"

  let search_pattern = "%" <> query <> "%"

  let decoder = {
    use fdc_id <- decode.field(0, decode.int)
    use description <- decode.field(1, decode.string)
    use data_type <- decode.field(2, decode.string)
    use category <- decode.field(3, decode.string)
    decode.success(UsdaFood(
      fdc_id: fdc_id,
      description: description,
      data_type: data_type,
      category: category,
    ))
  }

  case
    pog.query(sql)
    |> pog.parameter(pog.text(query))
    |> pog.parameter(pog.text(search_pattern))
    |> pog.parameter(pog.int(limit))
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(format_pog_error(e)))
    Ok(pog.Returned(_, rows)) -> Ok(rows)
  }
}

/// Get nutrients for a specific food
pub fn get_food_nutrients(
  conn: pog.Connection,
  fdc_id: Int,
) -> Result(List(FoodNutrientValue), StorageError) {
  let sql =
    "SELECT n.name, COALESCE(fn.amount, 0), n.unit_name
     FROM food_nutrients fn
     JOIN nutrients n ON fn.nutrient_id = n.id
     WHERE fn.fdc_id = $1
     ORDER BY n.rank NULLS LAST, n.name"

  let decoder = {
    use name <- decode.field(0, decode.string)
    use amount <- decode.field(1, decode.float)
    use unit <- decode.field(2, decode.string)
    decode.success(FoodNutrientValue(
      nutrient_name: name,
      amount: amount,
      unit: unit,
    ))
  }

  case
    pog.query(sql)
    |> pog.parameter(pog.int(fdc_id))
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(format_pog_error(e)))
    Ok(pog.Returned(_, rows)) -> Ok(rows)
  }
}

/// Get a single food by FDC ID
pub fn get_food_by_id(
  conn: pog.Connection,
  fdc_id: Int,
) -> Result(UsdaFood, StorageError) {
  let sql =
    "SELECT fdc_id, description, data_type, COALESCE(food_category, '')
     FROM foods WHERE fdc_id = $1"

  let decoder = {
    use fdc_id <- decode.field(0, decode.int)
    use description <- decode.field(1, decode.string)
    use data_type <- decode.field(2, decode.string)
    use category <- decode.field(3, decode.string)
    decode.success(UsdaFood(
      fdc_id: fdc_id,
      description: description,
      data_type: data_type,
      category: category,
    ))
  }

  case
    pog.query(sql)
    |> pog.parameter(pog.int(fdc_id))
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(format_pog_error(e)))
    Ok(pog.Returned(0, _)) -> Error(NotFound)
    Ok(pog.Returned(_, [])) -> Error(NotFound)
    Ok(pog.Returned(_, [row, ..])) -> Ok(row)
  }
}

/// Get count of foods in database
pub fn get_foods_count(conn: pog.Connection) -> Result(Int, StorageError) {
  let sql = "SELECT COUNT(*)::int FROM foods"

  let decoder = {
    use count <- decode.field(0, decode.int)
    decode.success(count)
  }

  case
    pog.query(sql)
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(format_pog_error(e)))
    Ok(pog.Returned(_, [count])) -> Ok(count)
    Ok(_) -> Ok(0)
  }
}

// ============================================================================
// Food Log Functions
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
    Error(e) -> Error(DatabaseError(format_pog_error(e)))
    Ok(_) -> Ok(Nil)
  }
}

/// Get food logs for a specific date
pub fn get_food_logs_by_date(
  conn: pog.Connection,
  date: String,
) -> Result(List(FoodLog), StorageError) {
  let sql =
    "SELECT id, date, recipe_id, recipe_name, servings, protein, fat, carbs, meal_type, logged_at::text,
            fiber, sugar, sodium, cholesterol, vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k,
            vitamin_b6, vitamin_b12, folate, thiamin, riboflavin, niacin, calcium, iron, magnesium,
            phosphorus, potassium, zinc
     FROM food_logs WHERE date = $1 ORDER BY logged_at"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(date))
    |> pog.returning(food_log_decoder())
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(format_pog_error(e)))
    Ok(pog.Returned(_, rows)) -> Ok(rows)
  }
}

/// Delete a food log entry
pub fn delete_food_log(
  conn: pog.Connection,
  log_id: String,
) -> Result(Nil, StorageError) {
  let sql = "DELETE FROM food_logs WHERE id = $1"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(log_id))
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(format_pog_error(e)))
    Ok(_) -> Ok(Nil)
  }
}

/// Get recent meals (distinct by recipe, most recent first)
pub fn get_recent_meals(
  conn: pog.Connection,
  limit: Int,
) -> Result(List(FoodLogEntry), StorageError) {
  let sql =
    "SELECT DISTINCT ON (recipe_id) id, date, recipe_id, recipe_name, servings, protein, fat, carbs, meal_type, logged_at::text,
            fiber, sugar, sodium, cholesterol, vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k,
            vitamin_b6, vitamin_b12, folate, thiamin, riboflavin, niacin, calcium, iron, magnesium,
            phosphorus, potassium, zinc
     FROM food_logs
     ORDER BY recipe_id, logged_at DESC
     LIMIT $1"

  let decoder = {
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
      None, None, None, None, None, None, None, None, None, None, None, None, None, None, None, None, None, None, None, None, None ->
        None
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
      id: id,
      recipe_id: recipe_id,
      recipe_name: recipe_name,
      servings: servings,
      macros: Macros(protein: protein, fat: fat, carbs: carbs),
      micronutrients: micronutrients,
      meal_type: meal_type,
      logged_at: logged_at,
    ))
  }

  case
    pog.query(sql)
    |> pog.parameter(pog.int(limit))
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(format_pog_error(e)))
    Ok(pog.Returned(_, rows)) -> Ok(rows)
  }
}

/// Save a food log entry using shared types
pub fn save_food_log_entry(
  conn: pog.Connection,
  date: String,
  entry: FoodLogEntry,
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

  let meal_type_str = case entry.meal_type {
    Breakfast -> "breakfast"
    Lunch -> "lunch"
    Dinner -> "dinner"
    Snack -> "snack"
  }

  case
    pog.query(sql)
    |> pog.parameter(pog.text(entry.id))
    |> pog.parameter(pog.text(date))
    |> pog.parameter(pog.text(entry.recipe_id))
    |> pog.parameter(pog.text(entry.recipe_name))
    |> pog.parameter(pog.float(entry.servings))
    |> pog.parameter(pog.float(entry.macros.protein))
    |> pog.parameter(pog.float(entry.macros.fat))
    |> pog.parameter(pog.float(entry.macros.carbs))
    |> pog.parameter(pog.text(meal_type_str))
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(format_pog_error(e)))
    Ok(_) -> Ok(Nil)
  }
}

/// Get user profile or return default if not found
pub fn get_user_profile_or_default(conn: pog.Connection) -> UserProfile {
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

fn food_log_decoder() -> decode.Decoder(FoodLog) {
  use id <- decode.field(0, decode.string)
  use date <- decode.field(1, decode.string)
  use recipe_id <- decode.field(2, decode.string)
  use recipe_name <- decode.field(3, decode.string)
  use servings <- decode.field(4, decode.float)
  use protein <- decode.field(5, decode.float)
  use fat <- decode.field(6, decode.float)
  use carbs <- decode.field(7, decode.float)
  use meal_type <- decode.field(8, decode.string)
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
  decode.success(FoodLog(
    id: id,
    date: date,
    recipe_id: recipe_id,
    recipe_name: recipe_name,
    servings: servings,
    protein: protein,
    fat: fat,
    carbs: carbs,
    meal_type: meal_type,
    logged_at: logged_at,
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

// ============================================================================
// Helper Functions
// ============================================================================

// ============================================================================
// Daily Log Functions (uses types from meal_planner/types)
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
            phosphorus, potassium, zinc
     FROM food_logs WHERE date = $1 ORDER BY logged_at"

  let decoder = {
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
      None, None, None, None, None, None, None, None, None, None, None, None, None, None, None, None, None, None, None, None, None ->
        None
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
      id: id,
      recipe_id: recipe_id,
      recipe_name: recipe_name,
      servings: servings,
      macros: Macros(protein: protein, fat: fat, carbs: carbs),
      micronutrients: micronutrients,
      meal_type: meal_type,
      logged_at: logged_at,
    ))
  }

  case
    pog.query(sql)
    |> pog.parameter(pog.text(date))
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(format_pog_error(e)))
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
) -> types.Micronutrients {
  let micros_list =
    list.filter_map(entries, fn(entry) {
      case entry.micronutrients {
        Some(m) -> Ok(m)
        None -> Error(Nil)
      }
    })
  types.micronutrients_sum(micros_list)
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Format pog error to string
fn format_pog_error(err: pog.QueryError) -> String {
  case err {
    pog.ConnectionUnavailable -> "Database connection unavailable"
    pog.ConstraintViolated(msg, constraint, _detail) ->
      "Constraint violated: " <> constraint <> " - " <> msg
    pog.PostgresqlError(_code, _name, msg) -> "PostgreSQL error: " <> msg
    pog.UnexpectedArgumentCount(expected, got) ->
      "Expected "
      <> int.to_string(expected)
      <> " arguments, got "
      <> int.to_string(got)
    pog.UnexpectedArgumentType(expected, got) ->
      "Expected type " <> expected <> ", got " <> got
    pog.UnexpectedResultType(errs) -> {
      let msgs =
        list.map(errs, fn(e) {
          case e {
            decode.DecodeError(expected, found, path) ->
              "Expected " <> expected <> " at " <> string.join(path, ".") <> ", found " <> found
          }
        })
      "Decode error: " <> string.join(msgs, "; ")
    }
    pog.QueryTimeout -> "Database query timeout"
  }
}
