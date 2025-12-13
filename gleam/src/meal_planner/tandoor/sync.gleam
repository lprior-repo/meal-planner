/// Tandoor recipe sync utilities
///
/// This module provides data synchronization tools for Tandoor integration.
/// It handles fetching recipes from Tandoor, tracking sync state, and managing
/// batch operations for efficient data synchronization.
///
/// Key responsibilities:
/// - Fetch recipes from Tandoor API in batches
/// - Track synchronization progress and state
/// - Detect and handle conflicts (local vs remote changes)
/// - Manage recipe updates and deletions
/// - Provide sync status and reporting
///
/// Note: Core sync data models are defined in models.gleam for centralized
/// management, following Hickey's principle: "Data is the core, put it in one place."

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import pog

import meal_planner/tandoor/models.{
  type RecipeSyncState, type SyncSession, type SyncStatus,
  sync_status_from_string_unsafe, sync_status_to_string,
}

/// Create a new sync session
///
/// This initializes a tracking record for a batch sync operation
pub fn create_sync_session(
  db: pog.Connection,
  session_id: String,
  total_recipes: Int,
  started_at: String,
) -> Result(Nil, String) {
  let sql =
    "INSERT INTO tandoor_sync_sessions
     (session_id, started_at, total_recipes, synced_count, failed_count, conflict_count)
     VALUES ($1, $2, $3, $4, $5, $6)"

  pog.query(sql)
  |> pog.parameter(pog.text(session_id))
  |> pog.parameter(pog.text(started_at))
  |> pog.parameter(pog.int(total_recipes))
  |> pog.parameter(pog.int(0))
  |> pog.parameter(pog.int(0))
  |> pog.parameter(pog.int(0))
  |> pog.execute(db)
  |> result.map_error(fn(_) { "Failed to create sync session" })
  |> result.map(fn(_) { Nil })
}

/// Get current sync session
///
/// Retrieves the state of an ongoing sync session.
/// Delegates to sync_session module for session state retrieval.
pub fn get_sync_session(
  db: pog.Connection,
  session_id: String,
) -> Result(SyncSession, String) {
  sync_session.get(db, session_id)
}

/// Increment synced count for a session.
/// Delegates to sync_session module.
pub fn increment_synced(
  db: pog.Connection,
  session_id: String,
) -> Result(Nil, String) {
  sync_session.increment_synced(db, session_id)
}

/// Increment failed count for a session.
/// Delegates to sync_session module.
pub fn increment_failed(
  db: pog.Connection,
  session_id: String,
) -> Result(Nil, String) {
  sync_session.increment_failed(db, session_id)
}

/// Increment conflict count for a session.
/// Delegates to sync_session module.
pub fn increment_conflicts(
  db: pog.Connection,
  session_id: String,
) -> Result(Nil, String) {
  sync_session.increment_conflicts(db, session_id)
}

/// Track recipe sync state
///
/// Records the sync status and timestamps for a recipe
pub fn track_recipe_sync(
  db: pog.Connection,
  tandoor_id: Int,
  recipe_id: String,
  status: SyncStatus,
  now: String,
) -> Result(Nil, String) {
  let sql =
    "INSERT INTO tandoor_recipe_sync
     (tandoor_id, recipe_id, sync_status, last_synced_at)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (tandoor_id)
     DO UPDATE SET sync_status = $3, last_synced_at = $4"

  pog.query(sql)
  |> pog.parameter(pog.int(tandoor_id))
  |> pog.parameter(pog.text(recipe_id))
  |> pog.parameter(pog.text(sync_status_to_string(status)))
  |> pog.parameter(pog.text(now))
  |> pog.execute(db)
  |> result.map_error(fn(_) { "Failed to track recipe sync" })
  |> result.map(fn(_) { Nil })
}

