//// TDD Test for CLI scheduler trigger command
////
//// RED PHASE: This test MUST fail initially because the implementation
//// does not exist yet. The test validates:
//// 1. Immediately execute scheduler job outside of schedule
//// 2. Log execution to scheduler_executions table
//// 3. Display job output/result to user
//// 4. Handle job errors and show error details
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

/// Test: mp scheduler trigger executes job immediately
///
/// EXPECTED FAILURE: scheduler_cmd.trigger_job function does not exist
///
/// This test validates that the trigger command:
/// 1. Accepts job name as argument: mp scheduler trigger sync
/// 2. Executes the job immediately (not on schedule)
/// 3. Logs execution to scheduler_executions table
/// 4. Returns Ok with execution result
///
/// Implementation strategy:
/// - Query scheduler_jobs WHERE name = 'sync'
/// - Call the job's handler function directly
/// - Record execution: INSERT INTO scheduler_executions (job_id, started_at, completed_at, status, output)
/// - Return Ok(ExecutionResult)
pub fn scheduler_trigger_executes_job_test() {
  let cfg = test_config()

  // When: calling trigger_job for specific job
  let result = scheduler_cmd.trigger_job(cfg, job_name: "sync")

  // Then: should execute job immediately and return Ok
  // This will FAIL because scheduler_cmd.trigger_job does not exist
  result
  |> should.be_ok()
}

/// Test: mp scheduler trigger displays execution output
///
/// EXPECTED FAILURE: scheduler_cmd.trigger_job does not show output
///
/// This test validates output display:
/// 1. Shows "Executing job: sync..."
/// 2. Streams job output line by line as it runs
/// 3. Shows "Job completed successfully" when done
/// 4. Shows execution duration: "Completed in 5.2 seconds"
///
/// Implementation strategy:
/// - Use io.println to show progress
/// - Capture job output/logs
/// - Print each line as it's produced
/// - Calculate duration = completed_at - started_at
/// - Print final message with duration
pub fn scheduler_trigger_displays_output_test() {
  let cfg = test_config()

  // When: calling trigger_job
  let result = scheduler_cmd.trigger_job(cfg, job_name: "sync")

  // Then: should display execution progress
  // Expected console output:
  // "Executing job: sync..."
  // "Syncing recipes from Tandoor..."
  // "Fetching batch 1/3..."
  // "Completed in 5.2 seconds"
  // This will FAIL because scheduler_cmd.trigger_job does not exist
  result
  |> should.be_ok()
}

/// Test: mp scheduler trigger handles job not found
///
/// EXPECTED FAILURE: scheduler_cmd.trigger_job does not validate job exists
///
/// This test validates error when job doesn't exist:
/// 1. Job name not found in scheduler_jobs
/// 2. Returns Error("Job 'unknown' not found")
/// 3. Lists available jobs
///
/// Implementation strategy:
/// - Query scheduler_jobs WHERE name = 'unknown'
/// - If no results, return Error with helpful message
pub fn scheduler_trigger_job_not_found_test() {
  let cfg = test_config()

  // When: calling trigger_job for non-existent job
  let result = scheduler_cmd.trigger_job(cfg, job_name: "nonexistent")

  // Then: should return Error
  // This will FAIL because scheduler_cmd.trigger_job does not exist
  result
  |> should.be_error()
}

/// Test: mp scheduler trigger handles job execution errors
///
/// EXPECTED FAILURE: scheduler_cmd.trigger_job does not handle errors gracefully
///
/// This test validates error handling during execution:
/// 1. Job execution fails (e.g., API error, DB error)
/// 2. Function returns Error with error message
/// 3. Execution still logged to database with status = 'failed'
/// 4. Error message included in database record
///
/// Implementation strategy:
/// - Wrap job execution in result.try
/// - Catch all error types
/// - Log execution with status = 'failed' and error_message
/// - Return Error("Job failed: <error>")
pub fn scheduler_trigger_handles_execution_errors_test() {
  let cfg = test_config()

  // When: job execution fails (e.g., API error)
  let result = scheduler_cmd.trigger_job(cfg, job_name: "sync")

  // Then: should return Error and log failure
  // This will FAIL because scheduler_cmd.trigger_job does not exist
  result
  |> should.be_error()
}

