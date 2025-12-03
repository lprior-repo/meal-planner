import gleam/dynamic
import gleam/option.{type Option}
import gleam/result
import pog
import shared/types.{
  type CustomFood, type Macros, type Micronutrients, CustomFood, Macros,
  Micronutrients,
}

/// Save or update a custom food in the PostgreSQL database
/// Handles all 21 micronutrient fields
pub fn save_custom_food(
  db: pog.Connection,
  food: CustomFood,
) -> Result(Nil, pog.QueryError) {
  // SQL with all 21 micronutrient fields
  let sql =
    "
    INSERT INTO custom_foods (
      id, user_id, name, brand, description,
      serving_size, serving_unit,
      protein, fat, carbs, calories,
      fiber, sugar, sodium, cholesterol,
      vitamin_a, vitamin_c, vitamin_d,
      calcium, iron, potassium,
      vitamin_e, vitamin_k, vitamin_b6, vitamin_b12,
      folate, thiamin, riboflavin, niacin,
      magnesium, phosphorus, zinc
    ) VALUES (
      $1, $2, $3, $4, $5,
      $6, $7,
      $8, $9, $10, $11,
      $12, $13, $14, $15,
      $16, $17, $18,
      $19, $20, $21,
      $22, $23, $24, $25,
      $26, $27, $28, $29,
      $30, $31, $32
    )
    ON CONFLICT (id) DO UPDATE SET
      user_id = EXCLUDED.user_id,
      name = EXCLUDED.name,
      brand = EXCLUDED.brand,
      description = EXCLUDED.description,
      serving_size = EXCLUDED.serving_size,
      serving_unit = EXCLUDED.serving_unit,
      protein = EXCLUDED.protein,
      fat = EXCLUDED.fat,
      carbs = EXCLUDED.carbs,
      calories = EXCLUDED.calories,
      fiber = EXCLUDED.fiber,
      sugar = EXCLUDED.sugar,
      sodium = EXCLUDED.sodium,
      cholesterol = EXCLUDED.cholesterol,
      vitamin_a = EXCLUDED.vitamin_a,
      vitamin_c = EXCLUDED.vitamin_c,
      vitamin_d = EXCLUDED.vitamin_d,
      calcium = EXCLUDED.calcium,
      iron = EXCLUDED.iron,
      potassium = EXCLUDED.potassium,
      vitamin_e = EXCLUDED.vitamin_e,
      vitamin_k = EXCLUDED.vitamin_k,
      vitamin_b6 = EXCLUDED.vitamin_b6,
      vitamin_b12 = EXCLUDED.vitamin_b12,
      folate = EXCLUDED.folate,
      thiamin = EXCLUDED.thiamin,
      riboflavin = EXCLUDED.riboflavin,
      niacin = EXCLUDED.niacin,
      magnesium = EXCLUDED.magnesium,
      phosphorus = EXCLUDED.phosphorus,
      zinc = EXCLUDED.zinc,
      updated_at = NOW()
    "

  // Extract all 21 micronutrient fields from the optional Micronutrients
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
    folate_val,
    thiamin_val,
    riboflavin_val,
    niacin_val,
    calcium,
    iron,
    magnesium_val,
    phosphorus_val,
    potassium,
    zinc_val,
  ) = case food.micronutrients {
    option.Some(micros) -> #(
      micros.fiber,
      micros.sugar,
      micros.sodium,
      micros.cholesterol,
      micros.vitamin_a,
      micros.vitamin_c,
      micros.vitamin_d,
      micros.vitamin_e,
      micros.vitamin_k,
      micros.vitamin_b6,
      micros.vitamin_b12,
      micros.folate,
      micros.thiamin,
      micros.riboflavin,
      micros.niacin,
      micros.calcium,
      micros.iron,
      micros.magnesium,
      micros.phosphorus,
      micros.potassium,
      micros.zinc,
    )
    option.None -> #(
      option.None,
      option.None,
      option.None,
      option.None,
      option.None,
      option.None,
      option.None,
      option.None,
      option.None,
      option.None,
      option.None,
      option.None,
      option.None,
      option.None,
      option.None,
      option.None,
      option.None,
      option.None,
      option.None,
      option.None,
      option.None,
    )
  }

  // Execute query with all 32 parameters
  pog.query(sql)
  // Core food fields (1-11)
  |> pog.parameter(pog.text(food.id))
  |> pog.parameter(pog.text(food.user_id))
  |> pog.parameter(pog.text(food.name))
  |> pog.parameter(pog.nullable(pog.text, food.brand))
  |> pog.parameter(pog.nullable(pog.text, food.description))
  |> pog.parameter(pog.float(food.serving_size))
  |> pog.parameter(pog.text(food.serving_unit))
  |> pog.parameter(pog.float(food.macros.protein))
  |> pog.parameter(pog.float(food.macros.fat))
  |> pog.parameter(pog.float(food.macros.carbs))
  |> pog.parameter(pog.float(food.calories))
  // First 10 micronutrient fields (12-21)
  |> pog.parameter(pog.nullable(pog.float, fiber))
  |> pog.parameter(pog.nullable(pog.float, sugar))
  |> pog.parameter(pog.nullable(pog.float, sodium))
  |> pog.parameter(pog.nullable(pog.float, cholesterol))
  |> pog.parameter(pog.nullable(pog.float, vitamin_a))
  |> pog.parameter(pog.nullable(pog.float, vitamin_c))
  |> pog.parameter(pog.nullable(pog.float, vitamin_d))
  |> pog.parameter(pog.nullable(pog.float, calcium))
  |> pog.parameter(pog.nullable(pog.float, iron))
  |> pog.parameter(pog.nullable(pog.float, potassium))
  // Additional 11 micronutrient fields (22-32)
  |> pog.parameter(pog.nullable(pog.float, vitamin_e))
  |> pog.parameter(pog.nullable(pog.float, vitamin_k))
  |> pog.parameter(pog.nullable(pog.float, vitamin_b6))
  |> pog.parameter(pog.nullable(pog.float, vitamin_b12))
  |> pog.parameter(pog.nullable(pog.float, folate_val))
  |> pog.parameter(pog.nullable(pog.float, thiamin_val))
  |> pog.parameter(pog.nullable(pog.float, riboflavin_val))
  |> pog.parameter(pog.nullable(pog.float, niacin_val))
  |> pog.parameter(pog.nullable(pog.float, magnesium_val))
  |> pog.parameter(pog.nullable(pog.float, phosphorus_val))
  |> pog.parameter(pog.nullable(pog.float, zinc_val))
  |> pog.execute(db)
  |> result.map(fn(_) { Nil })
}

