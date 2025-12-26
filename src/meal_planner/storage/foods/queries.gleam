/// Database query operations for foods
import gleam/dynamic/decode
import gleam/list
import gleam/result
import meal_planner/id
import meal_planner/storage/foods/decoders
import meal_planner/storage/foods/types.{
  type FoodNutrientValue, type UsdaFood, type UsdaFoodWithNutrients,
  FoodNutrientValue, UsdaFood, UsdaFoodWithNutrients,
}
import meal_planner/storage/profile.{
  type StorageError, DatabaseError, NotFound, result_to_storage_error,
}
import meal_planner/storage/utils
import meal_planner/types/custom_food.{type CustomFood}
import meal_planner/types/food.{
  type FoodSearchResponse, type SearchFilters, CustomFoodResult,
  FoodSearchResponse, UsdaFoodResult,
}
import pog

// USDA Foods

/// Search for USDA foods by query string
pub fn search_foods(
  conn: pog.Connection,
  query: String,
  limit: Int,
) -> Result(List(UsdaFood), StorageError) {
  let sql =
    "SELECT DISTINCT ON (fdc_id) fdc_id, description, data_type, COALESCE(food_category, ''), '100g'
     FROM foods
     WHERE to_tsvector('english', description) @@ plainto_tsquery('english', $1)
        OR description ILIKE $2
     ORDER BY
       fdc_id,
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
    use fdc_id_int <- decode.field(0, decode.int)
    use description <- decode.field(1, decode.string)
    use data_type <- decode.field(2, decode.string)
    use category <- decode.field(3, decode.string)
    use serving_size <- decode.field(4, decode.string)
    decode.success(UsdaFood(
      id.fdc_id(fdc_id_int),
      description,
      data_type,
      category,
      serving_size,
    ))
  }

  pog.query(sql)
  |> pog.parameter(pog.text(query))
  |> pog.parameter(pog.text(search_pattern))
  |> pog.parameter(pog.int(limit))
  |> pog.returning(decoder)
  |> pog.execute(conn)
  |> result_to_storage_error
  |> result.map(fn(ret) {
    let pog.Returned(_, rows) = ret
    rows
  })
}

/// Search for foods with filters
pub fn search_foods_filtered(
  conn: pog.Connection,
  query: String,
  _filters: SearchFilters,
  limit: Int,
) -> Result(List(UsdaFood), StorageError) {
  search_foods(conn, query, limit)
}

/// Search for foods with filters and offset for pagination
pub fn search_foods_filtered_with_offset(
  conn: pog.Connection,
  query: String,
  _filters: SearchFilters,
  limit: Int,
  offset: Int,
) -> Result(List(UsdaFood), StorageError) {
  let sql =
    "SELECT DISTINCT ON (fdc_id) fdc_id, description, data_type, COALESCE(food_category, ''), COALESCE(household_serving_fulltext, '')
     FROM foods
     WHERE to_tsvector('english', description) @@ plainto_tsquery('english', $1)
        OR description ILIKE $2
     ORDER BY
       fdc_id,
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
     LIMIT $3 OFFSET $4"

  let search_pattern = "%" <> query <> "%"

  let decoder = {
    use fdc_id_int <- decode.field(0, decode.int)
    use description <- decode.field(1, decode.string)
    use data_type <- decode.field(2, decode.string)
    use category <- decode.field(3, decode.string)
    use serving_size <- decode.field(4, decode.string)
    decode.success(UsdaFood(
      id.fdc_id(fdc_id_int),
      description,
      data_type,
      category,
      serving_size,
    ))
  }

  pog.query(sql)
  |> pog.parameter(pog.text(query))
  |> pog.parameter(pog.text(search_pattern))
  |> pog.parameter(pog.int(limit))
  |> pog.parameter(pog.int(offset))
  |> pog.returning(decoder)
  |> pog.execute(conn)
  |> result_to_storage_error
  |> result.map(fn(ret) {
    let pog.Returned(_, rows) = ret
    rows
  })
}

/// Get food by FDC ID
pub fn get_food_by_id(
  conn: pog.Connection,
  fdc_id: id.FdcId,
) -> Result(UsdaFood, StorageError) {
  let sql =
    "SELECT fdc_id, description, data_type, COALESCE(food_category, ''), '100g'
     FROM foods WHERE fdc_id = $1"

  let decoder = {
    use fdc_id_int <- decode.field(0, decode.int)
    use description <- decode.field(1, decode.string)
    use data_type <- decode.field(2, decode.string)
    use category <- decode.field(3, decode.string)
    use serving_size <- decode.field(4, decode.string)
    decode.success(UsdaFood(
      id.fdc_id(fdc_id_int),
      description,
      data_type,
      category,
      serving_size,
    ))
  }

  case
    pog.query(sql)
    |> pog.parameter(pog.int(id.fdc_id_to_int(fdc_id)))
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
  fdc_id: id.FdcId,
) -> Result(UsdaFoodWithNutrients, StorageError) {
  use food <- result.try(get_food_by_id(conn, fdc_id))
  use nutrients <- result.try(get_food_nutrients(conn, fdc_id))
  Ok(UsdaFoodWithNutrients(food: food, nutrients: nutrients))
}

