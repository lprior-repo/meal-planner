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

import meal_planner/tandoor/api/recipe/create as recipe_create_api
import meal_planner/tandoor/api/recipe/delete as recipe_delete
import meal_planner/tandoor/api/recipe/get as recipe_get
import meal_planner/tandoor/api/recipe/list as recipe_list
import meal_planner/tandoor/api/recipe/update as recipe_update
import meal_planner/tandoor/encoders/recipe/recipe_create_encoder.{
  type CreateRecipeRequest, CreateRecipeRequest,
}
import meal_planner/tandoor/handlers/helpers
import meal_planner/tandoor/types.{
  type TandoorIngredient, type TandoorKeyword, type TandoorNutrition,
  type TandoorRecipe, type TandoorStep,
}
import meal_planner/tandoor/types/recipe/recipe_update as recipe_update_type

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
        recipe_list.list_recipes(
          config,
          limit: option.None,
          offset: option.None,
        )
      {
        Ok(response) -> {
          let results_json =
            json.array(response.results, fn(recipe) { encode_recipe(recipe) })

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
