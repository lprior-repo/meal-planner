/// Tandoor Import/Export Module
///
/// Provides types for tracking recipe import and export operations, along with
/// JSON encoding/decoding and API operations.
///
/// Import logs track recipe imports from various sources (Nextcloud, PDF, URLs)
/// with progress information and keyword tagging.
///
/// Export logs track recipe exports to various formats (ZIP, PDF, JSON) with
/// caching and progress tracking.
///
/// Based on Tandoor API 2.3.6 specification.
import gleam/dynamic/decode
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import meal_planner/tandoor/api/crud_helpers.{
  execute_delete, execute_get, execute_patch, execute_post, parse_json_list,
  parse_json_single,
}
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/keyword.{type Keyword}

// ============================================================================
// Types
// ============================================================================

/// Import log tracking the status of a recipe import operation
///
/// Fields:
/// - id: Unique identifier for this import log
/// - import_type: Type of import (e.g., "nextcloud", "pdf", "url")
/// - msg: Status message or error description
/// - running: Whether the import is currently in progress
/// - keyword: Optional keyword to tag imported recipes with
/// - total_recipes: Total number of recipes to import
/// - imported_recipes: Number of recipes successfully imported so far
/// - created_by: ID of the user who initiated the import
/// - created_at: ISO 8601 timestamp when import was created
pub type ImportLog {
  ImportLog(
    id: Int,
    import_type: String,
    msg: String,
    running: Bool,
    keyword: Option(Keyword),
    total_recipes: Int,
    imported_recipes: Int,
    created_by: Int,
    created_at: String,
  )
}

/// Export log tracking the status of a recipe export operation
///
/// Fields:
/// - id: Unique identifier for this export log
/// - export_type: Type of export (e.g., "zip", "pdf", "json")
/// - msg: Status message or error description
/// - running: Whether the export is currently in progress
/// - total_recipes: Total number of recipes to export
/// - exported_recipes: Number of recipes successfully exported so far
/// - cache_duration: How long the export is cached (in seconds)
/// - possibly_not_expired: Whether the cached export might still be valid
/// - created_by: ID of the user who initiated the export
/// - created_at: ISO 8601 timestamp when export was created
pub type ExportLog {
  ExportLog(
    id: Int,
    export_type: String,
    msg: String,
    running: Bool,
    total_recipes: Int,
    exported_recipes: Int,
    cache_duration: Int,
    possibly_not_expired: Bool,
    created_by: Int,
    created_at: String,
  )
}

/// Paginated list of import logs from Tandoor API
///
/// Fields:
/// - count: Total number of import logs across all pages
/// - next: URL for the next page of results (None if last page)
/// - previous: URL for the previous page of results (None if first page)
/// - results: List of import logs on this page
pub type ImportLogList {
  ImportLogList(
    count: Int,
    next: Option(String),
    previous: Option(String),
    results: List(ImportLog),
  )
}

/// Paginated list of export logs from Tandoor API
///
/// Fields:
/// - count: Total number of export logs across all pages
/// - next: URL for the next page of results (None if last page)
/// - previous: URL for the previous page of results (None if first page)
/// - results: List of export logs on this page
pub type ExportLogList {
  ExportLogList(
    count: Int,
    next: Option(String),
    previous: Option(String),
    results: List(ExportLog),
  )
}

/// Request to create a new import log in Tandoor
///
/// Only includes writable fields (excludes readonly fields like id, created_at, etc.)
pub type ImportLogCreateRequest {
  ImportLogCreateRequest(
    import_type: String,
    msg: Option(String),
    keyword: Option(Int),
  )
}

/// Request to update an existing import log in Tandoor
///
/// All fields are optional to support partial updates
pub type ImportLogUpdateRequest {
  ImportLogUpdateRequest(
    import_type: Option(String),
    msg: Option(String),
    running: Option(Bool),
    keyword: Option(Option(Int)),
  )
}

/// Request to create a new export log in Tandoor
///
/// Only includes writable fields (excludes readonly fields like id, created_at, etc.)
pub type ExportLogCreateRequest {
  ExportLogCreateRequest(
    export_type: String,
    msg: Option(String),
    cache_duration: Option(Int),
  )
}