/// Get foods count
pub fn get_foods_count(conn: pog.Connection) -> Result(Int, StorageError) {
  let sql = "SELECT COUNT(*) FROM foods"

  let decoder = {
    use count <- decode.field(0, decode.int)
    decode.success(count)
  }

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

  pog.query(sql)
  |> pog.returning(decoder)
  |> pog.execute(conn)
  |> result_to_storage_error
  |> result.map(fn(ret) {
    let pog.Returned(_, rows) = ret
    rows
  })
}

// Custom Foods

/// Create custom food
pub fn create_custom_food(
  conn: pog.Connection,
  user_id: id.UserId,
  food: CustomFood,
) -> Result(CustomFood, StorageError) {
  let sql =
    "INSERT INTO custom_foods (id, user_id, name, brand, description, serving_size, serving_unit, protein, fat, carbs, calories)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
     RETURNING id, user_id, name, brand, description, serving_size, serving_unit, protein, fat, carbs, calories, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(id.custom_food_id_to_string(food.id)))
    |> pog.parameter(pog.text(id.user_id_to_string(user_id)))
    |> pog.parameter(pog.text(food.name))
    |> pog.parameter(pog.nullable(pog.text, food.brand))
    |> pog.parameter(pog.nullable(pog.text, food.description))
    |> pog.parameter(pog.float(food.serving_size))
    |> pog.parameter(pog.text(food.serving_unit))
    |> pog.parameter(pog.float(food.macros.protein))
    |> pog.parameter(pog.float(food.macros.fat))
    |> pog.parameter(pog.float(food.macros.carbs))
    |> pog.parameter(pog.float(food.calories))
    |> pog.returning(decoders.custom_food_decoder())
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
  user_id: id.UserId,
  food_id: id.CustomFoodId,
) -> Result(CustomFood, StorageError) {
  let sql =
    "SELECT id, user_id, name, brand, description, serving_size, serving_unit, protein, fat, carbs, calories, fiber, sugar, sodium, cholesterol, vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k, vitamin_b6, vitamin_b12, folate, thiamin, riboflavin, niacin, calcium, iron, magnesium, phosphorus, potassium, zinc
     FROM custom_foods WHERE id = $1 AND user_id = $2"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(id.custom_food_id_to_string(food_id)))
    |> pog.parameter(pog.text(id.user_id_to_string(user_id)))
    |> pog.returning(decoders.custom_food_decoder())
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
  user_id: id.UserId,
  query: String,
  limit: Int,
) -> Result(List(CustomFood), StorageError) {
  let sql =
    "SELECT id, user_id, name, brand, description, serving_size, serving_unit, protein, fat, carbs, calories, fiber, sugar, sodium, cholesterol, vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k, vitamin_b6, vitamin_b12, folate, thiamin, riboflavin, niacin, calcium, iron, magnesium, phosphorus, potassium, zinc
     FROM custom_foods
     WHERE user_id = $1
       AND (to_tsvector('english', name) @@ plainto_tsquery('english', $2)
            OR name ILIKE $3)
     ORDER BY LOWER(name), id DESC
     LIMIT $4"

  let search_pattern = "%" <> query <> "%"

  pog.query(sql)
  |> pog.parameter(pog.text(id.user_id_to_string(user_id)))
  |> pog.parameter(pog.text(query))
  |> pog.parameter(pog.text(search_pattern))
  |> pog.parameter(pog.int(limit))
  |> pog.returning(decoders.custom_food_decoder())
  |> pog.execute(conn)
  |> result_to_storage_error
  |> result.map(fn(ret) {
    let pog.Returned(_, rows) = ret
    rows
  })
}

/// Get custom foods for user
pub fn get_custom_foods_for_user(
  conn: pog.Connection,
  user_id: id.UserId,
) -> Result(List(CustomFood), StorageError) {
  let sql =
    "SELECT id, user_id, name, brand, description, serving_size, serving_unit, protein, fat, carbs, calories, fiber, sugar, sodium, cholesterol, vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k, vitamin_b6, vitamin_b12, folate, thiamin, riboflavin, niacin, calcium, iron, magnesium, phosphorus, potassium, zinc
     FROM custom_foods WHERE user_id = $1 ORDER BY name"

  pog.query(sql)
  |> pog.parameter(pog.text(id.user_id_to_string(user_id)))
  |> pog.returning(decoders.custom_food_decoder())
  |> pog.execute(conn)
  |> result_to_storage_error
  |> result.map(fn(ret) {
    let pog.Returned(_, rows) = ret
    rows
  })
}

