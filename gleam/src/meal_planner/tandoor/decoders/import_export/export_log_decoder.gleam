/// ExportLog decoder for Tandoor SDK
///
/// This module provides JSON decoders for ExportLog types from the Tandoor API.
/// It follows the gleam/dynamic decode pattern for type-safe JSON parsing.
///
/// The decoder handles:
/// - Required fields (id, type, running, etc.)
/// - Export progress tracking fields
/// - Cache management fields (duration, expiry status)
import gleam/dynamic/decode
import meal_planner/tandoor/types/import_export/export_log.{type ExportLog, ExportLog}

/// Decode an ExportLog from JSON
///
/// This decoder handles all fields of an export log including cache management
/// fields for tracking export file validity.
///
/// Example JSON structure:
/// ```json
/// {
///   "id": 321,
///   "type": "zip",
///   "msg": "Export in progress",
///   "running": true,
///   "total_recipes": 100,
///   "exported_recipes": 45,
///   "cache_duration": 3600,
///   "possibly_not_expired": true,
///   "created_by": 3,
///   "created_at": "2024-12-14T13:00:00Z"
/// }
/// ```
pub fn export_log_decoder() -> decode.Decoder(ExportLog) {
  use id <- decode.field("id", decode.int)
  use export_type <- decode.field("type", decode.string)
  use msg <- decode.field("msg", decode.string)
  use running <- decode.field("running", decode.bool)
  use total_recipes <- decode.field("total_recipes", decode.int)
  use exported_recipes <- decode.field("exported_recipes", decode.int)
  use cache_duration <- decode.field("cache_duration", decode.int)
  use possibly_not_expired <- decode.field("possibly_not_expired", decode.bool)
  use created_by <- decode.field("created_by", decode.int)
  use created_at <- decode.field("created_at", decode.string)

  decode.success(ExportLog(
    id: id,
    export_type: export_type,
    msg: msg,
    running: running,
    total_recipes: total_recipes,
    exported_recipes: exported_recipes,
    cache_duration: cache_duration,
    possibly_not_expired: possibly_not_expired,
    created_by: created_by,
    created_at: created_at,
  ))
}
