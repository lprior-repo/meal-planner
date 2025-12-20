//// Scheduler Enable/Disable Commands Tests (RED PHASE)
////
//// Tests for scheduler job enable/disable commands.
//// These tests verify that:
//// - Enable command sets enabled flag to TRUE in scheduled_jobs
//// - Disable command sets enabled flag to FALSE in scheduled_jobs
//// - State persistence through database updates
//// - Error handling for invalid job names
////
//// Implementation: PENDING (tests written first, MUST FAIL)
////
//// Expected CLI Commands:
//// - `mp scheduler enable <JOB_NAME>`
//// - `mp scheduler disable <JOB_NAME>`

import gleam/io
import gleam/option.{None}
import gleeunit
import gleeunit/should
import meal_planner/id
import meal_planner/postgres
import meal_planner/scheduler/types.{
  type ScheduledJob, DailyAdvisor, EveryNHours, High, Pending, RetryPolicy,
  ScheduledJob,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test 1: Enable Scheduler Job
// ============================================================================

/// Test that enable command sets enabled to TRUE
///
/// Expectations:
/// - Job starts with enabled = FALSE
/// - Command: `mp scheduler enable <job_name>`
/// - After command, job.enabled = TRUE
/// - Database persists the change
pub fn enable_scheduler_job_updates_enabled_flag_test() {
  case postgres.config_from_env() {
    Error(_) -> {
      io.println(
        "SKIP: enable_scheduler_job_updates_enabled_flag_test - Database not configured",
      )
      Nil
    }
    Ok(db_config) -> {
      // Create a disabled test job
      let job = create_disabled_test_job()

      // Verify job starts as disabled
      job.enabled
      |> should.be_false

      // Execute enable command
      // NOTE: This will FAIL until implementation exists
      let result = enable_job_command(db_config, "test_daily_advisor")

      // Verify command succeeded
      result
      |> should.be_ok

      // Verify job is now enabled
      let assert Ok(updated_job) =
        get_job_by_name(db_config, "test_daily_advisor")
      updated_job.enabled
      |> should.be_true
    }
  }
}

// ============================================================================
// Test 2: Disable Scheduler Job
// ============================================================================

/// Test that disable command sets enabled to FALSE
///
/// Expectations:
/// - Job starts with enabled = TRUE
/// - Command: `mp scheduler disable <job_name>`
/// - After command, job.enabled = FALSE
/// - Database persists the change
pub fn disable_scheduler_job_updates_enabled_flag_test() {
  case postgres.config_from_env() {
    Error(_) -> {
      io.println(
        "SKIP: disable_scheduler_job_updates_enabled_flag_test - Database not configured",
      )
      Nil
    }
    Ok(db_config) -> {
      // Create an enabled test job
      let job = create_enabled_test_job()

      // Verify job starts as enabled
      job.enabled
      |> should.be_true

      // Execute disable command
      // NOTE: This will FAIL until implementation exists
      let result = disable_job_command(db_config, "test_weekly_generation")

      // Verify command succeeded
      result
      |> should.be_ok

      // Verify job is now disabled
      let assert Ok(updated_job) =
        get_job_by_name(db_config, "test_weekly_generation")
      updated_job.enabled
      |> should.be_false
    }
  }
}

// ============================================================================
// Test 3: State Persistence
// ============================================================================

/// Test that enable/disable state persists across reads
///
/// Expectations:
/// - Enable job, verify state persists when re-reading from DB
/// - Disable job, verify state persists when re-reading from DB
/// - Multiple enable/disable cycles work correctly
pub fn enable_disable_state_persists_across_reads_test() {
  case postgres.config_from_env() {
    Error(_) -> {
      io.println(
        "SKIP: enable_disable_state_persists_across_reads_test - Database not configured",
      )
      Nil
    }
    Ok(db_config) -> {
      let job_name = "test_auto_sync"

      // Start with disabled job
      let _job = create_disabled_test_job_with_name(job_name)

      // Enable the job
      let _ = enable_job_command(db_config, job_name)

      // Read from DB and verify enabled
      let assert Ok(job_after_enable) = get_job_by_name(db_config, job_name)
      job_after_enable.enabled
      |> should.be_true

      // Disable the job
      let _ = disable_job_command(db_config, job_name)

      // Read from DB and verify disabled
      let assert Ok(job_after_disable) = get_job_by_name(db_config, job_name)
      job_after_disable.enabled
      |> should.be_false

      // Re-enable the job
      let _ = enable_job_command(db_config, job_name)

      // Read from DB and verify enabled again
      let assert Ok(job_after_reenable) = get_job_by_name(db_config, job_name)
      job_after_reenable.enabled
      |> should.be_true
    }
  }
}

// ============================================================================
// Test 4: Error Handling - Invalid Job Name
// ============================================================================

/// Test that commands handle invalid job names gracefully
///
/// Expectations:
/// - Enable with non-existent job name returns Error
/// - Disable with non-existent job name returns Error
/// - Error message indicates job not found
pub fn enable_disable_invalid_job_name_returns_error_test() {
  case postgres.config_from_env() {
    Error(_) -> {
      io.println(
        "SKIP: enable_disable_invalid_job_name_returns_error_test - Database not configured",
      )
      Nil
    }
    Ok(db_config) -> {
      // Try to enable non-existent job
      let enable_result = enable_job_command(db_config, "nonexistent_job")
      enable_result
      |> should.be_error

      // Try to disable non-existent job
      let disable_result = disable_job_command(db_config, "nonexistent_job")
      disable_result
      |> should.be_error

      Nil
    }
  }
}

// ============================================================================
// Test 5: Confirmation Messages
// ============================================================================

/// Test that commands return confirmation messages
///
/// Expectations:
/// - Enable command returns success message with job name
/// - Disable command returns success message with job name
/// - Messages are human-readable
pub fn enable_disable_return_confirmation_messages_test() {
  case postgres.config_from_env() {
    Error(_) -> {
      io.println(
        "SKIP: enable_disable_return_confirmation_messages_test - Database not configured",
      )
      Nil
    }
    Ok(db_config) -> {
      let job_name = "test_weekly_trends"

      // Create test job
      let _job = create_disabled_test_job_with_name(job_name)

      // Enable and check message
      let assert Ok(enable_message) = enable_job_command(db_config, job_name)
      enable_message
      |> should.equal("Enabled scheduler job: " <> job_name)

      // Disable and check message
      let assert Ok(disable_message) = disable_job_command(db_config, job_name)
      disable_message
      |> should.equal("Disabled scheduler job: " <> job_name)

      Nil
    }
  }
}

// ============================================================================
// Test Helper Functions (Placeholder - Will FAIL until implemented)
// ============================================================================

/// Execute scheduler enable command
///
/// NOTE: This function does NOT exist yet - test MUST FAIL
fn enable_job_command(
  _db_config: postgres.Config,
  _job_name: String,
) -> Result(String, String) {
  // Placeholder - implementation pending
  // This will cause test to fail until real implementation exists
  Error("enable_job_command not implemented")
}

/// Execute scheduler disable command
///
/// NOTE: This function does NOT exist yet - test MUST FAIL
fn disable_job_command(
  _db_config: postgres.Config,
  _job_name: String,
) -> Result(String, String) {
  // Placeholder - implementation pending
  // This will cause test to fail until real implementation exists
  Error("disable_job_command not implemented")
}

/// Get job by name from database
///
/// NOTE: This function does NOT exist yet - test MUST FAIL
fn get_job_by_name(
  _db_config: postgres.Config,
  _job_name: String,
) -> Result(ScheduledJob, String) {
  // Placeholder - implementation pending
  // This will cause test to fail until real implementation exists
  Error("get_job_by_name not implemented")
}

/// Create a disabled test job
fn create_disabled_test_job() -> ScheduledJob {
  ScheduledJob(
    id: id.job_id("job_test_daily_advisor"),
    job_type: DailyAdvisor,
    frequency: EveryNHours(24),
    status: Pending,
    priority: High,
    user_id: None,
    retry_policy: RetryPolicy(
      max_attempts: 3,
      backoff_seconds: 60,
      retry_on_failure: True,
    ),
    parameters: None,
    scheduled_for: None,
    started_at: None,
    completed_at: None,
    last_error: None,
    error_count: 0,
    created_at: "2025-12-19T00:00:00Z",
    updated_at: "2025-12-19T00:00:00Z",
    created_by: None,
    enabled: False,
  )
}

/// Create an enabled test job
fn create_enabled_test_job() -> ScheduledJob {
  ScheduledJob(
    id: id.job_id("job_test_weekly_generation"),
    job_type: types.WeeklyGeneration,
    frequency: types.Weekly(day: 5, hour: 6, minute: 0),
    status: Pending,
    priority: High,
    user_id: None,
    retry_policy: RetryPolicy(
      max_attempts: 3,
      backoff_seconds: 60,
      retry_on_failure: True,
    ),
    parameters: None,
    scheduled_for: None,
    started_at: None,
    completed_at: None,
    last_error: None,
    error_count: 0,
    created_at: "2025-12-19T00:00:00Z",
    updated_at: "2025-12-19T00:00:00Z",
    created_by: None,
    enabled: True,
  )
}

/// Create a disabled test job with custom name
fn create_disabled_test_job_with_name(job_name: String) -> ScheduledJob {
  ScheduledJob(
    id: id.job_id("job_" <> job_name),
    job_type: DailyAdvisor,
    frequency: EveryNHours(12),
    status: Pending,
    priority: High,
    user_id: None,
    retry_policy: RetryPolicy(
      max_attempts: 3,
      backoff_seconds: 60,
      retry_on_failure: True,
    ),
    parameters: None,
    scheduled_for: None,
    started_at: None,
    completed_at: None,
    last_error: None,
    error_count: 0,
    created_at: "2025-12-19T00:00:00Z",
    updated_at: "2025-12-19T00:00:00Z",
    created_by: None,
    enabled: False,
  )
}
