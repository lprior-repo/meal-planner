/// Decoder for ImportLogUpdateRequest from JSON
///
/// This module provides a JSON decoder for import log update requests.
import gleam/dynamic/decode
import gleam/option

/// Decode JSON to ImportLogUpdateRequest fields
///
/// Expected JSON structure (all fields optional):
/// ```json
/// {
///   "import_type": "json_recipe",
///   "msg": "Imported 5 recipes",
///   "running": false,
///   "keyword": 42
/// }
/// ```
pub fn import_log_update_request_decoder() -> decode.Decoder(
  #(
    option.Option(String),
    option.Option(String),
    option.Option(Bool),
    option.Option(option.Option(Int)),
  ),
) {
  use import_type <- decode.optional_field(
    "import_type",
    option.None,
    decode.optional(decode.string),
  )
  use msg <- decode.optional_field(
    "msg",
    option.None,
    decode.optional(decode.string),
  )
  use running <- decode.optional_field(
    "running",
    option.None,
    decode.optional(decode.bool),
  )
  use keyword <- decode.optional_field(
    "keyword",
    option.None,
    decode.optional(decode.optional(decode.int)),
  )
  decode.success(#(import_type, msg, running, keyword))
}
