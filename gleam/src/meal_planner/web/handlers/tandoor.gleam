/// Tandoor Recipe Manager web handlers
///
/// This module provides endpoints for Tandoor Recipe Manager integration,
/// including:
/// - Status checking
/// - Units listing
/// - Keywords listing
/// - Recipes CRUD operations
/// - Supermarkets CRUD operations
/// - Supermarket Categories CRUD operations
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/result

import meal_planner/tandoor/api/import_export/import_export_api
import meal_planner/tandoor/api/ingredient/list as ingredient_list
import meal_planner/tandoor/api/keyword/keyword_api
import meal_planner/tandoor/api/mealplan/create as mealplan_create_api
import meal_planner/tandoor/api/mealplan/get as mealplan_get
import meal_planner/tandoor/api/mealplan/list as mealplan_list
import meal_planner/tandoor/api/mealplan/update as mealplan_update
import meal_planner/tandoor/api/recipe/create as recipe_create_api
import meal_planner/tandoor/api/recipe/delete as recipe_delete
import meal_planner/tandoor/api/recipe/get as recipe_get
import meal_planner/tandoor/api/recipe/list as recipe_list
import meal_planner/tandoor/api/recipe/update as recipe_update
import meal_planner/tandoor/api/step/create as step_create_api
import meal_planner/tandoor/api/step/delete as step_delete
import meal_planner/tandoor/api/step/get as step_get
import meal_planner/tandoor/api/step/list as step_list
import meal_planner/tandoor/api/step/update as step_update
import meal_planner/tandoor/api/supermarket/create as supermarket_create_api
import meal_planner/tandoor/api/supermarket/delete as supermarket_delete
import meal_planner/tandoor/api/supermarket/get as supermarket_get
import meal_planner/tandoor/api/supermarket/list as supermarket_list
import meal_planner/tandoor/api/supermarket/update as supermarket_update
import meal_planner/tandoor/api/unit/list as unit_list
import meal_planner/tandoor/core/ids.{meal_plan_id_from_int, recipe_id_from_int}
import meal_planner/tandoor/decoders/import_export/export_log_create_request_decoder
import meal_planner/tandoor/decoders/import_export/export_log_update_request_decoder
import meal_planner/tandoor/decoders/import_export/import_log_create_request_decoder
import meal_planner/tandoor/decoders/import_export/import_log_update_request_decoder
import meal_planner/tandoor/encoders/import_export/export_log_encoder.{
  type ExportLogCreateRequest, type ExportLogUpdateRequest,
  ExportLogCreateRequest, ExportLogUpdateRequest,
}
import meal_planner/tandoor/encoders/import_export/import_log_encoder.{
  type ImportLogCreateRequest, type ImportLogUpdateRequest,
  ImportLogCreateRequest, ImportLogUpdateRequest,
}
import meal_planner/tandoor/encoders/recipe/recipe_create_encoder.{
  type CreateRecipeRequest, CreateRecipeRequest,
}
import meal_planner/tandoor/encoders/recipe/step_encoder.{
  type StepCreateRequest, type StepUpdateRequest, StepCreateRequest,
  StepUpdateRequest,
}
import meal_planner/tandoor/handlers/helpers
import meal_planner/tandoor/types.{
  type TandoorIngredient, type TandoorKeyword, type TandoorNutrition,
  type TandoorRecipe, type TandoorStep,
}
import meal_planner/tandoor/types/import_export/export_log.{type ExportLog}
import meal_planner/tandoor/types/import_export/import_log.{type ImportLog}
import meal_planner/tandoor/types/mealplan/meal_plan.{type MealPlan}
import meal_planner/tandoor/types/mealplan/meal_plan_entry.{type MealPlanEntry}
import meal_planner/tandoor/types/mealplan/meal_type.{
  meal_type_to_string as mt_to_string,
}
import meal_planner/tandoor/types/mealplan/mealplan.{
  type MealPlanCreate, type MealPlanUpdate, MealPlanCreate, MealPlanUpdate,
  meal_type_from_string as mp_meal_type_from_string,
}
import meal_planner/tandoor/types/recipe/ingredient.{type Ingredient}
import meal_planner/tandoor/types/recipe/recipe_update as recipe_update_type
import meal_planner/tandoor/types/recipe/step.{type Step}
import meal_planner/tandoor/types/supermarket/supermarket_category_create.{
  type SupermarketCategoryCreateRequest, SupermarketCategoryCreateRequest,
}
import meal_planner/tandoor/types/supermarket/supermarket_create.{
  type SupermarketCreateRequest, SupermarketCreateRequest,
}
import meal_planner/web/handlers/tandoor/steps

import wisp

