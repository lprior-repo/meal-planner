/// ImportLog decoder for Tandoor SDK
///
/// This module provides JSON decoders for ImportLog types from the Tandoor API.
/// It follows the gleam/dynamic decode pattern for type-safe JSON parsing.
///
/// The decoder handles:
/// - Required fields (id, type, running, etc.)
/// - Optional keyword field (nested Keyword object)
/// - Import progress tracking fields
import gleam/dynamic/decode
import meal_planner/tandoor/types/import_export/import_log.{type ImportLog, ImportLog}
import meal_planner/tandoor/decoders/keyword/keyword_decoder

/// Decode an ImportLog from JSON
///
/// This decoder handles all fields of an import log including the optional
/// nested keyword object for tagging imported recipes.
///
/// Example JSON structure:
/// ```json
/// {
///   "id": 123,
///   "type": "nextcloud",
///   "msg": "Import in progress",
///   "running": true,
///   "keyword": {
///     "id": 5,
///     "name": "italian",
///     "label": "Italian",
///     "description": "Italian recipes",
///     "icon": null,
///     "parent": null,
///     "numchild": 0,
///     "created_at": "2024-01-01T00:00:00Z",
///     "updated_at": "2024-01-01T00:00:00Z",
///     "full_name": "Italian"
///   },
///   "total_recipes": 50,
///   "imported_recipes": 25,
///   "created_by": 1,
///   "created_at": "2024-12-14T12:00:00Z"
/// }
/// ```
pub fn import_log_decoder() -> decode.Decoder(ImportLog) {
  use id <- decode.field("id", decode.int)
  use import_type <- decode.field("type", decode.string)
  use msg <- decode.field("msg", decode.string)
  use running <- decode.field("running", decode.bool)
  use keyword <- decode.field(
    "keyword",
    decode.optional(keyword_decoder.keyword_decoder()),
  )
  use total_recipes <- decode.field("total_recipes", decode.int)
  use imported_recipes <- decode.field("imported_recipes", decode.int)
  use created_by <- decode.field("created_by", decode.int)
  use created_at <- decode.field("created_at", decode.string)

  decode.success(ImportLog(
    id: id,
    import_type: import_type,
    msg: msg,
    running: running,
    keyword: keyword,
    total_recipes: total_recipes,
    imported_recipes: imported_recipes,
    created_by: created_by,
    created_at: created_at,
  ))
}
