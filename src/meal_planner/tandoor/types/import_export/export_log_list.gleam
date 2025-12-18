/// Paginated ExportLog list type for Tandoor SDK
///
/// Represents a paginated list response from the Tandoor API for export logs.
/// This follows the standard Django REST Framework pagination pattern.
import gleam/option.{type Option}
import meal_planner/tandoor/types/import_export/export_log.{type ExportLog}

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
