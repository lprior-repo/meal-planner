/// PostgreSQL storage module for nutrition data persistence
import gleam/dynamic/decode
import gleam/list
import gleam/result
import gleam/string
import meal_planner/id
import meal_planner/postgres
import meal_planner/storage/utils.{format_pog_error}
import meal_planner/types.{
  type Recipe, High, Ingredient, Low, Macros, Medium, Recipe,
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
    |> pog.parameter(pog.text(id.recipe_id_to_string(recipe.id)))
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
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))

    Ok(_) -> Ok(Nil)
  }
}

/// Get all recipes from the database
pub fn get_all_recipes(
  conn: pog.Connection,
) -> Result(List(Recipe), StorageError) {
  let sql =
    "SELECT id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant

     FROM recipes ORDER BY name"

  case
    pog.query(sql)
    |> pog.returning(recipe_decoder())
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))

    Ok(pog.Returned(_, rows)) -> Ok(rows)
  }
}

/// Get a specific recipe by ID
pub fn get_recipe_by_id(
  conn: pog.Connection,
  recipe_id: id.RecipeId,
) -> Result(Recipe, StorageError) {
  let sql =
    "SELECT id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant

     FROM recipes WHERE id = $1"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(id.recipe_id_to_string(recipe_id)))
    |> pog.returning(recipe_decoder())
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))

    Ok(pog.Returned(0, _)) -> Error(NotFound)

    Ok(pog.Returned(_, [])) -> Error(NotFound)

    Ok(pog.Returned(_, [row, ..])) -> Ok(row)
  }
}

/// Delete a recipe
pub fn delete_recipe(
  conn: pog.Connection,
  recipe_id: id.RecipeId,
) -> Result(Nil, StorageError) {
  let sql = "DELETE FROM recipes WHERE id = $1"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(id.recipe_id_to_string(recipe_id)))
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))

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
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))

    Ok(pog.Returned(_, rows)) -> Ok(rows)
  }
}

/// Filter recipes by macro constraints from recipes_simplified table
/// Returns recipes matching: protein >= min_protein, fat <= max_fat, calories <= max_calories
/// Used as pre-filtered candidates for knapsack solver
pub fn filter_recipes(
  conn: pog.Connection,
  min_protein: Int,
  max_fat: Int,
  max_calories: Int,
) -> Result(List(Recipe), StorageError) {
  let sql =
    "SELECT id::text, name, '', '', protein::float, fat::float, carbs::float, 1, category, 'low', false

     FROM recipes_simplified

     WHERE protein >= $1 AND fat <= $2 AND calories <= $3

     ORDER BY protein DESC, calories ASC"

  let decoder = {
    use recipe_id_str <- decode.field(0, decode.string)

    use name <- decode.field(1, decode.string)

    use _ingredients_str <- decode.field(2, decode.string)

    use _instructions_str <- decode.field(3, decode.string)

    use protein <- decode.field(4, decode.float)

    use fat <- decode.field(5, decode.float)

    use carbs <- decode.field(6, decode.float)

    use servings <- decode.field(7, decode.int)

    use category <- decode.field(8, decode.string)

    use fodmap_str <- decode.field(9, decode.string)

    use vertical_compliant <- decode.field(10, decode.bool)

    let fodmap_level = case fodmap_str {
      "low" -> Low

      "medium" -> Medium

      "high" -> High

      _ -> Low
    }

    decode.success(Recipe(
      id: id.recipe_id(recipe_id_str),
      name: name,
      ingredients: [],
      instructions: [],
      macros: Macros(protein: protein, fat: fat, carbs: carbs),
      servings: servings,
      category: category,
      fodmap_level: fodmap_level,
      vertical_compliant: vertical_compliant,
    ))
  }

  case
    pog.query(sql)
    |> pog.parameter(pog.int(min_protein))
    |> pog.parameter(pog.int(max_fat))
    |> pog.parameter(pog.int(max_calories))
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))

    Ok(pog.Returned(_, rows)) -> Ok(rows)
  }
}

/// Recipe decoder helper
fn recipe_decoder() -> decode.Decoder(Recipe) {
  use recipe_id_str <- decode.field(0, decode.string)

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
    id: id.recipe_id(recipe_id_str),
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
