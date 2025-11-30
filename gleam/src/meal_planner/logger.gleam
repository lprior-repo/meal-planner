// Logger module - wraps the logging package with convenience functions
// Ported from Go's fmt.Print* logging to Gleam's structured logging

import logging

// Re-export LogLevel type for convenience
pub type LogLevel = logging.LogLevel

/// Configure the default Erlang logger handler with pretty Gleam output
/// Should be called once at application startup
pub fn configure() -> Nil {
  logging.configure()
}

/// Set the log level for the logger
pub fn set_level(level: LogLevel) -> Nil {
  logging.set_level(level)
}

/// Log an info-level message
/// Use for general informational messages (replaces most fmt.Println in Go code)
pub fn info(message: String) -> Nil {
  logging.log(logging.Info, message)
}

/// Log a warning-level message
/// Use for warning conditions that should be noted
pub fn warning(message: String) -> Nil {
  logging.log(logging.Warning, message)
}

/// Log an error-level message
/// Use for error conditions (replaces error logging in Go code)
pub fn error(message: String) -> Nil {
  logging.log(logging.Error, message)
}

/// Log a debug-level message
/// Use for detailed debugging information
pub fn debug(message: String) -> Nil {
  logging.log(logging.Debug, message)
}

/// Log a notice-level message
/// Use for normal but significant conditions
pub fn notice(message: String) -> Nil {
  logging.log(logging.Notice, message)
}

/// Log a critical-level message
/// Use for critical conditions
pub fn critical(message: String) -> Nil {
  logging.log(logging.Critical, message)
}
