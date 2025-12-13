/// Tandoor synchronization data models
///
/// This module consolidates all core data types for Tandoor recipe synchronization,
/// providing a single canonical place for all sync-related models.
///
/// Following Rich Hickey's principle: "Data is the core, put it in one place."
/// This module serves as the centralized definition of sync data structures,
/// making it clear what state is being tracked and how it evolves.
///
/// Key types:
/// - SyncStatus: Six-state model for recipe sync lifecycle
/// - RecipeSyncState: Individual recipe sync metadata
/// - SyncSession: Batch operation tracking
/// - ConflictResolution: Conflict resolution strategies
/// - PreferenceHint: Hints for automatic conflict resolution
/// - ResolutionResult: Outcome of conflict resolution
import gleam/option.{type Option}

// ============================================================================
// Sync Status Model
// ============================================================================

/// Sync status for a recipe in the synchronization lifecycle
///
/// Represents the six distinct states a recipe can be in during sync:
/// - Synced: In sync with remote, no pending changes
/// - PendingSync: Waiting to be synced to remote
/// - SyncFailed: Last sync attempt failed
/// - LocalChanges: Local modifications not yet synced
/// - RemoteChanges: Remote modifications not yet fetched
/// - Conflict: Both local and remote have conflicting changes
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

/// Convert SyncStatus to its string representation
///
/// Used for database persistence and status reporting
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

/// Parse SyncStatus from string representation
///
/// Validates the string and returns a SyncStatus or error
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

/// Internal helper to parse SyncStatus with safe fallback
///
/// Used by decoders; defaults to Synced for unknown values
pub fn sync_status_from_string_unsafe(status: String) -> SyncStatus {
  case status {
    "synced" -> Synced
    "pending_sync" -> PendingSync
    "sync_failed" -> SyncFailed
    "local_changes" -> LocalChanges
    "remote_changes" -> RemoteChanges
    "conflict" -> Conflict
    _ -> Synced
    // Default fallback
  }
}

// ============================================================================
// Recipe Sync State Model
// ============================================================================

/// Tracks the synchronization state of an individual recipe
///
/// Maintains all metadata needed to understand and manage a recipe's
/// sync status relative to the remote Tandoor instance.
pub type RecipeSyncState {
  RecipeSyncState(
    /// Tandoor recipe ID
    tandoor_id: Int,
    /// Local recipe ID/slug
    recipe_id: String,
    /// Current sync status
    sync_status: SyncStatus,
    /// When the recipe was last successfully synced
    last_synced_at: Option(String),
    /// When local version was last modified
    local_modified_at: Option(String),
    /// When remote version was last modified
    remote_modified_at: Option(String),
    /// Error message if sync failed
    sync_error: Option(String),
  )
}

// ============================================================================
// Sync Session Model
// ============================================================================

/// Tracks a batch synchronization session
///
/// Used to monitor progress during bulk sync operations,
/// tracking counts of successful, failed, and conflicted recipes
pub type SyncSession {
  SyncSession(
    /// Unique session identifier
    session_id: String,
    /// When the sync session started
    started_at: String,
    /// When the sync session completed (if finished)
    completed_at: Option(String),
    /// Total recipes in this sync session
    total_recipes: Int,
    /// Count of successfully synced recipes
    synced_count: Int,
    /// Count of recipes that failed to sync
    failed_count: Int,
    /// Count of recipes with sync conflicts
    conflict_count: Int,
  )
}

// ============================================================================
// Conflict Type Model
// ============================================================================

/// Type representing a conflict between local and remote versions
///
/// Classifies the nature of a sync conflict based on which sides
/// have modifications relative to the last successful sync
pub type ConflictType {
  /// Local has changes, remote doesn't
  LocalOnlyConflict
  /// Remote has changes, local doesn't
  RemoteOnlyConflict
  /// Both local and remote have conflicting changes
  BidirectionalConflict
}

// ============================================================================
// Conflict Resolution Models
// ============================================================================

/// Strategy for resolving conflicts between local and remote versions
///
/// Specifies which version to keep when both local and remote have
/// conflicting changes
pub type ConflictResolution {
  /// Keep local version, overwrite remote
  PreferLocal
  /// Keep remote version, overwrite local
  PreferRemote
  /// Mark as pending, requires manual intervention
  ManualReview
  /// Use automatic conflict resolution based on timestamps
  AutoResolve(prefer: PreferenceHint)
}

/// Hint for automatic conflict resolution
///
/// Provides guidance for automatic resolution when both local and remote
/// have changes
pub type PreferenceHint {
  /// Prefer the most recently modified version
  MoreRecent
  /// Prefer the local version
  Local
  /// Prefer the remote version
  Remote
}

/// Result of a conflict resolution attempt
///
/// Records what happened when a conflict was resolved
pub type ResolutionResult {
  ResolutionResult(
    /// Recipe's Tandoor ID
    tandoor_id: Int,
    /// Recipe's local ID
    recipe_id: String,
    /// Whether recipe was actually conflicted
    was_conflicted: Bool,
    /// Strategy that was applied
    resolution_strategy: ConflictResolution,
    /// Status after resolution
    new_status: SyncStatus,
    /// When resolution occurred
    resolved_at: String,
  )
}
