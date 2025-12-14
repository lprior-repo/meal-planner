/// Tandoor Recipe Manager web handlers
///
/// Routes:
/// - GET /tandoor/status - Check Tandoor connection status
/// - GET /api/tandoor/recipes - List recipes from Tandoor
/// - GET /api/tandoor/recipes/:id - Get recipe detail with ingredients, steps, nutrition
/// - GET /api/tandoor/meal-plan - Get meal plan entries
/// - POST /api/tandoor/meal-plan - Create meal plan entry
import gleam/dynamic/decode
import gleam/http
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result

import meal_planner/env
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, AuthenticationError, NotFoundError,
  error_to_string, login, session_config,
}
import meal_planner/tandoor/api/recipe/get as recipe_get
import meal_planner/tandoor/api/recipe/list as recipe_list
import meal_planner/tandoor/api/mealplan/create as mealplan_create
import meal_planner/tandoor/api/mealplan/list as mealplan_list
import meal_planner/tandoor/api/mealplan/update as mealplan_update
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/types.{type TandoorRecipe}
import meal_planner/tandoor/types/mealplan/meal_plan.{type MealPlan}
import meal_planner/tandoor/types/mealplan/meal_plan_entry.{type MealPlanEntry}
import meal_planner/tandoor/types/mealplan/meal_type.{
  meal_type_from_string, meal_type_to_string,
}
import meal_planner/tandoor/types/mealplan/mealplan.{type MealPlanCreate}
import wisp

/// GET /tandoor/status
/// Returns JSON status of the Tandoor connection
pub fn handle_status(req: wisp.Request) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  let config_present = env.load_tandoor_config() |> option.is_some

  case config_present {
    False -> {
      let body =
        json.object([
          #("connected", json.bool(False)),
          #("configured", json.bool(False)),
          #(
            "message",
            json.string(
              "Tandoor not configured. Set TANDOOR_URL, TANDOOR_USERNAME, TANDOOR_PASSWORD in .env",
            ),
          ),
        ])
        |> json.to_string
      wisp.json_response(body, 200)
    }
    True -> {
      case env.load_tandoor_config() {
        None -> {
          let body =
            json.object([
              #("connected", json.bool(False)),
              #("configured", json.bool(False)),
            ])
            |> json.to_string
          wisp.json_response(body, 200)
        }
        Some(cfg) -> {
          let config = session_config(cfg.base_url, cfg.username, cfg.password)
          case login(config) {
            Ok(_) -> {
              let body =
                json.object([
                  #("connected", json.bool(True)),
                  #("configured", json.bool(True)),
                  #("base_url", json.string(cfg.base_url)),
                ])
                |> json.to_string
              wisp.json_response(body, 200)
            }
            Error(e) -> {
              let body =
                json.object([
                  #("connected", json.bool(False)),
                  #("configured", json.bool(True)),
                  #("error", json.string(error_to_string(e))),
                ])
                |> json.to_string
              wisp.json_response(body, 200)
            }
          }
        }
      }
    }
  }
}

/// GET /api/tandoor/recipes?limit=N&offset=N
/// Returns paginated list of recipes from Tandoor
pub fn handle_list_recipes(req: wisp.Request) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  let query_params = wisp.get_query(req)
  let limit =
    list.find(query_params, fn(p) { p.0 == "limit" })
    |> result.map(fn(p) { p.1 })
    |> result.try(int.parse)
    |> option.from_result

  let offset =
    list.find(query_params, fn(p) { p.0 == "offset" })
    |> result.map(fn(p) { p.1 })
    |> result.try(int.parse)
    |> option.from_result

  case get_authenticated_config() {
    Error(e) -> error_response(e.status, e.message)
    Ok(config) -> {
      case recipe_list.list_recipes(config, limit: limit, offset: offset) {
        Ok(response) -> {
          let body =
            json.object([
              #("count", json.int(response.count)),
              #("next", json.nullable(response.next, json.string)),
              #("previous", json.nullable(response.previous, json.string)),
              #("results", json.array(response.results, recipe_to_json)),
            ])
            |> json.to_string
          wisp.json_response(body, 200)
        }
        Error(e) ->
          error_response(
            500,
            "Failed to fetch recipes: " <> error_to_string(e),
          )
      }
    }
  }
}