/// Request to update an existing export log in Tandoor
///
/// All fields are optional to support partial updates
pub type ExportLogUpdateRequest {
  ExportLogUpdateRequest(
    export_type: Option(String),
    msg: Option(String),
    running: Option(Bool),
    cache_duration: Option(Int),
  )
}

// ============================================================================
// Decoders
// ============================================================================

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
    decode.optional(keyword.keyword_decoder()),
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
  use results <- decode.field("results", decode.list(import_log_decoder()))

  decode.success(ImportLogList(
    count: count,
    next: next,
    previous: previous,
    results: results,
  ))
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
  use results <- decode.field("results", decode.list(export_log_decoder()))

  decode.success(ExportLogList(
    count: count,
    next: next,
    previous: previous,
    results: results,
  ))
}

/// Decode an ImportLogCreateRequest from JSON
///
/// Expected JSON structure:
/// ```json
/// {
///   "type": "json_recipe",
///   "msg": "Imported 5 recipes",
///   "keyword": 42
/// }
/// ```
pub fn import_log_create_request_decoder() -> decode.Decoder(
  ImportLogCreateRequest,
) {
  use import_type <- decode.field("type", decode.string)
  use msg <- decode.optional_field("msg", None, decode.optional(decode.string))
  use keyword <- decode.optional_field(
    "keyword",
    None,
    decode.optional(decode.int),
  )

  decode.success(ImportLogCreateRequest(
    import_type: import_type,
    msg: msg,
    keyword: keyword,
  ))
}

/// Decode an ImportLogUpdateRequest from JSON
///
/// Expected JSON structure (all fields optional):
/// ```json
/// {
///   "type": "json_recipe",
///   "msg": "Imported 5 recipes",
///   "running": false,
///   "keyword": 42
/// }
/// ```
pub fn import_log_update_request_decoder() -> decode.Decoder(
  ImportLogUpdateRequest,
) {
  use import_type <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  use msg <- decode.optional_field("msg", None, decode.optional(decode.string))
  use running <- decode.optional_field(
    "running",
    None,
    decode.optional(decode.bool),
  )
  use keyword <- decode.optional_field(
    "keyword",
    None,
    decode.optional(decode.optional(decode.int)),
  )

  decode.success(ImportLogUpdateRequest(
    import_type: import_type,
    msg: msg,
    running: running,
    keyword: keyword,
  ))
}

/// Decode an ExportLogCreateRequest from JSON
///
/// Expected JSON structure:
/// ```json
/// {
///   "type": "zip",
///   "msg": "Exported 10 recipes",
///   "cache_duration": 3600
/// }
/// ```
pub fn export_log_create_request_decoder() -> decode.Decoder(
  ExportLogCreateRequest,
) {
  use export_type <- decode.field("type", decode.string)
  use msg <- decode.optional_field("msg", None, decode.optional(decode.string))
  use cache_duration <- decode.optional_field(
    "cache_duration",
    None,
    decode.optional(decode.int),
  )

  decode.success(ExportLogCreateRequest(
    export_type: export_type,
    msg: msg,
    cache_duration: cache_duration,
  ))
}

/// Decode an ExportLogUpdateRequest from JSON
///
/// Expected JSON structure (all fields optional):
/// ```json
/// {
///   "type": "zip",
///   "msg": "Exported 10 recipes",
///   "running": false,
///   "cache_duration": 3600
/// }
/// ```
pub fn export_log_update_request_decoder() -> decode.Decoder(
  ExportLogUpdateRequest,
) {
  use export_type <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  use msg <- decode.optional_field("msg", None, decode.optional(decode.string))
  use running <- decode.optional_field(
    "running",
    None,
    decode.optional(decode.bool),
  )
  use cache_duration <- decode.optional_field(
    "cache_duration",
    None,
    decode.optional(decode.int),
  )

  decode.success(ExportLogUpdateRequest(
    export_type: export_type,
    msg: msg,
    running: running,
    cache_duration: cache_duration,
  ))
}

// ============================================================================
// Encoders
// ============================================================================

/// Encode a complete ImportLog to JSON
///
/// This includes all fields for GET responses and complete representations.
pub fn encode_import_log(log: ImportLog) -> Json {
  json.object([
    #("id", json.int(log.id)),
    #("type", json.string(log.import_type)),
    #("msg", json.string(log.msg)),
    #("running", json.bool(log.running)),
    #("keyword", case log.keyword {
      Some(kw) -> keyword.encode_keyword(kw)
      None -> json.null()
    }),
    #("total_recipes", json.int(log.total_recipes)),
    #("imported_recipes", json.int(log.imported_recipes)),
    #("created_by", json.int(log.created_by)),
    #("created_at", json.string(log.created_at)),
  ])
}

