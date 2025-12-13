/// Tests for tandoor/sync.gleam module
///
/// Comprehensive unit tests for Tandoor synchronization utilities including:
/// - Sync status management
/// - Sync session tracking
/// - Recipe sync state operations
/// - Conflict detection and resolution
/// - Progress tracking
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/tandoor/sync.{
  type RecipeSyncState, type SyncSession, Conflict, LocalChanges, PendingSync,
  RemoteChanges, SyncFailed, Synced,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Sync Status Tests
// ============================================================================

pub fn sync_status_to_string_synced_test() {
  sync.sync_status_to_string(Synced)
  |> should.equal("synced")
}

pub fn sync_status_to_string_pending_test() {
  sync.sync_status_to_string(PendingSync)
  |> should.equal("pending_sync")
}

pub fn sync_status_to_string_failed_test() {
  sync.sync_status_to_string(SyncFailed)
  |> should.equal("sync_failed")
}

pub fn sync_status_to_string_local_changes_test() {
  sync.sync_status_to_string(LocalChanges)
  |> should.equal("local_changes")
}

pub fn sync_status_to_string_remote_changes_test() {
  sync.sync_status_to_string(RemoteChanges)
  |> should.equal("remote_changes")
}

pub fn sync_status_to_string_conflict_test() {
  sync.sync_status_to_string(Conflict)
  |> should.equal("conflict")
}

pub fn sync_status_from_string_synced_test() {
  sync.sync_status_from_string("synced")
  |> should.equal(Ok(Synced))
}

pub fn sync_status_from_string_pending_test() {
  sync.sync_status_from_string("pending_sync")
  |> should.equal(Ok(PendingSync))
}

pub fn sync_status_from_string_failed_test() {
  sync.sync_status_from_string("sync_failed")
  |> should.equal(Ok(SyncFailed))
}

pub fn sync_status_from_string_local_changes_test() {
  sync.sync_status_from_string("local_changes")
  |> should.equal(Ok(LocalChanges))
}

pub fn sync_status_from_string_remote_changes_test() {
  sync.sync_status_from_string("remote_changes")
  |> should.equal(Ok(RemoteChanges))
}

pub fn sync_status_from_string_conflict_test() {
  sync.sync_status_from_string("conflict")
  |> should.equal(Ok(Conflict))
}

pub fn sync_status_from_string_invalid_test() {
  sync.sync_status_from_string("invalid_status")
  |> should.be_error()
}

// ============================================================================
// Sync Progress Tests
// ============================================================================

pub fn get_sync_progress_percentage_empty_test() {
  let session =
    SyncSession(
      session_id: "test-session",
      started_at: "2025-12-12T10:00:00Z",
      completed_at: None,
      total_recipes: 0,
      synced_count: 0,
      failed_count: 0,
      conflict_count: 0,
    )

  sync.get_sync_progress_percentage(session)
  |> should.equal(0.0)
}

pub fn get_sync_progress_percentage_partial_test() {
  let session =
    SyncSession(
      session_id: "test-session",
      started_at: "2025-12-12T10:00:00Z",
      completed_at: None,
      total_recipes: 100,
      synced_count: 45,
      failed_count: 5,
      conflict_count: 0,
    )

  sync.get_sync_progress_percentage(session)
  |> should.equal(50.0)
}

pub fn get_sync_progress_percentage_complete_test() {
  let session =
    SyncSession(
      session_id: "test-session",
      started_at: "2025-12-12T10:00:00Z",
      completed_at: Some("2025-12-12T11:00:00Z"),
      total_recipes: 100,
      synced_count: 95,
      failed_count: 5,
      conflict_count: 0,
    )

  sync.get_sync_progress_percentage(session)
  |> should.equal(100.0)
}

pub fn format_sync_report_test() {
  let session =
    SyncSession(
      session_id: "test-session",
      started_at: "2025-12-12T10:00:00Z",
      completed_at: Some("2025-12-12T11:00:00Z"),
      total_recipes: 100,
      synced_count: 85,
      failed_count: 10,
      conflict_count: 5,
    )

  let report = sync.format_sync_report(session)
  report
  |> string.contains("Total Recipes: 100")
  |> should.be_true()
  report
  |> string.contains("Synced: 85")
  |> should.be_true()
  report
  |> string.contains("Failed: 10")
  |> should.be_true()
  report
  |> string.contains("Conflicts: 5")
  |> should.be_true()
  report
  |> string.contains("Progress: 95%")
  |> should.be_true()
}

// ============================================================================
// Recipe Sync State Tests
// ============================================================================

fn create_test_recipe_sync_state() -> RecipeSyncState {
  RecipeSyncState(
    tandoor_id: 123,
    recipe_id: "recipe-123",
    sync_status: Synced,
    last_synced_at: Some("2025-12-12T10:00:00Z"),
    local_modified_at: None,
    remote_modified_at: None,
    sync_error: None,
  )
}

fn create_test_recipe_with_local_changes() -> RecipeSyncState {
  RecipeSyncState(
    tandoor_id: 124,
    recipe_id: "recipe-124",
    sync_status: LocalChanges,
    last_synced_at: Some("2025-12-12T10:00:00Z"),
    local_modified_at: Some("2025-12-12T10:30:00Z"),
    remote_modified_at: None,
    sync_error: None,
  )
}

fn create_test_recipe_with_remote_changes() -> RecipeSyncState {
  RecipeSyncState(
    tandoor_id: 125,
    recipe_id: "recipe-125",
    sync_status: RemoteChanges,
    last_synced_at: Some("2025-12-12T10:00:00Z"),
    local_modified_at: None,
    remote_modified_at: Some("2025-12-12T10:30:00Z"),
    sync_error: None,
  )
}

fn create_test_recipe_with_conflict() -> RecipeSyncState {
  RecipeSyncState(
    tandoor_id: 126,
    recipe_id: "recipe-126",
    sync_status: Conflict,
    last_synced_at: Some("2025-12-12T10:00:00Z"),
    local_modified_at: Some("2025-12-12T10:30:00Z"),
    remote_modified_at: Some("2025-12-12T10:35:00Z"),
    sync_error: Some("Conflict: both local and remote modified"),
  )
}

pub fn has_local_modifications_true_test() {
  let state = create_test_recipe_with_local_changes()
  sync.has_local_modifications(state)
  |> should.be_true()
}

pub fn has_local_modifications_false_test() {
  let state = create_test_recipe_sync_state()
  sync.has_local_modifications(state)
  |> should.be_false()
}

pub fn has_local_modifications_no_sync_time_test() {
  let state =
    RecipeSyncState(
      tandoor_id: 127,
      recipe_id: "recipe-127",
      sync_status: LocalChanges,
      last_synced_at: None,
      local_modified_at: Some("2025-12-12T10:30:00Z"),
      remote_modified_at: None,
      sync_error: None,
    )
  sync.has_local_modifications(state)
  |> should.be_true()
}

pub fn has_remote_modifications_true_test() {
  let state = create_test_recipe_with_remote_changes()
  sync.has_remote_modifications(state)
  |> should.be_true()
}

pub fn has_remote_modifications_false_test() {
  let state = create_test_recipe_sync_state()
  sync.has_remote_modifications(state)
  |> should.be_false()
}

pub fn has_remote_modifications_no_sync_time_test() {
  let state =
    RecipeSyncState(
      tandoor_id: 128,
      recipe_id: "recipe-128",
      sync_status: RemoteChanges,
      last_synced_at: None,
      local_modified_at: None,
      remote_modified_at: Some("2025-12-12T10:30:00Z"),
      sync_error: None,
    )
  sync.has_remote_modifications(state)
  |> should.be_true()
}

pub fn detect_conflict_true_test() {
  let state = create_test_recipe_with_conflict()
  sync.detect_conflict(state)
  |> should.be_true()
}

pub fn detect_conflict_false_single_change_test() {
  let state = create_test_recipe_with_local_changes()
  sync.detect_conflict(state)
  |> should.be_false()
}

pub fn detect_conflict_false_no_changes_test() {
  let state = create_test_recipe_sync_state()
  sync.detect_conflict(state)
  |> should.be_false()
}

// ============================================================================
// Sync Session Tests
// ============================================================================

fn create_test_sync_session() -> SyncSession {
  SyncSession(
    session_id: "test-session-001",
    started_at: "2025-12-12T10:00:00Z",
    completed_at: None,
    total_recipes: 50,
    synced_count: 0,
    failed_count: 0,
    conflict_count: 0,
  )
}

pub fn sync_session_in_progress_test() {
  let session = create_test_sync_session()
  session.completed_at
  |> should.equal(None)
}

pub fn sync_session_completed_test() {
  let session =
    SyncSession(
      session_id: "test-session-001",
      started_at: "2025-12-12T10:00:00Z",
      completed_at: Some("2025-12-12T11:00:00Z"),
      total_recipes: 50,
      synced_count: 45,
      failed_count: 5,
      conflict_count: 0,
    )
  session.completed_at
  |> should.equal(Some("2025-12-12T11:00:00Z"))
}

// ============================================================================
// Helper Tests
// ============================================================================

pub fn recipe_sync_state_properties_test() {
  let state = create_test_recipe_sync_state()
  state.tandoor_id
  |> should.equal(123)
  state.recipe_id
  |> should.equal("recipe-123")
  state.sync_status
  |> should.equal(Synced)
}

pub fn local_and_remote_modifications_both_test() {
  let state =
    RecipeSyncState(
      tandoor_id: 129,
      recipe_id: "recipe-129",
      sync_status: Conflict,
      last_synced_at: Some("2025-12-12T10:00:00Z"),
      local_modified_at: Some("2025-12-12T10:20:00Z"),
      remote_modified_at: Some("2025-12-12T10:15:00Z"),
      sync_error: None,
    )

  sync.has_local_modifications(state)
  |> should.be_true()
  sync.has_remote_modifications(state)
  |> should.be_true()
  sync.detect_conflict(state)
  |> should.be_true()
}

pub fn sync_session_formula_percentage_test() {
  // 30 synced + 10 failed = 40 completed / 100 total = 40%
  let session =
    SyncSession(
      session_id: "test",
      started_at: "2025-12-12T10:00:00Z",
      completed_at: None,
      total_recipes: 100,
      synced_count: 30,
      failed_count: 10,
      conflict_count: 20,
    )

  sync.get_sync_progress_percentage(session)
  |> should.equal(40.0)
}