/// Get a custom food by ID
pub fn get_custom_food_by_id(
  db: pog.Connection,
  food_id: String,
) -> Result(CustomFood, pog.QueryError) {
  let sql =
    "
    SELECT id, user_id, name, brand, description, serving_size, serving_unit,
           protein, fat, carbs, calories,
           fiber, sugar, sodium, cholesterol,
           vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k, vitamin_b6, vitamin_b12,
           folate, thiamin, riboflavin, niacin,
           calcium, iron, magnesium, phosphorus, potassium, zinc
    FROM custom_foods WHERE id = $1"

  pog.query(sql)
  |> pog.parameter(pog.text(food_id))
  |> pog.returning(decode_custom_food())
  |> pog.execute(db)
  |> result.try(fn(returned) {
    case returned.rows {
      [food] -> Ok(food)
      [] ->
        Error(pog.QueryError(
          message: "Custom food not found",
          code: "NOT_FOUND",
          constraint: option.None,
          detail: option.Some("No custom food with id: " <> food_id),
        ))
      _ ->
        Error(pog.QueryError(
          message: "Unexpected multiple results",
          code: "UNEXPECTED",
          constraint: option.None,
          detail: option.Some("Multiple foods returned for single ID"),
        ))
    }
  })
}

/// Get all custom foods for a specific user
pub fn get_custom_foods_by_user(
  db: pog.Connection,
  user_id: String,
) -> Result(List(CustomFood), pog.QueryError) {
  let sql =
    "
    SELECT id, user_id, name, brand, description, serving_size, serving_unit,
           protein, fat, carbs, calories,
           fiber, sugar, sodium, cholesterol,
           vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k, vitamin_b6, vitamin_b12,
           folate, thiamin, riboflavin, niacin,
           calcium, iron, magnesium, phosphorus, potassium, zinc
    FROM custom_foods WHERE user_id = $1 ORDER BY name"

  pog.query(sql)
  |> pog.parameter(pog.text(user_id))
  |> pog.returning(decode_custom_food())
  |> pog.execute(db)
  |> result.map(fn(returned) { returned.rows })
}

/// Search custom foods by name or brand for a specific user
pub fn search_custom_foods(
  db: pog.Connection,
  user_id: String,
  query: String,
  limit: Int,
) -> Result(List(CustomFood), pog.QueryError) {
  let sql =
    "
    SELECT id, user_id, name, brand, description, serving_size, serving_unit,
           protein, fat, carbs, calories,
           fiber, sugar, sodium, cholesterol,
           vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k, vitamin_b6, vitamin_b12,
           folate, thiamin, riboflavin, niacin,
           calcium, iron, magnesium, phosphorus, potassium, zinc
    FROM custom_foods
    WHERE user_id = $1
      AND (name ILIKE $2 OR brand ILIKE $2)
    ORDER BY name LIMIT $3"

  let search_pattern = "%" <> query <> "%"

  pog.query(sql)
  |> pog.parameter(pog.text(user_id))
  |> pog.parameter(pog.text(search_pattern))
  |> pog.parameter(pog.int(limit))
  |> pog.returning(decode_custom_food())
  |> pog.execute(db)
  |> result.map(fn(returned) { returned.rows })
}