/// Get recipe sync state
///
/// Retrieves the current sync status and metadata for a recipe
pub fn get_recipe_sync_state(
  db: pog.Connection,
  tandoor_id: Int,
) -> Result(RecipeSyncState, String) {
  let sql =
    "SELECT tandoor_id, recipe_id, sync_status, last_synced_at,
            local_modified_at, remote_modified_at, sync_error
     FROM tandoor_recipe_sync
     WHERE tandoor_id = $1"

  pog.query(sql)
  |> pog.parameter(pog.int(tandoor_id))
  |> pog.execute(db)
  |> result.try(fn(rows) {
    case rows {
      [] -> Error("Recipe sync state not found")
      [row, ..] -> {
        use tandoor_id <- result.try(
          pog.col_int(row, 0)
          |> result.map_error(fn(_) { "Failed to parse tandoor_id" }),
        )
        use recipe_id <- result.try(
          pog.col_text(row, 1)
          |> result.map_error(fn(_) { "Failed to parse recipe_id" }),
        )
        use sync_status_str <- result.try(
          pog.col_text(row, 2)
          |> result.map_error(fn(_) { "Failed to parse sync_status" }),
        )
        use sync_status <- sync_status_from_string(sync_status_str)
        use last_synced_at <- result.try(
          pog.col_nullable_text(row, 3)
          |> result.map_error(fn(_) { "Failed to parse last_synced_at" }),
        )
        use local_modified_at <- result.try(
          pog.col_nullable_text(row, 4)
          |> result.map_error(fn(_) { "Failed to parse local_modified_at" }),
        )
        use remote_modified_at <- result.try(
          pog.col_nullable_text(row, 5)
          |> result.map_error(fn(_) { "Failed to parse remote_modified_at" }),
        )
        use sync_error <- result.try(
          pog.col_nullable_text(row, 6)
          |> result.map_error(fn(_) { "Failed to parse sync_error" }),
        )

        Ok(RecipeSyncState(
          tandoor_id: tandoor_id,
          recipe_id: recipe_id,
          sync_status: sync_status,
          last_synced_at: last_synced_at,
          local_modified_at: local_modified_at,
          remote_modified_at: remote_modified_at,
          sync_error: sync_error,
        ))
      }
    }
  })
}

/// Update recipe sync status
///
/// Updates the sync status and error information for a recipe
pub fn update_recipe_sync_status(
  db: pog.Connection,
  tandoor_id: Int,
  status: SyncStatus,
  error: Option(String),
  now: String,
) -> Result(Nil, String) {
  let error_str = case error {
    Some(msg) -> msg
    None -> ""
  }

  let sql =
    "UPDATE tandoor_recipe_sync
     SET sync_status = $1, sync_error = $2, last_synced_at = $3
     WHERE tandoor_id = $4"

  pog.query(sql)
  |> pog.parameter(pog.text(sync_status_to_string(status)))
  |> pog.parameter(pog.text(error_str))
  |> pog.parameter(pog.text(now))
  |> pog.parameter(pog.int(tandoor_id))
  |> pog.execute(db)
  |> result.map_error(fn(_) { "Failed to update recipe sync status" })
  |> result.map(fn(_) { Nil })
}

