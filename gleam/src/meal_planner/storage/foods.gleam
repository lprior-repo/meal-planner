/// Food storage module - USDA foods and custom foods
/// Handles searching, retrieving, and managing food data
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam/string
import meal_planner/storage/utils
import gleam/string
import meal_planner/storage/profile.{type StorageError, DatabaseError, NotFound}
import meal_planner/storage/utils
import meal_planner/storage/utils
import meal_planner/storage/utils
import meal_planner/types
import pog

// ============================================================================
// Type Exports
// ============================================================================

pub type UsdaFood {
  UsdaFood(
    fdc_id: Int,
    description: String,
    data_type: String,
    category: String,
  )
}

pub type FoodNutrientValue {
  FoodNutrientValue(
    nutrient_id: Int,
    nutrient_name: String,
    amount: Float,
    unit: String,
  )
}

pub type UsdaFoodWithNutrients {
  UsdaFoodWithNutrients(food: UsdaFood, nutrients: List(FoodNutrientValue))
}

// ============================================================================
// USDA Foods - Search and Retrieval
// ============================================================================

/// Search for USDA foods by query string
pub fn search_foods(
  conn: pog.Connection,
  query: String,
  limit: Int,
) -> Result(List(UsdaFood), StorageError) {
  let sql =
    "SELECT fdc_id, description, data_type, COALESCE(food_category, '')
     FROM foods
     WHERE to_tsvector('english', description) @@ plainto_tsquery('english', $1)
        OR description ILIKE $2
     ORDER BY
       CASE data_type
         WHEN 'foundation_food' THEN 100
         WHEN 'sr_legacy_food' THEN 95
         WHEN 'survey_fndds_food' THEN 90
         WHEN 'sub_sample_food' THEN 50
         WHEN 'agricultural_acquisition' THEN 40
         WHEN 'market_acquisition' THEN 35
         WHEN 'branded_food' THEN 30
         ELSE 10
       END DESC,
       array_length(string_to_array(description, ' '), 1),
       description
     LIMIT $3"

  let search_pattern = "%" <> query <> "%"

  let decoder = {
    use fdc_id <- decode.field(0, decode.int)
    use description <- decode.field(1, decode.string)
    use data_type <- decode.field(2, decode.string)
    use category <- decode.field(3, decode.string)
    decode.success(UsdaFood(fdc_id, description, data_type, category))
  }

  case
    pog.query(sql)
    |> pog.parameter(pog.text(query))
    |> pog.parameter(pog.text(search_pattern))
    |> pog.parameter(pog.int(limit))
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(_, rows)) -> Ok(rows)
  }
}

/// Search for foods with filters
pub fn search_foods_filtered(
  conn: pog.Connection,
  query: String,
  filters: types.SearchFilters,
  limit: Int,
) -> Result(List(UsdaFood), StorageError) {
  search_foods(conn, query, limit)
}

/// Get food by FDC ID
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
    decode.success(UsdaFood(fdc_id, description, data_type, category))
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
    Ok(pog.Returned(_, [food, ..])) -> Ok(food)
  }
}

/// Load USDA food with macros
pub fn load_usda_food_with_macros(
  conn: pog.Connection,
  fdc_id: Int,
) -> Result(UsdaFoodWithNutrients, StorageError) {
  use food <- result.try(get_food_by_id(conn, fdc_id))
  use nutrients <- result.try(get_food_nutrients(conn, fdc_id))
  Ok(UsdaFoodWithNutrients(food: food, nutrients: nutrients))
}

/// Get foods count
pub fn get_foods_count(conn: pog.Connection) -> Result(Int, StorageError) {
  let sql = "SELECT COUNT(*) FROM foods"

  let decoder = decode.field(0, decode.int)

  case
    pog.query(sql)
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(_, [])) -> Ok(0)
    Ok(pog.Returned(_, [count, ..])) -> Ok(count)
  }
}

/// Get food categories
pub fn get_food_categories(
  conn: pog.Connection,
) -> Result(List(String), StorageError) {
  let sql =
    "SELECT DISTINCT food_category FROM foods WHERE food_category IS NOT NULL"

  let decoder = {
    use category <- decode.field(0, decode.string)
    decode.success(category)
  }

  case
    pog.query(sql)
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(_, rows)) -> Ok(rows)
  }
}

// ============================================================================
// Custom Foods
// ============================================================================

