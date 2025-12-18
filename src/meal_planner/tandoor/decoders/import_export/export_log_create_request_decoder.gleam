/// Decoder for ExportLogCreateRequest from JSON
///
/// This module provides a JSON decoder for export log creation requests.
import gleam/dynamic/decode
import gleam/option

/// Decode JSON to ExportLogCreateRequest fields
/// 
/// Expected JSON structure:
/// ```json
/// {
///   "export_type": "zip",
///   "msg": "Exported 10 recipes",
///   "cache_duration": 3600
/// }
/// ```
pub fn export_log_create_request_decoder() -> decode.Decoder(
  #(String, option.Option(String), option.Option(Int)),
) {
  use export_type <- decode.field("export_type", decode.string)
  use msg <- decode.optional_field(
    "msg",
    option.None,
    decode.optional(decode.string),
  )
  use cache_duration <- decode.optional_field(
    "cache_duration",
    option.None,
    decode.optional(decode.int),
  )
  decode.success(#(export_type, msg, cache_duration))
}
