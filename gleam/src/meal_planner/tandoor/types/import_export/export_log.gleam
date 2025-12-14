/// ExportLog type for Tandoor SDK
///
/// Represents an export operation log from the Tandoor API.
/// Export logs track the status of recipe exports to various formats
/// (ZIP, PDF, JSON, etc.) and manage export caching.
///
/// This type corresponds to the Tandoor API's ExportLog schema.
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
