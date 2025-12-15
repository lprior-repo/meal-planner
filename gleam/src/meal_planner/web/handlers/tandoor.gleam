/// Tandoor Recipe Manager web handlers - Simplified GET-only implementation
///
/// Routes (GET only - POST/PUT/DELETE require complex state management):
/// - GET /tandoor/status - Check Tandoor connection status
/// - GET /api/tandoor/recipes - List recipes
/// - GET /api/tandoor/recipes/:id - Get recipe details  
/// - GET /api/tandoor/units - List measurement units
/// - GET /api/tandoor/keywords - List keywords
/// - GET /api/tandoor/meal-plans - List meal plans
/// - GET /api/tandoor/meal-plans/:id - Get meal plan details
/// - GET /api/tandoor/import-logs - List import logs
/// - GET /api/tandoor/export-logs - List export logs
/// - GET /api/tandoor/ingredients - List ingredients

import gleam/http
import gleam/int
import gleam/json
import gleam/option.{None, Some}

import meal_planner/env
import meal_planner/tandoor/client
import meal_planner/tandoor/api/recipe/list as recipe_list
import meal_planner/tandoor/api/recipe/get as recipe_get
import meal_planner/tandoor/api/unit/list as unit_list
import meal_planner/tandoor/api/keyword/keyword_api
import meal_planner/tandoor/api/mealplan/list as mealplan_list
import meal_planner/tandoor/api/mealplan/get as mealplan_get
import meal_planner/tandoor/api/ingredient/list as ingredient_list
import meal_planner/tandoor/api/import_export/import_export_api
import meal_planner/tandoor/handlers/helpers
import meal_planner/tandoor/core/ids

import wisp

/// Helper to build error response from TandoorError
fn error_response(error: client.TandoorError) -> wisp.Response {
  let #(status, message) = case error {
    client.AuthenticationError(msg) -> #(401, msg)
    client.AuthorizationError(msg) -> #(403, msg)
    client.NotFoundError(resource) -> #(404, resource)
    client.BadRequestError(msg) -> #(400, msg)
    client.ServerError(status, msg) -> #(status, msg)
    client.NetworkError(msg) -> #(502, msg)
    client.TimeoutError -> #(504, "Request timed out")
    client.ParseError(msg) -> #(500, msg)
    client.UnknownError(msg) -> #(500, msg)
  }
  helpers.error_response(status, message)
}

/// Get Tandoor client config with authentication
fn get_authenticated_client() -> Result(client.ClientConfig, wisp.Response) {
  case env.load_tandoor_config() {
    Some(cfg) -> {
      let config = client.session_config(cfg.base_url, cfg.username, cfg.password)
      case client.login(config) {
        Ok(auth_config) -> Ok(auth_config)
        Error(e) -> Error(error_response(e))
      }
    }
    None -> Error(helpers.error_response(502, "Tandoor not configured"))
  }
}

/// Handle GET /tandoor/status - Check connection status
pub fn handle_status(_req: wisp.Request) -> wisp.Response {
  case get_authenticated_client() {
    Ok(_) -> {
      json.object([
        #("status", json.string("connected")),
        #("service", json.string("tandoor")),
      ])
      |> json.to_string
      |> wisp.json_response(200)
    }
    Error(resp) -> resp
  }
}

