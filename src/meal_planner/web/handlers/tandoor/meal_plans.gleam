/// Meal Plans handlers for Tandoor Recipe Manager
///
/// This module handles HTTP requests for meal plans endpoints:
/// - GET /api/tandoor/meal-plans - List meal plans
/// - POST /api/tandoor/meal-plans - Create meal plan
/// - GET /api/tandoor/meal-plans/:id - Get meal plan by ID
/// - PATCH /api/tandoor/meal-plans/:id - Update meal plan
/// - DELETE /api/tandoor/meal-plans/:id - Delete meal plan
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http
import gleam/int
import gleam/json
import gleam/option
import gleam/result
import meal_planner/tandoor/handlers/helpers
import meal_planner/tandoor/mealplan.{
  type MealPlan, type MealPlanCreateRequest, type MealPlanEntry,
  type MealPlanUpdateRequest, MealPlanCreateRequest, MealPlanUpdateRequest,
  create_meal_plan, delete_meal_plan, encode_meal_plan, get_meal_plan,
  list_meal_plans, meal_type_to_string, update_meal_plan,
}
import wisp

// =============================================================================
// Meal Plans Collection Handler
// =============================================================================

/// Handle GET and POST /api/tandoor/meal-plans
pub fn handle_meal_plans_collection(req: wisp.Request) -> wisp.Response {
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
        list_meal_plans(config, from_date: option.None, to_date: option.None)
      {
        Ok(response) -> {
          let results_json =
            json.array(response.results, fn(meal_plan) {
              encode_meal_plan(meal_plan)
            })

          helpers.paginated_response(
            results_json,
            response.count,
            response.next,
            response.previous,
          )
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
          case create_meal_plan(config, request) {
            Ok(meal_plan) -> {
              encode_meal_plan(meal_plan)
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

/// Handle GET, PATCH, and DELETE /api/tandoor/meal-plans/:id
pub fn handle_meal_plan_by_id(
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
      case get_meal_plan(config, meal_plan_id: id) {
        Ok(meal_plan) -> {
          encode_meal_plan(meal_plan)
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
          case update_meal_plan(config, meal_plan_id: id, data: request) {
            Ok(meal_plan) -> {
              encode_meal_plan(meal_plan)
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
      case delete_meal_plan(config, meal_plan_id: id) {
        Ok(Nil) -> wisp.response(204)
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

// =============================================================================
// Meal Plan JSON Encoding
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
    #("meal_type", json.string(meal_type_to_string(meal_plan.meal_type))),
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
// Request Parsing
// =============================================================================

fn parse_meal_plan_create_request(
  json_data: dynamic.Dynamic,
) -> Result(MealPlanCreateRequest, String) {
  decode.run(json_data, meal_plan_create_decoder())
  |> result.map_error(fn(_) { "Invalid meal plan create request" })
}

fn meal_plan_create_decoder() -> decode.Decoder(MealPlanCreateRequest) {
  use recipe <- decode.field("recipe", decode.optional(decode.int))
  use title <- decode.field("title", decode.string)
  use servings <- decode.field("servings", decode.float)
  use note <- decode.field("note", decode.string)
  use from_date <- decode.field("from_date", decode.string)
  use to_date <- decode.field("to_date", decode.string)
  use meal_type <- decode.field("meal_type", decode.int)
  decode.success(MealPlanCreateRequest(
    recipe: recipe,
    title: title,
    servings: servings,
    note: note,
    from_date: from_date,
    to_date: to_date,
    meal_type: meal_type,
  ))
}

fn parse_meal_plan_update_request(
  json_data: dynamic.Dynamic,
) -> Result(MealPlanUpdateRequest, String) {
  decode.run(json_data, meal_plan_update_decoder())
  |> result.map_error(fn(_) { "Invalid meal plan update request" })
}

fn meal_plan_update_decoder() -> decode.Decoder(MealPlanUpdateRequest) {
  use recipe <- decode.field(
    "recipe",
    decode.optional(decode.optional(decode.int)),
  )
  use title <- decode.field("title", decode.optional(decode.string))
  use servings <- decode.field("servings", decode.optional(decode.float))
  use note <- decode.field("note", decode.optional(decode.string))
  use from_date <- decode.field("from_date", decode.optional(decode.string))
  use to_date <- decode.field("to_date", decode.optional(decode.string))
  use meal_type <- decode.field("meal_type", decode.optional(decode.int))
  decode.success(MealPlanUpdateRequest(
    recipe: recipe,
    title: title,
    servings: servings,
    note: note,
    from_date: from_date,
    to_date: to_date,
    meal_type: meal_type,
  ))
}
