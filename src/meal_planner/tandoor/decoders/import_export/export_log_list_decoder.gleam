/// ExportLogList decoder for Tandoor SDK
///
/// This module provides JSON decoders for paginated ExportLog lists
/// from the Tandoor API.
import gleam/dynamic/decode
import meal_planner/tandoor/decoders/import_export/export_log_decoder
import meal_planner/tandoor/types/import_export/export_log_list.{
  type ExportLogList, ExportLogList,
}

/// Decode a paginated ExportLogList from JSON
///
/// Example JSON structure:
/// ```json
/// {
///   "count": 45,
///   "next": null,
///   "previous": "http://localhost:8000/api/export-log/?page=1",
///   "results": [
///     {
///       "id": 1,
///       "type": "zip",
///       "msg": "Export ready",
///       ...
///     }
///   ]
/// }
/// ```
pub fn export_log_list_decoder() -> decode.Decoder(ExportLogList) {
  use count <- decode.field("count", decode.int)
  use next <- decode.field("next", decode.optional(decode.string))
  use previous <- decode.field("previous", decode.optional(decode.string))
  use results <- decode.field(
    "results",
    decode.list(export_log_decoder.export_log_decoder()),
  )

  decode.success(ExportLogList(
    count: count,
    next: next,
    previous: previous,
    results: results,
  ))
}
