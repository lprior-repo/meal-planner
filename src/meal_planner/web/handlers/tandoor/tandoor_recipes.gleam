/// Tandoor Recipe handlers
///
/// This module provides HTTP handler functions for Tandoor recipe operations:
/// - Listing recipes
/// - Creating recipes
/// - Getting a recipe by ID
/// - Updating recipes
/// - Deleting recipes
/// - JSON encoding/decoding for recipes
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http
import gleam/int
import gleam/json
import gleam/option
import gleam/result

import meal_planner/tandoor/client.{
  type Keyword, type NutritionInfo, type Step,
}
import meal_planner/tandoor/handlers/helpers
import meal_planner/tandoor/recipe.{
  type Recipe, type RecipeDetail, type RecipeCreateRequest, type RecipeUpdate,
  RecipeCreateRequest, RecipeUpdate,
  list_recipes, get_recipe, create_recipe, update_recipe, delete_recipe,
}

import wisp

// =============================================================================
// Recipe Collection Handler
// =============================================================================

pub fn handle_recipes_collection(req: wisp.Request) -> wisp.Response {
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
        list_recipes(
          config,
          limit: option.None,
          offset: option.None,
        )
      {
        Ok(response) -> {
          let results_json =
            json.array(response.results, fn(r) { encode_recipe_simple(r) })

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

fn handle_create_recipe(req: wisp.Request) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_recipe_create_request(body) {
    Ok(request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case create_recipe(config, request) {
            Ok(r) -> {
              encode_recipe_detail(r)
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

pub fn handle_recipe_by_id(
  req: wisp.Request,
  recipe_id: String,
) -> wisp.Response {
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
      case get_recipe(config, recipe_id: id) {
        Ok(r) -> {
          encode_recipe_detail(r)
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
            update_recipe(
              config,
              recipe_id: id,
              data: request,
            )
          {
            Ok(r) -> {
              encode_recipe_detail(r)
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
      case delete_recipe(config, recipe_id: id) {
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

/// Encode a simple Recipe (for list responses)
fn encode_recipe_simple(recipe: Recipe) -> json.Json {
  json.object([
    #("id", json.int(recipe.id)),
    #("name", json.string(recipe.name)),
    #("slug", helpers.encode_optional_string(recipe.slug)),
    #("description", helpers.encode_optional_string(recipe.description)),
    #("servings", json.int(recipe.servings)),
    #("servings_text", helpers.encode_optional_string(recipe.servings_text)),
    #("working_time", helpers.encode_optional_int(recipe.working_time)),
    #("waiting_time", helpers.encode_optional_int(recipe.waiting_time)),
    #("created_at", helpers.encode_optional_string(recipe.created_at)),
    #("updated_at", helpers.encode_optional_string(recipe.updated_at)),
  ])
}

/// Encode a detailed RecipeDetail (for single recipe responses)
fn encode_recipe_detail(recipe: RecipeDetail) -> json.Json {
  let nutrition_json = case recipe.nutrition {
    option.Some(n) -> encode_nutrition(n)
    option.None -> json.null()
  }

  json.object([
    #("id", json.int(recipe.id)),
    #("name", json.string(recipe.name)),
    #("slug", helpers.encode_optional_string(recipe.slug)),
    #("description", helpers.encode_optional_string(recipe.description)),
    #("servings", json.int(recipe.servings)),
    #("servings_text", helpers.encode_optional_string(recipe.servings_text)),
    #("working_time", helpers.encode_optional_int(recipe.working_time)),
    #("waiting_time", helpers.encode_optional_int(recipe.waiting_time)),
    #("created_at", helpers.encode_optional_string(recipe.created_at)),
    #("updated_at", helpers.encode_optional_string(recipe.updated_at)),
    #("steps", json.array(recipe.steps, encode_step)),
    #("nutrition", nutrition_json),
    #("keywords", json.array(recipe.keywords, encode_keyword)),
    #("source_url", helpers.encode_optional_string(recipe.source_url)),
  ])
}

fn encode_step(step: Step) -> json.Json {
  json.object([
    #("id", json.int(step.id)),
    #("name", json.string(step.name)),
    #("instruction", json.string(step.instruction)),
    #("time", json.int(step.time)),
    #("order", json.int(step.order)),
  ])
}

fn encode_nutrition(nutrition: NutritionInfo) -> json.Json {
  json.object([
    #("id", json.int(nutrition.id)),
    #("calories", json.float(nutrition.calories)),
    #("carbs", json.float(nutrition.carbohydrates)),
    #("protein", json.float(nutrition.proteins)),
    #("fats", json.float(nutrition.fats)),
    #("source", json.string(nutrition.source)),
  ])
}

fn encode_keyword(keyword: Keyword) -> json.Json {
  json.object([
    #("id", json.int(keyword.id)),
    #("name", json.string(keyword.name)),
  ])
}

fn parse_recipe_create_request(
  json_data: dynamic.Dynamic,
) -> Result(RecipeCreateRequest, String) {
  decode.run(json_data, recipe_create_decoder())
  |> result.map_error(fn(_) { "Invalid recipe create request" })
}

fn recipe_create_decoder() -> decode.Decoder(RecipeCreateRequest) {
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  use servings <- decode.field("servings", decode.int)
  use servings_text <- decode.field(
    "servings_text",
    decode.optional(decode.string),
  )
  use working_time <- decode.field("working_time", decode.optional(decode.int))
  use waiting_time <- decode.field("waiting_time", decode.optional(decode.int))
  decode.success(RecipeCreateRequest(
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
) -> Result(RecipeUpdate, String) {
  decode.run(json_data, recipe_update_decoder())
  |> result.map_error(fn(_) { "Invalid recipe update request" })
}

fn recipe_update_decoder() -> decode.Decoder(RecipeUpdate) {
  use name <- decode.field("name", decode.optional(decode.string))
  use description <- decode.field("description", decode.optional(decode.string))
  use servings <- decode.field("servings", decode.optional(decode.int))
  use servings_text <- decode.field(
    "servings_text",
    decode.optional(decode.string),
  )
  use working_time <- decode.field("working_time", decode.optional(decode.int))
  use waiting_time <- decode.field("waiting_time", decode.optional(decode.int))
  decode.success(RecipeUpdate(
    name: name,
    description: description,
    servings: servings,
    servings_text: servings_text,
    working_time: working_time,
    waiting_time: waiting_time,
  ))
}
