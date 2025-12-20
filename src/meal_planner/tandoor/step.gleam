/// Tandoor Step Module
///
/// Provides the Step type for recipe cooking instructions, along with JSON
/// encoding/decoding and CRUD API operations.
///
/// Steps represent individual cooking instructions within a recipe, including
/// timing, ingredient references, and optional files/attachments.
///
/// Based on Tandoor API 2.3.6 specification.
import gleam/dynamic/decode
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import meal_planner/tandoor/api/crud_helpers.{
  execute_delete, execute_get, execute_patch, execute_post, parse_json_paginated,
  parse_json_single,
}
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/core/http.{type PaginatedResponse}
import meal_planner/tandoor/core/ids.{
  type IngredientId, type StepId, ingredient_id_to_int, step_id_decoder,
  step_id_to_int,
}
import meal_planner/tandoor/ingredient.{
  type Ingredient, encode_ingredient, ingredient_decoder,
}
import meal_planner/tandoor/recipe.{type Recipe, recipe_decoder}

// ============================================================================
// Types
// ============================================================================

/// A single step in a recipe's instructions
///
/// Represents a cooking step with instructions, timing, and optional
/// ingredients and files. Steps can be marked as headers for organization.
///
/// Fields:
/// - id: Unique identifier for the step
/// - name: Short name/title for the step (max 128 chars)
/// - instruction: Full instruction text (plaintext)
/// - instruction_markdown: Optional markdown-formatted instructions (readonly)
/// - ingredients: List of ingredient IDs used in this step
/// - time: Time required in minutes
/// - order: Display order in the recipe (lower = earlier)
/// - show_as_header: If true, display as section header
/// - show_ingredients_table: If true, show ingredient table for this step
/// - file: Optional attached file (image, video, etc.)
pub type Step {
  Step(
    id: StepId,
    name: String,
    instruction: String,
    instruction_markdown: Option(String),
    ingredients: List(Ingredient),
    time: Int,
    order: Int,
    show_as_header: Bool,
    show_ingredients_table: Bool,
    file: Option(String),
    step_recipe: Option(Int),
    step_recipe_data: Option(Recipe),
    numrecipe: Int,
  )
}

/// Request to create a new step
///
/// Matches the Tandoor API /api/step/ POST endpoint expectations.
/// The instruction_markdown field is read-only and not included in creation.
pub type StepCreateRequest {
  StepCreateRequest(
    name: String,
    instruction: String,
    ingredients: List(IngredientId),
    time: Int,
    order: Int,
    show_as_header: Bool,
    show_ingredients_table: Bool,
    file: Option(String),
  )
}

/// Request to update an existing step
///
/// Matches the Tandoor API /api/step/{id}/ PATCH endpoint expectations.
/// All fields are optional to support partial updates.
pub type StepUpdateRequest {
  StepUpdateRequest(
    name: Option(String),
    instruction: Option(String),
    ingredients: Option(List(IngredientId)),
    time: Option(Int),
    order: Option(Int),
    show_as_header: Option(Bool),
    show_ingredients_table: Option(Bool),
    file: Option(String),
  )
}

// ============================================================================
// Decoder
// ============================================================================

/// Decode a Step from JSON
///
/// Handles all Step fields including optional fields:
/// - instruction_markdown (read-only)
/// - ingredients list
/// - file attachment
///
/// Example JSON structure:
/// ```json
/// {
///   "id": 123,
///   "name": "Prepare ingredients",
///   "instruction": "Chop all vegetables finely",
///   "instruction_markdown": "**Chop** all vegetables finely",
///   "ingredients": [1, 2, 3],
///   "time": 15,
///   "order": 0,
///   "show_as_header": false,
///   "show_ingredients_table": true,
///   "file": null
/// }
/// ```
pub fn step_decoder() -> decode.Decoder(Step) {
  use id <- decode.field("id", step_id_decoder())
  use name <- decode.field("name", decode.string)
  use instruction <- decode.field("instruction", decode.string)
  use instruction_markdown <- decode.field(
    "instruction_markdown",
    decode.optional(decode.string),
  )
  use ingredients <- decode.field(
    "ingredients",
    decode.list(ingredient_decoder()),
  )
  use time <- decode.field("time", decode.int)
  use order <- decode.field("order", decode.int)
  use show_as_header <- decode.field("show_as_header", decode.bool)
  use show_ingredients_table <- decode.field(
    "show_ingredients_table",
    decode.bool,
  )
  use file <- decode.field("file", decode.optional(decode.string))
  use step_recipe <- decode.field("step_recipe", decode.optional(decode.int))
  use step_recipe_data <- decode.field(
    "step_recipe_data",
    decode.optional(recipe_decoder()),
  )
  use numrecipe <- decode.field("numrecipe", decode.int)

  decode.success(Step(
    id: id,
    name: name,
    instruction: instruction,
    instruction_markdown: instruction_markdown,
    ingredients: ingredients,
    time: time,
    order: order,
    show_as_header: show_as_header,
    show_ingredients_table: show_ingredients_table,
    file: file,
    step_recipe: step_recipe,
    step_recipe_data: step_recipe_data,
    numrecipe: numrecipe,
  ))
}