/// Get all recipes pending sync
///
/// Returns a list of recipes that need to be synchronized
pub fn get_pending_sync_recipes(
  db: pog.Connection,
) -> Result(List(RecipeSyncState), String) {
  let sql =
    "SELECT tandoor_id, recipe_id, sync_status, last_synced_at,
            local_modified_at, remote_modified_at, sync_error
     FROM tandoor_recipe_sync
     WHERE sync_status IN ('pending_sync', 'sync_failed', 'local_changes')
     ORDER BY last_synced_at ASC"

  pog.query(sql)
  |> pog.execute(db)
  |> result.try(fn(rows) {
    rows
    |> list.try_map(fn(row) {
      use tandoor_id <- result.try(
        pog.col_int(row, 0)
        |> result.map_error(fn(_) { "Failed to parse tandoor_id" }),
      )
      use recipe_id <- result.try(
        pog.col_text(row, 1)
        |> result.map_error(fn(_) { "Failed to parse recipe_id" }),
      )
      use sync_status_str <- result.try(
        pog.col_text(row, 2)
        |> result.map_error(fn(_) { "Failed to parse sync_status" }),
      )
      use sync_status <- sync_status_from_string(sync_status_str)
      use last_synced_at <- result.try(
        pog.col_nullable_text(row, 3)
        |> result.map_error(fn(_) { "Failed to parse last_synced_at" }),
      )
      use local_modified_at <- result.try(
        pog.col_nullable_text(row, 4)
        |> result.map_error(fn(_) { "Failed to parse local_modified_at" }),
      )
      use remote_modified_at <- result.try(
        pog.col_nullable_text(row, 5)
        |> result.map_error(fn(_) { "Failed to parse remote_modified_at" }),
      )
      use sync_error <- result.try(
        pog.col_nullable_text(row, 6)
        |> result.map_error(fn(_) { "Failed to parse sync_error" }),
      )

      Ok(RecipeSyncState(
        tandoor_id: tandoor_id,
        recipe_id: recipe_id,
        sync_status: sync_status,
        last_synced_at: last_synced_at,
        local_modified_at: local_modified_at,
        remote_modified_at: remote_modified_at,
        sync_error: sync_error,
      ))
    })
  })
}

/// Get all recipes with conflicts
///
/// Returns recipes where local and remote versions differ
pub fn get_conflict_recipes(
  db: pog.Connection,
) -> Result(List(RecipeSyncState), String) {
  let sql =
    "SELECT tandoor_id, recipe_id, sync_status, last_synced_at,
            local_modified_at, remote_modified_at, sync_error
     FROM tandoor_recipe_sync
     WHERE sync_status = 'conflict'
     ORDER BY last_synced_at ASC"

  pog.query(sql)
  |> pog.execute(db)
  |> result.try(fn(rows) {
    rows
    |> list.try_map(fn(row) {
      use tandoor_id <- result.try(
        pog.col_int(row, 0)
        |> result.map_error(fn(_) { "Failed to parse tandoor_id" }),
      )
      use recipe_id <- result.try(
        pog.col_text(row, 1)
        |> result.map_error(fn(_) { "Failed to parse recipe_id" }),
      )
      use sync_status_str <- result.try(
        pog.col_text(row, 2)
        |> result.map_error(fn(_) { "Failed to parse sync_status" }),
      )
      use sync_status <- sync_status_from_string(sync_status_str)
      use last_synced_at <- result.try(
        pog.col_nullable_text(row, 3)
        |> result.map_error(fn(_) { "Failed to parse last_synced_at" }),
      )
      use local_modified_at <- result.try(
        pog.col_nullable_text(row, 4)
        |> result.map_error(fn(_) { "Failed to parse local_modified_at" }),
      )
      use remote_modified_at <- result.try(
        pog.col_nullable_text(row, 5)
        |> result.map_error(fn(_) { "Failed to parse remote_modified_at" }),
      )
      use sync_error <- result.try(
        pog.col_nullable_text(row, 6)
        |> result.map_error(fn(_) { "Failed to parse sync_error" }),
      )

      Ok(RecipeSyncState(
        tandoor_id: tandoor_id,
        recipe_id: recipe_id,
        sync_status: sync_status,
        last_synced_at: last_synced_at,
        local_modified_at: local_modified_at,
        remote_modified_at: remote_modified_at,
        sync_error: sync_error,
      ))
    })
  })
}

/// Get sync progress percentage
///
/// Calculates the percentage of recipes successfully synced in a session.
/// Delegates to sync_session module for analysis.
pub fn get_sync_progress_percentage(session: SyncSession) -> Float {
  sync_session.get_progress_percentage(session)
}

