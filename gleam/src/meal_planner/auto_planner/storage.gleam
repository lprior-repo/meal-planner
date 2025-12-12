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
import meal_planner/types.{Macros, recipe_decoder}
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
    json.array(plan.recipes, types.recipe_to_json)
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
    "SELECT id, recipe_ids, generated_at, total_protein, total_fat, total_carbs, config_json, recipe_json
     FROM auto_meal_plans WHERE id = $1"

  let decoder = {
    use plan_id <- decode.field(0, decode.string)
    use recipe_ids_str <- decode.field(1, decode.string)
    use generated_at <- decode.field(2, decode.string)
    use total_protein <- decode.field(3, decode.float)
    use total_fat <- decode.field(4, decode.float)
    use total_carbs <- decode.field(5, decode.float)
    use config_json <- decode.field(6, decode.string)
    use recipe_json <- decode.field(7, decode.optional(decode.string))

    decode.success(#(
      plan_id,
      recipe_ids_str,
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
      let #(
        plan_id,
        _recipe_ids_str,
        generated_at,
        total_macros,
        config_json,
        recipe_json,
      ) = row

      // Parse recipes from recipe_json
      let recipes_result = case recipe_json {
        Some(json_str) -> {
          // Parse recipes from JSON
          json.parse(json_str, using: decode.list(recipe_decoder()))
          |> result.map_error(fn(_) { "Failed to decode recipe JSON" })
        }
        None -> {
          // Recipe JSON should always be present; if missing, return error
          Error("Recipe JSON data is missing")
        }
      }

      // Parse config from JSON
      let config_result =
        json.parse(config_json, using: auto_types.auto_plan_config_decoder())
        |> result.map_error(fn(_) { "Failed to decode config JSON" })

      // Combine results
      case recipes_result, config_result {
        Ok(recipes), Ok(config) ->
          Ok(auto_types.AutoMealPlan(
            id: plan_id,
            recipes: recipes,
            generated_at: generated_at,
            total_macros: total_macros,
            config: config,
            recipe_json: recipe_json |> option.unwrap(""),
          ))
        Error(e), _ -> Error(DatabaseError(e))
        _, Error(e) -> Error(DatabaseError(e))
      }
    }
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
