//// Email receiver - Polls IMAP inbox, parses commands, routes to executor
////
//// This module provides both IMAP polling and webhook integration for
//// receiving email commands from users. It:
//// - Polls IMAP inbox for new emails
//// - Parses emails for @Claude commands using the parser module
//// - Routes parsed commands to the executor
//// - Marks processed emails as read/archived
//// - Handles errors and retries gracefully
////
//// Integration:
//// - Parser: meal_planner/email/parser - extracts EmailCommand from email body
//// - Executor: meal_planner/email/executor - executes commands against database
//// - Confirmation: meal_planner/email/confirmation - generates response emails

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import pog

import meal_planner/email/executor
import meal_planner/email/parser
import meal_planner/types.{
  type CommandExecutionResult, type EmailCommand, type EmailRequest,
  EmailRequest,
}

// ============================================================================
// Email Receiver Types
// ============================================================================

/// Configuration for email receiver
pub type ReceiverConfig {
  ReceiverConfig(
    /// IMAP server hostname (e.g., "imap.gmail.com")
    imap_host: String,
    /// IMAP server port (typically 993 for SSL)
    imap_port: Int,
    /// Email account username
    username: String,
    /// Email account password or app-specific password
    password: String,
    /// Polling interval in seconds
    poll_interval_seconds: Int,
    /// Maximum emails to process per poll
    batch_size: Int,
    /// Email folder to monitor (e.g., "INBOX")
    inbox_folder: String,
    /// Folder for processed emails (e.g., "Archive" or "Processed")
    processed_folder: Option(String),
  )
}

/// Result of processing a single email
pub type EmailProcessingResult {
  EmailProcessingResult(
    /// Unique identifier for the email (IMAP UID or message ID)
    email_id: String,
    /// Sender email address
    from: String,
    /// Subject line
    subject: String,
    /// Whether processing succeeded
    success: Bool,
    /// Command that was parsed (if any)
    command: Option(EmailCommand),
    /// Execution result (if command was executed)
    execution_result: Option(CommandExecutionResult),
    /// Error message (if processing failed)
    error: Option(String),
  )
}

/// Result of a polling cycle
pub type PollResult {
  PollResult(
    /// Number of new emails found
    emails_found: Int,
    /// Number of emails successfully processed
    emails_processed: Int,
    /// Number of emails that failed processing
    emails_failed: Int,
    /// Individual email results
    results: List(EmailProcessingResult),
  )
}

/// Email receiver error types
pub type ReceiverError {
  /// Failed to connect to IMAP server
  ConnectionError(message: String)
  /// Failed to authenticate with IMAP server
  AuthenticationError(message: String)
  /// Failed to fetch emails from server
  FetchError(message: String)
  /// Failed to mark email as processed
  MarkingError(message: String)
  /// Database connection error
  DatabaseError(message: String)
  /// Configuration error
  ConfigError(message: String)
}

// ============================================================================
// Default Configuration
// ============================================================================

/// Create default receiver configuration
///
/// Returns a basic configuration that must be customized with actual
/// IMAP credentials before use.
pub fn default_config() -> ReceiverConfig {
  ReceiverConfig(
    imap_host: "imap.gmail.com",
    imap_port: 993,
    username: "",
    password: "",
    poll_interval_seconds: 60,
    batch_size: 10,
    inbox_folder: "INBOX",
    processed_folder: Some("Archive"),
  )
}

/// Create receiver config from environment variables
///
/// Expects these environment variables:
/// - IMAP_HOST: IMAP server hostname
/// - IMAP_PORT: IMAP server port (default: 993)
/// - IMAP_USERNAME: Email account username
/// - IMAP_PASSWORD: Email account password
/// - IMAP_POLL_INTERVAL: Polling interval in seconds (default: 60)
/// - IMAP_BATCH_SIZE: Max emails per poll (default: 10)
/// - IMAP_INBOX_FOLDER: Folder to monitor (default: "INBOX")
/// - IMAP_PROCESSED_FOLDER: Folder for processed emails (optional)
///
/// Returns:
/// - Ok(ReceiverConfig) if all required variables are present
/// - Error(ReceiverError) if configuration is invalid
pub fn config_from_env() -> Result(ReceiverConfig, ReceiverError) {
  // TODO: Implement environment variable loading
  // For now, return error indicating this needs implementation
  Error(ConfigError(
    "config_from_env not yet implemented - use default_config() and set fields manually",
  ))
}

// ============================================================================
// Core Receiver Functions
// ============================================================================

/// Poll IMAP inbox for new emails and process them
///
/// This function:
/// 1. Connects to IMAP server using config
/// 2. Searches for unread emails in inbox folder
/// 3. Fetches email metadata and body
/// 4. Processes each email (parse → execute → confirm)
/// 5. Marks processed emails as read and optionally moves them
/// 6. Returns poll result with statistics
///
/// Parameters:
/// - config: ReceiverConfig with IMAP credentials and settings
/// - db: Database connection for command execution
///
/// Returns:
/// - Ok(PollResult) with processing statistics
/// - Error(ReceiverError) on connection or fetch failure
pub fn poll_inbox(
  config: ReceiverConfig,
  db: pog.Connection,
) -> Result(PollResult, ReceiverError) {
  // TODO: Implement IMAP polling
  // For now, return stub result

  // Note: Gleam doesn't have native IMAP support, so this would require
  // either FFI to an Erlang IMAP library or HTTP API to an email service

  Ok(PollResult(
    emails_found: 0,
    emails_processed: 0,
    emails_failed: 0,
    results: [],
  ))
}

