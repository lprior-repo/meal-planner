/// ImportLog type for Tandoor SDK
///
/// Represents an import operation log from the Tandoor API.
/// Import logs track the status of recipe imports from various sources
/// (Nextcloud, PDF, URLs, etc.) and provide progress information.
///
/// This type corresponds to the Tandoor API's ImportLog schema.
import gleam/option.{type Option}
import meal_planner/tandoor/types/keyword/keyword.{type Keyword}

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
