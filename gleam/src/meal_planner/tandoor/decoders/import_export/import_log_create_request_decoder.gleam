/// Decoder for ImportLogCreateRequest from JSON
///
/// This module provides a JSON decoder for import log creation requests.
import gleam/dynamic/decode
import gleam/option

/// Decode JSON to ImportLogCreateRequest fields
/// 
/// Expected JSON structure:
/// ```json
/// {
///   "import_type": "json_recipe",
///   "msg": "Imported 5 recipes",
///   "keyword": 42
/// }
/// ```
pub fn import_log_create_request_decoder() -> decode.Decoder(
  #(String, option.Option(String), option.Option(Int)),
) {
  use import_type <- decode.field("import_type", decode.string)
  use msg <- decode.optional_field(
    "msg",
    option.None,
    decode.optional(decode.string),
  )
  use keyword <- decode.optional_field(
    "keyword",
    option.None,
    decode.optional(decode.int),
  )
  decode.success(#(import_type, msg, keyword))
}