/// Format sync session report
///
/// Creates a human-readable summary of sync session progress.
/// Delegates to sync_session module for reporting.
pub fn format_sync_report(session: SyncSession) -> String {
  sync_session.format_report(session)
}

/// Complete a sync session
///
/// Marks a sync session as completed and records the end time.
/// Delegates to sync_session module for session state management.
pub fn complete_sync_session(
  db: pog.Connection,
  session_id: String,
  completed_at: String,
) -> Result(Nil, String) {
  sync_session.complete(db, session_id, completed_at)
}

/// Resolve conflict - prefer local
///
/// Marks a conflicting recipe as synced, keeping local version
pub fn resolve_conflict_local(
  db: pog.Connection,
  tandoor_id: Int,
  now: String,
) -> Result(Nil, String) {
  update_recipe_sync_status(db, tandoor_id, LocalChanges, None, now)
}

/// Resolve conflict - prefer remote
///
/// Marks a conflicting recipe as synced, accepting remote version
pub fn resolve_conflict_remote(
  db: pog.Connection,
  tandoor_id: Int,
  now: String,
) -> Result(Nil, String) {
  update_recipe_sync_status(db, tandoor_id, RemoteChanges, None, now)
}

/// Get count of recipes by sync status
///
/// Returns the number of recipes in each sync status
pub fn count_by_sync_status(
  db: pog.Connection,
) -> Result(List(#(SyncStatus, Int)), String) {
  let sql =
    "SELECT sync_status, COUNT(*) as count
     FROM tandoor_recipe_sync
     GROUP BY sync_status
     ORDER BY sync_status"

  pog.query(sql)
  |> pog.execute(db)
  |> result.try(fn(rows) {
    rows
    |> list.try_map(fn(row) {
      use status_str <- result.try(
        pog.col_text(row, 0)
        |> result.map_error(fn(_) { "Failed to parse sync_status" }),
      )
      use status <- sync_status_from_string(status_str)
      use count <- result.try(
        pog.col_int(row, 1)
        |> result.map_error(fn(_) { "Failed to parse count" }),
      )
      Ok(#(status, count))
    })
  })
}

/// Check if recipe has unsync local modifications
///
/// Returns true if local modified_at is more recent than last_synced_at
pub fn has_local_modifications(state: RecipeSyncState) -> Bool {
  case state.local_modified_at, state.last_synced_at {
    Some(local), Some(synced) -> local >. synced
    Some(_), None -> True
    None, _ -> False
  }
}

/// Check if recipe has unsync remote modifications
///
/// Returns true if remote modified_at is more recent than last_synced_at
pub fn has_remote_modifications(state: RecipeSyncState) -> Bool {
  case state.remote_modified_at, state.last_synced_at {
    Some(remote), Some(synced) -> remote >. synced
    Some(_), None -> True
    None, _ -> False
  }
}

/// Detect sync conflict between local and remote versions
///
/// Returns true if both local and remote have modifications since last sync
pub fn detect_conflict(state: RecipeSyncState) -> Bool {
  has_local_modifications(state) && has_remote_modifications(state)
}

// ============================================================================
// Recipe Mapping Audit Logging
// ============================================================================

/// Type for recipe mapping audit log entries
pub type RecipeMappingAuditLog {
  RecipeMappingAuditLog(
    mapping_id: Int,
    mealie_slug: String,
    tandoor_id: Int,
    mealie_name: String,
    tandoor_name: String,
    mapped_at: String,
    notes: Option(String),
    status: String,
  )
}

/// Log a recipe mapping operation for audit trail
///
/// Records the mapping between a Mealie recipe slug and its Tandoor ID.
/// This provides an audit trail for recipe imports and migrations.
pub fn log_recipe_mapping(
  db: pog.Connection,
  mealie_slug: String,
  tandoor_id: Int,
  mealie_name: String,
  tandoor_name: String,
  notes: Option(String),
  now: String,
) -> Result(Int, String) {
  let notes_str = case notes {
    Some(n) -> n
    None -> ""
  }

  let sql =
    "INSERT INTO recipe_mappings
     (mealie_slug, tandoor_id, mealie_name, tandoor_name, mapped_at, notes, status)
     VALUES ($1, $2, $3, $4, $5, $6, 'active')
     RETURNING mapping_id"

  pog.query(sql)
  |> pog.parameter(pog.text(mealie_slug))
  |> pog.parameter(pog.int(tandoor_id))
  |> pog.parameter(pog.text(mealie_name))
  |> pog.parameter(pog.text(tandoor_name))
  |> pog.parameter(pog.text(now))
  |> pog.parameter(pog.text(notes_str))
  |> pog.execute(db)
  |> result.try(fn(rows) {
    case rows {
      [] -> Error("Failed to insert recipe mapping")
      [row, ..] -> {
        pog.col_int(row, 0)
        |> result.map_error(fn(_) { "Failed to parse mapping_id" })
      }
    }
  })
}

/// Get a recipe mapping by Mealie slug
///
/// Retrieves the mapping record for a specific Mealie recipe slug
pub fn get_recipe_mapping(
  db: pog.Connection,
  mealie_slug: String,
) -> Result(RecipeMappingAuditLog, String) {
  let sql =
    "SELECT mapping_id, mealie_slug, tandoor_id, mealie_name, tandoor_name,
            mapped_at::text, notes, status
     FROM recipe_mappings
     WHERE mealie_slug = $1"

  pog.query(sql)
  |> pog.parameter(pog.text(mealie_slug))
  |> pog.execute(db)
  |> result.try(fn(rows) {
    case rows {
      [] -> Error("Recipe mapping not found: " <> mealie_slug)
      [row, ..] -> {
        use mapping_id <- result.try(
          pog.col_int(row, 0)
          |> result.map_error(fn(_) { "Failed to parse mapping_id" }),
        )
        use mealie_slug <- result.try(
          pog.col_text(row, 1)
          |> result.map_error(fn(_) { "Failed to parse mealie_slug" }),
        )
        use tandoor_id <- result.try(
          pog.col_int(row, 2)
          |> result.map_error(fn(_) { "Failed to parse tandoor_id" }),
        )
        use mealie_name <- result.try(
          pog.col_text(row, 3)
          |> result.map_error(fn(_) { "Failed to parse mealie_name" }),
        )
        use tandoor_name <- result.try(
          pog.col_text(row, 4)
          |> result.map_error(fn(_) { "Failed to parse tandoor_name" }),
        )
        use mapped_at <- result.try(
          pog.col_text(row, 5)
          |> result.map_error(fn(_) { "Failed to parse mapped_at" }),
        )
        use notes <- result.try(
          pog.col_nullable_text(row, 6)
          |> result.map_error(fn(_) { "Failed to parse notes" }),
        )
        use status <- result.try(
          pog.col_text(row, 7)
          |> result.map_error(fn(_) { "Failed to parse status" }),
        )

        Ok(RecipeMappingAuditLog(
          mapping_id: mapping_id,
          mealie_slug: mealie_slug,
          tandoor_id: tandoor_id,
          mealie_name: mealie_name,
          tandoor_name: tandoor_name,
          mapped_at: mapped_at,
          notes: notes,
          status: status,
        ))
      }
    }
  })
}

/// Get a recipe mapping by Tandoor ID
///
/// Retrieves the mapping record for a specific Tandoor recipe ID
pub fn get_mapping_by_tandoor_id(
  db: pog.Connection,
  tandoor_id: Int,
) -> Result(Option(RecipeMappingAuditLog), String) {
  let sql =
    "SELECT mapping_id, mealie_slug, tandoor_id, mealie_name, tandoor_name,
            mapped_at::text, notes, status
     FROM recipe_mappings
     WHERE tandoor_id = $1
     LIMIT 1"

  pog.query(sql)
  |> pog.parameter(pog.int(tandoor_id))
  |> pog.execute(db)
  |> result.try(fn(rows) {
    case rows {
      [] -> Ok(None)
      [row, ..] -> {
        use mapping_id <- result.try(
          pog.col_int(row, 0)
          |> result.map_error(fn(_) { "Failed to parse mapping_id" }),
        )
        use mealie_slug <- result.try(
          pog.col_text(row, 1)
          |> result.map_error(fn(_) { "Failed to parse mealie_slug" }),
        )
        use tandoor_id <- result.try(
          pog.col_int(row, 2)
          |> result.map_error(fn(_) { "Failed to parse tandoor_id" }),
        )
        use mealie_name <- result.try(
          pog.col_text(row, 3)
          |> result.map_error(fn(_) { "Failed to parse mealie_name" }),
        )
        use tandoor_name <- result.try(
          pog.col_text(row, 4)
          |> result.map_error(fn(_) { "Failed to parse tandoor_name" }),
        )
        use mapped_at <- result.try(
          pog.col_text(row, 5)
          |> result.map_error(fn(_) { "Failed to parse mapped_at" }),
        )
        use notes <- result.try(
          pog.col_nullable_text(row, 6)
          |> result.map_error(fn(_) { "Failed to parse notes" }),
        )
        use status <- result.try(
          pog.col_text(row, 7)
          |> result.map_error(fn(_) { "Failed to parse status" }),
        )

        Ok(Some(RecipeMappingAuditLog(
          mapping_id: mapping_id,
          mealie_slug: mealie_slug,
          tandoor_id: tandoor_id,
          mealie_name: mealie_name,
          tandoor_name: tandoor_name,
          mapped_at: mapped_at,
          notes: notes,
          status: status,
        )))
      }
    }
  })
}

/// Get all active recipe mappings
///
/// Retrieves all recipe mappings that are currently active
pub fn get_active_mappings(
  db: pog.Connection,
) -> Result(List(RecipeMappingAuditLog), String) {
  let sql =
    "SELECT mapping_id, mealie_slug, tandoor_id, mealie_name, tandoor_name,
            mapped_at::text, notes, status
     FROM recipe_mappings
     WHERE status = 'active'
     ORDER BY mapped_at DESC"

  pog.query(sql)
  |> pog.execute(db)
  |> result.try(fn(rows) {
    rows
    |> list.try_map(fn(row) {
      use mapping_id <- result.try(
        pog.col_int(row, 0)
        |> result.map_error(fn(_) { "Failed to parse mapping_id" }),
      )
      use mealie_slug <- result.try(
        pog.col_text(row, 1)
        |> result.map_error(fn(_) { "Failed to parse mealie_slug" }),
      )
      use tandoor_id <- result.try(
        pog.col_int(row, 2)
        |> result.map_error(fn(_) { "Failed to parse tandoor_id" }),
      )
      use mealie_name <- result.try(
        pog.col_text(row, 3)
        |> result.map_error(fn(_) { "Failed to parse mealie_name" }),
      )
      use tandoor_name <- result.try(
        pog.col_text(row, 4)
        |> result.map_error(fn(_) { "Failed to parse tandoor_name" }),
      )
      use mapped_at <- result.try(
        pog.col_text(row, 5)
        |> result.map_error(fn(_) { "Failed to parse mapped_at" }),
      )
      use notes <- result.try(
        pog.col_nullable_text(row, 6)
        |> result.map_error(fn(_) { "Failed to parse notes" }),
      )
      use status <- result.try(
        pog.col_text(row, 7)
        |> result.map_error(fn(_) { "Failed to parse status" }),
      )

      Ok(RecipeMappingAuditLog(
        mapping_id: mapping_id,
        mealie_slug: mealie_slug,
        tandoor_id: tandoor_id,
        mealie_name: mealie_name,
        tandoor_name: tandoor_name,
        mapped_at: mapped_at,
        notes: notes,
        status: status,
      ))
    })
  })
}

/// Get recent recipe mappings
///
/// Returns the N most recently mapped recipes
pub fn get_recent_mappings(
  db: pog.Connection,
  limit: Int,
) -> Result(List(RecipeMappingAuditLog), String) {
  let sql =
    "SELECT mapping_id, mealie_slug, tandoor_id, mealie_name, tandoor_name,
            mapped_at::text, notes, status
     FROM recipe_mappings
     ORDER BY mapped_at DESC
     LIMIT $1"

  pog.query(sql)
  |> pog.parameter(pog.int(limit))
  |> pog.execute(db)
  |> result.try(fn(rows) {
    rows
    |> list.try_map(fn(row) {
      use mapping_id <- result.try(
        pog.col_int(row, 0)
        |> result.map_error(fn(_) { "Failed to parse mapping_id" }),
      )
      use mealie_slug <- result.try(
        pog.col_text(row, 1)
        |> result.map_error(fn(_) { "Failed to parse mealie_slug" }),
      )
      use tandoor_id <- result.try(
        pog.col_int(row, 2)
        |> result.map_error(fn(_) { "Failed to parse tandoor_id" }),
      )
      use mealie_name <- result.try(
        pog.col_text(row, 3)
        |> result.map_error(fn(_) { "Failed to parse mealie_name" }),
      )
      use tandoor_name <- result.try(
        pog.col_text(row, 4)
        |> result.map_error(fn(_) { "Failed to parse tandoor_name" }),
      )
      use mapped_at <- result.try(
        pog.col_text(row, 5)
        |> result.map_error(fn(_) { "Failed to parse mapped_at" }),
      )
      use notes <- result.try(
        pog.col_nullable_text(row, 6)
        |> result.map_error(fn(_) { "Failed to parse notes" }),
      )
      use status <- result.try(
        pog.col_text(row, 7)
        |> result.map_error(fn(_) { "Failed to parse status" }),
      )

      Ok(RecipeMappingAuditLog(
        mapping_id: mapping_id,
        mealie_slug: mealie_slug,
        tandoor_id: tandoor_id,
        mealie_name: mealie_name,
        tandoor_name: tandoor_name,
        mapped_at: mapped_at,
        notes: notes,
        status: status,
      ))
    })
  })
}

/// Deprecate a recipe mapping
///
/// Marks a mapping as deprecated when a recipe is no longer needed
pub fn deprecate_mapping(
  db: pog.Connection,
  mealie_slug: String,
) -> Result(Nil, String) {
  let sql =
    "UPDATE recipe_mappings
     SET status = 'deprecated'
     WHERE mealie_slug = $1"

  pog.query(sql)
  |> pog.parameter(pog.text(mealie_slug))
  |> pog.execute(db)
  |> result.map_error(fn(_) { "Failed to deprecate recipe mapping" })
  |> result.map(fn(_) { Nil })
}

/// Mark a recipe mapping as error
///
/// Records when a recipe mapping failed or encountered issues
pub fn mark_mapping_error(
  db: pog.Connection,
  mealie_slug: String,
  error_notes: String,
) -> Result(Nil, String) {
  let sql =
    "UPDATE recipe_mappings
     SET status = 'error', notes = $2
     WHERE mealie_slug = $1"

  pog.query(sql)
  |> pog.parameter(pog.text(mealie_slug))
  |> pog.parameter(pog.text(error_notes))
  |> pog.execute(db)
  |> result.map_error(fn(_) { "Failed to mark recipe mapping as error" })
  |> result.map(fn(_) { Nil })
}

/// Count total recipe mappings by status
///
/// Returns the number of mappings in each status state
pub fn count_mappings_by_status(
  db: pog.Connection,
) -> Result(List(#(String, Int)), String) {
  let sql =
    "SELECT status, COUNT(*)::int as count
     FROM recipe_mappings
     GROUP BY status
     ORDER BY status"

  pog.query(sql)
  |> pog.execute(db)
  |> result.try(fn(rows) {
    rows
    |> list.try_map(fn(row) {
      use status <- result.try(
        pog.col_text(row, 0)
        |> result.map_error(fn(_) { "Failed to parse status" }),
      )
      use count <- result.try(
        pog.col_int(row, 1)
        |> result.map_error(fn(_) { "Failed to parse count" }),
      )
      Ok(#(status, count))
    })
  })
}

/// Get total count of recipe mappings
///
/// Returns the total number of recipe mappings in the audit log
pub fn count_total_mappings(db: pog.Connection) -> Result(Int, String) {
  let sql = "SELECT COUNT(*)::int FROM recipe_mappings"

  pog.query(sql)
  |> pog.execute(db)
  |> result.try(fn(rows) {
    case rows {
      [] -> Ok(0)
      [row, ..] -> {
        pog.col_int(row, 0)
        |> result.map_error(fn(_) { "Failed to parse count" })
      }
    }
  })
}

/// Format recipe mapping for display
///
/// Creates a human-readable summary of a recipe mapping
pub fn format_mapping(log: RecipeMappingAuditLog) -> String {
  let notes_str = case log.notes {
    Some(n) -> " - " <> n
    None -> ""
  }

  "[" <> log.mapped_at <> "] " <> log.mealie_name <> " -> " <> log.tandoor_name
  <> " (id: " <> int.to_string(log.tandoor_id) <> ", slug: " <> log.mealie_slug
  <> ", status: " <> log.status <> ")" <> notes_str
}

/// Get mapping audit report for a time period
///
/// Returns mappings created within a specific time range
pub fn get_mappings_in_period(
  db: pog.Connection,
  from_time: String,
  to_time: String,
) -> Result(List(RecipeMappingAuditLog), String) {
  let sql =
    "SELECT mapping_id, mealie_slug, tandoor_id, mealie_name, tandoor_name,
            mapped_at::text, notes, status
     FROM recipe_mappings
     WHERE mapped_at >= $1 AND mapped_at <= $2
     ORDER BY mapped_at DESC"

  pog.query(sql)
  |> pog.parameter(pog.text(from_time))
  |> pog.parameter(pog.text(to_time))
  |> pog.execute(db)
  |> result.try(fn(rows) {
    rows
    |> list.try_map(fn(row) {
      use mapping_id <- result.try(
        pog.col_int(row, 0)
        |> result.map_error(fn(_) { "Failed to parse mapping_id" }),
      )
      use mealie_slug <- result.try(
        pog.col_text(row, 1)
        |> result.map_error(fn(_) { "Failed to parse mealie_slug" }),
      )
      use tandoor_id <- result.try(
        pog.col_int(row, 2)
        |> result.map_error(fn(_) { "Failed to parse tandoor_id" }),
      )
      use mealie_name <- result.try(
        pog.col_text(row, 3)
        |> result.map_error(fn(_) { "Failed to parse mealie_name" }),
      )
      use tandoor_name <- result.try(
        pog.col_text(row, 4)
        |> result.map_error(fn(_) { "Failed to parse tandoor_name" }),
      )
      use mapped_at <- result.try(
        pog.col_text(row, 5)
        |> result.map_error(fn(_) { "Failed to parse mapped_at" }),
      )
      use notes <- result.try(
        pog.col_nullable_text(row, 6)
        |> result.map_error(fn(_) { "Failed to parse notes" }),
      )
      use status <- result.try(
        pog.col_text(row, 7)
        |> result.map_error(fn(_) { "Failed to parse status" }),
      )

      Ok(RecipeMappingAuditLog(
        mapping_id: mapping_id,
        mealie_slug: mealie_slug,
        tandoor_id: tandoor_id,
        mealie_name: mealie_name,
        tandoor_name: tandoor_name,
        mapped_at: mapped_at,
        notes: notes,
        status: status,
      ))
    })
  })
}