/// Create custom food
pub fn create_custom_food(
  conn: pog.Connection,
  user_id: String,
  food: types.CustomFood,
) -> Result(types.CustomFood, StorageError) {
  let sql =
    "INSERT INTO custom_foods (id, user_id, name, brand, description, serving_size, serving_unit, protein, fat, carbs, calories) 
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
     RETURNING id, user_id, name, brand, description, serving_size, serving_unit, protein, fat, carbs, calories, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(food.id))
    |> pog.parameter(pog.text(user_id))
    |> pog.parameter(pog.text(food.name))
    |> pog.parameter(pog.nullable(pog.text, food.brand))
    |> pog.parameter(pog.nullable(pog.text, food.description))
    |> pog.parameter(pog.float(food.serving_size))
    |> pog.parameter(pog.text(food.serving_unit))
    |> pog.parameter(pog.float(food.macros.protein))
    |> pog.parameter(pog.float(food.macros.fat))
    |> pog.parameter(pog.float(food.macros.carbs))
    |> pog.parameter(pog.float(food.calories))
    |> pog.returning(custom_food_decoder())
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(_, [created_food, ..])) -> Ok(created_food)
    Ok(_) -> Error(NotFound)
  }
}

/// Get custom food by ID
pub fn get_custom_food_by_id(
  conn: pog.Connection,
  user_id: String,
  food_id: String,
) -> Result(types.CustomFood, StorageError) {
  let sql =
    "SELECT id, user_id, name, brand, description, serving_size, serving_unit, protein, fat, carbs, calories, fiber, sugar, sodium, cholesterol, vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k, vitamin_b6, vitamin_b12, folate, thiamin, riboflavin, niacin, calcium, iron, magnesium, phosphorus, potassium, zinc
     FROM custom_foods WHERE id = $1 AND user_id = $2"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(food_id))
    |> pog.parameter(pog.text(user_id))
    |> pog.returning(custom_food_decoder())
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(0, _)) -> Error(NotFound)
    Ok(pog.Returned(_, [])) -> Error(NotFound)
    Ok(pog.Returned(_, [food, ..])) -> Ok(food)
  }
}

/// Search custom foods
pub fn search_custom_foods(
  conn: pog.Connection,
  user_id: String,
  query: String,
  limit: Int,
) -> Result(List(types.CustomFood), StorageError) {
  let sql =
    "SELECT id, user_id, name, brand, description, serving_size, serving_unit, protein, fat, carbs, calories, fiber, sugar, sodium, cholesterol, vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k, vitamin_b6, vitamin_b12, folate, thiamin, riboflavin, niacin, calcium, iron, magnesium, phosphorus, potassium, zinc
     FROM custom_foods
     WHERE user_id = $1
       AND (to_tsvector('english', name) @@ plainto_tsquery('english', $2)
            OR name ILIKE $3)
     ORDER BY LOWER(name), id DESC
     LIMIT $4"

  let search_pattern = "%" <> query <> "%"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(user_id))
    |> pog.parameter(pog.text(query))
    |> pog.parameter(pog.text(search_pattern))
    |> pog.parameter(pog.int(limit))
    |> pog.returning(custom_food_decoder())
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(_, rows)) -> Ok(rows)
  }
}

/// Get custom foods for user
pub fn get_custom_foods_for_user(
  conn: pog.Connection,
  user_id: String,
) -> Result(List(types.CustomFood), StorageError) {
  let sql =
    "SELECT id, user_id, name, brand, description, serving_size, serving_unit, protein, fat, carbs, calories, fiber, sugar, sodium, cholesterol, vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k, vitamin_b6, vitamin_b12, folate, thiamin, riboflavin, niacin, calcium, iron, magnesium, phosphorus, potassium, zinc
     FROM custom_foods WHERE user_id = $1 ORDER BY name"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(user_id))
    |> pog.returning(custom_food_decoder())
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(_, rows)) -> Ok(rows)
  }
}

/// Delete custom food
pub fn delete_custom_food(
  conn: pog.Connection,
  user_id: String,
  food_id: String,
) -> Result(Nil, StorageError) {
  let sql = "DELETE FROM custom_foods WHERE id = $1 AND user_id = $2"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(food_id))
    |> pog.parameter(pog.text(user_id))
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(_) -> Ok(Nil)
  }
}

