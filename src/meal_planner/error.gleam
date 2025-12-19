//// Error handling module for the Meal Planner application.
////
//// Provides comprehensive error types, exit codes, and utilities for
//// handling errors gracefully with proper cleanup and informative messages.

/// Exit code type for different error scenarios
pub type ExitCode {
  /// Success exit code (0)
  Success
  /// General error exit code (1)
  GeneralError
  /// Invalid usage exit code (2)
  InvalidUsage
  /// Authentication error exit code (3)
  AuthError
  /// Network error exit code (4)
  NetworkError
  /// Database error exit code (5)
  DatabaseError
}

/// Convert ExitCode to integer value
pub fn exit_code_to_int(code: ExitCode) -> Int {
  case code {
    Success -> 0
    GeneralError -> 1
    InvalidUsage -> 2
    AuthError -> 3
    NetworkError -> 4
    DatabaseError -> 5
  }
}

/// Application error type
pub type AppError {
  /// Configuration error (missing or invalid env vars)
  ConfigError(message: String, hint: String)
  /// Database connection error
  DbError(message: String, hint: String)
  /// Network/HTTP error
  NetError(message: String, hint: String)
  /// Authentication error
  AuthenticationError(message: String, hint: String)
  /// File/IO error
  IoError(message: String, hint: String)
  /// Invalid usage/argument error
  UsageError(message: String, hint: String)
  /// Generic application error
  ApplicationError(message: String, hint: String)
}

/// Get the exit code for an error
pub fn get_exit_code(error: AppError) -> ExitCode {
  case error {
    ConfigError(_, _) -> GeneralError
    DbError(_, _) -> DatabaseError
    NetError(_, _) -> NetworkError
    AuthenticationError(_, _) -> AuthError
    IoError(_, _) -> GeneralError
    UsageError(_, _) -> InvalidUsage
    ApplicationError(_, _) -> GeneralError
  }
}

/// Format error message for display
pub fn format_error(error: AppError) -> String {
  let #(title, message, hint) = case error {
    ConfigError(msg, h) -> #("Configuration Error", msg, h)
    DbError(msg, h) -> #("Database Error", msg, h)
    NetError(msg, h) -> #("Network Error", msg, h)
    AuthenticationError(msg, h) -> #("Authentication Error", msg, h)
    IoError(msg, h) -> #("File/IO Error", msg, h)
    UsageError(msg, h) -> #("Invalid Usage", msg, h)
    ApplicationError(msg, h) -> #("Application Error", msg, h)
  }

  let error_message = "❌ " <> title <> "\n  " <> message

  let hint_message = case hint {
    "" -> ""
    _ -> "\n\n💡 Suggestion:\n  " <> hint
  }

  error_message <> hint_message
}

/// Create a config error
pub fn config_error(message: String, hint: String) -> AppError {
  ConfigError(message, hint)
}

/// Create a database error
pub fn database_error(message: String, hint: String) -> AppError {
  DbError(message, hint)
}

/// Create a network error
pub fn network_error(message: String, hint: String) -> AppError {
  NetError(message, hint)
}

/// Create an auth error
pub fn auth_error(message: String, hint: String) -> AppError {
  AuthenticationError(message, hint)
}

/// Create an IO error
pub fn io_error(message: String, hint: String) -> AppError {
  IoError(message, hint)
}

/// Create a usage error
pub fn usage_error(message: String, hint: String) -> AppError {
  UsageError(message, hint)
}

/// Create a generic application error
pub fn app_error(message: String, hint: String) -> AppError {
  ApplicationError(message, hint)
}

/// Result alias for AppError
pub type AppResult(a) =
  Result(a, AppError)
