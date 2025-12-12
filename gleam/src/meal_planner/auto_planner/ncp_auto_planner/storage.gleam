//// Storage operations for auto meal planner

import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import meal_planner/auto_planner/types as auto_types
import meal_planner/id
import meal_planner/storage.{type StorageError}
import meal_planner/storage/profile.{DatabaseError, NotFound}
import meal_planner/types.{
  type Recipe, Macros, recipe_to_json, recipe_decoder,
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
     (id, recipe_ids, generated_at, total_protein, total_fat, total_carbs, config_json, recipe_json)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     ON CONFLICT (id) DO UPDATE SET
       recipe_ids = EXCLUDED.recipe_ids,
       generated_at = EXCLUDED.generated_at,
       total_protein = EXCLUDED.total_protein,
       total_fat = EXCLUDED.total_fat,
       total_carbs = EXCLUDED.total_carbs,
       config_json = EXCLUDED.config_json,
       recipe_json = EXCLUDED.recipe_json"

  // Join recipe IDs
  let recipe_ids =
    string.join(
      list.map(plan.recipes, fn(r) { id.recipe_id_to_string(r.id) }),
      ",",
    )

  // Serialize config to JSON string
  let config_json =
    auto_types.auto_plan_config_to_json(plan.config)
    |> json.to_string

  // Serialize recipes to JSON string
  let recipe_json =
    json.array(plan.recipes, recipe_to_json)
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
    |> pog.parameter(pog.text(recipe_json))
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
    "SELECT id, generated_at, total_protein, total_fat, total_carbs, config_json, recipe_json
     FROM auto_meal_plans WHERE id = $1"

  let decoder = {
    use plan_id <- decode.field(0, decode.string)
    use generated_at <- decode.field(1, decode.string)
    use total_protein <- decode.field(2, decode.float)
    use total_fat <- decode.field(3, decode.float)
    use total_carbs <- decode.field(4, decode.float)
    use config_json <- decode.field(5, decode.string)
    use recipe_json <- decode.field(6, decode.string)

    decode.success(#(
      plan_id,
      generated_at,
      Macros(protein: total_protein, fat: total_fat, carbs: total_carbs),
      config_json,
      recipe_json,
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
      let #(plan_id, generated_at, total_macros, config_json, recipe_json) =
        row

      // Parse recipes from recipe_json
      let recipes_result =
        json.parse(
          recipe_json,
          using: decode.list(recipe_decoder()),
        )
        |> result.map_error(fn(_) { "Failed to decode recipe JSON" })

      case recipes_result {
        Error(e) -> Error(DatabaseError(e))
        Ok(recipes) -> {
          // Parse config from JSON
          let config_result =
            json.parse(
              config_json,
              using: auto_types.auto_plan_config_decoder(),
            )
            |> result.map_error(fn(_) { "Failed to decode config JSON" })

          case config_result {
            Error(e) -> Error(DatabaseError(e))
            Ok(config) -> {
              // Serialize recipes to JSON string
              let recipe_json =
                json.array(recipes, types.recipe_to_json)
                |> json.to_string

              Ok(auto_types.AutoMealPlan(
                id: plan_id,
                recipes: recipes,
                generated_at: generated_at,
                total_macros: total_macros,
                config: config,
                recipe_json: recipe_json,
              ))
            }
          }
        }
      }
    }
  }
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
