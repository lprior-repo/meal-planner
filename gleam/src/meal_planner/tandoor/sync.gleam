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

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import pog

/// Sync status for a recipe
pub type SyncStatus {
  /// Recipe synced and up-to-date with Tandoor
  Synced
  /// Recipe pending sync to Tandoor
  PendingSync
  /// Sync failed, needs retry
  SyncFailed
  /// Local changes not yet synced
  LocalChanges
  /// Remote changes need to be fetched
  RemoteChanges
  /// Conflict between local and remote versions
  Conflict
}

/// Sync status string representation
pub fn sync_status_to_string(status: SyncStatus) -> String {
  case status {
    Synced -> "synced"
    PendingSync -> "pending_sync"
    SyncFailed -> "sync_failed"
    LocalChanges -> "local_changes"
    RemoteChanges -> "remote_changes"
    Conflict -> "conflict"
  }
}

/// Parse sync status from string
pub fn sync_status_from_string(status: String) -> Result(SyncStatus, String) {
  case status {
    "synced" -> Ok(Synced)
    "pending_sync" -> Ok(PendingSync)
    "sync_failed" -> Ok(SyncFailed)
    "local_changes" -> Ok(LocalChanges)
    "remote_changes" -> Ok(RemoteChanges)
    "conflict" -> Ok(Conflict)
    _ -> Error("Invalid sync status: " <> status)
  }
}

/// Recipe sync state tracking
pub type RecipeSyncState {
  RecipeSyncState(
    tandoor_id: Int,
    recipe_id: String,
    sync_status: SyncStatus,
    last_synced_at: Option(String),
    local_modified_at: Option(String),
    remote_modified_at: Option(String),
    sync_error: Option(String),
  )
}

/// Sync session for batch operations
pub type SyncSession {
  SyncSession(
    session_id: String,
    started_at: String,
    completed_at: Option(String),
    total_recipes: Int,
    synced_count: Int,
    failed_count: Int,
    conflict_count: Int,
  )
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
/// Retrieves the state of an ongoing sync session
pub fn get_sync_session(
  db: pog.Connection,
  session_id: String,
) -> Result(SyncSession, String) {
  let sql =
    "SELECT session_id, started_at, completed_at, total_recipes, synced_count,
            failed_count, conflict_count
     FROM tandoor_sync_sessions
     WHERE session_id = $1"

  pog.query(sql)
  |> pog.parameter(pog.text(session_id))
  |> pog.execute(db)
  |> result.try(fn(rows) {
    case rows {
      [] -> Error("Sync session not found")
      [row, ..] -> {
        use session_id <- result.try(
          pog.col_text(row, 0)
          |> result.map_error(fn(_) { "Failed to parse session_id" }),
        )
        use started_at <- result.try(
          pog.col_text(row, 1)
          |> result.map_error(fn(_) { "Failed to parse started_at" }),
        )
        use completed_at <- result.try(
          pog.col_nullable_text(row, 2)
          |> result.map_error(fn(_) { "Failed to parse completed_at" }),
        )
        use total_recipes <- result.try(
          pog.col_int(row, 3)
          |> result.map_error(fn(_) { "Failed to parse total_recipes" }),
        )
        use synced_count <- result.try(
          pog.col_int(row, 4)
          |> result.map_error(fn(_) { "Failed to parse synced_count" }),
        )
        use failed_count <- result.try(
          pog.col_int(row, 5)
          |> result.map_error(fn(_) { "Failed to parse failed_count" }),
        )
        use conflict_count <- result.try(
          pog.col_int(row, 6)
          |> result.map_error(fn(_) { "Failed to parse conflict_count" }),
        )

        Ok(SyncSession(
          session_id: session_id,
          started_at: started_at,
          completed_at: completed_at,
          total_recipes: total_recipes,
          synced_count: synced_count,
          failed_count: failed_count,
          conflict_count: conflict_count,
        ))
      }
    }
  })
}

/// Increment synced count for a session
pub fn increment_synced(
  db: pog.Connection,
  session_id: String,
) -> Result(Nil, String) {
  let sql =
    "UPDATE tandoor_sync_sessions
     SET synced_count = synced_count + 1
     WHERE session_id = $1"

  pog.query(sql)
  |> pog.parameter(pog.text(session_id))
  |> pog.execute(db)
  |> result.map_error(fn(_) { "Failed to increment synced count" })
  |> result.map(fn(_) { Nil })
}

/// Increment failed count for a session
pub fn increment_failed(
  db: pog.Connection,
  session_id: String,
) -> Result(Nil, String) {
  let sql =
    "UPDATE tandoor_sync_sessions
     SET failed_count = failed_count + 1
     WHERE session_id = $1"

  pog.query(sql)
  |> pog.parameter(pog.text(session_id))
  |> pog.execute(db)
  |> result.map_error(fn(_) { "Failed to increment failed count" })
  |> result.map(fn(_) { Nil })
}

/// Increment conflict count for a session
pub fn increment_conflicts(
  db: pog.Connection,
  session_id: String,
) -> Result(Nil, String) {
  let sql =
    "UPDATE tandoor_sync_sessions
     SET conflict_count = conflict_count + 1
     WHERE session_id = $1"

  pog.query(sql)
  |> pog.parameter(pog.text(session_id))
  |> pog.execute(db)
  |> result.map_error(fn(_) { "Failed to increment conflict count" })
  |> result.map(fn(_) { Nil })
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
/// Calculates the percentage of recipes successfully synced in a session
pub fn get_sync_progress_percentage(session: SyncSession) -> Float {
  case session.total_recipes {
    0 -> 0.0
    _ -> {
      let completed = session.synced_count + session.failed_count
      let completed_float = int.to_float(completed)
      let total_float = int.to_float(session.total_recipes)
      completed_float /. total_float *. 100.0
    }
  }
}

/// Format sync session report
///
/// Creates a human-readable summary of sync session progress
pub fn format_sync_report(session: SyncSession) -> String {
  let progress_pct = get_sync_progress_percentage(session)
  let progress_str = int.to_string(int.floor(progress_pct))

  "Sync Session Report:\n"
  <> "  Total Recipes: "
  <> int.to_string(session.total_recipes)
  <> "\n"
  <> "  Synced: "
  <> int.to_string(session.synced_count)
  <> "\n"
  <> "  Failed: "
  <> int.to_string(session.failed_count)
  <> "\n"
  <> "  Conflicts: "
  <> int.to_string(session.conflict_count)
  <> "\n"
  <> "  Progress: "
  <> progress_str
  <> "%"
}

/// Complete a sync session
///
/// Marks a sync session as completed and records the end time
pub fn complete_sync_session(
  db: pog.Connection,
  session_id: String,
  completed_at: String,
) -> Result(Nil, String) {
  let sql =
    "UPDATE tandoor_sync_sessions
     SET completed_at = $1
     WHERE session_id = $2"

  pog.query(sql)
  |> pog.parameter(pog.text(completed_at))
  |> pog.parameter(pog.text(session_id))
  |> pog.execute(db)
  |> result.map_error(fn(_) { "Failed to complete sync session" })
  |> result.map(fn(_) { Nil })
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
