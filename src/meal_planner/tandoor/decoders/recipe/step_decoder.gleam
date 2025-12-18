/// Step Decoder
///
/// Decodes Tandoor API Step JSON responses into Step types.
/// Supports both simple step data and full step details with all optional fields.
import gleam/dynamic/decode
import gleam/option
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/types/recipe/step.{type Step, Step}

/// Decode a Step from JSON
///
/// Handles all Step fields including optional fields:
/// - instruction_markdown (read-only)
/// - ingredients list
/// - file attachment
///
/// # Example JSON
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
  use id <- decode.field("id", ids.step_id_decoder())
  use name <- decode.field("name", decode.string)
  use instruction <- decode.field("instruction", decode.string)
  use instruction_markdown <- decode.field(
    "instruction_markdown",
    decode.optional(decode.string),
  )
  use ingredients <- decode.field(
    "ingredients",
    decode.list(ids.ingredient_id_decoder()),
  )
  use time <- decode.field("time", decode.int)
  use order <- decode.field("order", decode.int)
  use show_as_header <- decode.field("show_as_header", decode.bool)
  use show_ingredients_table <- decode.field(
    "show_ingredients_table",
    decode.bool,
  )
  use file <- decode.field("file", decode.optional(decode.string))

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
  ))
}

/// Decode a simple Step from JSON (simplified format)
///
/// Supports the old TandoorStep format with minimal fields.
/// Used for backwards compatibility with existing recipe decoders.
///
/// # Example JSON
/// ```json
/// {
///   "id": 123,
///   "name": "Prepare",
///   "instructions": "Chop vegetables",
///   "time": 15
/// }
/// ```
pub fn simple_step_decoder() -> decode.Decoder(Step) {
  use id <- decode.field("id", ids.step_id_decoder())
  use name <- decode.field("name", decode.string)
  use instructions <- decode.field("instructions", decode.string)
  use time <- decode.field("time", decode.int)

  // Map to full Step with default values
  decode.success(Step(
    id: id,
    name: name,
    instruction: instructions,
    instruction_markdown: option.None,
    ingredients: [],
    time: time,
    order: 0,
    show_as_header: False,
    show_ingredients_table: False,
    file: option.None,
  ))
}
