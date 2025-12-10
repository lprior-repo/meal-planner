/// PostgreSQL storage module for nutrition data persistence
import gleam/dynamic/decode
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/id
import meal_planner/postgres
import meal_planner/storage/foods.{type UsdaFood, UsdaFood}
import meal_planner/storage/profile.{
  type StorageError, DatabaseError, InvalidInput, NotFound, Unauthorized,
}
import meal_planner/storage/utils
import meal_planner/types.{
  type DailyLog, type FoodLogEntry, type Macros, type UserProfile, Active,
  Breakfast, DailyLog, Dinner, FoodLogEntry, Gain, Lose, Lunch, Macros, Maintain,
  Moderate, Sedentary, Snack, UserProfile,
}
import pog

/// Valid USDA food categories for SQL injection prevention
/// These are the official USDA FoodData Central categories
const valid_food_categories = [
  "Branded Foods",
  "Dairy and Egg Products",
  "Spices and Herbs",
  "Baby Foods",
  "Fats and Oils",
  "Poultry Products",
  "Fruits and Fruit Juices",
  "Beef Products",
  "Beverages",
  "Vegetables and Vegetable Products",
  "Nut and Seed Products",
  "Legumes and Legume Products",
  "Cereal Grains and Pasta",
  "Fast Foods",
  "Meals, Entrees, and Side Dishes",
  "Snacks",
  "Sweets",
  "Soups, Sauces, and Gravies",
  "Restaurant Foods",
  "Pork Products",
  "Lamb, Veal, and Game Products",
  "Finfish and Shellfish Products",
  "Baked Products",
  "American Indian/Alaska Native Foods",
]

/// Validate category against whitelist to prevent SQL injection
/// Returns Ok with the matched category or Error with message
fn validate_category(category: String) -> Result(String, String) {
  let trimmed = string.trim(category)

  case
    list.find(valid_food_categories, fn(valid) {
      string.lowercase(valid) == string.lowercase(trimmed)
    })
  {
    Ok(found) -> Ok(found)
    Error(_) -> Error("Invalid food category: '" <> trimmed <> "'")
  }
}

/// Database configuration (re-export from postgres module)
pub type DbConfig =
  postgres.Config

/// Default configuration for development (re-export from postgres module)
pub fn default_config() -> DbConfig {
  postgres.default_config()
}

/// Start the database connection pool (re-export from postgres module)
pub fn start_pool(config: DbConfig) -> Result(pog.Connection, String) {
  postgres.connect(config)
  |> result.map_error(postgres.format_error)
}

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

/// Log entry type for food consumption tracking
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

/// Food summary item for weekly aggregation
pub type FoodSummaryItem {

  FoodSummaryItem(
    food_id: Int,
    food_name: String,
    log_count: Int,
    avg_protein: Float,
    avg_fat: Float,
    avg_carbs: Float,
  )
}

/// Weekly summary of nutrition data
pub type WeeklySummary {

  WeeklySummary(
    total_logs: Int,
    avg_protein: Float,
    avg_fat: Float,
    avg_carbs: Float,
    by_food: List(FoodSummaryItem),
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
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))

    Ok(_) -> Ok(Nil)
  }
}

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
    |> pog.returning(food_log_decoder())
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))

    Ok(pog.Returned(_, rows)) -> Ok(rows)
  }
}