/// Process a single email: parse command, execute, and mark as processed
///
/// This is the core processing pipeline for each email:
/// 1. Parse email body for @Claude commands
/// 2. If command found, execute it via executor module
/// 3. Generate confirmation email (optional)
/// 4. Return processing result
///
/// Parameters:
/// - email: EmailRequest with email metadata and body
/// - db: Database connection for command execution
///
/// Returns:
/// - EmailProcessingResult with execution status and results
pub fn process_email(
  email: EmailRequest,
  db: pog.Connection,
) -> EmailProcessingResult {
  // Parse email for commands
  case parser.parse_email_command(email) {
    Ok(command) -> {
      // Execute the parsed command
      let execution_result = executor.execute_command(command, db)

      EmailProcessingResult(
        email_id: "unknown",
        // Would be set from IMAP UID
        from: email.from_email,
        subject: email.subject,
        success: execution_result.success,
        command: Some(command),
        execution_result: Some(execution_result),
        error: None,
      )
    }
    Error(parse_error) -> {
      // Command parsing failed
      EmailProcessingResult(
        email_id: "unknown",
        from: email.from_email,
        subject: email.subject,
        success: False,
        command: None,
        execution_result: None,
        error: Some(error_to_string(parse_error)),
      )
    }
  }
}

/// Mark email as processed in IMAP (read and optionally move)
///
/// This function:
/// 1. Marks email as read/seen
/// 2. Optionally moves email to processed folder
/// 3. Returns success/failure status
///
/// Parameters:
/// - config: ReceiverConfig with IMAP settings
/// - email_id: IMAP UID or message ID
///
/// Returns:
/// - Ok(Nil) on success
/// - Error(ReceiverError) on failure
pub fn mark_as_processed(
  config: ReceiverConfig,
  email_id: String,
) -> Result(Nil, ReceiverError) {
  // TODO: Implement IMAP marking
  // For now, return success stub

  case config.processed_folder {
    Some(_folder) -> {
      // Would move email to processed folder
      Ok(Nil)
    }
    None -> {
      // Would just mark as read
      Ok(Nil)
    }
  }
}

/// Start continuous polling loop with interval
///
/// This function runs indefinitely, polling the inbox at regular intervals.
/// It should be run in a supervised process (OTP GenServer or similar).
///
/// Parameters:
/// - config: ReceiverConfig with polling settings
/// - db: Database connection for command execution
/// - on_result: Callback function to handle poll results
///
/// Returns:
/// - Never returns (runs until process is killed)
/// - Errors are logged but don't stop the loop
pub fn start_polling_loop(
  config: ReceiverConfig,
  db: pog.Connection,
  on_result: fn(Result(PollResult, ReceiverError)) -> Nil,
) -> Nil {
  // TODO: Implement polling loop
  // For now, just call the callback once with empty result

  let result = poll_inbox(config, db)
  on_result(result)

  // In real implementation, would:
  // 1. Loop indefinitely
  // 2. Sleep for config.poll_interval_seconds between polls
  // 3. Handle errors gracefully (log and continue)
  // 4. Respect shutdown signals
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Convert EmailCommandError to string
fn error_to_string(error: types.EmailCommandError) -> String {
  case error {
    types.InvalidCommand(reason) -> "Invalid command: " <> reason
    types.AmbiguousCommand(message) -> "Ambiguous command: " <> message
    types.MissingContext(required) -> "Missing context: " <> required
  }
}

/// Convert ReceiverError to string for logging
pub fn receiver_error_to_string(error: ReceiverError) -> String {
  case error {
    ConnectionError(msg) -> "Connection error: " <> msg
    AuthenticationError(msg) -> "Authentication error: " <> msg
    FetchError(msg) -> "Fetch error: " <> msg
    MarkingError(msg) -> "Marking error: " <> msg
    DatabaseError(msg) -> "Database error: " <> msg
    ConfigError(msg) -> "Config error: " <> msg
  }
}

/// Create summary string from poll result
pub fn poll_result_summary(result: PollResult) -> String {
  "Found "
  <> int.to_string(result.emails_found)
  <> " emails, processed "
  <> int.to_string(result.emails_processed)
  <> ", failed "
  <> int.to_string(result.emails_failed)
}

/// Check if email processing was successful
pub fn is_success(result: EmailProcessingResult) -> Bool {
  result.success
}

/// Filter successful email results
pub fn successful_results(
  results: List(EmailProcessingResult),
) -> List(EmailProcessingResult) {
  list.filter(results, is_success)
}

/// Filter failed email results
pub fn failed_results(
  results: List(EmailProcessingResult),
) -> List(EmailProcessingResult) {
  list.filter(results, fn(r) { !is_success(r) })
}

/// Extract error messages from failed results
pub fn extract_errors(results: List(EmailProcessingResult)) -> List(String) {
  results
  |> failed_results
  |> list.filter_map(fn(r) {
    case r.error {
      Some(err) -> Ok(err)
      None -> Error(Nil)
    }
  })
}
