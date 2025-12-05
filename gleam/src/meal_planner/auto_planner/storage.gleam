//// Storage operations for auto meal planner

import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import meal_planner/auto_planner/types as auto_types
import meal_planner/storage.{type StorageError, DatabaseError, NotFound}
import meal_planner/types.{
  type Recipe, High, Ingredient, Low, Macros, Medium, Recipe,
}
import pog

// ============================================================================
// Auto Meal Plan Storage
// ============================================================================

/// Save auto meal plan to database
pub fn save_auto_plan(
  conn: pog.Connection,
  plan: auto_types.AutoMealPlan,
) -> Result(Nil, StorageError) {
  let sql =
    "INSERT INTO auto_meal_plans
     (id, recipe_ids, generated_at, total_protein, total_fat, total_carbs, config_json)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     ON CONFLICT (id) DO UPDATE SET
       recipe_ids = EXCLUDED.recipe_ids,
       generated_at = EXCLUDED.generated_at,
       total_protein = EXCLUDED.total_protein,
       total_fat = EXCLUDED.total_fat,
       total_carbs = EXCLUDED.total_carbs,
       config_json = EXCLUDED.config_json"

  // Join recipe IDs
  let recipe_ids = string.join(list.map(plan.recipes, fn(r) { r.id }), ",")

  // Serialize config to JSON string
  let config_json =
    auto_types.auto_plan_config_to_json(plan.config)
    |> json.to_string

  case
    pog.query(sql)
    |> pog.parameter(pog.text(plan.id))
    |> pog.parameter(pog.text(recipe_ids))
    |> pog.parameter(pog.text(plan.generated_at))
    |> pog.parameter(pog.float(plan.total_macros.protein))
    |> pog.parameter(pog.float(plan.total_macros.fat))
    |> pog.parameter(pog.float(plan.total_macros.carbs))
    |> pog.parameter(pog.text(config_json))
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(format_pog_error(e)))
    Ok(_) -> Ok(Nil)
  }
}

/// Get auto meal plan by ID
pub fn get_auto_plan(
  conn: pog.Connection,
  id: String,
) -> Result(auto_types.AutoMealPlan, StorageError) {
  let sql =
    "SELECT id, recipe_ids, generated_at, total_protein, total_fat, total_carbs, config_json
     FROM auto_meal_plans WHERE id = $1"

  let decoder = {
    use plan_id <- decode.field(0, decode.string)
    use recipe_ids_str <- decode.field(1, decode.string)
    use generated_at <- decode.field(2, decode.string)
    use total_protein <- decode.field(3, decode.float)
    use total_fat <- decode.field(4, decode.float)
    use total_carbs <- decode.field(5, decode.float)
    use config_json <- decode.field(6, decode.string)

    decode.success(#(
      plan_id,
      recipe_ids_str,
      generated_at,
      Macros(protein: total_protein, fat: total_fat, carbs: total_carbs),
      config_json,
    ))
  }

  case
    pog.query(sql)
    |> pog.parameter(pog.text(id))
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(format_pog_error(e)))
    Ok(pog.Returned(0, _)) -> Error(NotFound)
    Ok(pog.Returned(_, [])) -> Error(NotFound)
    Ok(pog.Returned(_, [row, ..])) -> {
      let #(plan_id, recipe_ids_str, generated_at, total_macros, config_json) =
        row

      // Parse recipe IDs
      let recipe_ids = string.split(recipe_ids_str, ",")

      // Load recipes
      case load_recipes_by_ids(conn, recipe_ids) {
        Error(e) -> Error(e)
        Ok(recipes) -> {
          // Parse config from JSON
          let config_result = {
            use json_val <- result.try(json.parse(config_json))
            decode.run(json_val, auto_types.auto_plan_config_decoder())
          }

          case config_result {
            Error(_) -> Error(DatabaseError("Failed to decode config JSON"))
            Ok(config) ->
              Ok(auto_types.AutoMealPlan(
                id: plan_id,
                recipes: recipes,
                generated_at: generated_at,
                total_macros: total_macros,
                config: config,
              ))
          }
        }
      }
    }
  }
}

