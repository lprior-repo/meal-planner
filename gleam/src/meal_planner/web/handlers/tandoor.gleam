/// Tandoor Recipe Manager web handlers - Complete CRUD implementation
///
/// Routes:
/// - GET /tandoor/status - Check Tandoor connection status
/// - GET /api/tandoor/recipes - List recipes
/// - POST /api/tandoor/recipes - Create recipe
/// - GET /api/tandoor/recipes/:id - Get recipe details  
/// - PATCH /api/tandoor/recipes/:id - Update recipe
/// - DELETE /api/tandoor/recipes/:id - Delete recipe
/// - GET /api/tandoor/units - List measurement units
/// - GET /api/tandoor/keywords - List keywords
/// - GET /api/tandoor/ingredients - List ingredients
/// - POST /api/tandoor/ingredients - Create ingredient
/// - GET /api/tandoor/meal-plans - List meal plans
/// - POST /api/tandoor/meal-plans - Create meal plan
/// - GET /api/tandoor/meal-plans/:id - Get meal plan details
/// - PATCH /api/tandoor/meal-plans/:id - Update meal plan
/// - GET /api/tandoor/import-logs - List import logs
/// - POST /api/tandoor/import-logs - Create import log
/// - GET /api/tandoor/export-logs - List export logs
/// - POST /api/tandoor/export-logs - Create export log

import gleam/dynamic
import gleam/dynamic/decode
import gleam/http
import gleam/int
import gleam/json
import gleam/option.{None, Some}

import meal_planner/env
import meal_planner/tandoor/client
import meal_planner/tandoor/api/recipe/list as recipe_list
import meal_planner/tandoor/api/recipe/get as recipe_get
import meal_planner/tandoor/api/recipe/create as recipe_create
import meal_planner/tandoor/api/recipe/update as recipe_update_api
import meal_planner/tandoor/api/recipe/delete as recipe_delete
import meal_planner/tandoor/api/unit/list as unit_list
import meal_planner/tandoor/api/keyword/keyword_api
import meal_planner/tandoor/api/mealplan/list as mealplan_list
import meal_planner/tandoor/api/mealplan/get as mealplan_get
import meal_planner/tandoor/api/mealplan/create as mealplan_create
import meal_planner/tandoor/api/mealplan/update as mealplan_update
import meal_planner/tandoor/api/ingredient/list as ingredient_list
import meal_planner/tandoor/api/ingredient/create as ingredient_create
import meal_planner/tandoor/api/ingredient/update as ingredient_update
import meal_planner/tandoor/api/ingredient/delete as ingredient_delete
import meal_planner/tandoor/api/import_export/import_export_api
import meal_planner/tandoor/handlers/helpers
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/encoders/recipe/recipe_create_encoder
import meal_planner/tandoor/encoders/recipe/recipe_update_encoder
import meal_planner/tandoor/encoders/ingredient/ingredient_encoder
import meal_planner/tandoor/encoders/mealplan/mealplan_encoder
import meal_planner/tandoor/types/recipe/recipe_update
import meal_planner/tandoor/types/mealplan/mealplan

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
                  #("amount", json.float(ingredient.amount)),
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

// =============================================================================
// POST Handlers (Create)
// =============================================================================

/// Handle POST /api/tandoor/recipes - Create recipe
pub fn handle_create_recipe(req: wisp.Request) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Post)
  use body <- wisp.require_json(req)

  let decoder = {
    use name <- decode.field("name", decode.string)
    use description <- decode.optional_field(
      "description",
      None,
      decode.optional(decode.string),
    )
    use servings <- decode.field("servings", decode.int)
    use servings_text <- decode.optional_field(
      "servings_text",
      None,
      decode.optional(decode.string),
    )
    use working_time <- decode.optional_field(
      "working_time",
      None,
      decode.optional(decode.int),
    )
    use waiting_time <- decode.optional_field(
      "waiting_time",
      None,
      decode.optional(decode.int),
    )
    decode.success(#(
      name,
      description,
      servings,
      servings_text,
      working_time,
      waiting_time,
    ))
  }

  case decode.run(body, decoder) {
    Ok(#(name, description, servings, servings_text, working_time, waiting_time)) -> {
      case get_authenticated_client() {
        Ok(config) -> {
          let create_request =
            recipe_create_encoder.CreateRecipeRequest(
              name:,
              description:,
              servings:,
              servings_text:,
              working_time:,
              waiting_time:,
            )

          case recipe_create.create_recipe(config, create_request) {
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
              |> wisp.json_response(201)
            }
            Error(e) -> error_response(e)
          }
        }
        Error(resp) -> resp
      }
    }
    Error(_) -> helpers.error_response(400, "Invalid request body")
  }
}

