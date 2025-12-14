/// Step encoder for Tandoor SDK
///
/// This module provides JSON encoders for Step create/update types for the Tandoor API.
/// It follows the gleam/json encoding pattern for type-safe JSON serialization.
///
/// The encoders handle:
/// - Required fields (always encoded)
/// - Optional fields (null for None values)
/// - Clean, minimal JSON output matching Tandoor API expectations
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option}

// ============================================================================
// Step Create/Update Request Types
// ============================================================================

/// Request to create a new step
///
/// Matches the Tandoor API /api/step/ POST endpoint expectations.
/// The `instruction_markdown` field is read-only and not included in creation.
pub type StepCreateRequest {
  StepCreateRequest(
    name: String,
    // Short step name/title (max 128 chars)
    instruction: String,
    // Full instruction text (plaintext)
    ingredients: List(Int),
    // List of ingredient IDs used in this step
    time: Int,
    // Time required in minutes
    order: Int,
    // Display order in recipe (lower = earlier)
    show_as_header: Bool,
    // Display as section header
    show_ingredients_table: Bool,
    // Show ingredient table for this step
    file: Option(String),
    // Optional attached file URL
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
    ingredients: Option(List(Int)),
    time: Option(Int),
    order: Option(Int),
    show_as_header: Option(Bool),
    show_ingredients_table: Option(Bool),
    file: Option(String),
  )
}

// ============================================================================
// Step Create Encoder
// ============================================================================

/// Encode a StepCreateRequest to JSON
///
/// This encoder creates JSON for step creation requests.
/// It includes all required fields and properly handles optional fields.
///
/// # Example
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
/// let encoded = encode_step_create(step)
/// json.to_string(encoded)
/// ```
///
/// # Arguments
/// * `step` - The step create request to encode
///
/// # Returns
/// JSON representation of the step create request
pub fn encode_step_create(step: StepCreateRequest) -> Json {
  json.object([
    #("name", json.string(step.name)),
    #("instruction", json.string(step.instruction)),
    #("ingredients", json.array(step.ingredients, json.int)),
    #("time", json.int(step.time)),
    #("order", json.int(step.order)),
    #("show_as_header", json.bool(step.show_as_header)),
    #("show_ingredients_table", json.bool(step.show_ingredients_table)),
    #("file", encode_optional_string(step.file)),
  ])
}

// ============================================================================
// Step Update Encoder
// ============================================================================

/// Encode a StepUpdateRequest to JSON
///
/// This encoder creates JSON for step update requests (PATCH).
/// It only includes fields that are Some(), allowing partial updates.
///
/// # Example
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
/// let encoded = encode_step_update(update)
/// json.to_string(encoded)
/// ```
///
/// # Arguments
/// * `step` - The step update request to encode
///
/// # Returns
/// JSON representation of the step update request with only modified fields
pub fn encode_step_update(step: StepUpdateRequest) -> Json {
  let fields =
    []
    |> add_optional_field("name", step.name, encode_optional_string)
    |> add_optional_field(
      "instruction",
      step.instruction,
      encode_optional_string,
    )
    |> add_optional_field(
      "ingredients",
      step.ingredients,
      encode_optional_int_list,
    )
    |> add_optional_field("time", step.time, encode_optional_int)
    |> add_optional_field("order", step.order, encode_optional_int)
    |> add_optional_field(
      "show_as_header",
      step.show_as_header,
      encode_optional_bool,
    )
    |> add_optional_field(
      "show_ingredients_table",
      step.show_ingredients_table,
      encode_optional_bool,
    )
    |> add_optional_field("file", step.file, encode_optional_string)
    |> list.reverse

  json.object(fields)
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Encode optional integer field (None becomes null)
fn encode_optional_int(value: Option(Int)) -> Json {
  case value {
    option.Some(v) -> json.int(v)
    option.None -> json.null()
  }
}

/// Encode optional string field (None becomes null)
fn encode_optional_string(value: Option(String)) -> Json {
  case value {
    option.Some(v) -> json.string(v)
    option.None -> json.null()
  }
}

/// Encode optional boolean field (None becomes null)
fn encode_optional_bool(value: Option(Bool)) -> Json {
  case value {
    option.Some(v) -> json.bool(v)
    option.None -> json.null()
  }
}

/// Encode optional integer list field (None becomes null)
fn encode_optional_int_list(value: Option(List(Int))) -> Json {
  case value {
    option.Some(v) -> json.array(v, json.int)
    option.None -> json.null()
  }
}

/// Add optional field to object fields list (only if Some)
fn add_optional_field(
  fields: List(#(String, Json)),
  key: String,
  value: Option(a),
  encoder: fn(Option(a)) -> Json,
) -> List(#(String, Json)) {
  case value {
    option.Some(_) -> [#(key, encoder(value)), ..fields]
    option.None -> fields
  }
}
