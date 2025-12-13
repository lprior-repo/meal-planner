/// Tandoor conflict resolution utilities
///
/// This module provides comprehensive conflict detection and resolution
/// for recipe synchronization between local and remote versions.
/// It encapsulates all decision-making logic for handling sync conflicts.
///
/// Key responsibilities:
/// - Detect conflicts between local and remote versions
/// - Resolve conflicts using configurable strategies
/// - Track conflict resolution decisions
/// - Provide conflict analysis and reporting
///
/// Based on principles from Martin Fowler (Extract Method/Class) and
/// Rich Hickey (make decisions explicit, not implicit).
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/result
import gleam/string
import pog

import meal_planner/tandoor/models

// ============================================================================
// Conflict Detection Functions
// ============================================================================

/// Detect if a recipe sync state has unsynced local modifications
///
/// Returns true if local modified_at is more recent than last_synced_at.
/// This indicates the local version has changes that haven't been synced to remote.
///
/// # Parameters
/// - `local_modified_at`: Optional timestamp of last local modification
/// - `last_synced_at`: Optional timestamp of last successful sync
///
/// # Returns
/// Boolean indicating whether local has unsynced modifications
pub fn has_local_modifications(
  local_modified_at: Option(String),
  last_synced_at: Option(String),
) -> Bool {
  case local_modified_at, last_synced_at {
    Some(local), Some(synced) ->
      case string.compare(local, synced) {
        order.Gt -> True
        _ -> False
      }
    Some(_), None -> True
    None, _ -> False
  }
}

/// Detect if a recipe sync state has unsynced remote modifications
///
/// Returns true if remote modified_at is more recent than last_synced_at.
/// This indicates the remote version has changes that haven't been fetched locally.
///
/// # Parameters
/// - `remote_modified_at`: Optional timestamp of last remote modification
/// - `last_synced_at`: Optional timestamp of last successful sync
///
/// # Returns
/// Boolean indicating whether remote has unsynced modifications
pub fn has_remote_modifications(
  remote_modified_at: Option(String),
  last_synced_at: Option(String),
) -> Bool {
  case remote_modified_at, last_synced_at {
    Some(remote), Some(synced) ->
      case string.compare(remote, synced) {
        order.Gt -> True
        _ -> False
      }
    Some(_), None -> True
    None, _ -> False
  }
}

/// Detect a sync conflict between local and remote versions
///
/// Returns true if both local and remote have modifications since last sync.
/// This represents a true bidirectional conflict that needs resolution.
///
/// # Parameters
/// - `local_modified_at`: Optional timestamp of last local modification
/// - `remote_modified_at`: Optional timestamp of last remote modification
/// - `last_synced_at`: Optional timestamp of last successful sync
///
/// # Returns
/// Boolean indicating whether a bidirectional conflict exists
pub fn detect_conflict(
  local_modified_at: Option(String),
  remote_modified_at: Option(String),
  last_synced_at: Option(String),
) -> Bool {
  has_local_modifications(local_modified_at, last_synced_at)
  && has_remote_modifications(remote_modified_at, last_synced_at)
}

/// Classify the type of conflict present in a recipe sync state
///
/// Analyzes the modification timestamps to determine the conflict type:
/// - models.LocalOnlyConflict: only local has changes
/// - models.RemoteOnlyConflict: only remote has changes
/// - models.BidirectionalConflict: both have changes
pub fn classify_conflict(
  local_modified_at: Option(String),
  remote_modified_at: Option(String),
  last_synced_at: Option(String),
) -> Option(models.ConflictType) {
  let local_mods = has_local_modifications(local_modified_at, last_synced_at)
  let remote_mods = has_remote_modifications(remote_modified_at, last_synced_at)

  case local_mods, remote_mods {
    True, True -> Some(models.BidirectionalConflict)
    True, False -> Some(models.LocalOnlyConflict)
    False, True -> Some(models.RemoteOnlyConflict)
    False, False -> None
  }
}

// ============================================================================
// Conflict Resolution Functions
// ============================================================================

/// Resolve a conflict between local and remote versions
///
/// Applies the specified conflict resolution strategy and updates the database
/// accordingly. Returns a models.ResolutionResult containing the outcome.
///
/// This function makes the conflict resolution decision explicit, following
/// Rich Hickey's principle of avoiding implicit decisions.
///
/// # Parameters
/// - `db`: Database connection
/// - `tandoor_id`: ID of the recipe in Tandoor
/// - `recipe_id`: Internal recipe ID
/// - `local_modified_at`: Optional timestamp of last local modification
/// - `remote_modified_at`: Optional timestamp of last remote modification
/// - `last_synced_at`: Optional timestamp of last successful sync
/// - `strategy`: Resolution strategy to apply
/// - `now`: Current timestamp
///
/// # Returns
/// Result containing the models.ResolutionResult on success, or error message on failure
pub fn resolve(
  db: pog.Connection,
  tandoor_id: Int,
  recipe_id: String,
  local_modified_at: Option(String),
  remote_modified_at: Option(String),
  last_synced_at: Option(String),
  strategy: models.ConflictResolution,
  now: String,
) -> Result(models.ResolutionResult, String) {
  // Classify the conflict type
  let conflict_type =
    classify_conflict(local_modified_at, remote_modified_at, last_synced_at)

  // Check if recipe is actually in conflict
  let is_conflicted =
    detect_conflict(local_modified_at, remote_modified_at, last_synced_at)

  // Determine which status to set based on strategy
  let new_status = case strategy {
    models.PreferLocal -> "local_changes"
    models.PreferRemote -> "remote_changes"
    models.ManualReview -> "conflict"
    models.AutoResolve(hint) ->
      resolve_with_hint(local_modified_at, remote_modified_at, hint)
  }

  // Update the sync status in the database
  use _ <- result.try(update_sync_status_in_db(
    db,
    tandoor_id,
    new_status,
    None,
    now,
  ))

  Ok(models.ResolutionResult(
    tandoor_id: tandoor_id,
    recipe_id: recipe_id,
    was_conflicted: is_conflicted,
    conflict_type: conflict_type,
    resolution_strategy: strategy,
    new_status: new_status,
    resolved_at: now,
  ))
}