/// Handle GET /api/tandoor/recipes - List recipes with pagination
pub fn handle_list_recipes(req: wisp.Request) -> wisp.Response {
  let query = wisp.get_query(req)
  let limit = helpers.parse_int_param(query, "limit")
  let offset = helpers.parse_int_param(query, "offset")

  case get_authenticated_client() {
    Ok(config) -> {
      case recipe_list.list_recipes(config, limit: limit, offset: offset) {
        Ok(response) -> {
          let results_json =
            json.array(
              response.results,
              fn(recipe) {
                json.object([
                  #("id", json.int(recipe.id)),
                  #("name", json.string(recipe.name)),
                  #("description", json.string(recipe.description)),
                  #("servings", json.int(recipe.servings)),
                  #("prep_time", json.int(recipe.prep_time)),
                  #("cooking_time", json.int(recipe.cooking_time)),
                ])
              },
            )

          let paginated = json.object([
            #("count", json.int(response.count)),
            #("next", helpers.encode_optional_string(response.next)),
            #("previous", helpers.encode_optional_string(response.previous)),
            #("results", results_json),
          ])

          paginated
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(e) -> error_response(e)
      }
    }
    Error(resp) -> resp
  }
}

/// Handle GET /api/tandoor/recipes/:id - Get recipe details
pub fn handle_get_recipe(_req: wisp.Request, recipe_id: String) -> wisp.Response {
  case int.parse(recipe_id) {
    Ok(id) -> {
      case get_authenticated_client() {
        Ok(config) -> {
          case recipe_get.get_recipe(config, recipe_id: id) {
            Ok(recipe) -> {
              json.object([
                #("id", json.int(recipe.id)),
                #("name", json.string(recipe.name)),
                #("description", json.string(recipe.description)),
                #("servings", json.int(recipe.servings)),
                #("servings_text", json.string(recipe.servings_text)),
                #("prep_time", json.int(recipe.prep_time)),
                #("cooking_time", json.int(recipe.cooking_time)),
              ])
              |> json.to_string
              |> wisp.json_response(200)
            }
            Error(e) -> error_response(e)
          }
        }
        Error(resp) -> resp
      }
    }
    Error(_) -> helpers.error_response(400, "Invalid recipe ID")
  }
}

/// Handle GET /api/tandoor/units - List measurement units
pub fn handle_list_units(req: wisp.Request) -> wisp.Response {
  let query = wisp.get_query(req)
  let page = helpers.parse_int_param(query, "page")
  let limit = helpers.parse_int_param(query, "limit")

  case get_authenticated_client() {
    Ok(config) -> {
      case unit_list.list_units(config, limit: limit, page: page) {
        Ok(response) -> {
          let results_json =
            json.array(
              response.results,
              fn(unit) {
                json.object([
                  #("id", json.int(unit.id)),
                  #("name", json.string(unit.name)),
                  #("plural_name", helpers.encode_optional_string(unit.plural_name)),
                ])
              },
            )

          let paginated = json.object([
            #("count", json.int(response.count)),
            #("next", helpers.encode_optional_string(response.next)),
            #("previous", helpers.encode_optional_string(response.previous)),
            #("results", results_json),
          ])

          paginated
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(e) -> error_response(e)
      }
    }
    Error(resp) -> resp
  }
}

/// Handle GET /api/tandoor/keywords - List keywords
pub fn handle_list_keywords(_req: wisp.Request) -> wisp.Response {
  case get_authenticated_client() {
    Ok(config) -> {
      case keyword_api.list_keywords(config) {
        Ok(keywords) -> {
          let results_json =
            json.array(
              keywords,
              fn(keyword) {
                json.object([
                  #("id", json.int(keyword.id)),
                  #("name", json.string(keyword.name)),
                ])
              },
            )

          results_json
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(e) -> error_response(e)
      }
    }
    Error(resp) -> resp
  }
}

/// Handle GET /api/tandoor/ingredients - List ingredients
pub fn handle_list_ingredients(req: wisp.Request) -> wisp.Response {
  let query = wisp.get_query(req)
  let page = helpers.parse_int_param(query, "page")
  let limit = helpers.parse_int_param(query, "limit")

  case get_authenticated_client() {
    Ok(config) -> {
      case ingredient_list.list_ingredients(config, limit: limit, page: page) {
        Ok(response) -> {
          let results_json =
            json.array(
              response.results,
              fn(ingredient) {
                let food_id = case ingredient.food {
                  Some(food) -> Some(food.id)
                  None -> None
                }
                let unit_id = case ingredient.unit {
                  Some(unit) -> Some(unit.id)
                  None -> None
                }
                json.object([
                  #("id", json.int(ingredient.id)),
                  #("food", helpers.encode_optional_int(food_id)),
                  #("unit", helpers.encode_optional_int(unit_id)),
                  #("amount", helpers.encode_optional_float(Some(ingredient.amount))),
                  #("note", helpers.encode_optional_string(ingredient.note)),
                ])
              },
            )

          let paginated = json.object([
            #("count", json.int(response.count)),
            #("next", helpers.encode_optional_string(response.next)),
            #("previous", helpers.encode_optional_string(response.previous)),
            #("results", results_json),
          ])

          paginated
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(e) -> error_response(e)
      }
    }
    Error(resp) -> resp
  }
}

/// Handle GET /api/tandoor/meal-plans - List meal plans with optional date filtering
pub fn handle_list_meal_plans(req: wisp.Request) -> wisp.Response {
  let query = wisp.get_query(req)
  let from_date = helpers.get_query_param(query, "from_date")
  let to_date = helpers.get_query_param(query, "to_date")

  case get_authenticated_client() {
    Ok(config) -> {
      case mealplan_list.list_meal_plans(config, from_date: from_date, to_date: to_date) {
        Ok(response) -> {
          let results_json =
            json.array(
              response.results,
              fn(entry) {
                json.object([
                  #("id", json.int(entry.id)),
                  #("title", json.string(entry.title)),
                  #("recipe_name", json.string(entry.recipe_name)),
                  #("servings", json.float(entry.servings)),
                  #("from_date", json.string(entry.from_date)),
                  #("to_date", json.string(entry.to_date)),
                  #("meal_type", json.string(entry.meal_type_name)),
                  #("shopping", json.bool(entry.shopping)),
                ])
              },
            )

          let paginated = json.object([
            #("count", json.int(response.count)),
            #("next", helpers.encode_optional_string(response.next)),
            #("previous", helpers.encode_optional_string(response.previous)),
            #("results", results_json),
          ])

          paginated
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(e) -> error_response(e)
      }
    }
    Error(resp) -> resp
  }
}

/// Handle GET /api/tandoor/meal-plans/:id - Get meal plan details
pub fn handle_get_meal_plan(
  _req: wisp.Request,
  meal_plan_id: String,
) -> wisp.Response {
  case int.parse(meal_plan_id) {
    Ok(id) -> {
      let id_wrapped = ids.meal_plan_id_from_int(id)
      case get_authenticated_client() {
        Ok(config) -> {
          case mealplan_get.get_meal_plan(config, id_wrapped) {
            Ok(entry) -> {
              json.object([
                #("id", json.int(entry.id)),
                #("title", json.string(entry.title)),
                #("recipe_name", json.string(entry.recipe_name)),
                #("servings", json.float(entry.servings)),
                #("from_date", json.string(entry.from_date)),
                #("to_date", json.string(entry.to_date)),
                #("meal_type", json.string(entry.meal_type_name)),
              ])
              |> json.to_string
              |> wisp.json_response(200)
            }
            Error(e) -> error_response(e)
          }
        }
        Error(resp) -> resp
      }
    }
    Error(_) -> helpers.error_response(400, "Invalid meal plan ID")
  }
}

/// Handle GET /api/tandoor/import-logs - List import logs
pub fn handle_list_import_logs(req: wisp.Request) -> wisp.Response {
  let query = wisp.get_query(req)
  let limit = helpers.parse_int_param(query, "limit")
  let offset = helpers.parse_int_param(query, "offset")

  case get_authenticated_client() {
    Ok(config) -> {
      case import_export_api.list_import_logs(config, limit: limit, offset: offset) {
        Ok(response) -> {
          let results_json =
            json.array(
              response.results,
              fn(import_log) {
                json.object([
                  #("id", json.int(import_log.id)),
                  #("import_type", json.string(import_log.import_type)),
                  #("msg", json.string(import_log.msg)),
                  #("running", json.bool(import_log.running)),
                  #("created_at", json.string(import_log.created_at)),
                ])
              },
            )

          let paginated = json.object([
            #("count", json.int(response.count)),
            #("next", helpers.encode_optional_string(response.next)),
            #("previous", helpers.encode_optional_string(response.previous)),
            #("results", results_json),
          ])

          paginated
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(e) -> error_response(e)
      }
    }
    Error(resp) -> resp
  }
}

/// Handle GET /api/tandoor/export-logs - List export logs
pub fn handle_list_export_logs(req: wisp.Request) -> wisp.Response {
  let query = wisp.get_query(req)
  let limit = helpers.parse_int_param(query, "limit")
  let offset = helpers.parse_int_param(query, "offset")

  case get_authenticated_client() {
    Ok(config) -> {
      case import_export_api.list_export_logs(config, limit: limit, offset: offset) {
        Ok(response) -> {
          let results_json =
            json.array(
              response.results,
              fn(export_log) {
                json.object([
                  #("id", json.int(export_log.id)),
                  #("export_type", json.string(export_log.export_type)),
                  #("msg", json.string(export_log.msg)),
                  #("running", json.bool(export_log.running)),
                  #("created_at", json.string(export_log.created_at)),
                ])
              },
            )

          let paginated = json.object([
            #("count", json.int(response.count)),
            #("next", helpers.encode_optional_string(response.next)),
            #("previous", helpers.encode_optional_string(response.previous)),
            #("results", results_json),
          ])

          paginated
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(e) -> error_response(e)
      }
    }
    Error(resp) -> resp
  }
}

/// Main router for all Tandoor API requests
pub fn handle_tandoor_routes(req: wisp.Request) -> wisp.Response {
  let path = wisp.path_segments(req)
  let method = req.method

  case method, path {
    // Status
    http.Get, ["tandoor", "status"] -> handle_status(req)

    // Recipes
    http.Get, ["api", "tandoor", "recipes"] -> handle_list_recipes(req)
    http.Get, ["api", "tandoor", "recipes", id] -> handle_get_recipe(req, id)

    // Ingredients
    http.Get, ["api", "tandoor", "ingredients"] -> handle_list_ingredients(req)

    // Meal Plans
    http.Get, ["api", "tandoor", "meal-plans"] -> handle_list_meal_plans(req)
    http.Get, ["api", "tandoor", "meal-plans", id] -> handle_get_meal_plan(req, id)

    // Import/Export Logs
    http.Get, ["api", "tandoor", "import-logs"] -> handle_list_import_logs(req)
    http.Get, ["api", "tandoor", "export-logs"] -> handle_list_export_logs(req)

    // Units and Keywords
    http.Get, ["api", "tandoor", "units"] -> handle_list_units(req)
    http.Get, ["api", "tandoor", "keywords"] -> handle_list_keywords(req)

    _, _ -> wisp.not_found()
  }
}