/// Delete a custom food by ID
pub fn delete_custom_food(
  db: pog.Connection,
  food_id: String,
) -> Result(Nil, pog.QueryError) {
  let sql = "DELETE FROM custom_foods WHERE id = $1"

  pog.query(sql)
  |> pog.parameter(pog.text(food_id))
  |> pog.execute(db)
  |> result.map(fn(_) { Nil })
}

/// Decoder for CustomFood from PostgreSQL rows
/// Decodes all 32 columns: core fields + macros + 21 micronutrients
fn decode_custom_food() -> dynamic.Decoder(CustomFood) {
  dynamic.decode32(
    // Constructor function that builds CustomFood
    fn(
      id,
      user_id,
      name,
      brand,
      description,
      serving_size,
      serving_unit,
      protein,
      fat,
      carbs,
      calories,
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
    ) {
      // Build Macros
      let macros = Macros(protein: protein, fat: fat, carbs: carbs)

      // Build Micronutrients - check if any values exist
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
        option.None,
          option.None,
          option.None,
          option.None,
          option.None,
          option.None,
          option.None,
          option.None,
          option.None,
          option.None,
          option.None,
          option.None,
          option.None,
          option.None,
          option.None,
          option.None,
          option.None,
          option.None,
          option.None,
          option.None,
          option.None
        -> option.None
        _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ ->
          option.Some(Micronutrients(
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

      // Build CustomFood
      CustomFood(
        id: id,
        user_id: user_id,
        name: name,
        brand: brand,
        description: description,
        serving_size: serving_size,
        serving_unit: serving_unit,
        macros: macros,
        calories: calories,
        micronutrients: micronutrients,
      )
    },
    // Field decoders - all 32 columns
    dynamic.element(0, dynamic.string),
    // id
    dynamic.element(1, dynamic.string),
    // user_id
    dynamic.element(2, dynamic.string),
    // name
    dynamic.element(3, dynamic.optional(dynamic.string)),
    // brand
    dynamic.element(4, dynamic.optional(dynamic.string)),
    // description
    dynamic.element(5, dynamic.float),
    // serving_size
    dynamic.element(6, dynamic.string),
    // serving_unit
    dynamic.element(7, dynamic.float),
    // protein
    dynamic.element(8, dynamic.float),
    // fat
    dynamic.element(9, dynamic.float),
    // carbs
    dynamic.element(10, dynamic.float),
    // calories
    dynamic.element(11, dynamic.optional(dynamic.float)),
    // fiber
    dynamic.element(12, dynamic.optional(dynamic.float)),
    // sugar
    dynamic.element(13, dynamic.optional(dynamic.float)),
    // sodium
    dynamic.element(14, dynamic.optional(dynamic.float)),
    // cholesterol
    dynamic.element(15, dynamic.optional(dynamic.float)),
    // vitamin_a
    dynamic.element(16, dynamic.optional(dynamic.float)),
    // vitamin_c
    dynamic.element(17, dynamic.optional(dynamic.float)),
    // vitamin_d
    dynamic.element(18, dynamic.optional(dynamic.float)),
    // vitamin_e
    dynamic.element(19, dynamic.optional(dynamic.float)),
    // vitamin_k
    dynamic.element(20, dynamic.optional(dynamic.float)),
    // vitamin_b6
    dynamic.element(21, dynamic.optional(dynamic.float)),
    // vitamin_b12
    dynamic.element(22, dynamic.optional(dynamic.float)),
    // folate
    dynamic.element(23, dynamic.optional(dynamic.float)),
    // thiamin
    dynamic.element(24, dynamic.optional(dynamic.float)),
    // riboflavin
    dynamic.element(25, dynamic.optional(dynamic.float)),
    // niacin
    dynamic.element(26, dynamic.optional(dynamic.float)),
    // calcium
    dynamic.element(27, dynamic.optional(dynamic.float)),
    // iron
    dynamic.element(28, dynamic.optional(dynamic.float)),
    // magnesium
    dynamic.element(29, dynamic.optional(dynamic.float)),
    // phosphorus
    dynamic.element(30, dynamic.optional(dynamic.float)),
    // potassium
    dynamic.element(31, dynamic.optional(dynamic.float)),
    // zinc
  )
}
