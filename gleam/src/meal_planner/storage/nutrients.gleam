/// PostgreSQL storage module for nutrition data persistence
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/ncp
import meal_planner/postgres
import meal_planner/storage/foods.{type FoodNutrientValue}
import meal_planner/storage/utils
import meal_planner/types.{
  type DailyLog, type FoodLogEntry, type Macros, type Recipe, type UserProfile,
  Active, Breakfast, DailyLog, Dinner, FoodLogEntry, Gain, High, Ingredient,
  Lose, Low, Lunch, Macros, Maintain, Medium, Moderate, Recipe, Sedentary, Snack,
  UserProfile,
}
import pog

/// Error type for storage operations
pub type StorageError {
  NotFound
  DatabaseError(String)
  InvalidInput(String)
  Unauthorized(String)
}

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
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))

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
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))

    Ok(pog.Returned(0, _)) -> Error(NotFound)

    Ok(pog.Returned(_, [])) -> Error(NotFound)

    Ok(pog.Returned(_, [row, ..])) -> Ok(row)
  }
}

/// Load USDA food with calculated macros and micronutrients
/// This combines food info with parsed nutrient data for display in forms
pub fn load_usda_food_with_macros(
  conn: pog.Connection,
  fdc_id: Int,
) -> Result(UsdaFoodWithNutrients, StorageError) {
  use food <- result.try(get_food_by_id(conn, fdc_id))

  use nutrients <- result.try(get_food_nutrients(conn, fdc_id))

  let macros = parse_usda_macros(nutrients)

  let micronutrients = parse_usda_micronutrients(nutrients)

  Ok(UsdaFoodWithNutrients(
    fdc_id: food.fdc_id,
    description: food.description,
    data_type: food.data_type,
    category: food.category,
    macros: macros,
    micronutrients: micronutrients,
  ))
}

/// Get count of foods in database
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
      id: id,
      recipe_id: recipe_id,
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
/// Sums all macros across daily food logs
/// Public so it can be tested and reused
pub fn calculate_total_macros(entries: List(FoodLogEntry)) -> Macros {
  list.fold(entries, Macros(protein: 0.0, fat: 0.0, carbs: 0.0), fn(acc, entry) {
    Macros(
      protein: acc.protein +. entry.macros.protein,
      fat: acc.fat +. entry.macros.fat,
      carbs: acc.carbs +. entry.macros.carbs,
    )
  })
}

