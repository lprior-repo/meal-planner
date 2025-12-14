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
import gleam/option.{type Option, None, Some}
import gleam/result

import meal_planner/env
import meal_planner/tandoor/client as tandoor

import meal_planner/tandoor/types/mealplan/meal_plan.{type MealPlan}
import meal_planner/tandoor/types/mealplan/meal_plan_entry.{type MealPlanEntry}
import meal_planner/tandoor/types/mealplan/meal_type.{
  type MealType, meal_type_from_string, meal_type_to_string,
}
import meal_planner/tandoor/types/recipe/recipe_overview.{type RecipeOverview}
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
          let config =
            tandoor.session_config(cfg.base_url, cfg.username, cfg.password)
          case tandoor.login(config) {
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
                  #("error", json.string(tandoor.error_to_string(e))),
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
      case tandoor.get_recipes(config, limit, offset) {
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
            "Failed to fetch recipes: " <> tandoor.error_to_string(e),
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
          case tandoor.get_recipe_detail(config, id) {
            Ok(detail) -> {
              let body = recipe_detail_to_json(detail) |> json.to_string
              wisp.json_response(body, 200)
            }
            Error(tandoor.NotFoundError(_)) ->
              error_response(404, "Recipe not found")
            Error(e) ->
              error_response(
                500,
                "Failed to fetch recipe: " <> tandoor.error_to_string(e),
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
      case tandoor.get_meal_plan(config, from_date, to_date) {
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
          error_response(
            500,
            "Failed to fetch meal plan: " <> tandoor.error_to_string(e),
          )
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
          case tandoor.create_meal_plan_entry(config, entry_request) {
            Ok(created) -> {
              let body = meal_plan_entry_to_json(created) |> json.to_string
              wisp.json_response(body, 201)
            }
            Error(e) ->
              error_response(
                500,
                "Failed to create meal plan: " <> tandoor.error_to_string(e),
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
          case tandoor.delete_meal_plan_entry(config, id) {
            Ok(_) -> {
              let body =
                json.object([
                  #("success", json.bool(True)),
                  #("message", json.string("Meal plan entry deleted")),
                ])
                |> json.to_string
              wisp.json_response(body, 200)
            }
            Error(tandoor.NotFoundError(_)) ->
              error_response(404, "Meal plan entry not found")
            Error(e) ->
              error_response(
                500,
                "Failed to delete meal plan: " <> tandoor.error_to_string(e),
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
fn get_authenticated_config() -> Result(tandoor.ClientConfig, ConfigError) {
  case env.load_tandoor_config() {
    None -> Error(ConfigError(500, "Tandoor not configured"))
    Some(cfg) -> {
      let config =
        tandoor.session_config(cfg.base_url, cfg.username, cfg.password)
      case tandoor.login(config) {
        Ok(auth_config) -> Ok(auth_config)
        Error(e) ->
          Error(ConfigError(
            502,
            "Tandoor authentication failed: " <> tandoor.error_to_string(e),
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
fn recipe_to_json(recipe: tandoor.Recipe) -> json.Json {
  json.object([
    #("id", json.int(recipe.id)),
    #("name", json.string(recipe.name)),
    #("slug", json.nullable(recipe.slug, json.string)),
    #("description", json.nullable(recipe.description, json.string)),
    #("servings", json.int(recipe.servings)),
    #("servings_text", json.nullable(recipe.servings_text, json.string)),
    #("working_time", json.nullable(recipe.working_time, json.int)),
    #("waiting_time", json.nullable(recipe.waiting_time, json.int)),
    #("created_at", json.nullable(recipe.created_at, json.string)),
    #("updated_at", json.nullable(recipe.updated_at, json.string)),
  ])
}

/// Convert RecipeDetail to JSON (full recipe with steps, ingredients, nutrition)
fn recipe_detail_to_json(detail: tandoor.RecipeDetail) -> json.Json {
  json.object([
    #("id", json.int(detail.id)),
    #("name", json.string(detail.name)),
    #("slug", json.nullable(detail.slug, json.string)),
    #("description", json.nullable(detail.description, json.string)),
    #("servings", json.int(detail.servings)),
    #("servings_text", json.nullable(detail.servings_text, json.string)),
    #("working_time", json.nullable(detail.working_time, json.int)),
    #("waiting_time", json.nullable(detail.waiting_time, json.int)),
    #("source_url", json.nullable(detail.source_url, json.string)),
    #("steps", json.array(detail.steps, step_to_json)),
    #("nutrition", case detail.nutrition {
      Some(n) -> nutrition_to_json(n)
      None -> json.null()
    }),
    #("keywords", json.array(detail.keywords, keyword_to_json)),
    #("created_at", json.nullable(detail.created_at, json.string)),
    #("updated_at", json.nullable(detail.updated_at, json.string)),
  ])
}

/// Convert Step to JSON
fn step_to_json(step: tandoor.Step) -> json.Json {
  json.object([
    #("id", json.int(step.id)),
    #("name", json.string(step.name)),
    #("instruction", json.string(step.instruction)),
    #("time", json.int(step.time)),
    #("order", json.int(step.order)),
    #("ingredients", json.array(step.ingredients, ingredient_to_json)),
    #("show_as_header", json.bool(step.show_as_header)),
    #("show_ingredients_table", json.bool(step.show_ingredients_table)),
  ])
}

/// Convert Ingredient to JSON
fn ingredient_to_json(ing: tandoor.Ingredient) -> json.Json {
  json.object([
    #("id", json.int(ing.id)),
    #("amount", json.float(ing.amount)),
    #("note", json.string(ing.note)),
    #("is_header", json.bool(ing.is_header)),
    #("no_amount", json.bool(ing.no_amount)),
    #("original_text", json.nullable(ing.original_text, json.string)),
    #("food", case ing.food {
      Some(f) -> food_to_json(f)
      None -> json.null()
    }),
    #("unit", case ing.unit {
      Some(u) -> unit_to_json(u)
      None -> json.null()
    }),
  ])
}

/// Convert Food to JSON
fn food_to_json(food: tandoor.Food) -> json.Json {
  json.object([
    #("id", json.int(food.id)),
    #("name", json.string(food.name)),
    #("plural_name", json.nullable(food.plural_name, json.string)),
    #("description", json.string(food.description)),
  ])
}

/// Convert Unit to JSON
fn unit_to_json(unit: tandoor.Unit) -> json.Json {
  json.object([
    #("id", json.int(unit.id)),
    #("name", json.string(unit.name)),
    #("plural_name", json.nullable(unit.plural_name, json.string)),
    #("description", json.string(unit.description)),
  ])
}

/// Convert NutritionInfo to JSON
fn nutrition_to_json(n: tandoor.NutritionInfo) -> json.Json {
  json.object([
    #("id", json.int(n.id)),
    #("calories", json.float(n.calories)),
    #("proteins", json.float(n.proteins)),
    #("carbohydrates", json.float(n.carbohydrates)),
    #("fats", json.float(n.fats)),
    #("source", json.string(n.source)),
  ])
}

/// Convert Keyword to JSON
fn keyword_to_json(kw: tandoor.Keyword) -> json.Json {
  json.object([
    #("id", json.int(kw.id)),
    #("name", json.string(kw.name)),
    #("description", json.string(kw.description)),
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
fn parse_meal_plan_request(
  body: String,
) -> Result(tandoor.CreateMealPlanRequest, String) {
  let decoder = create_meal_plan_request_decoder()
  case json.parse(body, decoder) {
    Ok(request) -> Ok(request)
    Error(_) ->
      Error(
        "Invalid request: expected JSON with recipe_name, from_date, to_date fields",
      )
  }
}

fn create_meal_plan_request_decoder() -> decode.Decoder(
  tandoor.CreateMealPlanRequest,
) {
  use recipe <- decode.optional_field(
    "recipe",
    None,
    decode.optional(decode.int),
  )
  use title <- decode.field("title", decode.string)
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

  decode.success(tandoor.CreateMealPlanRequest(
    recipe: recipe,
    title: title,
    servings: servings,
    note: note,
    from_date: from_date,
    to_date: to_date,
    meal_type: meal_type,
  ))
}
