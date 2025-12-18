/// Tandoor Steps Handler
///
/// Handles CRUD operations for recipe steps in Tandoor
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http
import gleam/int
import gleam/json
import gleam/option
import gleam/result

import meal_planner/tandoor/api/step/create as step_create_api
import meal_planner/tandoor/api/step/delete as step_delete
import meal_planner/tandoor/api/step/get as step_get
import meal_planner/tandoor/api/step/list as step_list
import meal_planner/tandoor/api/step/update as step_update
import meal_planner/tandoor/encoders/recipe/step_encoder.{
  type StepCreateRequest, type StepUpdateRequest, StepCreateRequest,
  StepUpdateRequest,
}
import meal_planner/tandoor/handlers/helpers
import meal_planner/tandoor/types/recipe/step.{type Step}

import wisp

// =============================================================================
// Steps Collection Handler
// =============================================================================

pub fn handle_steps_collection(req: wisp.Request) -> wisp.Response {
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

pub fn handle_step_by_id(req: wisp.Request, step_id: String) -> wisp.Response {
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
