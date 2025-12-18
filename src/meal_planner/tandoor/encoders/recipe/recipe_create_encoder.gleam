/// Recipe Create Encoder
///
/// This module provides JSON encoding for creating new recipes in the Tandoor API.
import gleam/json
import gleam/option.{type Option}

/// Request structure for creating a new recipe
pub type CreateRecipeRequest {
  CreateRecipeRequest(
    name: String,
    description: Option(String),
    servings: Int,
    servings_text: Option(String),
    working_time: Option(Int),
    waiting_time: Option(Int),
  )
}

/// Encode a CreateRecipeRequest to JSON string
///
/// Tandoor API requires steps array with at least one empty step.
pub fn encode_create_recipe(request: CreateRecipeRequest) -> json.Json {
  let working_time_json = case request.working_time {
    option.Some(val) -> json.int(val)
    option.None -> json.int(0)
  }

  let waiting_time_json = case request.waiting_time {
    option.Some(val) -> json.int(val)
    option.None -> json.int(0)
  }

  let description_json = case request.description {
    option.Some(val) -> json.string(val)
    option.None -> json.null()
  }

  let servings_text_json = case request.servings_text {
    option.Some(val) -> json.string(val)
    option.None -> json.null()
  }

  // Tandoor requires steps with ingredients array
  let empty_step =
    json.object([
      #("instruction", json.string("")),
      #("ingredients", json.array([], json.object)),
    ])

  json.object([
    #("name", json.string(request.name)),
    #("description", description_json),
    #("servings", json.int(request.servings)),
    #("servings_text", servings_text_json),
    #("working_time", working_time_json),
    #("waiting_time", waiting_time_json),
    #("steps", json.array([empty_step], fn(x) { x })),
  ])
}