/// Delete custom food
pub fn delete_custom_food(
  conn: pog.Connection,
  user_id: id.UserId,
  food_id: id.CustomFoodId,
) -> Result(Nil, StorageError) {
  let sql = "DELETE FROM custom_foods WHERE id = $1 AND user_id = $2"

  pog.query(sql)
  |> pog.parameter(pog.text(id.custom_food_id_to_string(food_id)))
  |> pog.parameter(pog.text(id.user_id_to_string(user_id)))
  |> pog.execute(conn)
  |> result_to_storage_error
  |> result.map(fn(_) { Nil })
}

/// Update custom food
pub fn update_custom_food(
  conn: pog.Connection,
  user_id: id.UserId,
  food: CustomFood,
) -> Result(CustomFood, StorageError) {
  let sql =
    "UPDATE custom_foods SET name = $3, brand = $4, description = $5, serving_size = $6, serving_unit = $7, protein = $8, fat = $9, carbs = $10, calories = $11 WHERE id = $1 AND user_id = $2
     RETURNING id, user_id, name, brand, description, serving_size, serving_unit, protein, fat, carbs, calories, fiber, sugar, sodium, cholesterol, vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k, vitamin_b6, vitamin_b12, folate, thiamin, riboflavin, niacin, calcium, iron, magnesium, phosphorus, potassium, zinc"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(id.custom_food_id_to_string(food.id)))
    |> pog.parameter(pog.text(id.user_id_to_string(user_id)))
    |> pog.parameter(pog.text(food.name))
    |> pog.parameter(pog.nullable(pog.text, food.brand))
    |> pog.parameter(pog.nullable(pog.text, food.description))
    |> pog.parameter(pog.float(food.serving_size))
    |> pog.parameter(pog.text(food.serving_unit))
    |> pog.parameter(pog.float(food.macros.protein))
    |> pog.parameter(pog.float(food.macros.fat))
    |> pog.parameter(pog.float(food.macros.carbs))
    |> pog.parameter(pog.float(food.calories))
    |> pog.returning(decoders.custom_food_decoder())
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(0, _)) -> Error(NotFound)
    Ok(pog.Returned(_, [])) -> Error(NotFound)
    Ok(pog.Returned(_, [updated_food, ..])) -> Ok(updated_food)
  }
}

// Unified Search

/// Unified food search - searches both custom foods and USDA foods
pub fn unified_search_foods(
  conn: pog.Connection,
  user_id: id.UserId,
  query: String,
  limit: Int,
) -> Result(FoodSearchResponse, StorageError) {
  use custom_foods <- result.try(search_custom_foods(
    conn,
    user_id,
    query,
    limit,
  ))

  let custom_count = list.length(custom_foods)
  let remaining_limit = limit - custom_count

  let usda_foods = case remaining_limit > 0 {
    True -> {
      case search_foods(conn, query, remaining_limit) {
        Ok(foods) -> foods
        Error(_) -> []
      }
    }
    False -> []
  }

  let usda_count = list.length(usda_foods)

  let custom_results =
    list.map(custom_foods, fn(food) { CustomFoodResult(food) })

  let usda_results =
    list.map(usda_foods, fn(food) {
      UsdaFoodResult(
        food.fdc_id,
        food.description,
        food.data_type,
        food.category,
        food.serving_size,
      )
    })

  let all_results = list.append(custom_results, usda_results)
  let total_count = custom_count + usda_count

  Ok(FoodSearchResponse(
    results: all_results,
    total_count: total_count,
    custom_count: custom_count,
    usda_count: usda_count,
  ))
}

// Nutrients

/// Get food nutrients
pub fn get_food_nutrients(
  conn: pog.Connection,
  fdc_id: id.FdcId,
) -> Result(List(FoodNutrientValue), StorageError) {
  let sql =
    "SELECT fn.nutrient_id, n.name, fn.amount, n.unit_name
     FROM food_nutrients fn
     JOIN nutrients n ON fn.nutrient_id = n.id
     WHERE fn.fdc_id = $1"

  let decoder = {
    use nutrient_id <- decode.field(0, decode.int)
    use nutrient_name <- decode.field(1, decode.string)
    use amount <- decode.field(2, decode.float)
    use unit <- decode.field(3, decode.string)
    decode.success(FoodNutrientValue(nutrient_id, nutrient_name, amount, unit))
  }

  case
    pog.query(sql)
    |> pog.parameter(pog.int(id.fdc_id_to_int(fdc_id)))
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(_, rows)) -> Ok(rows)
  }
}