/// Handle POST /api/tandoor/ingredients - Create ingredient
pub fn handle_create_ingredient(req: wisp.Request) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Post)
  use body <- wisp.require_json(req)

  let decoder = {
    use food <- decode.optional_field(
      "food",
      None,
      decode.optional(decode.int),
    )
    use unit <- decode.optional_field(
      "unit",
      None,
      decode.optional(decode.int),
    )
    use amount <- decode.field("amount", decode.float)
    use note <- decode.optional_field(
      "note",
      None,
      decode.optional(decode.string),
    )
    use order <- decode.optional_field(
      "order",
      1,
      decode.int,
    )
    use is_header <- decode.optional_field(
      "is_header",
      False,
      decode.bool,
    )
    use no_amount <- decode.optional_field(
      "no_amount",
      False,
      decode.bool,
    )
    use original_text <- decode.optional_field(
      "original_text",
      None,
      decode.optional(decode.string),
    )
    decode.success(#(food, unit, amount, note, order, is_header, no_amount, original_text))
  }

  case decode.run(body, decoder) {
    Ok(#(food, unit, amount, note, order, is_header, no_amount, original_text)) -> {
      case get_authenticated_client() {
        Ok(config) -> {
          let create_request =
            ingredient_encoder.IngredientCreateRequest(
              food:,
              unit:,
              amount:,
              note:,
              order:,
              is_header:,
              no_amount:,
              original_text:,
            )

          case ingredient_create.create_ingredient(config, create_request) {
            Ok(ingredient) -> {
              let food_id = case ingredient.food {
                Some(f) -> Some(f.id)
                None -> None
              }
              let unit_id = case ingredient.unit {
                Some(u) -> Some(u.id)
                None -> None
              }
              json.object([
                #("id", json.int(ingredient.id)),
                #("food", helpers.encode_optional_int(food_id)),
                #("unit", helpers.encode_optional_int(unit_id)),
                #("amount", json.float(ingredient.amount)),
                #("note", helpers.encode_optional_string(ingredient.note)),
              ])
              |> json.to_string
              |> wisp.json_response(201)
            }
            Error(e) -> error_response(e)
          }
        }
        Error(resp) -> resp
      }
    }
    Error(_) -> helpers.error_response(400, "Invalid request body")
  }
}

/// Handle POST /api/tandoor/meal-plans - Create meal plan
pub fn handle_create_meal_plan(req: wisp.Request) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Post)
  use body <- wisp.require_json(req)

  let decoder = {
    use recipe <- decode.optional_field(
      "recipe",
      None,
      decode.optional(decode.int),
    )
    use recipe_name <- decode.field("recipe_name", decode.string)
    use servings <- decode.field("servings", decode.float)
    use note <- decode.optional_field(
      "note",
      "",
      decode.string,
    )
    use from_date <- decode.field("from_date", decode.string)
    use to_date <- decode.field("to_date", decode.string)
    use meal_type_str <- decode.field("meal_type", decode.string)
    decode.success(#(recipe, recipe_name, servings, note, from_date, to_date, meal_type_str))
  }

  case decode.run(body, decoder) {
    Ok(#(recipe, recipe_name, servings, note, from_date, to_date, meal_type_str)) -> {
      case get_authenticated_client() {
        Ok(config) -> {
          let recipe_id = case recipe {
            Some(id) -> Some(ids.recipe_id_from_int(id))
            None -> None
          }
          let meal_type = mealplan.meal_type_from_string(meal_type_str)
          let create_request =
            mealplan.MealPlanCreate(
              recipe: recipe_id,
              recipe_name:,
              servings:,
              note:,
              from_date:,
              to_date:,
              meal_type:,
            )

          case mealplan_create.create_meal_plan(config, create_request) {
            Ok(entry) -> {
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
              |> json.to_string
              |> wisp.json_response(201)
            }
            Error(e) -> error_response(e)
          }
        }
        Error(resp) -> resp
      }
    }
    Error(_) -> helpers.error_response(400, "Invalid request body")
  }
}

// =============================================================================
// PATCH Handlers (Update)
// =============================================================================