/// Main router for Tandoor API requests
pub fn handle_tandoor_routes(req: wisp.Request) -> wisp.Response {
  let path = wisp.path_segments(req)

  case path {
    // Status endpoint
    ["tandoor", "status"] -> {
      case helpers.get_authenticated_client() {
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

    // Units (GET only)
    ["api", "tandoor", "units"] -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case
            unit_list.list_units(config, limit: option.None, page: option.None)
          {
            Ok(response) -> {
              let results_json =
                json.array(response.results, fn(unit) {
                  json.object([
                    #("id", json.int(unit.id)),
                    #("name", json.string(unit.name)),
                    #(
                      "plural_name",
                      helpers.encode_optional_string(unit.plural_name),
                    ),
                  ])
                })

              json.object([
                #("count", json.int(response.count)),
                #("next", helpers.encode_optional_string(response.next)),
                #("previous", helpers.encode_optional_string(response.previous)),
                #("results", results_json),
              ])
              |> json.to_string
              |> wisp.json_response(200)
            }
            Error(_) -> wisp.not_found()
          }
        }
        Error(resp) -> resp
      }
    }

    // Keywords (GET only)
    ["api", "tandoor", "keywords"] -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case keyword_api.list_keywords(config) {
            Ok(keywords) -> {
              json.array(keywords, fn(keyword) {
                json.object([
                  #("id", json.int(keyword.id)),
                  #("name", json.string(keyword.name)),
                ])
              })
              |> json.to_string
              |> wisp.json_response(200)
            }
            Error(_) -> wisp.not_found()
          }
        }
        Error(resp) -> resp
      }
    }

    // Recipes (GET list, POST create)
    ["api", "tandoor", "recipes"] -> handle_recipes_collection(req)

    // Recipe by ID (GET, PATCH, DELETE)
    ["api", "tandoor", "recipes", recipe_id] ->
      handle_recipe_by_id(req, recipe_id)

    // Meal Plans (GET list, POST create)
    ["api", "tandoor", "meal-plans"] -> handle_meal_plans_collection(req)

    // Meal Plan by ID (GET, PATCH, DELETE)
    ["api", "tandoor", "meal-plans", meal_plan_id] ->
      handle_meal_plan_by_id(req, meal_plan_id)

    // Steps (GET list, POST create)
    ["api", "tandoor", "steps"] -> steps.handle_steps_collection(req)

    // Step by ID (GET, PATCH, DELETE)
    ["api", "tandoor", "steps", step_id] ->
      steps.handle_step_by_id(req, step_id)

    // Ingredients (GET list only)
    ["api", "tandoor", "ingredients"] -> handle_ingredients_collection(req)

    // Import Logs
    ["api", "tandoor", "import-logs"] -> handle_import_logs_collection(req)
    ["api", "tandoor", "import-logs", log_id] ->
      handle_import_log_by_id(req, log_id)

    // Export Logs
    ["api", "tandoor", "export-logs"] -> handle_export_logs_collection(req)
    ["api", "tandoor", "export-logs", log_id] ->
      handle_export_log_by_id(req, log_id)

    // Supermarkets (GET list, POST create)
    ["api", "tandoor", "supermarkets"] -> handle_supermarkets_collection(req)

    // Supermarket by ID (GET, PATCH, DELETE)
    ["api", "tandoor", "supermarkets", supermarket_id] ->
      handle_supermarket_by_id(req, supermarket_id)

    // Supermarket Categories (GET list, POST create)
    ["api", "tandoor", "supermarket-categories"] ->
      handle_categories_collection(req)

    // Supermarket Category by ID (GET, PATCH, DELETE)
    ["api", "tandoor", "supermarket-categories", category_id] ->
      handle_category_by_id(req, category_id)

    _ -> wisp.not_found()
  }
}

// =============================================================================
// Recipe Collection Handler
// =============================================================================