/// GET /api/tandoor/recipes/:id
/// Returns full recipe detail with ingredients, steps, and nutrition
pub fn handle_get_recipe(req: wisp.Request, recipe_id: String) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  case int.parse(recipe_id) {
    Error(_) -> error_response(400, "Invalid recipe ID")
    Ok(id) -> {
      case get_authenticated_config() {
        Error(e) -> error_response(e.status, e.message)
        Ok(config) -> {
          case recipe_get.get_recipe(config, recipe_id: id) {
            Ok(recipe) -> {
              let body = recipe_to_json(recipe) |> json.to_string
              wisp.json_response(body, 200)
            }
            Error(NotFoundError(_)) -> error_response(404, "Recipe not found")
            Error(e) ->
              error_response(
                500,
                "Failed to fetch recipe: " <> error_to_string(e),
              )
          }
        }
      }
    }
  }
}

/// GET /api/tandoor/meal-plan?from_date=YYYY-MM-DD&to_date=YYYY-MM-DD
/// Returns meal plan entries for the specified date range
pub fn handle_get_meal_plan(req: wisp.Request) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  let query_params = wisp.get_query(req)
  let from_date =
    list.find(query_params, fn(p) { p.0 == "from_date" })
    |> result.map(fn(p) { p.1 })
    |> option.from_result

  let to_date =
    list.find(query_params, fn(p) { p.0 == "to_date" })
    |> result.map(fn(p) { p.1 })
    |> option.from_result

  case get_authenticated_config() {
    Error(e) -> error_response(e.status, e.message)
    Ok(config) -> {
      case
        mealplan_list.list_meal_plans(
          config,
          from_date: from_date,
          to_date: to_date,
        )
      {
        Ok(response) -> {
          let body =
            json.object([
              #("count", json.int(response.count)),
              #("next", json.nullable(response.next, json.string)),
              #("previous", json.nullable(response.previous, json.string)),
              #("results", json.array(response.results, meal_plan_to_json)),
            ])
            |> json.to_string
          wisp.json_response(body, 200)
        }
        Error(e) ->
          error_response(500, "Failed to fetch meal plan: " <> error_to_string(e))
      }
    }
  }
}

/// POST /api/tandoor/meal-plan
/// Creates a new meal plan entry
pub fn handle_create_meal_plan(req: wisp.Request) -> wisp.Response {
  use <- wisp.require_method(req, http.Post)

  case get_authenticated_config() {
    Error(e) -> error_response(e.status, e.message)
    Ok(config) -> {
      use body <- wisp.require_string_body(req)

      case parse_meal_plan_request(body) {
        Error(msg) -> error_response(400, msg)
        Ok(entry_request) -> {
          case mealplan_create.create_meal_plan(config, entry_request) {
            Ok(created) -> {
              let body = meal_plan_entry_to_json(created) |> json.to_string
              wisp.json_response(body, 201)
            }
            Error(e) ->
              error_response(
                500,
                "Failed to create meal plan: " <> error_to_string(e),
              )
          }
        }
      }
    }
  }
}

/// DELETE /api/tandoor/meal-plan/:id
/// Deletes a meal plan entry
pub fn handle_delete_meal_plan(
  req: wisp.Request,
  entry_id: String,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Delete)

  case int.parse(entry_id) {
    Error(_) -> error_response(400, "Invalid meal plan entry ID")
    Ok(id) -> {
      case get_authenticated_config() {
        Error(e) -> error_response(e.status, e.message)
        Ok(config) -> {
          let meal_plan_id = ids.meal_plan_id_from_int(id)
          case mealplan_update.delete_meal_plan(config, meal_plan_id) {
            Ok(_) -> {
              let body =
                json.object([
                  #("success", json.bool(True)),
                  #("message", json.string("Meal plan entry deleted")),
                ])
                |> json.to_string
              wisp.json_response(body, 200)
            }
            Error(NotFoundError(_)) ->
              error_response(404, "Meal plan entry not found")
            Error(e) ->
              error_response(
                500,
                "Failed to delete meal plan: " <> error_to_string(e),
              )
          }
        }
      }
    }
  }
}

// ============================================================================
// Internal Helpers
// ============================================================================

type ConfigError {
  ConfigError(status: Int, message: String)
}

/// Get authenticated Tandoor client config
fn get_authenticated_config() -> Result(ClientConfig, ConfigError) {
  case env.load_tandoor_config() {
    None -> Error(ConfigError(500, "Tandoor not configured"))
    Some(cfg) -> {
      let config = session_config(cfg.base_url, cfg.username, cfg.password)
      case login(config) {
        Ok(auth_config) -> Ok(auth_config)
        Error(e) ->
          Error(ConfigError(
            502,
            "Tandoor authentication failed: " <> error_to_string(e),
          ))
      }
    }
  }
}

