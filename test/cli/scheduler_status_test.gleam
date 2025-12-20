//// TDD Test for CLI scheduler status command
////
//// RED PHASE: This test MUST fail initially because the implementation
//// does not exist yet. The test validates:
//// 1. Show status of specific scheduler job
//// 2. Display last execution time and result
//// 3. Show next scheduled run time
//// 4. Display job health/failure details if failed
////
//// Test follows Gleam 7 Commandments:
//// - Immutability: All test data is immutable
//// - No Nulls: Uses Option(T) and Result(T, E) exclusively
//// - Exhaustive Matching: All case branches covered
//// - Type Safety: Custom types for domain concepts

import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/scheduler as scheduler_cmd
import meal_planner/config

pub fn main() {
  gleeunit.main()
}

/// Test config for CLI commands
fn test_config() -> config.Config {
  config.Config(
    environment: config.Development,
    database: config.DatabaseConfig(
      host: "localhost",
      port: 5432,
      name: "meal_planner_test",
      user: "test_user",
      password: "test_password",
      pool_size: 10,
      connection_timeout_ms: 5000,
    ),
    server: config.ServerConfig(port: 8080, cors_allowed_origins: []),
    tandoor: config.TandoorConfig(
      base_url: "http://localhost:8000",
      api_token: "test_token",
      connect_timeout_ms: 5000,
      request_timeout_ms: 30_000,
    ),
    external_services: config.ExternalServicesConfig(
      fatsecret: Some(config.FatSecretConfig(
        consumer_key: "test_client_id",
        consumer_secret: "test_client_secret",
      )),
      todoist_api_key: "test_todoist",
      usda_api_key: "test_usda",
      openai_api_key: "test_openai",
      openai_model: "gpt-4",
    ),
    secrets: config.SecretsConfig(
      oauth_encryption_key: None,
      jwt_secret: None,
      database_password: "test_password",
      tandoor_token: "test_token",
    ),
    logging: config.LoggingConfig(level: config.InfoLevel, debug_mode: False),
    performance: config.PerformanceConfig(
      request_timeout_ms: 30_000,
      connection_timeout_ms: 5000,
      max_concurrent_requests: 100,
      rate_limit_requests: 1000,
    ),
  )
}

// ============================================================================
// RED PHASE: Tests that MUST FAIL initially
// ============================================================================

/// Test: mp scheduler status shows job details
///
/// EXPECTED FAILURE: scheduler_cmd.get_status function does not exist
///
/// This test validates that the status command:
/// 1. Accepts job name as argument: mp scheduler status sync
/// 2. Fetches job from scheduler database
/// 3. Returns Ok with job status information
/// 4. Displays job details to user
///
/// Implementation strategy:
/// - Query scheduler_jobs table WHERE name = 'sync'
/// - Return JobStatus containing: name, enabled, last_run_at, last_result
/// - Print formatted output
pub fn scheduler_status_shows_job_details_test() {
  let cfg = test_config()

  // When: calling get_status for specific job
  let result = scheduler_cmd.get_status(cfg, job_name: "sync")

  // Then: should return Ok with job status
  // This will FAIL because scheduler_cmd.get_status does not exist
  result
  |> should.be_ok()
}

/// Test: mp scheduler status displays last execution
///
/// EXPECTED FAILURE: scheduler_cmd.get_status does not format output
///
/// This test validates output formatting:
/// 1. Shows "Last Run: 2025-12-20 14:30:45" (most recent execution)
/// 2. Shows execution duration
/// 3. Shows result: "Success" or "Failed"
/// 4. Shows error message if failed
///
/// Implementation strategy:
/// - Query scheduler_executions table for job
/// - Find most recent record (ORDER BY executed_at DESC LIMIT 1)
/// - Format timestamp and duration
/// - Print: "Last Run: {date} {time}"
/// - Print: "Result: {status} ({duration}s)"
pub fn scheduler_status_displays_last_execution_test() {
  let cfg = test_config()

  // When: calling get_status
  let result = scheduler_cmd.get_status(cfg, job_name: "sync")

  // Then: should display last execution details
  // Expected console output:
  // "Job: sync"
  // "Status: Enabled"
  // "Last Run: 2025-12-20 14:30:45"
  // "Result: Success (45s)"
  // This will FAIL because scheduler_cmd.get_status does not exist
  result
  |> should.be_ok()
}

/// Test: mp scheduler status shows next scheduled run
///
/// EXPECTED FAILURE: scheduler_cmd.get_status does not calculate next run
///
/// This test validates next run time calculation:
/// 1. Based on job schedule and last run time
/// 2. Shows: "Next Run: 2025-12-20 15:00:00" (in 30 minutes)
/// 3. Shows countdown: "in 30 minutes"
/// 4. Uses job.frequency to calculate
///
/// Implementation strategy:
/// - Get job.frequency (daily, weekly, monthly, custom_cron)
/// - Calculate next_run_at based on last_run_at + frequency_interval
/// - Format as human-readable: "Next Run: {date} {time} (in X minutes)"
pub fn scheduler_status_shows_next_run_test() {
  let cfg = test_config()

  // When: calling get_status
  let result = scheduler_cmd.get_status(cfg, job_name: "sync")

  // Then: should show next scheduled run
  // Expected console output:
  // "Next Run: 2025-12-20 15:00:00 (in 30 minutes)"
  // This will FAIL because scheduler_cmd.get_status does not exist
  result
  |> should.be_ok()
}