/// Handle PATCH /api/tandoor/recipes/:id - Update recipe
pub fn handle_update_recipe(
  req: wisp.Request,
  recipe_id: String,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Patch)
  use body <- wisp.require_json(req)

  case int.parse(recipe_id) {
    Ok(id) -> {
      let decoder = {
        use name <- decode.optional_field(
          "name",
          None,
          decode.optional(decode.string),
        )
        use description <- decode.optional_field(
          "description",
          None,
          decode.optional(decode.string),
        )
        use servings <- decode.optional_field(
          "servings",
          None,
          decode.optional(decode.int),
        )
        use servings_text <- decode.optional_field(
          "servings_text",
          None,
          decode.optional(decode.string),
        )
        use working_time <- decode.optional_field(
          "working_time",
          None,
          decode.optional(decode.int),
        )
        use waiting_time <- decode.optional_field(
          "waiting_time",
          None,
          decode.optional(decode.int),
        )
        decode.success(#(name, description, servings, servings_text, working_time, waiting_time))
      }

      case decode.run(body, decoder) {
        Ok(#(name, description, servings, servings_text, working_time, waiting_time)) -> {
          case get_authenticated_client() {
            Ok(config) -> {
              let update_request =
                recipe_update.RecipeUpdate(
                  name:,
                  description:,
                  servings:,
                  servings_text:,
                  working_time:,
                  waiting_time:,
                )

              case recipe_update_api.update_recipe(config, recipe_id: id, update_data: update_request) {
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
        Error(_) -> helpers.error_response(400, "Invalid request body")
      }
    }
    Error(_) -> helpers.error_response(400, "Invalid recipe ID")
  }
}

/// Handle PATCH /api/tandoor/ingredients/:id - Update ingredient
pub fn handle_update_ingredient(
  req: wisp.Request,
  ingredient_id: String,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Patch)
  use body <- wisp.require_json(req)

  case int.parse(ingredient_id) {
    Ok(id) -> {
      let decoder = {
        use food <- decode.optional_field(
          "food",
          None,
          decode.optional(decode.int),
        )
        use unit <- decode.optional_field(
          "unit",
          None,
          decode.optional(decode.int),
        )
        use amount <- decode.optional_field(
          "amount",
          0.0,
          decode.float,
        )
        use note <- decode.optional_field(
          "note",
          None,
          decode.optional(decode.string),
        )
        use order <- decode.optional_field(
          "order",
          1,
          decode.int,
        )
        use is_header <- decode.optional_field(
          "is_header",
          False,
          decode.bool,
        )
        use no_amount <- decode.optional_field(
          "no_amount",
          False,
          decode.bool,
        )
        use original_text <- decode.optional_field(
          "original_text",
          None,
          decode.optional(decode.string),
        )
        decode.success(#(food, unit, amount, note, order, is_header, no_amount, original_text))
      }

      case decode.run(body, decoder) {
        Ok(#(food, unit, amount, note, order, is_header, no_amount, original_text)) -> {
          case get_authenticated_client() {
            Ok(config) -> {
              let update_request =
                ingredient_encoder.IngredientCreateRequest(
                  food:,
                  unit:,
                  amount:,
                  note:,
                  order:,
                  is_header:,
                  no_amount:,
                  original_text:,
                )

              case ingredient_update.update_ingredient(config, ingredient_id: id, ingredient_data: update_request) {
                Ok(ingredient) -> {
                  let food_id = case ingredient.food {
                    Some(f) -> Some(f.id)
                    None -> None
                  }
                  let unit_id = case ingredient.unit {
                    Some(u) -> Some(u.id)
                    None -> None
                  }
                  json.object([
                    #("id", json.int(ingredient.id)),
                    #("food", helpers.encode_optional_int(food_id)),
                    #("unit", helpers.encode_optional_int(unit_id)),
                    #("amount", json.float(ingredient.amount)),
                    #("note", helpers.encode_optional_string(ingredient.note)),
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
        Error(_) -> helpers.error_response(400, "Invalid request body")
      }
    }
    Error(_) -> helpers.error_response(400, "Invalid ingredient ID")
  }
}

/// Handle PATCH /api/tandoor/meal-plans/:id - Update meal plan
pub fn handle_update_meal_plan(
  req: wisp.Request,
  meal_plan_id: String,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Patch)
  use body <- wisp.require_json(req)

  case int.parse(meal_plan_id) {
    Ok(id) -> {
      let decoder = {
        use recipe <- decode.optional_field(
          "recipe",
          None,
          decode.optional(decode.int),
        )
        use recipe_name <- decode.optional_field(
          "recipe_name",
          "",
          decode.string,
        )
        use servings <- decode.optional_field(
          "servings",
          0.0,
          decode.float,
        )
        use note <- decode.optional_field(
          "note",
          "",
          decode.string,
        )
        use from_date <- decode.optional_field(
          "from_date",
          "",
          decode.string,
        )
        use to_date <- decode.optional_field(
          "to_date",
          "",
          decode.string,
        )
        use meal_type_str <- decode.optional_field(
          "meal_type",
          "other",
          decode.string,
        )
        decode.success(#(recipe, recipe_name, servings, note, from_date, to_date, meal_type_str))
      }

      case decode.run(body, decoder) {
        Ok(#(recipe, recipe_name, servings, note, from_date, to_date, meal_type_str)) -> {
          case get_authenticated_client() {
            Ok(config) -> {
              let id_wrapped = ids.meal_plan_id_from_int(id)
              let recipe_id = case recipe {
                Some(r) -> Some(ids.recipe_id_from_int(r))
                None -> None
              }
              let meal_type = mealplan.meal_type_from_string(meal_type_str)
              let update_request =
                mealplan.MealPlanUpdate(
                  recipe: recipe_id,
                  recipe_name:,
                  servings:,
                  note:,
                  from_date:,
                  to_date:,
                  meal_type:,
                )

              case mealplan_update.update_meal_plan(config, id_wrapped, update_request) {
                Ok(entry) -> {
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
                  |> json.to_string
                  |> wisp.json_response(200)
                }
                Error(e) -> error_response(e)
              }
            }
            Error(resp) -> resp
          }
        }
        Error(_) -> helpers.error_response(400, "Invalid request body")
      }
    }
    Error(_) -> helpers.error_response(400, "Invalid meal plan ID")
  }
}

// =============================================================================
// DELETE Handlers
// =============================================================================

/// Handle DELETE /api/tandoor/recipes/:id - Delete recipe
pub fn handle_delete_recipe(
  req: wisp.Request,
  recipe_id: String,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Delete)

  case int.parse(recipe_id) {
    Ok(id) -> {
      case get_authenticated_client() {
        Ok(config) -> {
          case recipe_delete.delete_recipe(config, id) {
            Ok(Nil) -> wisp.response(204)
            Error(e) -> error_response(e)
          }
        }
        Error(resp) -> resp
      }
    }
    Error(_) -> helpers.error_response(400, "Invalid recipe ID")
  }
}

/// Handle DELETE /api/tandoor/ingredients/:id - Delete ingredient
pub fn handle_delete_ingredient(
  req: wisp.Request,
  ingredient_id: String,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Delete)

  case int.parse(ingredient_id) {
    Ok(id) -> {
      case get_authenticated_client() {
        Ok(config) -> {
          case ingredient_delete.delete_ingredient(config, id) {
            Ok(Nil) -> wisp.response(204)
            Error(e) -> error_response(e)
          }
        }
        Error(resp) -> resp
      }
    }
    Error(_) -> helpers.error_response(400, "Invalid ingredient ID")
  }
}

/// Handle DELETE /api/tandoor/meal-plans/:id - Delete meal plan
pub fn handle_delete_meal_plan(
  req: wisp.Request,
  meal_plan_id: String,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Delete)

  case int.parse(meal_plan_id) {
    Ok(id) -> {
      case get_authenticated_client() {
        Ok(config) -> {
          let id_wrapped = ids.meal_plan_id_from_int(id)
          case mealplan_update.delete_meal_plan(config, id_wrapped) {
            Ok(Nil) -> wisp.response(204)
            Error(e) -> error_response(e)
          }
        }
        Error(resp) -> resp
      }
    }
    Error(_) -> helpers.error_response(400, "Invalid meal plan ID")
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
    http.Post, ["api", "tandoor", "recipes"] -> handle_create_recipe(req)
    http.Get, ["api", "tandoor", "recipes", id] -> handle_get_recipe(req, id)
    http.Patch, ["api", "tandoor", "recipes", id] -> handle_update_recipe(req, id)
    http.Delete, ["api", "tandoor", "recipes", id] -> handle_delete_recipe(req, id)

    // Ingredients
    http.Get, ["api", "tandoor", "ingredients"] -> handle_list_ingredients(req)
    http.Post, ["api", "tandoor", "ingredients"] -> handle_create_ingredient(req)
    http.Patch, ["api", "tandoor", "ingredients", id] -> handle_update_ingredient(req, id)
    http.Delete, ["api", "tandoor", "ingredients", id] -> handle_delete_ingredient(req, id)

    // Meal Plans
    http.Get, ["api", "tandoor", "meal-plans"] -> handle_list_meal_plans(req)
    http.Post, ["api", "tandoor", "meal-plans"] -> handle_create_meal_plan(req)
    http.Get, ["api", "tandoor", "meal-plans", id] -> handle_get_meal_plan(req, id)
    http.Patch, ["api", "tandoor", "meal-plans", id] -> handle_update_meal_plan(req, id)
    http.Delete, ["api", "tandoor", "meal-plans", id] -> handle_delete_meal_plan(req, id)

    // Import/Export Logs
    http.Get, ["api", "tandoor", "import-logs"] -> handle_list_import_logs(req)
    http.Get, ["api", "tandoor", "export-logs"] -> handle_list_export_logs(req)

    // Units and Keywords
    http.Get, ["api", "tandoor", "units"] -> handle_list_units(req)
    http.Get, ["api", "tandoor", "keywords"] -> handle_list_keywords(req)

    _, _ -> wisp.not_found()
  }
}