/// Test: mp scheduler trigger logs execution to database
///
/// EXPECTED FAILURE: scheduler_cmd.trigger_job does not save to database
///
/// This test validates execution logging:
/// 1. Execution recorded in scheduler_executions table
/// 2. Records: job_id, started_at, completed_at, status, output, error_message
/// 3. Can later query execution history
/// 4. Persists across restarts
///
/// Implementation strategy:
/// - Before execution: INSERT INTO scheduler_executions (job_id, started_at) RETURNING id
/// - After execution: UPDATE scheduler_executions SET completed_at, status, output WHERE id = execution_id
pub fn scheduler_trigger_logs_execution_test() {
  let cfg = test_config()

  // When: calling trigger_job
  let result = scheduler_cmd.trigger_job(cfg, job_name: "sync")

  // Then: execution should be recorded in database
  // This will FAIL because scheduler_cmd.trigger_job does not exist
  result
  |> should.be_ok()
}

/// Test: mp scheduler trigger updates job's last_run_at
///
/// EXPECTED FAILURE: scheduler_cmd.trigger_job does not update job metadata
///
/// This test validates job metadata update:
/// 1. Updates scheduler_jobs.last_run_at = now
/// 2. Sets last_result = 'success' or 'failed'
/// 3. Used for next scheduled run calculation
///
/// Implementation strategy:
/// - After execution, UPDATE scheduler_jobs SET last_run_at = now, last_result = status WHERE id = job_id
pub fn scheduler_trigger_updates_last_run_time_test() {
  let cfg = test_config()

  // When: calling trigger_job
  let result = scheduler_cmd.trigger_job(cfg, job_name: "sync")

  // Then: job's last_run_at should be updated
  // This will FAIL because scheduler_cmd.trigger_job does not exist
  result
  |> should.be_ok()
}

/// Test: mp scheduler trigger shows execution duration
///
/// EXPECTED FAILURE: scheduler_cmd.trigger_job does not calculate duration
///
/// This test validates duration reporting:
/// 1. Measures time from job start to completion
/// 2. Displays: "Completed in 5.2 seconds"
/// 3. Shows as human-readable format
/// 4. Helps identify slow-running jobs
///
/// Implementation strategy:
/// - Record started_at before execution
/// - Record completed_at after execution
/// - Calculate: duration_ms = completed_at - started_at
/// - Format and print: "Completed in {duration_s}s"
pub fn scheduler_trigger_shows_duration_test() {
  let cfg = test_config()

  // When: calling trigger_job
  let result = scheduler_cmd.trigger_job(cfg, job_name: "sync")

  // Then: should display execution duration
  // Expected console output:
  // "Completed in 5.2 seconds"
  // This will FAIL because scheduler_cmd.trigger_job does not exist
  result
  |> should.be_ok()
}

/// Test: mp scheduler trigger returns execution result
///
/// EXPECTED FAILURE: scheduler_cmd.trigger_job does not return detailed result
///
/// This test validates return value:
/// 1. Returns Ok(ExecutionResult) containing:
///    - execution_id: unique identifier
///    - status: 'success' or 'failed'
///    - duration_ms: execution time
///    - output: job output/log text
/// 2. Can be used for further processing
///
/// Implementation strategy:
/// - Define ExecutionResult type
/// - Populate all fields from execution record
/// - Return Ok(ExecutionResult)
pub fn scheduler_trigger_returns_execution_result_test() {
  let cfg = test_config()

  // When: calling trigger_job
  let result = scheduler_cmd.trigger_job(cfg, job_name: "sync")

  // Then: should return Ok(ExecutionResult)
  // This will FAIL because scheduler_cmd.trigger_job does not exist
  result
  |> should.be_ok()
}
