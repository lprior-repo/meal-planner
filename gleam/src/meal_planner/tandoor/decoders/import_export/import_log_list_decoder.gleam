/// ImportLogList decoder for Tandoor SDK
///
/// This module provides JSON decoders for paginated ImportLog lists
/// from the Tandoor API.
import gleam/dynamic/decode
import meal_planner/tandoor/decoders/import_export/import_log_decoder
import meal_planner/tandoor/types/import_export/import_log_list.{
  type ImportLogList, ImportLogList,
}

/// Decode a paginated ImportLogList from JSON
///
/// Example JSON structure:
/// ```json
/// {
///   "count": 123,
///   "next": "http://localhost:8000/api/import-log/?page=2",
///   "previous": null,
///   "results": [
///     {
///       "id": 1,
///       "type": "nextcloud",
///       "msg": "Import complete",
///       ...
///     }
///   ]
/// }
/// ```
pub fn import_log_list_decoder() -> decode.Decoder(ImportLogList) {
  use count <- decode.field("count", decode.int)
  use next <- decode.field("next", decode.optional(decode.string))
  use previous <- decode.field("previous", decode.optional(decode.string))
  use results <- decode.field(
    "results",
    decode.list(import_log_decoder.import_log_decoder()),
  )

  decode.success(ImportLogList(
    count: count,
    next: next,
    previous: previous,
    results: results,
  ))
}