/// Update custom food
pub fn update_custom_food(
  conn: pog.Connection,
  user_id: String,
  food: types.CustomFood,
) -> Result(types.CustomFood, StorageError) {
  let sql =
    "UPDATE custom_foods SET name = $3, brand = $4, description = $5, serving_size = $6, serving_unit = $7, protein = $8, fat = $9, carbs = $10, calories = $11 WHERE id = $1 AND user_id = $2
     RETURNING id, user_id, name, brand, description, serving_size, serving_unit, protein, fat, carbs, calories, fiber, sugar, sodium, cholesterol, vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k, vitamin_b6, vitamin_b12, folate, thiamin, riboflavin, niacin, calcium, iron, magnesium, phosphorus, potassium, zinc"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(food.id))
    |> pog.parameter(pog.text(user_id))
    |> pog.parameter(pog.text(food.name))
    |> pog.parameter(pog.nullable(pog.text, food.brand))
    |> pog.parameter(pog.nullable(pog.text, food.description))
    |> pog.parameter(pog.float(food.serving_size))
    |> pog.parameter(pog.text(food.serving_unit))
    |> pog.parameter(pog.float(food.macros.protein))
    |> pog.parameter(pog.float(food.macros.fat))
    |> pog.parameter(pog.float(food.macros.carbs))
    |> pog.parameter(pog.float(food.calories))
    |> pog.returning(custom_food_decoder())
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(0, _)) -> Error(NotFound)
    Ok(pog.Returned(_, [])) -> Error(NotFound)
    Ok(pog.Returned(_, [updated_food, ..])) -> Ok(updated_food)
  }
}

// ============================================================================
// Nutrients
// ============================================================================

/// Get food nutrients
pub fn get_food_nutrients(
  conn: pog.Connection,
  fdc_id: Int,
) -> Result(List(FoodNutrientValue), StorageError) {
  let sql =
    "SELECT nutrient_id, nutrient_name, amount, unit FROM food_nutrients WHERE fdc_id = $1"

  let decoder = {
    use nutrient_id <- decode.field(0, decode.int)
    use nutrient_name <- decode.field(1, decode.string)
    use amount <- decode.field(2, decode.float)
    use unit <- decode.field(3, decode.string)
    decode.success(FoodNutrientValue(nutrient_id, nutrient_name, amount, unit))
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

// ============================================================================
// Decoders
// ============================================================================

fn custom_food_decoder() -> decode.Decoder(types.CustomFood) {
  use id <- decode.field(0, decode.string)
  use user_id <- decode.field(1, decode.string)
  use name <- decode.field(2, decode.string)
  use brand <- decode.field(3, decode.optional(decode.string))
  use description <- decode.field(4, decode.optional(decode.string))
  use serving_size <- decode.field(5, decode.float)
  use serving_unit <- decode.field(6, decode.string)
  use protein <- decode.field(7, decode.float)
  use fat <- decode.field(8, decode.float)
  use carbs <- decode.field(9, decode.float)
  use calories <- decode.field(10, decode.float)
  use fiber <- decode.field(11, decode.optional(decode.float))
  use sugar <- decode.field(12, decode.optional(decode.float))
  use sodium <- decode.field(13, decode.optional(decode.float))
  use cholesterol <- decode.field(14, decode.optional(decode.float))
  use vitamin_a <- decode.field(15, decode.optional(decode.float))
  use vitamin_c <- decode.field(16, decode.optional(decode.float))
  use vitamin_d <- decode.field(17, decode.optional(decode.float))
  use vitamin_e <- decode.field(18, decode.optional(decode.float))
  use vitamin_k <- decode.field(19, decode.optional(decode.float))
  use vitamin_b6 <- decode.field(20, decode.optional(decode.float))
  use vitamin_b12 <- decode.field(21, decode.optional(decode.float))
  use folate <- decode.field(22, decode.optional(decode.float))
  use thiamin <- decode.field(23, decode.optional(decode.float))
  use riboflavin <- decode.field(24, decode.optional(decode.float))
  use niacin <- decode.field(25, decode.optional(decode.float))
  use calcium <- decode.field(26, decode.optional(decode.float))
  use iron <- decode.field(27, decode.optional(decode.float))
  use magnesium <- decode.field(28, decode.optional(decode.float))
  use phosphorus <- decode.field(29, decode.optional(decode.float))
  use potassium <- decode.field(30, decode.optional(decode.float))
  use zinc <- decode.field(31, decode.optional(decode.float))

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

  decode.success(types.CustomFood(
    id: id,
    user_id: user_id,
    name: name,
    brand: brand,
    description: description,
    serving_size: serving_size,
    serving_unit: serving_unit,
    macros: types.Macros(protein: protein, fat: fat, carbs: carbs),
    calories: calories,
    micronutrients: micronutrients,
  ))
}