/// Decode a simple Step from JSON (simplified format)
///
/// Supports the old TandoorStep format with minimal fields.
/// Used for backwards compatibility with existing recipe decoders.
///
/// Example JSON structure:
/// ```json
/// {
///   "id": 123,
///   "name": "Prepare",
///   "instructions": "Chop vegetables",
///   "time": 15
/// }
/// ```
pub fn simple_step_decoder() -> decode.Decoder(Step) {
  use id <- decode.field("id", step_id_decoder())
  use name <- decode.field("name", decode.string)
  use instructions <- decode.field("instructions", decode.string)
  use time <- decode.field("time", decode.int)

  // Map to full Step with default values
  decode.success(Step(
    id: id,
    name: name,
    instruction: instructions,
    instruction_markdown: None,
    ingredients: [],
    time: time,
    order: 0,
    show_as_header: False,
    show_ingredients_table: False,
    file: None,
    step_recipe: None,
    step_recipe_data: None,
    numrecipe: 0,
  ))
}

// ============================================================================
// Encoders
// ============================================================================

/// Encode a complete Step to JSON
///
/// This includes all fields for GET responses and complete representations.
pub fn encode_step(step: Step) -> Json {
  json.object([
    #("id", json.int(step_id_to_int(step.id))),
    #("name", json.string(step.name)),
    #("instruction", json.string(step.instruction)),
    #("instruction_markdown", case step.instruction_markdown {
      Some(md) -> json.string(md)
      None -> json.null()
    }),
    #(
      "ingredients",
      json.array(step.ingredients, fn(ingredient) {
        encode_ingredient(ingredient)
      }),
    ),
    #("time", json.int(step.time)),
    #("order", json.int(step.order)),
    #("show_as_header", json.bool(step.show_as_header)),
    #("show_ingredients_table", json.bool(step.show_ingredients_table)),
    #("file", case step.file {
      Some(f) -> json.string(f)
      None -> json.null()
    }),
    #("step_recipe", case step.step_recipe {
      Some(sr) -> json.int(sr)
      None -> json.null()
    }),
    #("step_recipe_data", case step.step_recipe_data {
      Some(_data) -> json.null()
      None -> json.null()
    }),
    #("numrecipe", json.int(step.numrecipe)),
  ])
}

/// Encode a StepCreateRequest to JSON
///
/// Only includes writable fields for POST requests.
///
/// Example:
/// ```gleam
/// let step = StepCreateRequest(
///   name: "Prepare ingredients",
///   instruction: "Chop all vegetables finely and set aside",
///   ingredients: [1, 2, 3],
///   time: 15,
///   order: 0,
///   show_as_header: False,
///   show_ingredients_table: True,
///   file: None
/// )
/// let encoded = encode_step_create_request(step)
/// ```
pub fn encode_step_create_request(step: StepCreateRequest) -> Json {
  json.object([
    #("name", json.string(step.name)),
    #("instruction", json.string(step.instruction)),
    #(
      "ingredients",
      json.array(step.ingredients, fn(id) { json.int(ingredient_id_to_int(id)) }),
    ),
    #("time", json.int(step.time)),
    #("order", json.int(step.order)),
    #("show_as_header", json.bool(step.show_as_header)),
    #("show_ingredients_table", json.bool(step.show_ingredients_table)),
    #("file", case step.file {
      Some(f) -> json.string(f)
      None -> json.null()
    }),
  ])
}