/// Load multiple recipes by their IDs
fn load_recipes_by_ids(
  conn: pog.Connection,
  ids: List(String),
) -> Result(List(Recipe), StorageError) {
  case ids {
    [] -> Ok([])
    _ -> {
      // Build placeholders for IN clause
      let placeholders =
        list.index_map(ids, fn(_, i) { "$" <> int.to_string(i + 1) })
        |> string.join(", ")

      let sql =
        "SELECT id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant
         FROM recipes WHERE id IN ("
        <> placeholders
        <> ")"

      let decoder = recipe_row_decoder()

      // Build query with parameters
      let query =
        list.fold(ids, pog.query(sql), fn(q, id) {
          pog.parameter(q, pog.text(id))
        })

      case pog.returning(query, decoder) |> pog.execute(conn) {
        Error(e) -> Error(DatabaseError(format_pog_error(e)))
        Ok(pog.Returned(_, recipes)) -> Ok(recipes)
      }
    }
  }
}

/// Decoder for recipe rows
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
  use vertical_compliant <- decode.field(10, decode.bool)

  let ingredients =
    string.split(ingredients_str, "|")
    |> list.map(fn(part) {
      case string.split(part, ":") {
        [name, quantity] -> Ingredient(name: name, quantity: quantity)
        _ -> Ingredient(name: part, quantity: "")
      }
    })

  let instructions = string.split(instructions_str, "|")

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
// Recipe Source Storage
// ============================================================================

/// Save recipe source
pub fn save_recipe_source(
  conn: pog.Connection,
  source: auto_types.RecipeSource,
) -> Result(Nil, StorageError) {
  let sql =
    "INSERT INTO recipe_sources (id, name, type, config)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (id) DO UPDATE SET
       name = EXCLUDED.name,
       type = EXCLUDED.type,
       config = EXCLUDED.config"

  let type_str = auto_types.recipe_source_type_to_string(source.source_type)

  case
    pog.query(sql)
    |> pog.parameter(pog.text(source.id))
    |> pog.parameter(pog.text(source.name))
    |> pog.parameter(pog.text(type_str))
    |> pog.parameter(case source.config {
      Some(cfg) -> pog.text(cfg)
      None -> pog.null()
    })
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(format_pog_error(e)))
    Ok(_) -> Ok(Nil)
  }
}

/// Get all recipe sources
pub fn get_recipe_sources(
  conn: pog.Connection,
) -> Result(List(auto_types.RecipeSource), StorageError) {
  let sql = "SELECT id, name, type, config FROM recipe_sources ORDER BY name"

  let decoder = {
    use id <- decode.field(0, decode.string)
    use name <- decode.field(1, decode.string)
    use type_str <- decode.field(2, decode.string)
    use config <- decode.field(3, decode.optional(decode.string))

    let source_type = case type_str {
      "database" -> auto_types.Database
      "api" -> auto_types.Api
      "user_provided" -> auto_types.UserProvided
      _ -> auto_types.Database
    }

    decode.success(auto_types.RecipeSource(
      id: id,
      name: name,
      source_type: source_type,
      config: config,
    ))
  }

  case pog.query(sql) |> pog.returning(decoder) |> pog.execute(conn) {
    Error(e) -> Error(DatabaseError(format_pog_error(e)))
    Ok(pog.Returned(_, sources)) -> Ok(sources)
  }
}

// ============================================================================
// Helpers
// ============================================================================

fn format_pog_error(error: pog.QueryError) -> String {
  case error {
    pog.ConstraintViolated(msg, _, _) -> "Constraint violated: " <> msg
    pog.ConnectionUnavailable -> "Database connection unavailable"
    pog.PostgresqlError(code, name, msg) ->
      "PostgreSQL error " <> code <> " (" <> name <> "): " <> msg
    pog.UnexpectedResultType(_expected) -> "Unexpected result type"
    pog.QueryTimeout -> "Database query timeout"
    pog.UnexpectedArgumentCount(expected, got) ->
      "Expected "
      <> int.to_string(expected)
      <> " arguments, got "
      <> int.to_string(got)
    pog.UnexpectedArgumentType(expected, got) ->
      "Expected type " <> expected <> ", got " <> got
  }
}