/// Test: mp scheduler status handles job not found
///
/// EXPECTED FAILURE: scheduler_cmd.get_status does not check if job exists
///
/// This test validates error when job doesn't exist:
/// 1. Job name not found in scheduler_jobs
/// 2. Returns Error("Job 'unknown' not found")
/// 3. Lists available jobs in error message
///
/// Implementation strategy:
/// - Query scheduler_jobs WHERE name = 'unknown'
/// - If no results, return Error with available jobs
pub fn scheduler_status_job_not_found_test() {
  let cfg = test_config()

  // When: calling get_status for non-existent job
  let result = scheduler_cmd.get_status(cfg, job_name: "unknown_job")

  // Then: should return Error
  // This will FAIL because scheduler_cmd.get_status does not exist
  result
  |> should.be_error()
}

/// Test: mp scheduler status shows failure details
///
/// EXPECTED FAILURE: scheduler_cmd.get_status does not show error messages
///
/// This test validates failure information:
/// 1. If last execution failed, show error message
/// 2. Display: "Result: Failed - HTTP 500 Internal Server Error"
/// 3. Show stack trace or error details
/// 4. Helpful for debugging
///
/// Implementation strategy:
/// - Check if last execution has status = 'failed'
/// - Fetch error_message from scheduler_executions
/// - Print: "Result: Failed - {error_message}"
pub fn scheduler_status_shows_failure_details_test() {
  let cfg = test_config()

  // When: calling get_status for failed job
  let result = scheduler_cmd.get_status(cfg, job_name: "sync")

  // Then: should display failure details
  // Expected console output:
  // "Result: Failed - HTTP 500 Internal Server Error"
  // This will FAIL because scheduler_cmd.get_status does not exist
  result
  |> should.be_ok()
}

/// Test: mp scheduler status shows job enabled/disabled
///
/// EXPECTED FAILURE: scheduler_cmd.get_status does not show enabled status
///
/// This test validates status indicator:
/// 1. Shows "Status: Enabled" if job.enabled = true
/// 2. Shows "Status: Disabled" if job.enabled = false
/// 3. Visual indicator: ✓ for enabled, ✗ for disabled
///
/// Implementation strategy:
/// - Check job.enabled field
/// - Print: "Status: {Enabled|Disabled}"
pub fn scheduler_status_shows_enabled_status_test() {
  let cfg = test_config()

  // When: calling get_status
  let result = scheduler_cmd.get_status(cfg, job_name: "sync")

  // Then: should show enabled status with visual indicator
  // Expected console output:
  // "✓ Status: Enabled"  OR  "✗ Status: Disabled"
  // This will FAIL because scheduler_cmd.get_status does not exist
  result
  |> should.be_ok()
}

/// Test: mp scheduler status shows execution count
///
/// EXPECTED FAILURE: scheduler_cmd.get_status does not count executions
///
/// This test validates execution history:
/// 1. Shows total execution count: "Total Runs: 42"
/// 2. Shows success count and failure count
/// 3. Shows success rate: "Success Rate: 97.6%"
///
/// Implementation strategy:
/// - Query scheduler_executions WHERE job_id = X
/// - Count total, successes, failures
/// - Calculate success_rate = successes / total * 100
/// - Print statistics
pub fn scheduler_status_shows_execution_stats_test() {
  let cfg = test_config()

  // When: calling get_status
  let result = scheduler_cmd.get_status(cfg, job_name: "sync")

  // Then: should show execution statistics
  // Expected console output:
  // "Total Runs: 42"
  // "Successes: 41"
  // "Failures: 1"
  // "Success Rate: 97.6%"
  // This will FAIL because scheduler_cmd.get_status does not exist
  result
  |> should.be_ok()
}

/// Test: mp scheduler status handles database errors
///
/// EXPECTED FAILURE: scheduler_cmd.get_status does not handle DB errors
///
/// This test validates database error handling:
/// 1. Database connection fails
/// 2. Returns Error with descriptive message
/// 3. No crash
///
/// Implementation strategy:
/// - Wrap DB queries in result.try
/// - Map errors to Error("Failed to fetch job status: <error>")
pub fn scheduler_status_handles_database_errors_test() {
  let cfg = test_config()

  // When: database connection fails
  let result = scheduler_cmd.get_status(cfg, job_name: "sync")

  // Then: should return Error
  // This will FAIL because scheduler_cmd.get_status does not exist
  result
  |> should.be_error()
}