/// JSON error response
fn error_response(status: Int, message: String) -> wisp.Response {
  let body =
    json.object([#("error", json.string(message))])
    |> json.to_string
  wisp.json_response(body, status)
}

/// Convert Recipe to JSON
fn recipe_to_json(recipe: TandoorRecipe) -> json.Json {
  json.object([
    #("id", json.int(recipe.id)),
    #("name", json.string(recipe.name)),
    #("description", json.string(recipe.description)),
    #("servings", json.int(recipe.servings)),
    #("servings_text", json.string(recipe.servings_text)),
    #("working_time", json.int(recipe.prep_time)),
    #("waiting_time", json.int(recipe.cooking_time)),
    #("created_at", json.string(recipe.created_at)),
    #("updated_at", json.string(recipe.updated_at)),
    #("steps", json.array(recipe.steps, step_to_json)),
    #("nutrition", case recipe.nutrition {
      Some(n) -> nutrition_to_json(n)
      None -> json.null()
    }),
    #("keywords", json.array(recipe.keywords, keyword_to_json)),
  ])
}

/// Convert Step to JSON
fn step_to_json(step: types.TandoorStep) -> json.Json {
  json.object([
    #("id", json.int(step.id)),
    #("name", json.string(step.name)),
    #("instructions", json.string(step.instructions)),
    #("time", json.int(step.time)),
  ])
}

/// Convert Nutrition to JSON
fn nutrition_to_json(n: types.TandoorNutrition) -> json.Json {
  json.object([
    #("calories", json.float(n.calories)),
    #("carbs", json.float(n.carbs)),
    #("protein", json.float(n.protein)),
    #("fats", json.float(n.fats)),
    #("fiber", json.float(n.fiber)),
    #("sugars", json.nullable(n.sugars, json.float)),
    #("sodium", json.nullable(n.sodium, json.float)),
  ])
}

/// Convert Keyword to JSON
fn keyword_to_json(kw: types.TandoorKeyword) -> json.Json {
  json.object([
    #("id", json.int(kw.id)),
    #("name", json.string(kw.name)),
  ])
}

/// Convert MealPlan to JSON
fn meal_plan_to_json(entry: MealPlan) -> json.Json {
  json.object([
    #("id", json.int(entry.id)),
    #("recipe", case entry.recipe {
      Some(r) -> json.int(r.id)
      None -> json.null()
    }),
    #("recipe_name", json.string(entry.title)),
    #("servings", json.float(entry.servings)),
    #("note", json.string(entry.note)),
    #("from_date", json.string(entry.from_date)),
    #("to_date", json.string(entry.to_date)),
    #("meal_type", json.string(meal_type_to_string(entry.meal_type))),
    #("created_by", json.int(entry.created_by)),
  ])
}

/// Convert MealPlanEntry to JSON
fn meal_plan_entry_to_json(entry: MealPlanEntry) -> json.Json {
  json.object([
    #("id", json.int(entry.id)),
    #("recipe", case entry.recipe_id {
      Some(r_id) -> json.int(r_id)
      None -> json.null()
    }),
    #("recipe_name", json.string(entry.recipe_name)),
    #("servings", json.float(entry.servings)),
    #("from_date", json.string(entry.from_date)),
    #("to_date", json.string(entry.to_date)),
    #(
      "meal_type",
      json.string(
        meal_type_to_string(
          meal_type_from_string(int.to_string(entry.meal_type_id)),
        ),
      ),
    ),
  ])
}

/// Parse meal plan creation request from JSON body
fn parse_meal_plan_request(body: String) -> Result(MealPlanCreate, String) {
  let decoder = create_meal_plan_request_decoder()
  case json.parse(body, decoder) {
    Ok(request) -> Ok(request)
    Error(_) ->
      Error(
        "Invalid request: expected JSON with recipe_name, from_date, to_date fields",
      )
  }
}

fn create_meal_plan_request_decoder() -> decode.Decoder(MealPlanCreate) {
  use recipe <- decode.optional_field(
    "recipe",
    None,
    decode.optional(decode.int),
  )
  use recipe_name <- decode.field("recipe_name", decode.string)
  use servings <- decode.optional_field("servings", 1.0, decode.float)
  use note <- decode.optional_field("note", "", decode.string)
  use from_date <- decode.field("from_date", decode.string)
  use to_date <- decode.field("to_date", decode.string)
  use meal_type_str <- decode.optional_field(
    "meal_type",
    "OTHER",
    decode.string,
  )

  let meal_type = meal_type_from_string(meal_type_str)

  decode.success(mealplan.MealPlanCreate(
    recipe: recipe,
    recipe_name: recipe_name,
    servings: servings,
    note: note,
    from_date: from_date,
    to_date: to_date,
    meal_type: meal_type,
  ))
}
