/// Helper functions for Result type transformations
///
/// This module provides utilities to reduce duplicate error handling patterns
/// across the codebase, following the Extract Method refactoring pattern.

import meal_planner/storage/profile.{type StorageError, DatabaseError}
import meal_planner/storage/utils
import pog

/// Convert a Result with pog.QueryError to a Result with StorageError
///
/// This helper eliminates the duplicate pattern:
/// ```gleam
/// case result {
///   Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
///   Ok(x) -> Ok(x)
/// }
/// ```
///
/// Usage:
/// ```gleam
/// pog.query(sql)
/// |> pog.execute(conn)
/// |> result_to_storage_error
/// ```
pub fn result_to_storage_error(
  result: Result(a, pog.QueryError),
) -> Result(a, StorageError) {
  case result {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(value) -> Ok(value)
  }
}
