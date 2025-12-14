/// Paginated ImportLog list type for Tandoor SDK
///
/// Represents a paginated list response from the Tandoor API for import logs.
/// This follows the standard Django REST Framework pagination pattern.
import gleam/option.{type Option}
import meal_planner/tandoor/types/import_export/import_log.{type ImportLog}

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
