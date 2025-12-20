//// Scheduler Daemon - Long-running background job runner
////
//// This module provides the core daemon loop that:
//// - Continuously checks for pending jobs
//// - Executes jobs on schedule
//// - Updates job execution records
//// - Handles errors gracefully
////
//// The daemon integrates with:
//// - job_manager: For querying pending jobs and updating status
//// - executor: For actually running scheduled jobs
////
//// Design follows "infinite loop with sleep" pattern for background processing.

import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import meal_planner/scheduler/errors.{type AppError}
import meal_planner/scheduler/executor
import meal_planner/scheduler/job_manager
import meal_planner/scheduler/types.{type ScheduledJob}

// ============================================================================
// Configuration
// ============================================================================

/// Daemon configuration settings
pub type DaemonConfig {
  DaemonConfig(
    /// Milliseconds between job queue checks
    check_interval_ms: Int,
    /// Maximum number of jobs to execute concurrently
    max_concurrent_jobs: Int,
  )
}

/// Default daemon configuration
///
/// - Check every 60 seconds (60,000ms)
/// - Run up to 5 jobs concurrently
pub fn default_config() -> DaemonConfig {
  DaemonConfig(check_interval_ms: 60_000, max_concurrent_jobs: 5)
}

// ============================================================================
// Main Daemon Loop
// ============================================================================

/// Check for pending jobs and execute them
///
/// This function:
/// 1. Queries job_manager for next pending jobs
/// 2. Executes each job via executor
/// 3. Logs results
/// 4. Returns list of executed job IDs
///
/// Returns:
/// - Ok(List(String)) with executed job IDs
/// - Error(AppError) on failure
pub fn check_and_execute_jobs() -> Result(List(String), AppError) {
  // Query for pending jobs (limit to 10)
  use jobs <- result.try(job_manager.get_next_pending_jobs(limit: 10))

  // Execute each job and collect results
  let executed_job_ids =
    jobs
    |> list.map(execute_single_job)
    |> list.filter_map(fn(result) {
      case result {
        Ok(job) -> Ok(job.id |> meal_planner / id.job_id_to_string)
        Error(_) -> Error(Nil)
      }
    })

  Ok(executed_job_ids)
}

/// Execute a single scheduled job
///
/// Internal helper that wraps executor.execute_scheduled_job
/// with error handling and logging.
///
/// Parameters:
/// - job: ScheduledJob to execute
///
/// Returns:
/// - Ok(ScheduledJob) on success
/// - Error(AppError) on failure
fn execute_single_job(job: ScheduledJob) -> Result(types.JobExecution, AppError) {
  // Log execution attempt
  io.println("Executing job: " <> meal_planner / id.job_id_to_string(job.id))

  // Execute via executor module
  case executor.execute_scheduled_job(job) {
    Ok(execution) -> {
      io.println(
        "Job completed: " <> meal_planner / id.job_id_to_string(job.id),
      )
      Ok(execution)
    }
    Error(error) -> {
      io.println(
        "Job failed: "
        <> meal_planner / id.job_id_to_string(job.id)
        <> " - "
        <> errors.error_to_string(error),
      )
      Error(error)
    }
  }
}

/// Run daemon loop (infinite)
///
/// This is the main entry point for the background daemon.
/// It continuously checks for pending jobs and executes them.
///
/// WARNING: This function never returns under normal operation.
/// Only returns on fatal error.
///
/// Parameters:
/// - config: DaemonConfig with check interval and concurrency settings
///
/// Returns:
/// - Never returns normally
/// - Error(AppError) only on fatal daemon failure
pub fn run_daemon(config: DaemonConfig) -> Result(Nil, AppError) {
  io.println("Scheduler daemon starting...")
  io.println(
    "Check interval: " <> int.to_string(config.check_interval_ms) <> "ms",
  )
  io.println(
    "Max concurrent jobs: " <> int.to_string(config.max_concurrent_jobs),
  )

  // Start infinite loop
  daemon_loop(config)
}

/// Internal daemon loop (recursive)
///
/// Checks for jobs, executes them, sleeps, then repeats.
///
/// Parameters:
/// - config: DaemonConfig
///
/// Returns:
/// - Never returns normally (infinite recursion)
/// - Error(AppError) on fatal failure
fn daemon_loop(config: DaemonConfig) -> Result(Nil, AppError) {
  // Check and execute pending jobs
  case check_and_execute_jobs() {
    Ok(job_ids) -> {
      case list.length(job_ids) {
        0 -> io.println("No pending jobs")
        count ->
          io.println(
            "Executed "
            <> int.to_string(count)
            <> " jobs: "
            <> list_to_string(job_ids),
          )
      }
    }
    Error(error) -> {
      io.println("Error checking jobs: " <> errors.error_to_string(error))
    }
  }

  // Sleep for check interval
  process.sleep(config.check_interval_ms)

  // Recurse (tail call optimization)
  daemon_loop(config)
}

/// Convert list of strings to comma-separated string
///
/// Helper for logging job IDs
fn list_to_string(items: List(String)) -> String {
  case items {
    [] -> ""
    [single] -> single
    [first, second] -> first <> ", " <> second
    [first, second, third] -> first <> ", " <> second <> ", " <> third
    [first, second, third, ..rest] ->
      first
      <> ", "
      <> second
      <> ", "
      <> third
      <> " (+"
      <> int.to_string(list.length(rest))
      <> " more)"
  }
}