/// Resolve a conflict using preference hints
///
/// Automatically determines the resolution based on the preference hint
/// and the state of local/remote modifications
fn resolve_with_hint(
  local_modified_at: Option(String),
  remote_modified_at: Option(String),
  hint: models.PreferenceHint,
) -> String {
  case hint {
    Local -> "local_changes"
    Remote -> "remote_changes"
    models.MoreRecent -> {
      case local_modified_at, remote_modified_at {
        Some(local), Some(remote) ->
          case string.compare(local, remote) {
            order.Gt -> "local_changes"
            _ -> "remote_changes"
          }
        Some(_), None -> "local_changes"
        None, Some(_) -> "remote_changes"
        None, None -> "synced"
      }
    }
  }
}

/// Update sync status in database
///
/// Internal function to update the tandoor_recipe_sync table with new status.
/// This is extracted to keep the resolve() function focused on decision-making.
fn update_sync_status_in_db(
  db: pog.Connection,
  tandoor_id: Int,
  status: String,
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
  |> pog.parameter(pog.text(status))
  |> pog.parameter(pog.text(error_str))
  |> pog.parameter(pog.text(now))
  |> pog.parameter(pog.int(tandoor_id))
  |> pog.execute(db)
  |> result.map_error(fn(_) { "Failed to update recipe sync status" })
  |> result.map(fn(_) { Nil })
}

/// Resolve conflict preferring local version
///
/// Marks a conflicting recipe as having local changes,
/// keeping the local version and marking it for sync to remote
pub fn resolve_conflict_local(
  db: pog.Connection,
  tandoor_id: Int,
  now: String,
) -> Result(Nil, String) {
  update_sync_status_in_db(db, tandoor_id, "local_changes", None, now)
}

/// Resolve conflict preferring remote version
///
/// Marks a conflicting recipe as having remote changes,
/// accepting the remote version and marking it for fetch from remote
pub fn resolve_conflict_remote(
  db: pog.Connection,
  tandoor_id: Int,
  now: String,
) -> Result(Nil, String) {
  update_sync_status_in_db(db, tandoor_id, "remote_changes", None, now)
}

// ============================================================================
// Conflict Analysis Functions
// ============================================================================

/// Determine which version is more recent
///
/// Compares local and remote modification timestamps and returns
/// which version is more recent, or None if they're equal or unknown
pub fn which_is_more_recent(
  local_modified_at: Option(String),
  remote_modified_at: Option(String),
) -> Option(#(String, String)) {
  case local_modified_at, remote_modified_at {
    Some(local), Some(remote) ->
      case string.compare(local, remote) {
        order.Gt -> Some(#("local", local))
        order.Lt -> Some(#("remote", remote))
        order.Eq -> None
      }
    Some(local), None -> Some(#("local", local))
    None, Some(remote) -> Some(#("remote", remote))
    None, None -> None
  }
}

/// Get a human-readable description of the conflict
///
/// Provides information about which sides have modifications and
/// their relative modification times
pub fn describe_conflict(
  local_modified_at: Option(String),
  remote_modified_at: Option(String),
  last_synced_at: Option(String),
) -> String {
  let local_status = case
    has_local_modifications(local_modified_at, last_synced_at)
  {
    True -> "Local has modifications"
    False -> "Local unchanged"
  }

  let remote_status = case
    has_remote_modifications(remote_modified_at, last_synced_at)
  {
    True -> "Remote has modifications"
    False -> "Remote unchanged"
  }

  let recent = case
    which_is_more_recent(local_modified_at, remote_modified_at)
  {
    Some(#(side, timestamp)) ->
      " (More recent: " <> side <> " at " <> timestamp <> ")"
    None -> ""
  }

  local_status <> " | " <> remote_status <> recent
}

/// Get human-readable description of conflict type
pub fn conflict_type_to_string(conflict_type: models.ConflictType) -> String {
  case conflict_type {
    models.LocalOnlyConflict -> "Local-only changes"
    models.RemoteOnlyConflict -> "Remote-only changes"
    models.BidirectionalConflict -> "Bidirectional conflict"
  }
}

/// Get human-readable description of resolution strategy
pub fn strategy_to_string(strategy: models.ConflictResolution) -> String {
  case strategy {
    models.PreferLocal -> "Prefer local version"
    models.PreferRemote -> "Prefer remote version"
    models.ManualReview -> "Manual review required"
    models.AutoResolve(hint) ->
      "Auto-resolve ("
      <> case hint {
        models.MoreRecent -> "prefer most recent"
        Local -> "prefer local"
        Remote -> "prefer remote"
      }
      <> ")"
  }
}
