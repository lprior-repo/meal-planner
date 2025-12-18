/// Decoder for ExportLogUpdateRequest from JSON
///
/// This module provides a JSON decoder for export log update requests.
import gleam/dynamic/decode
import gleam/option

/// Decode JSON to ExportLogUpdateRequest fields
///
/// Expected JSON structure (all fields optional):
/// ```json
/// {
///   "export_type": "zip",
///   "msg": "Exported 10 recipes",
///   "running": false,
///   "cache_duration": 3600
/// }
/// ```
pub fn export_log_update_request_decoder() -> decode.Decoder(
  #(
    option.Option(String),
    option.Option(String),
    option.Option(Bool),
    option.Option(Int),
  ),
) {
  use export_type <- decode.optional_field(
    "export_type",
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
  use cache_duration <- decode.optional_field(
    "cache_duration",
    option.None,
    decode.optional(decode.int),
  )
  decode.success(#(export_type, msg, running, cache_duration))
}
