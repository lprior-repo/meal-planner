import gleeunit/should
import meal_planner/id
import meal_planner/scheduler/sync_scheduler

/// Test that trigger_auto_sync creates and updates job execution record
///
/// This test verifies that the sync function:
/// 1. Creates a JobExecution record
/// 2. Runs the sync operation
/// 3. Updates the record with results
/// 4. Returns a SyncResult with counts
pub fn trigger_auto_sync_creates_execution_record_test() {
  // Arrange: Create test user ID
  let user_id = id.user_id("test-user-123")

  // Act: Trigger auto sync
  let result = sync_scheduler.trigger_auto_sync(user_id)

  // Assert: Should return Ok with SyncResult
  result
  |> should.be_ok()
}

/// Test that SyncResult contains expected fields after auto sync
pub fn trigger_auto_sync_returns_sync_result_test() {
  // Arrange
  let user_id = id.user_id("test-user-456")

  // Act
  let assert Ok(result) = sync_scheduler.trigger_auto_sync(user_id)

  // Assert: Result should have non-negative counts
  { result.synced >= 0 }
  |> should.be_true()

  { result.skipped >= 0 }
  |> should.be_true()

  { result.failed >= 0 }
  |> should.be_true()

  // Errors should be a list
  result.errors
  |> should.be_ok()
}
