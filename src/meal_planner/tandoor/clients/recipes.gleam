import gleam/dynamic
import gleam/dynamic/decode
import gleam/httpc
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string
import meal_planner/logger
import meal_planner/tandoor/types/base.{
  type ApiResponse, type ClientConfig, type TandoorError, ParseError,
}
import meal_planner/tandoor/clients/request_builder
import meal_planner/tandoor/clients/response as response_utils
import meal_planner/tandoor/recipe as recipe_mod

pub type Recipe = recipe_mod.Recipe
pub type RecipeDetail = recipe_mod.RecipeDetail
pub type CreateRecipeRequest = recipe_mod.RecipeCreateRequest

pub type RecipeListResponse {
  RecipeListResponse(
    count: Int,
    next: Option(String),
    previous: Option(String),
    results: List(Recipe),
  )
}

fn execute_and_parse(
  req: httpc.Request(String),
) -> Result(ApiResponse, TandoorError) {
  use resp <- result.try(httpc.send(req))
  response_utils.parse_response(resp)
}

fn decode_json(
  body: String,
  decoder: decode.Decoder(a),
  context: String,
) -> Result(a, TandoorError) {
  case json.parse(body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, decoder) {
        Ok(value) -> Ok(value)
        Error(errors) -> Error(ParseError(format_decode_errors(context, errors)))
      }
    }
    Error(_) -> Error(ParseError(context <> " invalid JSON response"))
  }
}

fn recipe_list_decoder() -> decode.Decoder(RecipeListResponse) {
  use count <- decode.field("count", decode.int)
  use next <- decode.field("next", decode.optional(decode.string))
  use previous <- decode.field("previous", decode.optional(decode.string))
  use results <- decode.field("results", recipe_mod.recipe_decoder())

  decode.success(RecipeListResponse(
    count: count,
    next: next,
    previous: previous,
    results: results,
  ))
}

fn format_decode_errors(context: String, errors: List(decode.DecodeError)) -> String {
  let parts =
    list.map(errors, fn(error) {
      case error {
        decode.DecodeError(expected, _found, path) ->
          expected <> " at " <> string.join(path, ".")
      }
    })

  context <> " decode failed: " <> string.join(parts, ", ")
}

pub fn recipe_decoder(json_value: dynamic.Dynamic) -> Result(Recipe, String) {
  decode.run(json_value, recipe_mod.recipe_decoder())
  |> result.map_error(fn(errors) {
    "Failed to decode recipe: "
    <> string.join(
      list.map(errors, fn(e) {
        case e {
          decode.DecodeError(expected, _found, path) ->
            expected <> " at " <> string.join(path, ".")
        }
      }),
      ", ",
    )
  })
}

pub fn recipe_detail_decoder(
  json_value: dynamic.Dynamic,
) -> Result(RecipeDetail, String) {
  decode.run(json_value, recipe_mod.recipe_detail_decoder())
  |> result.map_error(fn(errors) {
    "Failed to decode recipe detail: "
    <> string.join(
      list.map(errors, fn(e) {
        case e {
          decode.DecodeError(expected, _found, path) ->
            expected <> " at " <> string.join(path, ".")
        }
      }),
      ", ",
    )
  })
}

pub fn get_recipes(
  config: ClientConfig,
  limit: Option(Int),
  offset: Option(Int),
) -> Result(RecipeListResponse, TandoorError) {
  let limit_val = option.unwrap(limit, 100)
  let offset_val = option.unwrap(offset, 0)

  let query_params = [
    #("limit", int.to_string(limit_val)),
    #("offset", int.to_string(offset_val)),
  ]

  use req <- result.try(
    request_builder.build_get_request(config, "/api/recipe/", query_params),
  )
  logger.debug("Tandoor GET /api/recipe/")

  use resp <- result.try(execute_and_parse(req))
  decode_json(resp.body, recipe_list_decoder(), "recipe list")
}

pub fn get_recipe_by_id(
  config: ClientConfig,
  recipe_id: Int,
) -> Result(Recipe, TandoorError) {
  let path = "/api/recipe/" <> int.to_string(recipe_id) <> "/"

  use req <- result.try(request_builder.build_get_request(config, path, []))
  logger.debug("Tandoor GET " <> path)

  use resp <- result.try(execute_and_parse(req))
  decode_json(resp.body, recipe_mod.recipe_decoder(), "recipe")
}

pub fn get_recipe_detail(
  config: ClientConfig,
  recipe_id: Int,
) -> Result(RecipeDetail, TandoorError) {
  let path = "/api/recipe/" <> int.to_string(recipe_id) <> "/"

  use req <- result.try(request_builder.build_get_request(config, path, []))
  logger.debug("Tandoor GET (detail) " <> path)

  use resp <- result.try(execute_and_parse(req))
  decode_json(resp.body, recipe_mod.recipe_detail_decoder(), "recipe detail")
}

pub fn create_recipe(
  config: ClientConfig,
  recipe_request: CreateRecipeRequest,
) -> Result(Recipe, TandoorError) {
  let body = recipe_mod.encode_recipe_create_request(recipe_request)
  |> json.to_string

  use req <- result.try(request_builder.build_post_request(
    config,
    "/api/recipe/",
    body,
  ))
  logger.debug("Tandoor POST /api/recipe/")

  use resp <- result.try(execute_and_parse(req))
  decode_json(resp.body, recipe_mod.recipe_decoder(), "created recipe")
}

pub fn delete_recipe(
  config: ClientConfig,
  recipe_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/recipe/" <> int.to_string(recipe_id) <> "/"

  use req <- result.try(request_builder.build_delete_request(config, path))
  logger.debug("Tandoor DELETE " <> path)

  use _resp <- result.try(execute_and_parse(req))
  Ok(Nil)
}

pub fn test_connection(config: ClientConfig) -> Result(Bool, TandoorError) {
  use req <- result.try(
    request_builder.build_get_request(config, "/api/recipe/", [#("limit", "1")]),
  )
  logger.debug("Tandoor connection test")

  case execute_and_parse(req) {
    Ok(_) -> Ok(True)
    Error(e) -> Error(e)
  }
}