/// Get logs for a specific user and date from the logs table
///
/// Queries the logs table (distinct from food_logs) which tracks:
/// - user_id: Reference to user
/// - food_id: Reference to food item from USDA database
/// - quantity: Amount consumed
/// - log_date: Date of consumption
/// - macros: JSONB column storing macro nutrients
///
/// Returns empty list if no logs exist for the date (handles gracefully)
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

  let decoder = {
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

/// Get the 10 most recently logged USDA foods (distinct by fdc_id)
///
/// Returns the most recent USDA foods that have been logged by the user.
/// Uses SELECT DISTINCT ON (f.fdc_id) to ensure only one entry per food.
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
      serving_size: option.unwrap(serving_size, "100g"),
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

/// Save a food log entry using shared types
pub fn save_food_log_entry(
  conn: pog.Connection,
  date: String,
  entry: FoodLogEntry,
) -> Result(Nil, StorageError) {
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

/// Get user profile or return default if not found
pub fn get_user_profile_or_default(conn: pog.Connection) -> UserProfile {
  case profile.get_user_profile(conn) {
    Ok(profile) -> profile

    Error(_) -> default_user_profile()
  }
}

fn default_user_profile() -> UserProfile {
  UserProfile(
    id: id.user_id("user-1"),
    bodyweight: 180.0,
    activity_level: Moderate,
    goal: Maintain,
    meals_per_day: 3,
    micronutrient_goals: None,
  )
}

fn food_log_decoder() -> decode.Decoder(FoodLogEntry) {
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

            phosphorus, potassium, zinc, source_type, source_id

     FROM food_logs WHERE date = $1 ORDER BY logged_at"

  let decoder = {
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

  case
    pog.query(sql)
    |> pog.parameter(pog.text(date))
    |> pog.returning(decoder)
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

/// Get weekly summary of nutrition data aggregated by food
/// Calculates totals and averages for logs within 7 days starting from start_date
pub fn get_weekly_summary(
  conn: pog.Connection,
  user_id: Int,
  start_date: String,
) -> Result(WeeklySummary, StorageError) {
  let sql =
    "WITH weekly_logs AS (

       SELECT

         l.id,

         l.food_id,

         f.description as food_name,

         l.macros->>'protein' as protein_str,

         l.macros->>'fat' as fat_str,

         l.macros->>'carbs' as carbs_str,

         l.log_date

       FROM logs l

       JOIN foods f ON l.food_id = f.fdc_id

       WHERE l.user_id = $1

         AND l.log_date >= $2::date

         AND l.log_date < ($2::date + INTERVAL '7 days')

     )

     SELECT

       COALESCE(COUNT(DISTINCT id), 0) as total_logs,

       COALESCE(AVG(CAST(protein_str AS FLOAT)), 0.0) as avg_protein,

       COALESCE(AVG(CAST(fat_str AS FLOAT)), 0.0) as avg_fat,

       COALESCE(AVG(CAST(carbs_str AS FLOAT)), 0.0) as avg_carbs,

       food_id,

       food_name,

       COUNT(DISTINCT id) as log_count,

       COALESCE(AVG(CAST(protein_str AS FLOAT)), 0.0) as food_avg_protein,

       COALESCE(AVG(CAST(fat_str AS FLOAT)), 0.0) as food_avg_fat,

       COALESCE(AVG(CAST(carbs_str AS FLOAT)), 0.0) as food_avg_carbs

     FROM weekly_logs

     GROUP BY ROLLUP(food_id, food_name)

     ORDER BY food_id DESC NULLS FIRST"

  let summary_decoder = {
    use total_logs <- decode.field(0, decode.int)

    use avg_protein <- decode.field(1, decode.float)

    use avg_fat <- decode.field(2, decode.float)

    use avg_carbs <- decode.field(3, decode.float)

    use food_id <- decode.field(4, decode.optional(decode.int))

    use food_name <- decode.field(5, decode.optional(decode.string))

    use log_count <- decode.field(6, decode.optional(decode.int))

    use food_avg_protein <- decode.field(7, decode.float)

    use food_avg_fat <- decode.field(8, decode.float)

    use food_avg_carbs <- decode.field(9, decode.float)

    decode.success(#(
      total_logs,
      avg_protein,
      avg_fat,
      avg_carbs,
      food_id,
      food_name,
      log_count,
      food_avg_protein,
      food_avg_fat,
      food_avg_carbs,
    ))
  }

  case
    pog.query(sql)
    |> pog.parameter(pog.int(user_id))
    |> pog.parameter(pog.text(start_date))
    |> pog.returning(summary_decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))

    Ok(pog.Returned(_, rows)) -> {
      case rows {
        [] ->
          Ok(
            WeeklySummary(
              total_logs: 0,
              avg_protein: 0.0,
              avg_fat: 0.0,
              avg_carbs: 0.0,
              by_food: [],
            ),
          )

        [first, ..] -> {
          let #(total_logs, avg_protein, avg_fat, avg_carbs, _, _, _, _, _, _) =
            first

          let food_items =
            list.filter_map(rows, fn(row) {
              let #(
                _,
                _,
                _,
                _,
                food_id,
                food_name,
                log_count,
                food_avg_protein,
                food_avg_fat,
                food_avg_carbs,
              ) = row

              case food_id, food_name, log_count {
                Some(fid), Some(fname), Some(count) ->
                  Ok(FoodSummaryItem(
                    food_id: fid,
                    food_name: fname,
                    log_count: count,
                    avg_protein: food_avg_protein,
                    avg_fat: food_avg_fat,
                    avg_carbs: food_avg_carbs,
                  ))

                _, _, _ -> Error(Nil)
              }
            })

          Ok(WeeklySummary(
            total_logs: total_logs,
            avg_protein: avg_protein,
            avg_fat: avg_fat,
            avg_carbs: avg_carbs,
            by_food: food_items,
          ))
        }
      }
    }
  }
}
// ============================================================================
