/// Migration progress tracking
/// Stores and retrieves progress data for recipe migrations
///
/// This module provides utilities for tracking the progress of recipe migrations,
/// including counting total recipes, tracking migrated count, and providing
/// progress reporting (e.g., "X of Y recipes migrated").

import gleam/int
import gleam/result
import pog

/// Migration progress state
pub type MigrationProgress {
  MigrationProgress(
    migration_id: String,
    total_recipes: Int,
    migrated_count: Int,
    failed_count: Int,
    status: String,
  )
}

/// Initialize a new migration progress tracker
///
/// Returns an error if the database operation fails
pub fn create_migration(
  db: pog.Connection,
  migration_id: String,
  total_recipes: Int,
) -> Result(Nil, String) {
  let sql =
    "INSERT INTO migration_progress (migration_id, total_recipes, migrated_count, failed_count, status)
     VALUES ($1, $2, $3, $4, $5)"

  pog.query(sql)
  |> pog.parameter(pog.text(migration_id))
  |> pog.parameter(pog.int(total_recipes))
  |> pog.parameter(pog.int(0))
  |> pog.parameter(pog.int(0))
  |> pog.parameter(pog.text("in_progress"))
  |> pog.execute(db)
  |> result.map_error(fn(_) { "Failed to create migration progress record" })
  |> result.map(fn(_) { Nil })
}

/// Update migration progress
///
/// Increments the migrated count for a migration
pub fn increment_migrated(
  db: pog.Connection,
  migration_id: String,
) -> Result(Nil, String) {
  let sql =
    "UPDATE migration_progress
     SET migrated_count = migrated_count + 1
     WHERE migration_id = $1"

  pog.query(sql)
  |> pog.parameter(pog.text(migration_id))
  |> pog.execute(db)
  |> result.map_error(fn(_) { "Failed to update migration progress" })
  |> result.map(fn(_) { Nil })
}

/// Record a failed migration
///
/// Increments the failed count for a migration
pub fn increment_failed(
  db: pog.Connection,
  migration_id: String,
) -> Result(Nil, String) {
  let sql =
    "UPDATE migration_progress
     SET failed_count = failed_count + 1
     WHERE migration_id = $1"

  pog.query(sql)
  |> pog.parameter(pog.text(migration_id))
  |> pog.execute(db)
  |> result.map_error(fn(_) { "Failed to record failed migration" })
  |> result.map(fn(_) { Nil })
}

/// Get current migration progress
///
/// Returns the current state of a migration, including total, migrated, and failed counts
pub fn get_progress(
  db: pog.Connection,
  migration_id: String,
) -> Result(MigrationProgress, String) {
  let sql =
    "SELECT migration_id, total_recipes, migrated_count, failed_count, status
     FROM migration_progress
     WHERE migration_id = $1"

  pog.query(sql)
  |> pog.parameter(pog.text(migration_id))
  |> pog.execute(db)
  |> result.try(fn(rows) {
    case rows {
      [] -> Error("Migration not found")
      [row, ..] -> {
        use migration_id <- result.try(
          pog.col_text(row, 0)
          |> result.map_error(fn(_) { "Failed to parse migration_id" }),
        )
        use total_recipes <- result.try(
          pog.col_int(row, 1)
          |> result.map_error(fn(_) { "Failed to parse total_recipes" }),
        )
        use migrated_count <- result.try(
          pog.col_int(row, 2)
          |> result.map_error(fn(_) { "Failed to parse migrated_count" }),
        )
        use failed_count <- result.try(
          pog.col_int(row, 3)
          |> result.map_error(fn(_) { "Failed to parse failed_count" }),
        )
        use status <- result.try(
          pog.col_text(row, 4)
          |> result.map_error(fn(_) { "Failed to parse status" }),
        )

        Ok(MigrationProgress(
          migration_id: migration_id,
          total_recipes: total_recipes,
          migrated_count: migrated_count,
          failed_count: failed_count,
          status: status,
        ))
      }
    }
  })
}

/// Get formatted progress message
///
/// Returns a string like "45 of 100 recipes migrated"
pub fn format_progress_message(progress: MigrationProgress) -> String {
  int.to_string(progress.migrated_count)
  <> " of "
  <> int.to_string(progress.total_recipes)
  <> " recipes migrated"
}

/// Get progress percentage
///
/// Returns the percentage of recipes migrated (0-100)
pub fn get_progress_percentage(progress: MigrationProgress) -> Float {
  case progress.total_recipes {
    0 -> 0.0
    _ -> {
      let migrated_float = int.to_float(progress.migrated_count)
      let total_float = int.to_float(progress.total_recipes)
      migrated_float /. total_float *. 100.0
    }
  }
}

/// Mark migration as complete
///
/// Updates the status to "completed"
pub fn complete_migration(
  db: pog.Connection,
  migration_id: String,
) -> Result(Nil, String) {
  let sql =
    "UPDATE migration_progress
     SET status = 'completed'
     WHERE migration_id = $1"

  pog.query(sql)
  |> pog.parameter(pog.text(migration_id))
  |> pog.execute(db)
  |> result.map_error(fn(_) { "Failed to complete migration" })
  |> result.map(fn(_) { Nil })
}

/// Mark migration as failed
///
/// Updates the status to "failed"
pub fn fail_migration(
  db: pog.Connection,
  migration_id: String,
) -> Result(Nil, String) {
  let sql =
    "UPDATE migration_progress
     SET status = 'failed'
     WHERE migration_id = $1"

  pog.query(sql)
  |> pog.parameter(pog.text(migration_id))
  |> pog.execute(db)
  |> result.map_error(fn(_) { "Failed to mark migration as failed" })
  |> result.map(fn(_) { Nil })
}