/// Encode a complete ExportLog to JSON
///
/// This includes all fields for GET responses and complete representations.
pub fn encode_export_log(log: ExportLog) -> Json {
  json.object([
    #("id", json.int(log.id)),
    #("type", json.string(log.export_type)),
    #("msg", json.string(log.msg)),
    #("running", json.bool(log.running)),
    #("total_recipes", json.int(log.total_recipes)),
    #("exported_recipes", json.int(log.exported_recipes)),
    #("cache_duration", json.int(log.cache_duration)),
    #("possibly_not_expired", json.bool(log.possibly_not_expired)),
    #("created_by", json.int(log.created_by)),
    #("created_at", json.string(log.created_at)),
  ])
}

/// Encode an ImportLogCreateRequest to JSON
///
/// Only includes writable fields for POST requests.
pub fn encode_import_log_create_request(request: ImportLogCreateRequest) -> Json {
  let base_fields = [#("type", json.string(request.import_type))]

  let msg_field = case request.msg {
    Some(msg) -> [#("msg", json.string(msg))]
    None -> []
  }

  let keyword_field = case request.keyword {
    Some(keyword_id) -> [#("keyword", json.int(keyword_id))]
    None -> []
  }

  json.object(list.flatten([base_fields, msg_field, keyword_field]))
}

/// Encode an ImportLogUpdateRequest to JSON
///
/// Only includes fields that are being updated (partial update support).
pub fn encode_import_log_update_request(request: ImportLogUpdateRequest) -> Json {
  let import_type_field = case request.import_type {
    Some(import_type) -> [#("type", json.string(import_type))]
    None -> []
  }

  let msg_field = case request.msg {
    Some(msg) -> [#("msg", json.string(msg))]
    None -> []
  }

  let running_field = case request.running {
    Some(running) -> [#("running", json.bool(running))]
    None -> []
  }

  let keyword_field = case request.keyword {
    Some(Some(keyword_id)) -> [#("keyword", json.int(keyword_id))]
    Some(None) -> [#("keyword", json.null())]
    None -> []
  }

  json.object(
    list.flatten([import_type_field, msg_field, running_field, keyword_field]),
  )
}

/// Encode an ExportLogCreateRequest to JSON
///
/// Only includes writable fields for POST requests.
pub fn encode_export_log_create_request(request: ExportLogCreateRequest) -> Json {
  let base_fields = [#("type", json.string(request.export_type))]

  let msg_field = case request.msg {
    Some(msg) -> [#("msg", json.string(msg))]
    None -> []
  }

  let cache_duration_field = case request.cache_duration {
    Some(duration) -> [#("cache_duration", json.int(duration))]
    None -> []
  }

  json.object(list.flatten([base_fields, msg_field, cache_duration_field]))
}

/// Encode an ExportLogUpdateRequest to JSON
///
/// Only includes fields that are being updated (partial update support).
pub fn encode_export_log_update_request(request: ExportLogUpdateRequest) -> Json {
  let export_type_field = case request.export_type {
    Some(export_type) -> [#("type", json.string(export_type))]
    None -> []
  }

  let msg_field = case request.msg {
    Some(msg) -> [#("msg", json.string(msg))]
    None -> []
  }

  let running_field = case request.running {
    Some(running) -> [#("running", json.bool(running))]
    None -> []
  }

  let cache_duration_field = case request.cache_duration {
    Some(duration) -> [#("cache_duration", json.int(duration))]
    None -> []
  }

  json.object(
    list.flatten([
      export_type_field,
      msg_field,
      running_field,
      cache_duration_field,
    ]),
  )
}

// ============================================================================
// API - CRUD Operations
// ============================================================================

/// List import logs from Tandoor API with pagination
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `limit` - Optional number of results per page
/// * `offset` - Optional offset for pagination
///
/// # Returns
/// Result with paginated import log list or error
pub fn list_import_logs(
  config: ClientConfig,
  limit limit: Option(Int),
  offset offset: Option(Int),
) -> Result(ImportLogList, TandoorError) {
  let query_params = case limit, offset {
    Some(l), Some(o) -> [
      #("limit", int.to_string(l)),
      #("offset", int.to_string(o)),
    ]
    Some(l), None -> [#("limit", int.to_string(l))]
    None, Some(o) -> [#("offset", int.to_string(o))]
    None, None -> []
  }

  use resp <- result.try(execute_get(config, "/api/import-log/", query_params))
  parse_json_single(resp, import_log_list_decoder())
}

/// Get a single import log by ID from Tandoor API
pub fn get_import_log(
  config: ClientConfig,
  log_id log_id: Int,
) -> Result(ImportLog, TandoorError) {
  let path = "/api/import-log/" <> int.to_string(log_id) <> "/"
  use resp <- result.try(execute_get(config, path, []))
  parse_json_single(resp, import_log_decoder())
}

/// Create a new import log in Tandoor API
pub fn create_import_log(
  config: ClientConfig,
  request: ImportLogCreateRequest,
) -> Result(ImportLog, TandoorError) {
  let body =
    encode_import_log_create_request(request)
    |> json.to_string
  use resp <- result.try(execute_post(config, "/api/import-log/", body))
  parse_json_single(resp, import_log_decoder())
}

/// Update an existing import log in Tandoor API (supports partial updates)
pub fn update_import_log(
  config: ClientConfig,
  log_id log_id: Int,
  request update_data: ImportLogUpdateRequest,
) -> Result(ImportLog, TandoorError) {
  let path = "/api/import-log/" <> int.to_string(log_id) <> "/"
  let body =
    encode_import_log_update_request(update_data)
    |> json.to_string
  use resp <- result.try(execute_patch(config, path, body))
  parse_json_single(resp, import_log_decoder())
}

/// Delete an import log from Tandoor API
pub fn delete_import_log(
  config: ClientConfig,
  log_id log_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/import-log/" <> int.to_string(log_id) <> "/"
  use _resp <- result.try(execute_delete(config, path))
  Ok(Nil)
}

/// List export logs from Tandoor API with pagination
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `limit` - Optional number of results per page
/// * `offset` - Optional offset for pagination
///
/// # Returns
/// Result with paginated export log list or error
pub fn list_export_logs(
  config: ClientConfig,
  limit limit: Option(Int),
  offset offset: Option(Int),
) -> Result(ExportLogList, TandoorError) {
  let query_params = case limit, offset {
    Some(l), Some(o) -> [
      #("limit", int.to_string(l)),
      #("offset", int.to_string(o)),
    ]
    Some(l), None -> [#("limit", int.to_string(l))]
    None, Some(o) -> [#("offset", int.to_string(o))]
    None, None -> []
  }

  use resp <- result.try(execute_get(config, "/api/export-log/", query_params))
  parse_json_single(resp, export_log_list_decoder())
}

/// Get a single export log by ID from Tandoor API
pub fn get_export_log(
  config: ClientConfig,
  log_id log_id: Int,
) -> Result(ExportLog, TandoorError) {
  let path = "/api/export-log/" <> int.to_string(log_id) <> "/"
  use resp <- result.try(execute_get(config, path, []))
  parse_json_single(resp, export_log_decoder())
}

/// Create a new export log in Tandoor API
pub fn create_export_log(
  config: ClientConfig,
  request: ExportLogCreateRequest,
) -> Result(ExportLog, TandoorError) {
  let body =
    encode_export_log_create_request(request)
    |> json.to_string
  use resp <- result.try(execute_post(config, "/api/export-log/", body))
  parse_json_single(resp, export_log_decoder())
}

/// Update an existing export log in Tandoor API (supports partial updates)
pub fn update_export_log(
  config: ClientConfig,
  log_id log_id: Int,
  request update_data: ExportLogUpdateRequest,
) -> Result(ExportLog, TandoorError) {
  let path = "/api/export-log/" <> int.to_string(log_id) <> "/"
  let body =
    encode_export_log_update_request(update_data)
    |> json.to_string
  use resp <- result.try(execute_patch(config, path, body))
  parse_json_single(resp, export_log_decoder())
}

/// Delete an export log from Tandoor API
pub fn delete_export_log(
  config: ClientConfig,
  log_id log_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/export-log/" <> int.to_string(log_id) <> "/"
  use _resp <- result.try(execute_delete(config, path))
  Ok(Nil)
}