/// Calculate total micronutrients from food log entries
/// Aggregates all 21 micronutrients across daily food logs
/// Returns None if no entries have micronutrient data
/// Public so it can be tested and reused
pub fn calculate_total_micronutrients(
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

// Unified Food Logging with Source Tracking

// ============================================================================

/// Save any food (recipe/custom/USDA) to the daily log with source tracking
/// This is the unified entry point for logging all food types
pub fn save_food_to_log(
  conn: pog.Connection,
  date: String,
  food_source: types.FoodSource,
  servings: Float,
  meal_type: types.MealType,
) -> Result(FoodLogEntry, StorageError) {
  // Validate servings is non-negative

  case servings <. 0.0 {
    True -> Error(InvalidInput("Servings must be non-negative"))

    False ->
      // Pattern match on food source type to fetch appropriate data

      case food_source {
        // Recipe source: Fetch recipe and use its macros
        types.RecipeSource(recipe_id) -> {
          use recipe <- result.try(get_recipe_by_id(conn, recipe_id))

          // Scale recipe macros by servings

          let scaled_macros = types.macros_scale(recipe.macros, servings)

          // Generate unique ID for the log entry

          let log_id = generate_log_id(date, recipe_id, meal_type)

          // Insert into food_logs table with source tracking

          insert_food_log_entry(
            conn,
            log_id,
            date,
            recipe.id,
            recipe.name,
            servings,
            scaled_macros,
            None,
            // Recipes don't have micronutrients yet

            meal_type,
            "recipe",
            recipe.id,
          )
        }

        // USDA food source: Fetch food and nutrients, parse and scale
        types.UsdaFoodSource(fdc_id) -> {
          use food <- result.try(get_food_by_id(conn, fdc_id))

          use nutrients <- result.try(get_food_nutrients(conn, fdc_id))

          // Parse USDA nutrients into macros and micronutrients

          let macros = parse_usda_macros(nutrients)

          let micronutrients = parse_usda_micronutrients(nutrients)

          // USDA data is per 100g, scale by servings

          let scaled_macros = types.macros_scale(macros, servings)

          let scaled_micros = case micronutrients {
            Some(m) -> Some(types.micronutrients_scale(m, servings))

            None -> None
          }

          // Generate unique ID

          let source_id = int.to_string(fdc_id)

          let log_id = generate_log_id(date, source_id, meal_type)

          // Insert with USDA source tracking

          insert_food_log_entry(
            conn,
            log_id,
            date,
            source_id,
            food.description,
            servings,
            scaled_macros,
            scaled_micros,
            meal_type,
            "usda_food",
            source_id,
          )
        }

        // Custom food source: Fetch custom food and use its macros/micronutrients
        types.CustomFoodSource(custom_food_id, user_id) -> {
          use custom_food <- result.try(get_custom_food_by_id(
            conn,
            custom_food_id,
            user_id,
          ))

          // Scale custom food macros by servings

          let scaled_macros = types.macros_scale(custom_food.macros, servings)

          let scaled_micros = case custom_food.micronutrients {
            Some(m) -> Some(types.micronutrients_scale(m, servings))

            None -> None
          }

          // Generate unique ID

          let log_id = generate_log_id(date, custom_food_id, meal_type)

          // Insert with custom food source tracking

          insert_food_log_entry(
            conn,
            log_id,
            date,
            custom_food_id,
            custom_food.name,
            servings,
            scaled_macros,
            scaled_micros,
            meal_type,
            "custom_food",
            custom_food_id,
          )
        }
      }
  }
}

/// Parse USDA nutrient list into Macros
/// Extracts protein, fat, and carbs from the nutrient list
fn parse_usda_macros(nutrients: List(FoodNutrientValue)) -> Macros {
  let protein = find_nutrient_amount(nutrients, "Protein") |> option.unwrap(0.0)

  let fat =
    find_nutrient_amount(nutrients, "Total lipid (fat)") |> option.unwrap(0.0)

  let carbs =
    find_nutrient_amount(nutrients, "Carbohydrate, by difference")
    |> option.unwrap(0.0)

  Macros(protein: protein, fat: fat, carbs: carbs)
}

/// Parse USDA nutrient list into Micronutrients
/// Maps USDA nutrient names to our micronutrient fields
fn parse_usda_micronutrients(
  nutrients: List(FoodNutrientValue),
) -> Option(types.Micronutrients) {
  let fiber = find_nutrient_amount(nutrients, "Fiber, total dietary")

  let sugar = find_nutrient_amount(nutrients, "Sugars, total including NLEA")

  let sodium = find_nutrient_amount(nutrients, "Sodium, Na")

  let cholesterol = find_nutrient_amount(nutrients, "Cholesterol")

  let vitamin_a = find_nutrient_amount(nutrients, "Vitamin A, RAE")

  let vitamin_c =
    find_nutrient_amount(nutrients, "Vitamin C, total ascorbic acid")

  let vitamin_d = find_nutrient_amount(nutrients, "Vitamin D (D2 + D3)")

  let vitamin_e =
    find_nutrient_amount(nutrients, "Vitamin E (alpha-tocopherol)")

  let vitamin_k = find_nutrient_amount(nutrients, "Vitamin K (phylloquinone)")

  let vitamin_b6 = find_nutrient_amount(nutrients, "Vitamin B-6")

  let vitamin_b12 = find_nutrient_amount(nutrients, "Vitamin B-12")

  let folate = find_nutrient_amount(nutrients, "Folate, total")

  let thiamin = find_nutrient_amount(nutrients, "Thiamin")

  let riboflavin = find_nutrient_amount(nutrients, "Riboflavin")

  let niacin = find_nutrient_amount(nutrients, "Niacin")

  let calcium = find_nutrient_amount(nutrients, "Calcium, Ca")

  let iron = find_nutrient_amount(nutrients, "Iron, Fe")

  let magnesium = find_nutrient_amount(nutrients, "Magnesium, Mg")

  let phosphorus = find_nutrient_amount(nutrients, "Phosphorus, P")

  let potassium = find_nutrient_amount(nutrients, "Potassium, K")

  let zinc = find_nutrient_amount(nutrients, "Zinc, Zn")

  // Return Some if at least one micronutrient is present

  case
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
}

/// Find a nutrient value by name in the nutrient list
fn find_nutrient_amount(
  nutrients: List(FoodNutrientValue),
  name: String,
) -> Option(Float) {
  case list.find(nutrients, fn(n) { n.nutrient_name == name }) {
    Ok(nutrient) -> Some(nutrient.amount)

    Error(_) -> None
  }
}

/// Generate a unique ID for a food log entry
/// Format: date_sourceid_mealtype_timestamp
fn generate_log_id(
  date: String,
  source_id: String,
  meal_type: types.MealType,
) -> String {
  let meal_str = case meal_type {
    Breakfast -> "breakfast"

    Lunch -> "lunch"

    Dinner -> "dinner"

    Snack -> "snack"
  }

  // Simple ID generation - in production you'd want a UUID

  date <> "_" <> source_id <> "_" <> meal_str
}

/// Insert a food log entry into the database
/// Internal helper for save_food_to_log
fn insert_food_log_entry(
  conn: pog.Connection,
  id: String,
  date: String,
  recipe_id: String,
  recipe_name: String,
  servings: Float,
  macros: Macros,
  micronutrients: Option(types.Micronutrients),
  meal_type: types.MealType,
  source_type: String,
  source_id: String,
) -> Result(FoodLogEntry, StorageError) {
  let meal_type_str = case meal_type {
    Breakfast -> "breakfast"

    Lunch -> "lunch"

    Dinner -> "dinner"

    Snack -> "snack"
  }

  // Build SQL with micronutrient columns

  let sql =
    "INSERT INTO food_logs

     (id, date, recipe_id, recipe_name, servings, protein, fat, carbs, meal_type,

      fiber, sugar, sodium, cholesterol, vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k,

      vitamin_b6, vitamin_b12, folate, thiamin, riboflavin, niacin, calcium, iron, magnesium,

      phosphorus, potassium, zinc, source_type, source_id, logged_at)

     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9,

             $10, $11, $12, $13, $14, $15, $16, $17, $18,

             $19, $20, $21, $22, $23, $24, $25, $26, $27,

             $28, $29, $30, $31, $32, NOW())

     RETURNING id, date, recipe_id, recipe_name, servings, protein, fat, carbs, meal_type, logged_at::text,

               fiber, sugar, sodium, cholesterol, vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k,

               vitamin_b6, vitamin_b12, folate, thiamin, riboflavin, niacin, calcium, iron, magnesium,

               phosphorus, potassium, zinc, source_type, source_id"

  // Helper to convert Option(Float) to pog parameter

  let opt_float = fn(opt: Option(Float)) {
    case opt {
      Some(v) -> pog.nullable(pog.float, Some(v))

      None -> pog.nullable(pog.float, None)
    }
  }

  // Extract micronutrients or use Nones

  let micros = case micronutrients {
    Some(m) -> m

    None -> types.micronutrients_zero()
  }

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
      id: id,
      recipe_id: recipe_id,
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
    |> pog.parameter(pog.text(id))
    |> pog.parameter(pog.text(date))
    |> pog.parameter(pog.text(recipe_id))
    |> pog.parameter(pog.text(recipe_name))
    |> pog.parameter(pog.float(servings))
    |> pog.parameter(pog.float(macros.protein))
    |> pog.parameter(pog.float(macros.fat))
    |> pog.parameter(pog.float(macros.carbs))
    |> pog.parameter(pog.text(meal_type_str))
    |> pog.parameter(opt_float(micros.fiber))
    |> pog.parameter(opt_float(micros.sugar))
    |> pog.parameter(opt_float(micros.sodium))
    |> pog.parameter(opt_float(micros.cholesterol))
    |> pog.parameter(opt_float(micros.vitamin_a))
    |> pog.parameter(opt_float(micros.vitamin_c))
    |> pog.parameter(opt_float(micros.vitamin_d))
    |> pog.parameter(opt_float(micros.vitamin_e))
    |> pog.parameter(opt_float(micros.vitamin_k))
    |> pog.parameter(opt_float(micros.vitamin_b6))
    |> pog.parameter(opt_float(micros.vitamin_b12))
    |> pog.parameter(opt_float(micros.folate))
    |> pog.parameter(opt_float(micros.thiamin))
    |> pog.parameter(opt_float(micros.riboflavin))
    |> pog.parameter(opt_float(micros.niacin))
    |> pog.parameter(opt_float(micros.calcium))
    |> pog.parameter(opt_float(micros.iron))
    |> pog.parameter(opt_float(micros.magnesium))
    |> pog.parameter(opt_float(micros.phosphorus))
    |> pog.parameter(opt_float(micros.potassium))
    |> pog.parameter(opt_float(micros.zinc))
    |> pog.parameter(pog.text(source_type))
    |> pog.parameter(pog.text(source_id))
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))

    Ok(pog.Returned(0, _)) ->
      Error(DatabaseError("Failed to insert food log entry"))

    Ok(pog.Returned(_, [])) ->
      Error(DatabaseError("Failed to insert food log entry"))

    Ok(pog.Returned(_, [entry, ..])) -> Ok(entry)
  }
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
              "Expected "
              <> expected
              <> " at "
              <> string.join(path, ".")
              <> ", found "
              <> found
          }
        })

      "Decode error: " <> string.join(msgs, "; ")
    }

    pog.QueryTimeout -> "Database query timeout"
  }
}