/// Encode a StepUpdateRequest to JSON
///
/// Only includes fields that are Some(), allowing partial updates.
///
/// Example:
/// ```gleam
/// let update = StepUpdateRequest(
///   name: Some("Prepare ingredients carefully"),
///   instruction: None,
///   ingredients: None,
///   time: Some(20),
///   order: None,
///   show_as_header: None,
///   show_ingredients_table: None,
///   file: None
/// )
/// let encoded = encode_step_update_request(update)
/// ```
pub fn encode_step_update_request(step: StepUpdateRequest) -> Json {
  let name_field = case step.name {
    Some(name) -> [#("name", json.string(name))]
    None -> []
  }

  let instruction_field = case step.instruction {
    Some(inst) -> [#("instruction", json.string(inst))]
    None -> []
  }

  let ingredients_field = case step.ingredients {
    Some(ings) -> [
      #(
        "ingredients",
        json.array(ings, fn(id) { json.int(ingredient_id_to_int(id)) }),
      ),
    ]
    None -> []
  }

  let time_field = case step.time {
    Some(t) -> [#("time", json.int(t))]
    None -> []
  }

  let order_field = case step.order {
    Some(o) -> [#("order", json.int(o))]
    None -> []
  }

  let show_as_header_field = case step.show_as_header {
    Some(h) -> [#("show_as_header", json.bool(h))]
    None -> []
  }

  let show_ingredients_table_field = case step.show_ingredients_table {
    Some(t) -> [#("show_ingredients_table", json.bool(t))]
    None -> []
  }

  let file_field = case step.file {
    Some(f) -> [#("file", json.string(f))]
    None -> []
  }

  json.object(
    list.flatten([
      name_field,
      instruction_field,
      ingredients_field,
      time_field,
      order_field,
      show_as_header_field,
      show_ingredients_table_field,
      file_field,
    ]),
  )
}

// ============================================================================
// API - CRUD Operations
// ============================================================================

/// List steps from Tandoor API with pagination
///
/// Returns a paginated response containing steps.
pub fn list_steps(
  config: ClientConfig,
  limit limit: Option(Int),
  page page: Option(Int),
) -> Result(PaginatedResponse(Step), TandoorError) {
  // Build query parameters
  let params = case limit, page {
    Some(l), Some(p) -> [
      #("page_size", int.to_string(l)),
      #("page", int.to_string(p)),
    ]
    Some(l), None -> [#("page_size", int.to_string(l))]
    None, Some(p) -> [#("page", int.to_string(p))]
    None, None -> []
  }

  use resp <- result.try(execute_get(config, "/api/step/", params))
  parse_json_paginated(resp, step_decoder())
}

/// Get a single step by ID
pub fn get_step(
  config: ClientConfig,
  step_id step_id: Int,
) -> Result(Step, TandoorError) {
  let path = "/api/step/" <> int.to_string(step_id) <> "/"
  use resp <- result.try(execute_get(config, path, []))
  parse_json_single(resp, step_decoder())
}

/// Create a new step in Tandoor
pub fn create_step(
  config: ClientConfig,
  create_data: StepCreateRequest,
) -> Result(Step, TandoorError) {
  let body =
    encode_step_create_request(create_data)
    |> json.to_string
  use resp <- result.try(execute_post(config, "/api/step/", body))
  parse_json_single(resp, step_decoder())
}

/// Update an existing step (supports partial updates)
pub fn update_step(
  config: ClientConfig,
  step_id step_id: Int,
  data update_data: StepUpdateRequest,
) -> Result(Step, TandoorError) {
  let path = "/api/step/" <> int.to_string(step_id) <> "/"
  let body =
    encode_step_update_request(update_data)
    |> json.to_string
  use resp <- result.try(execute_patch(config, path, body))
  parse_json_single(resp, step_decoder())
}

/// Replace an existing step (full update)
///
/// Note: Uses PATCH internally as PUT is not directly supported by generic_crud.
/// For full replacement semantics, PATCH with all fields is equivalent.
pub fn replace_step(
  config: ClientConfig,
  step_id step_id: Int,
  data replace_data: StepCreateRequest,
) -> Result(Step, TandoorError) {
  let path = "/api/step/" <> int.to_string(step_id) <> "/"
  let body =
    encode_step_create_request(replace_data)
    |> json.to_string
  use resp <- result.try(execute_patch(config, path, body))
  parse_json_single(resp, step_decoder())
}

/// Delete a step from Tandoor
pub fn delete_step(
  config: ClientConfig,
  step_id step_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/step/" <> int.to_string(step_id) <> "/"
  use _resp <- result.try(execute_delete(config, path))
  Ok(Nil)
}
