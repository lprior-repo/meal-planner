//// Unified error types for scheduler and executor
////
//// This module consolidates all scheduler and job execution errors into a
//// single AppError type. This provides:
//// - Clear error categorization (transient vs permanent)
//// - Consistent error handling across modules
//// - Better error messages and debugging

import gleam/int
import meal_planner/id.{type JobId}

// ============================================================================
// Unified Application Error Type
// ============================================================================

/// Unified error type for all scheduler and executor operations
///
/// Errors are categorized by retriability:
/// - Transient errors (ApiError, TimeoutError): Retry with backoff
/// - Permanent errors (DatabaseError, InvalidJobType, etc.): No retry
pub type AppError {
  // ========== API & Network Errors (Transient - Retriable) ==========
  /// External API returned error response (transient - retry)
  ApiError(code: Int, message: String)
  /// Job execution timed out (transient - retry)
  TimeoutError(timeout_ms: Int)

  // ========== Database Errors (Permanent - Non-Retriable) ==========
  /// Database operation failed (permanent - no retry)
  DatabaseError(message: String)
  /// Database transaction failed (permanent - no retry)
  TransactionError(message: String)

  // ========== Job Management Errors ==========
  /// Job not found in database
  JobNotFound(job_id: JobId)
  /// Job already running (cannot start duplicate)
  JobAlreadyRunning(job_id: JobId)
  /// Job execution failed with reason
  ExecutionFailed(job_id: JobId, reason: String)
  /// Maximum retry attempts exceeded
  MaxRetriesExceeded(job_id: JobId)

  // ========== Configuration & Validation Errors ==========
  /// Invalid job configuration
  InvalidConfiguration(reason: String)
  /// Invalid job type specified (permanent - no retry)
  InvalidJobType(job_type: String)

  // ========== Service State Errors ==========
  /// Scheduler is disabled (master kill switch)
  SchedulerDisabled
  /// Job dependency not met (cannot run yet)
  DependencyNotMet(job_id: JobId, dependency: JobId)
}

// ============================================================================
// Error Classification
// ============================================================================

/// Determine if error is transient (should retry)
///
/// Transient errors:
/// - ApiError (API may recover)
/// - TimeoutError (may succeed on retry)
///
/// Permanent errors:
/// - InvalidJobType (will never succeed)
/// - DatabaseError (requires intervention)
/// - MaxRetriesExceeded (already exhausted retries)
/// - JobNotFound (job doesn't exist)
/// - InvalidConfiguration (config is broken)
/// - etc.
pub fn is_transient_error(error: AppError) -> Bool {
  case error {
    // Transient errors - retry
    ApiError(_, _) -> True
    TimeoutError(_) -> True

    // Permanent errors - no retry
    DatabaseError(_) -> False
    TransactionError(_) -> False
    JobNotFound(_) -> False
    JobAlreadyRunning(_) -> False
    ExecutionFailed(_, _) -> False
    MaxRetriesExceeded(_) -> False
    InvalidConfiguration(_) -> False
    InvalidJobType(_) -> False
    SchedulerDisabled -> False
    DependencyNotMet(_, _) -> False
  }
}

/// Alias for is_transient_error to make intent clearer in retry logic
pub fn should_retry(error: AppError) -> Bool {
  is_transient_error(error)
}

// ============================================================================
// Error Message Formatting
// ============================================================================

/// Convert AppError to human-readable message
pub fn error_to_string(error: AppError) -> String {
  case error {
    // API & Network Errors
    ApiError(code, message) ->
      "API error (code " <> int.to_string(code) <> "): " <> message
    TimeoutError(ms) ->
      "Operation timed out after " <> int.to_string(ms) <> "ms"

    // Database Errors
    DatabaseError(message) -> "Database error: " <> message
    TransactionError(message) -> "Transaction error: " <> message

    // Job Management Errors
    JobNotFound(job_id) -> "Job not found: " <> id.job_id_to_string(job_id)
    JobAlreadyRunning(job_id) ->
      "Job already running: " <> id.job_id_to_string(job_id)
    ExecutionFailed(job_id, reason) ->
      "Job " <> id.job_id_to_string(job_id) <> " execution failed: " <> reason
    MaxRetriesExceeded(job_id) ->
      "Maximum retry attempts exceeded for job: " <> id.job_id_to_string(job_id)

    // Configuration & Validation Errors
    InvalidConfiguration(reason) -> "Invalid configuration: " <> reason
    InvalidJobType(job_type) -> "Invalid job type: " <> job_type

    // Service State Errors
    SchedulerDisabled -> "Scheduler is disabled"
    DependencyNotMet(job_id, dependency) ->
      "Job "
      <> id.job_id_to_string(job_id)
      <> " depends on job "
      <> id.job_id_to_string(dependency)
      <> " which is not complete"
  }
}

/// Shorter error code for logging (e.g., "API_ERROR", "TIMEOUT")
pub fn error_code(error: AppError) -> String {
  case error {
    ApiError(_, _) -> "API_ERROR"
    TimeoutError(_) -> "TIMEOUT"
    DatabaseError(_) -> "DATABASE_ERROR"
    TransactionError(_) -> "TRANSACTION_ERROR"
    JobNotFound(_) -> "JOB_NOT_FOUND"
    JobAlreadyRunning(_) -> "JOB_ALREADY_RUNNING"
    ExecutionFailed(_, _) -> "EXECUTION_FAILED"
    MaxRetriesExceeded(_) -> "MAX_RETRIES_EXCEEDED"
    InvalidConfiguration(_) -> "INVALID_CONFIGURATION"
    InvalidJobType(_) -> "INVALID_JOB_TYPE"
    SchedulerDisabled -> "SCHEDULER_DISABLED"
    DependencyNotMet(_, _) -> "DEPENDENCY_NOT_MET"
  }
}

// ============================================================================
// Error Severity Levels (for logging/alerting)
// ============================================================================

/// Error severity for logging and alerting
pub type ErrorSeverity {
  /// Informational - expected errors (e.g., job not found)
  Info
  /// Warning - recoverable errors (e.g., API error, timeout)
  Warning
  /// Error - non-recoverable but not critical (e.g., invalid config)
  Error
  /// Critical - system-level failures (e.g., database down)
  Critical
}

/// Get severity level for error
pub fn error_severity(error: AppError) -> ErrorSeverity {
  case error {
    // Transient errors - Warning (expected to recover)
    ApiError(_, _) -> Warning
    TimeoutError(_) -> Warning

    // Database errors - Critical (system failure)
    DatabaseError(_) -> Critical
    TransactionError(_) -> Critical

    // Job errors - Info/Error (expected failures)
    JobNotFound(_) -> Info
    JobAlreadyRunning(_) -> Warning
    ExecutionFailed(_, _) -> Error
    MaxRetriesExceeded(_) -> Error

    // Configuration errors - Error (needs fixing)
    InvalidConfiguration(_) -> Error
    InvalidJobType(_) -> Error

    // Service state - Warning/Info
    SchedulerDisabled -> Info
    DependencyNotMet(_, _) -> Info
  }
}