fn handle_recipes_collection(req: wisp.Request) -> wisp.Response {
  case req.method {
    http.Get -> handle_list_recipes(req)
    http.Post -> handle_create_recipe(req)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn handle_list_recipes(_req: wisp.Request) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case
        recipe_list.list_recipes(
          config,
          limit: option.None,
          offset: option.None,
        )
      {
        Ok(response) -> {
          let results_json =
            json.array(response.results, fn(recipe) { encode_recipe(recipe) })

          json.object([
            #("count", json.int(response.count)),
            #("next", helpers.encode_optional_string(response.next)),
            #("previous", helpers.encode_optional_string(response.previous)),
            #("results", results_json),
          ])
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

fn handle_create_recipe(req: wisp.Request) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_recipe_create_request(body) {
    Ok(request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case recipe_create_api.create_recipe(config, request) {
            Ok(recipe) -> {
              encode_recipe(recipe)
              |> json.to_string
              |> wisp.json_response(201)
            }
            Error(_) -> helpers.error_response(500, "Failed to create recipe")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

// =============================================================================
// Recipe Item Handler
// =============================================================================

fn handle_recipe_by_id(req: wisp.Request, recipe_id: String) -> wisp.Response {
  case int.parse(recipe_id) {
    Ok(id) -> {
      case req.method {
        http.Get -> handle_get_recipe(req, id)
        http.Patch -> handle_update_recipe(req, id)
        http.Delete -> handle_delete_recipe(req, id)
        _ -> wisp.method_not_allowed([http.Get, http.Patch, http.Delete])
      }
    }
    Error(_) -> helpers.error_response(400, "Invalid recipe ID")
  }
}

fn handle_get_recipe(_req: wisp.Request, id: Int) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case recipe_get.get_recipe(config, recipe_id: id) {
        Ok(recipe) -> {
          encode_recipe(recipe)
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

fn handle_update_recipe(req: wisp.Request, id: Int) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_recipe_update_request(body) {
    Ok(request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case
            recipe_update.update_recipe(
              config,
              recipe_id: id,
              update_data: request,
            )
          {
            Ok(recipe) -> {
              encode_recipe(recipe)
              |> json.to_string
              |> wisp.json_response(200)
            }
            Error(_) -> helpers.error_response(500, "Failed to update recipe")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

fn handle_delete_recipe(_req: wisp.Request, id: Int) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case recipe_delete.delete_recipe(config, id) {
        Ok(Nil) -> wisp.response(204)
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

// =============================================================================
// Meal Plans Collection Handler
// =============================================================================

fn handle_meal_plans_collection(req: wisp.Request) -> wisp.Response {
  case req.method {
    http.Get -> handle_list_meal_plans(req)
    http.Post -> handle_create_meal_plan(req)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn handle_list_meal_plans(_req: wisp.Request) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case
        mealplan_list.list_meal_plans(
          config,
          from_date: option.None,
          to_date: option.None,
        )
      {
        Ok(response) -> {
          let results_json =
            json.array(response.results, fn(meal_plan) {
              encode_meal_plan(meal_plan)
            })

          json.object([
            #("count", json.int(response.count)),
            #("next", helpers.encode_optional_string(response.next)),
            #("previous", helpers.encode_optional_string(response.previous)),
            #("results", results_json),
          ])
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

fn handle_create_meal_plan(req: wisp.Request) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_meal_plan_create_request(body) {
    Ok(request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case mealplan_create_api.create_meal_plan(config, request) {
            Ok(meal_plan) -> {
              encode_meal_plan_entry(meal_plan)
              |> json.to_string
              |> wisp.json_response(201)
            }
            Error(_) ->
              helpers.error_response(500, "Failed to create meal plan")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

// =============================================================================
// Meal Plans Item Handler
// =============================================================================

fn handle_meal_plan_by_id(
  req: wisp.Request,
  meal_plan_id: String,
) -> wisp.Response {
  case int.parse(meal_plan_id) {
    Ok(id) -> {
      case req.method {
        http.Get -> handle_get_meal_plan(req, id)
        http.Patch -> handle_update_meal_plan(req, id)
        http.Delete -> handle_delete_meal_plan(req, id)
        _ -> wisp.method_not_allowed([http.Get, http.Patch, http.Delete])
      }
    }
    Error(_) -> helpers.error_response(400, "Invalid meal plan ID")
  }
}

fn handle_get_meal_plan(_req: wisp.Request, id: Int) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case mealplan_get.get_meal_plan(config, meal_plan_id_from_int(id)) {
        Ok(meal_plan) -> {
          encode_meal_plan_entry(meal_plan)
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

fn handle_update_meal_plan(req: wisp.Request, id: Int) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_meal_plan_update_request(body) {
    Ok(request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case
            mealplan_update.update_meal_plan(
              config,
              meal_plan_id_from_int(id),
              request,
            )
          {
            Ok(meal_plan) -> {
              encode_meal_plan_entry(meal_plan)
              |> json.to_string
              |> wisp.json_response(200)
            }
            Error(_) ->
              helpers.error_response(500, "Failed to update meal plan")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

fn handle_delete_meal_plan(_req: wisp.Request, id: Int) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case mealplan_update.delete_meal_plan(config, meal_plan_id_from_int(id)) {
        Ok(Nil) -> wisp.response(204)
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

// =============================================================================
// Steps Collection Handler
// =============================================================================

fn handle_steps_collection(req: wisp.Request) -> wisp.Response {
  case req.method {
    http.Get -> handle_list_steps(req)
    http.Post -> handle_create_step(req)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn handle_list_steps(_req: wisp.Request) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case step_list.list_steps(config, limit: option.None, page: option.None) {
        Ok(response) -> {
          let results_json =
            json.array(response.results, fn(step) { encode_recipe_step(step) })

          json.object([
            #("count", json.int(response.count)),
            #("next", helpers.encode_optional_string(response.next)),
            #("previous", helpers.encode_optional_string(response.previous)),
            #("results", results_json),
          ])
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

fn handle_create_step(req: wisp.Request) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_step_create_request(body) {
    Ok(request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case step_create_api.create_step(config, request) {
            Ok(step) -> {
              encode_recipe_step(step)
              |> json.to_string
              |> wisp.json_response(201)
            }
            Error(_) -> helpers.error_response(500, "Failed to create step")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

// =============================================================================
// Steps Item Handler
// =============================================================================

fn handle_step_by_id(req: wisp.Request, step_id: String) -> wisp.Response {
  case int.parse(step_id) {
    Ok(id) -> {
      case req.method {
        http.Get -> handle_get_step(req, id)
        http.Patch -> handle_update_step(req, id)
        http.Delete -> handle_delete_step(req, id)
        _ -> wisp.method_not_allowed([http.Get, http.Patch, http.Delete])
      }
    }
    Error(_) -> helpers.error_response(400, "Invalid step ID")
  }
}

fn handle_get_step(_req: wisp.Request, id: Int) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case step_get.get_step(config, step_id: id) {
        Ok(step) -> {
          encode_recipe_step(step)
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

fn handle_update_step(req: wisp.Request, id: Int) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_step_update_request(body) {
    Ok(request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case step_update.update_step(config, step_id: id, request: request) {
            Ok(step) -> {
              encode_recipe_step(step)
              |> json.to_string
              |> wisp.json_response(200)
            }
            Error(_) -> helpers.error_response(500, "Failed to update step")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

fn handle_delete_step(_req: wisp.Request, id: Int) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case step_delete.delete_step(config, id) {
        Ok(Nil) -> wisp.response(204)
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

// =============================================================================
// Ingredients Collection Handler
// =============================================================================

fn handle_ingredients_collection(req: wisp.Request) -> wisp.Response {
  case req.method {
    http.Get -> handle_list_ingredients(req)
    _ -> wisp.method_not_allowed([http.Get])
  }
}

fn handle_list_ingredients(_req: wisp.Request) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case
        ingredient_list.list_ingredients(
          config,
          limit: option.None,
          page: option.None,
        )
      {
        Ok(response) -> {
          let results_json =
            json.array(response.results, fn(ingredient) {
              encode_ingredient_detail(ingredient)
            })

          json.object([
            #("count", json.int(response.count)),
            #("next", helpers.encode_optional_string(response.next)),
            #("previous", helpers.encode_optional_string(response.previous)),
            #("results", results_json),
          ])
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

// =============================================================================
// Import Logs Collection Handler
// =============================================================================

fn handle_import_logs_collection(req: wisp.Request) -> wisp.Response {
  case req.method {
    http.Get -> handle_list_import_logs(req)
    http.Post -> handle_create_import_log(req)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn handle_list_import_logs(req: wisp.Request) -> wisp.Response {
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

  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case
        import_export_api.list_import_logs(config, limit: limit, offset: offset)
      {
        Ok(response) -> {
          let results_json =
            json.array(response.results, fn(log) { encode_import_log(log) })

          json.object([
            #("count", json.int(response.count)),
            #("next", helpers.encode_optional_string(response.next)),
            #("previous", helpers.encode_optional_string(response.previous)),
            #("results", results_json),
          ])
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

fn handle_create_import_log(req: wisp.Request) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_import_log_create_request(body) {
    Ok(request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case import_export_api.create_import_log(config, request) {
            Ok(log) -> {
              encode_import_log(log)
              |> json.to_string
              |> wisp.json_response(201)
            }
            Error(_) ->
              helpers.error_response(500, "Failed to create import log")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

fn handle_import_log_by_id(req: wisp.Request, log_id: String) -> wisp.Response {
  case int.parse(log_id) {
    Ok(id) -> {
      case req.method {
        http.Get -> handle_get_import_log(req, id)
        http.Patch -> handle_update_import_log(req, id)
        http.Delete -> handle_delete_import_log(req, id)
        _ -> wisp.method_not_allowed([http.Get, http.Patch, http.Delete])
      }
    }
    Error(_) -> helpers.error_response(400, "Invalid log ID")
  }
}

fn handle_get_import_log(_req: wisp.Request, id: Int) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case import_export_api.get_import_log(config, log_id: id) {
        Ok(log) -> {
          encode_import_log(log)
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

fn handle_update_import_log(req: wisp.Request, id: Int) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_import_log_update_request(body) {
    Ok(request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case
            import_export_api.update_import_log(config, request, log_id: id)
          {
            Ok(log) -> {
              encode_import_log(log)
              |> json.to_string
              |> wisp.json_response(200)
            }
            Error(_) ->
              helpers.error_response(500, "Failed to update import log")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

fn handle_delete_import_log(_req: wisp.Request, id: Int) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case import_export_api.delete_import_log(config, log_id: id) {
        Ok(Nil) -> wisp.response(204)
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

// =============================================================================
// Export Logs Collection Handler
// =============================================================================

fn handle_export_logs_collection(req: wisp.Request) -> wisp.Response {
  case req.method {
    http.Get -> handle_list_export_logs(req)
    http.Post -> handle_create_export_log(req)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn handle_list_export_logs(req: wisp.Request) -> wisp.Response {
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

  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case
        import_export_api.list_export_logs(config, limit: limit, offset: offset)
      {
        Ok(response) -> {
          let results_json =
            json.array(response.results, fn(log) { encode_export_log(log) })

          json.object([
            #("count", json.int(response.count)),
            #("next", helpers.encode_optional_string(response.next)),
            #("previous", helpers.encode_optional_string(response.previous)),
            #("results", results_json),
          ])
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

fn handle_create_export_log(req: wisp.Request) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_export_log_create_request(body) {
    Ok(request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case import_export_api.create_export_log(config, request) {
            Ok(log) -> {
              encode_export_log(log)
              |> json.to_string
              |> wisp.json_response(201)
            }
            Error(_) ->
              helpers.error_response(500, "Failed to create export log")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

fn handle_export_log_by_id(req: wisp.Request, log_id: String) -> wisp.Response {
  case int.parse(log_id) {
    Ok(id) -> {
      case req.method {
        http.Get -> handle_get_export_log(req, id)
        http.Patch -> handle_update_export_log(req, id)
        http.Delete -> handle_delete_export_log(req, id)
        _ -> wisp.method_not_allowed([http.Get, http.Patch, http.Delete])
      }
    }
    Error(_) -> helpers.error_response(400, "Invalid log ID")
  }
}

fn handle_get_export_log(_req: wisp.Request, id: Int) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case import_export_api.get_export_log(config, log_id: id) {
        Ok(log) -> {
          encode_export_log(log)
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

fn handle_update_export_log(req: wisp.Request, id: Int) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_export_log_update_request(body) {
    Ok(request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case
            import_export_api.update_export_log(config, request, log_id: id)
          {
            Ok(log) -> {
              encode_export_log(log)
              |> json.to_string
              |> wisp.json_response(200)
            }
            Error(_) ->
              helpers.error_response(500, "Failed to update export log")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

fn handle_delete_export_log(_req: wisp.Request, id: Int) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case import_export_api.delete_export_log(config, log_id: id) {
        Ok(Nil) -> wisp.response(204)
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

// =============================================================================
// Supermarket Collection Handler
// =============================================================================

fn handle_supermarkets_collection(req: wisp.Request) -> wisp.Response {
  case req.method {
    http.Get -> handle_list_supermarkets(req)
    http.Post -> handle_create_supermarket(req)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn handle_list_supermarkets(_req: wisp.Request) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case
        supermarket_list.list_supermarkets(
          config,
          limit: option.None,
          page: option.None,
        )
      {
        Ok(response) -> {
          let results_json =
            json.array(response.results, fn(supermarket) {
              json.object([
                #("id", json.int(supermarket.id)),
                #("name", json.string(supermarket.name)),
                #(
                  "description",
                  helpers.encode_optional_string(supermarket.description),
                ),
              ])
            })

          json.object([
            #("count", json.int(response.count)),
            #("next", helpers.encode_optional_string(response.next)),
            #("previous", helpers.encode_optional_string(response.previous)),
            #("results", results_json),
          ])
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

fn handle_create_supermarket(req: wisp.Request) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_supermarket_create_request(body) {
    Ok(request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case supermarket_create_api.create_supermarket(config, request) {
            Ok(supermarket) -> {
              json.object([
                #("id", json.int(supermarket.id)),
                #("name", json.string(supermarket.name)),
                #(
                  "description",
                  helpers.encode_optional_string(supermarket.description),
                ),
              ])
              |> json.to_string
              |> wisp.json_response(201)
            }
            Error(_) ->
              helpers.error_response(500, "Failed to create supermarket")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

// =============================================================================
// Supermarket Item Handler
// =============================================================================

fn handle_supermarket_by_id(
  req: wisp.Request,
  supermarket_id: String,
) -> wisp.Response {
  case int.parse(supermarket_id) {
    Ok(id) -> {
      case req.method {
        http.Get -> handle_get_supermarket(req, id)
        http.Patch -> handle_update_supermarket(req, id)
        http.Delete -> handle_delete_supermarket(req, id)
        _ -> wisp.method_not_allowed([http.Get, http.Patch, http.Delete])
      }
    }
    Error(_) -> helpers.error_response(400, "Invalid supermarket ID")
  }
}

fn handle_get_supermarket(_req: wisp.Request, id: Int) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case supermarket_get.get_supermarket(config, id: id) {
        Ok(supermarket) -> {
          json.object([
            #("id", json.int(supermarket.id)),
            #("name", json.string(supermarket.name)),
            #(
              "description",
              helpers.encode_optional_string(supermarket.description),
            ),
          ])
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

fn handle_update_supermarket(req: wisp.Request, id: Int) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_supermarket_create_request(body) {
    Ok(request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case
            supermarket_update.update_supermarket(
              config,
              id: id,
              supermarket_data: request,
            )
          {
            Ok(supermarket) -> {
              json.object([
                #("id", json.int(supermarket.id)),
                #("name", json.string(supermarket.name)),
                #(
                  "description",
                  helpers.encode_optional_string(supermarket.description),
                ),
              ])
              |> json.to_string
              |> wisp.json_response(200)
            }
            Error(_) ->
              helpers.error_response(500, "Failed to update supermarket")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

fn handle_delete_supermarket(_req: wisp.Request, id: Int) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case supermarket_delete.delete_supermarket(config, id) {
        Ok(Nil) -> wisp.response(204)
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

// =============================================================================
// Supermarket Category Collection Handler
// =============================================================================

fn handle_categories_collection(req: wisp.Request) -> wisp.Response {
  case req.method {
    http.Get -> handle_list_categories(req)
    http.Post -> handle_create_category(req)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn handle_list_categories(_req: wisp.Request) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case
        supermarket_category.list_categories(
          config,
          limit: option.None,
          offset: option.None,
        )
      {
        Ok(response) -> {
          let results_json =
            json.array(response.results, fn(category) {
              json.object([
                #("id", json.int(category.id)),
                #("name", json.string(category.name)),
                #(
                  "description",
                  helpers.encode_optional_string(category.description),
                ),
              ])
            })

          json.object([
            #("count", json.int(response.count)),
            #("next", helpers.encode_optional_string(response.next)),
            #("previous", helpers.encode_optional_string(response.previous)),
            #("results", results_json),
          ])
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

fn handle_create_category(req: wisp.Request) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_supermarket_category_create_request(body) {
    Ok(request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case supermarket_category.create_category(config, request) {
            Ok(category) -> {
              json.object([
                #("id", json.int(category.id)),
                #("name", json.string(category.name)),
                #(
                  "description",
                  helpers.encode_optional_string(category.description),
                ),
              ])
              |> json.to_string
              |> wisp.json_response(201)
            }
            Error(_) -> helpers.error_response(500, "Failed to create category")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

// =============================================================================
// Supermarket Category Item Handler
// =============================================================================

fn handle_category_by_id(
  req: wisp.Request,
  category_id: String,
) -> wisp.Response {
  case int.parse(category_id) {
    Ok(id) -> {
      case req.method {
        http.Get -> handle_get_category(req, id)
        http.Patch -> handle_update_category(req, id)
        http.Delete -> handle_delete_category(req, id)
        _ -> wisp.method_not_allowed([http.Get, http.Patch, http.Delete])
      }
    }
    Error(_) -> helpers.error_response(400, "Invalid category ID")
  }
}

fn handle_get_category(_req: wisp.Request, id: Int) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case supermarket_category.get_category(config, category_id: id) {
        Ok(category) -> {
          json.object([
            #("id", json.int(category.id)),
            #("name", json.string(category.name)),
            #(
              "description",
              helpers.encode_optional_string(category.description),
            ),
          ])
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

fn handle_update_category(req: wisp.Request, id: Int) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_supermarket_category_create_request(body) {
    Ok(request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case
            supermarket_category.update_category(
              config,
              category_id: id,
              category_data: request,
            )
          {
            Ok(category) -> {
              json.object([
                #("id", json.int(category.id)),
                #("name", json.string(category.name)),
                #(
                  "description",
                  helpers.encode_optional_string(category.description),
                ),
              ])
              |> json.to_string
              |> wisp.json_response(200)
            }
            Error(_) -> helpers.error_response(500, "Failed to update category")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

fn handle_delete_category(_req: wisp.Request, id: Int) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case supermarket_category.delete_category(config, id) {
        Ok(Nil) -> wisp.response(204)
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

// =============================================================================
// Recipe JSON Encoding and Decoding
// =============================================================================

fn encode_recipe(recipe: TandoorRecipe) -> json.Json {
  let nutrition_json = case recipe.nutrition {
    option.Some(nutrition) -> encode_nutrition(nutrition)
    option.None -> json.null()
  }

  json.object([
    #("id", json.int(recipe.id)),
    #("name", json.string(recipe.name)),
    #("description", json.string(recipe.description)),
    #("servings", json.int(recipe.servings)),
    #("servings_text", json.string(recipe.servings_text)),
    #("prep_time", json.int(recipe.prep_time)),
    #("cooking_time", json.int(recipe.cooking_time)),
    #("ingredients", json.array(recipe.ingredients, encode_ingredient)),
    #("steps", json.array(recipe.steps, encode_step)),
    #("nutrition", nutrition_json),
    #("keywords", json.array(recipe.keywords, encode_keyword)),
    #("image", helpers.encode_optional_string(recipe.image)),
    #("internal_id", helpers.encode_optional_string(recipe.internal_id)),
    #("created_at", json.string(recipe.created_at)),
    #("updated_at", json.string(recipe.updated_at)),
  ])
}

fn encode_ingredient(ingredient: TandoorIngredient) -> json.Json {
  json.object([
    #("id", json.int(ingredient.id)),
    #(
      "food",
      json.object([
        #("id", json.int(ingredient.food.id)),
        #("name", json.string(ingredient.food.name)),
      ]),
    ),
    #(
      "unit",
      json.object([
        #("id", json.int(ingredient.unit.id)),
        #("name", json.string(ingredient.unit.name)),
        #("abbreviation", json.string(ingredient.unit.abbreviation)),
      ]),
    ),
    #("amount", json.float(ingredient.amount)),
    #("note", json.string(ingredient.note)),
  ])
}

fn encode_step(step: TandoorStep) -> json.Json {
  json.object([
    #("id", json.int(step.id)),
    #("name", json.string(step.name)),
    #("instructions", json.string(step.instructions)),
    #("time", json.int(step.time)),
  ])
}

fn encode_nutrition(nutrition: TandoorNutrition) -> json.Json {
  json.object([
    #("calories", json.float(nutrition.calories)),
    #("carbs", json.float(nutrition.carbs)),
    #("protein", json.float(nutrition.protein)),
    #("fats", json.float(nutrition.fats)),
    #("fiber", json.float(nutrition.fiber)),
    #("sugars", helpers.encode_optional_float(nutrition.sugars)),
    #("sodium", helpers.encode_optional_float(nutrition.sodium)),
  ])
}

fn encode_keyword(keyword: TandoorKeyword) -> json.Json {
  json.object([
    #("id", json.int(keyword.id)),
    #("name", json.string(keyword.name)),
  ])
}

// =============================================================================
// Meal Plan JSON Encoding and Decoding
// =============================================================================

fn encode_meal_plan(meal_plan: MealPlan) -> json.Json {
  let recipe_json = case meal_plan.recipe {
    option.Some(recipe) ->
      json.object([
        #("id", json.int(recipe.id)),
        #("name", json.string(recipe.name)),
      ])
    option.None -> json.null()
  }

  let shared_json = case meal_plan.shared {
    option.Some(users) ->
      json.array(users, fn(user) {
        json.object([
          #("id", json.int(user.id)),
          #("username", json.string(user.username)),
        ])
      })
    option.None -> json.null()
  }

  json.object([
    #("id", json.int(meal_plan.id)),
    #("title", json.string(meal_plan.title)),
    #("recipe", recipe_json),
    #("servings", json.float(meal_plan.servings)),
    #("note", json.string(meal_plan.note)),
    #("note_markdown", json.string(meal_plan.note_markdown)),
    #("from_date", json.string(meal_plan.from_date)),
    #("to_date", json.string(meal_plan.to_date)),
    #("meal_type", json.string(mt_to_string(meal_plan.meal_type))),
    #("created_by", json.int(meal_plan.created_by)),
    #("shared", shared_json),
    #("recipe_name", json.string(meal_plan.recipe_name)),
    #("meal_type_name", json.string(meal_plan.meal_type_name)),
    #("shopping", json.bool(meal_plan.shopping)),
  ])
}

fn encode_meal_plan_entry(entry: MealPlanEntry) -> json.Json {
  json.object([
    #("id", json.int(entry.id)),
    #("title", json.string(entry.title)),
    #("recipe_id", helpers.encode_optional_int(entry.recipe_id)),
    #("recipe_name", json.string(entry.recipe_name)),
    #("servings", json.float(entry.servings)),
    #("from_date", json.string(entry.from_date)),
    #("to_date", json.string(entry.to_date)),
    #("meal_type_id", json.int(entry.meal_type_id)),
    #("meal_type_name", json.string(entry.meal_type_name)),
    #("shopping", json.bool(entry.shopping)),
  ])
}

// =============================================================================
// Ingredient JSON Encoding
// =============================================================================

fn encode_ingredient_detail(ingredient: Ingredient) -> json.Json {
  let food_json = case ingredient.food {
    option.Some(food) ->
      json.object([
        #("id", json.int(food.id)),
        #("name", json.string(food.name)),
        #("plural_name", helpers.encode_optional_string(food.plural_name)),
        #("description", json.string(food.description)),
      ])
    option.None -> json.null()
  }

  let unit_json = case ingredient.unit {
    option.Some(unit) ->
      json.object([
        #("id", json.int(unit.id)),
        #("name", json.string(unit.name)),
        #("plural_name", helpers.encode_optional_string(unit.plural_name)),
      ])
    option.None -> json.null()
  }

  json.object([
    #("id", json.int(ingredient.id)),
    #("food", food_json),
    #("unit", unit_json),
    #("amount", json.float(ingredient.amount)),
    #("note", helpers.encode_optional_string(ingredient.note)),
    #("order", json.int(ingredient.order)),
    #("is_header", json.bool(ingredient.is_header)),
    #("no_amount", json.bool(ingredient.no_amount)),
    #("original_text", helpers.encode_optional_string(ingredient.original_text)),
  ])
}

// =============================================================================
// Import/Export Logs JSON Encoding
// =============================================================================

fn encode_import_log(log: ImportLog) -> json.Json {
  let keyword_json = case log.keyword {
    option.Some(keyword) ->
      json.object([
        #("id", json.int(keyword.id)),
        #("name", json.string(keyword.name)),
      ])
    option.None -> json.null()
  }

  json.object([
    #("id", json.int(log.id)),
    #("import_type", json.string(log.import_type)),
    #("msg", json.string(log.msg)),
    #("running", json.bool(log.running)),
    #("keyword", keyword_json),
    #("total_recipes", json.int(log.total_recipes)),
    #("imported_recipes", json.int(log.imported_recipes)),
    #("created_by", json.int(log.created_by)),
    #("created_at", json.string(log.created_at)),
  ])
}

fn encode_export_log(log: ExportLog) -> json.Json {
  json.object([
    #("id", json.int(log.id)),
    #("export_type", json.string(log.export_type)),
    #("msg", json.string(log.msg)),
    #("running", json.bool(log.running)),
    #("total_recipes", json.int(log.total_recipes)),
    #("exported_recipes", json.int(log.exported_recipes)),
    #("cache_duration", json.int(log.cache_duration)),
    #("possibly_not_expired", json.bool(log.possibly_not_expired)),
    #("created_by", json.int(log.created_by)),
    #("created_at", json.string(log.created_at)),
  ])
}

fn parse_meal_plan_create_request(
  json_data: dynamic.Dynamic,
) -> Result(MealPlanCreate, String) {
  decode.run(json_data, meal_plan_create_decoder())
  |> result.map_error(fn(_) { "Invalid meal plan create request" })
}

fn meal_plan_create_decoder() -> decode.Decoder(MealPlanCreate) {
  use recipe <- decode.field(
    "recipe",
    decode.optional(decode.int |> decode.map(recipe_id_from_int)),
  )
  use recipe_name <- decode.field("recipe_name", decode.string)
  use servings <- decode.field("servings", decode.float)
  use note <- decode.field("note", decode.string)
  use from_date <- decode.field("from_date", decode.string)
  use to_date <- decode.field("to_date", decode.string)
  use meal_type <- decode.field("meal_type", decode.string)
  decode.success(MealPlanCreate(
    recipe: recipe,
    recipe_name: recipe_name,
    servings: servings,
    note: note,
    from_date: from_date,
    to_date: to_date,
    meal_type: mp_meal_type_from_string(meal_type),
  ))
}

fn parse_meal_plan_update_request(
  json_data: dynamic.Dynamic,
) -> Result(MealPlanUpdate, String) {
  decode.run(json_data, meal_plan_update_decoder())
  |> result.map_error(fn(_) { "Invalid meal plan update request" })
}

fn meal_plan_update_decoder() -> decode.Decoder(MealPlanUpdate) {
  use recipe <- decode.field(
    "recipe",
    decode.optional(decode.int |> decode.map(recipe_id_from_int)),
  )
  use recipe_name <- decode.field("recipe_name", decode.string)
  use servings <- decode.field("servings", decode.float)
  use note <- decode.field("note", decode.string)
  use from_date <- decode.field("from_date", decode.string)
  use to_date <- decode.field("to_date", decode.string)
  use meal_type <- decode.field("meal_type", decode.string)
  decode.success(MealPlanUpdate(
    recipe: recipe,
    recipe_name: recipe_name,
    servings: servings,
    note: note,
    from_date: from_date,
    to_date: to_date,
    meal_type: mp_meal_type_from_string(meal_type),
  ))
}

fn parse_recipe_create_request(
  json_data: dynamic.Dynamic,
) -> Result(CreateRecipeRequest, String) {
  decode.run(json_data, recipe_create_decoder())
  |> result.map_error(fn(_) { "Invalid recipe create request" })
}

fn recipe_create_decoder() -> decode.Decoder(CreateRecipeRequest) {
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  use servings <- decode.field("servings", decode.int)
  use servings_text <- decode.field(
    "servings_text",
    decode.optional(decode.string),
  )
  use working_time <- decode.field("working_time", decode.optional(decode.int))
  use waiting_time <- decode.field("waiting_time", decode.optional(decode.int))
  decode.success(CreateRecipeRequest(
    name: name,
    description: description,
    servings: servings,
    servings_text: servings_text,
    working_time: working_time,
    waiting_time: waiting_time,
  ))
}

fn parse_recipe_update_request(
  json_data: dynamic.Dynamic,
) -> Result(recipe_update_type.RecipeUpdate, String) {
  decode.run(json_data, recipe_update_decoder())
  |> result.map_error(fn(_) { "Invalid recipe update request" })
}

fn recipe_update_decoder() -> decode.Decoder(recipe_update_type.RecipeUpdate) {
  use name <- decode.field("name", decode.optional(decode.string))
  use description <- decode.field("description", decode.optional(decode.string))
  use servings <- decode.field("servings", decode.optional(decode.int))
  use servings_text <- decode.field(
    "servings_text",
    decode.optional(decode.string),
  )
  use working_time <- decode.field("working_time", decode.optional(decode.int))
  use waiting_time <- decode.field("waiting_time", decode.optional(decode.int))
  decode.success(recipe_update_type.RecipeUpdate(
    name: name,
    description: description,
    servings: servings,
    servings_text: servings_text,
    working_time: working_time,
    waiting_time: waiting_time,
  ))
}

// =============================================================================
// Step JSON Encoding and Decoding
// =============================================================================

fn encode_recipe_step(step: Step) -> json.Json {
  json.object([
    #("id", json.int(step.id)),
    #("name", json.string(step.name)),
    #("instruction", json.string(step.instruction)),
    #(
      "instruction_markdown",
      helpers.encode_optional_string(step.instruction_markdown),
    ),
    #("ingredients", json.array(step.ingredients, json.int)),
    #("time", json.int(step.time)),
    #("order", json.int(step.order)),
    #("show_as_header", json.bool(step.show_as_header)),
    #("show_ingredients_table", json.bool(step.show_ingredients_table)),
    #("file", helpers.encode_optional_string(step.file)),
  ])
}

fn parse_step_create_request(
  json_data: dynamic.Dynamic,
) -> Result(StepCreateRequest, String) {
  decode.run(json_data, step_create_decoder())
  |> result.map_error(fn(_) { "Invalid step create request" })
}

fn step_create_decoder() -> decode.Decoder(StepCreateRequest) {
  use name <- decode.field("name", decode.string)
  use instruction <- decode.field("instruction", decode.string)
  use ingredients <- decode.field("ingredients", decode.list(decode.int))
  use time <- decode.field("time", decode.int)
  use order <- decode.field("order", decode.int)
  use show_as_header <- decode.field("show_as_header", decode.bool)
  use show_ingredients_table <- decode.field(
    "show_ingredients_table",
    decode.bool,
  )
  use file <- decode.field("file", decode.optional(decode.string))
  decode.success(StepCreateRequest(
    name: name,
    instruction: instruction,
    ingredients: ingredients,
    time: time,
    order: order,
    show_as_header: show_as_header,
    show_ingredients_table: show_ingredients_table,
    file: file,
  ))
}

fn parse_step_update_request(
  json_data: dynamic.Dynamic,
) -> Result(StepUpdateRequest, String) {
  decode.run(json_data, step_update_decoder())
  |> result.map_error(fn(_) { "Invalid step update request" })
}

fn step_update_decoder() -> decode.Decoder(StepUpdateRequest) {
  use name <- decode.field("name", decode.optional(decode.string))
  use instruction <- decode.field("instruction", decode.optional(decode.string))
  use ingredients <- decode.field(
    "ingredients",
    decode.optional(decode.list(decode.int)),
  )
  use time <- decode.field("time", decode.optional(decode.int))
  use order <- decode.field("order", decode.optional(decode.int))
  use show_as_header <- decode.field(
    "show_as_header",
    decode.optional(decode.bool),
  )
  use show_ingredients_table <- decode.field(
    "show_ingredients_table",
    decode.optional(decode.bool),
  )
  use file <- decode.field("file", decode.optional(decode.string))
  decode.success(StepUpdateRequest(
    name: name,
    instruction: instruction,
    ingredients: ingredients,
    time: time,
    order: order,
    show_as_header: show_as_header,
    show_ingredients_table: show_ingredients_table,
    file: file,
  ))
}

// =============================================================================
// Supermarket JSON Decoders
// =============================================================================

fn parse_supermarket_create_request(
  json_data: dynamic.Dynamic,
) -> Result(SupermarketCreateRequest, String) {
  decode.run(json_data, supermarket_create_decoder())
  |> result.map_error(fn(_) { "Invalid supermarket create request" })
}

fn supermarket_create_decoder() -> decode.Decoder(SupermarketCreateRequest) {
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  decode.success(SupermarketCreateRequest(name: name, description: description))
  decode.success(SupermarketCreateRequest(name: name, description: description))
}

fn parse_supermarket_category_create_request(
  json_data: dynamic.Dynamic,
) -> Result(SupermarketCategoryCreateRequest, String) {
  decode.run(json_data, supermarket_category_create_decoder())
  |> result.map_error(fn(_) { "Invalid category create request" })
}

fn supermarket_category_create_decoder() -> decode.Decoder(
  SupermarketCategoryCreateRequest,
) {
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  decode.success(SupermarketCategoryCreateRequest(
    name: name,
    description: description,
  ))
}

fn parse_import_log_create_request(
  json_data: dynamic.Dynamic,
) -> Result(ImportLogCreateRequest, String) {
  decode.run(
    json_data,
    import_log_create_request_decoder.import_log_create_request_decoder(),
  )
  |> result.map(fn(tuple) {
    let #(import_type, msg, keyword) = tuple
    ImportLogCreateRequest(import_type: import_type, msg: msg, keyword: keyword)
  })
  |> result.map_error(fn(_) { "Invalid import log create request" })
}

fn parse_import_log_update_request(
  json_data: dynamic.Dynamic,
) -> Result(ImportLogUpdateRequest, String) {
  decode.run(
    json_data,
    import_log_update_request_decoder.import_log_update_request_decoder(),
  )
  |> result.map(fn(tuple) {
    let #(import_type, msg, running, keyword) = tuple
    ImportLogUpdateRequest(
      import_type: import_type,
      msg: msg,
      running: running,
      keyword: keyword,
    )
  })
  |> result.map_error(fn(_) { "Invalid import log update request" })
}

fn parse_export_log_create_request(
  json_data: dynamic.Dynamic,
) -> Result(ExportLogCreateRequest, String) {
  decode.run(
    json_data,
    export_log_create_request_decoder.export_log_create_request_decoder(),
  )
  |> result.map(fn(tuple) {
    let #(export_type, msg, cache_duration) = tuple
    ExportLogCreateRequest(
      export_type: export_type,
      msg: msg,
      cache_duration: cache_duration,
    )
  })
  |> result.map_error(fn(_) { "Invalid export log create request" })
}

fn parse_export_log_update_request(
  json_data: dynamic.Dynamic,
) -> Result(ExportLogUpdateRequest, String) {
  decode.run(
    json_data,
    export_log_update_request_decoder.export_log_update_request_decoder(),
  )
  |> result.map(fn(tuple) {
    let #(export_type, msg, running, cache_duration) = tuple
    ExportLogUpdateRequest(
      export_type: export_type,
      msg: msg,
      running: running,
      cache_duration: cache_duration,
    )
  })
  |> result.map_error(fn(_) { "Invalid export log update request" })
}
