//// Logging Configuration for Meal Planner
////
//// This module provides:
//// - Logging configuration types
//// - Logging config loading from environment variables
//// - Log level utilities
//// - Logging configuration and setup
////
//// Configuration is loaded from environment variables:
//// - LOG_LEVEL (debug | info | warn | error, default: info)
//// - DEBUG_MODE (true | false, default: false)

import meal_planner/config/environment.{
  type ConfigError, type LogLevel, DebugLevel, ErrorLevel, InfoLevel, WarnLevel,
  get_env_bool, get_env_or, parse_log_level,
}

// ============================================================================
// TYPES
// ============================================================================

/// Logging configuration
///
/// Contains all settings needed for application logging:
/// - level: The minimum log level to display (Debug, Info, Warn, Error)
/// - debug_mode: Enable debug mode for verbose output
pub type LoggingConfig {
  LoggingConfig(level: LogLevel, debug_mode: Bool)
}

// ============================================================================
// CONFIGURATION LOADING
// ============================================================================

/// Load logging configuration from environment variables
///
/// Uses sensible defaults for development:
/// - level: InfoLevel
/// - debug_mode: False
///
/// Environment variables:
/// - LOG_LEVEL: debug | info | warn | error (default: info)
/// - DEBUG_MODE: true | false (default: false)
///
/// Returns Ok(LoggingConfig) always (no error cases for logging config)
pub fn load() -> Result(LoggingConfig, ConfigError) {
  let log_level = get_env_or("LOG_LEVEL", "info") |> parse_log_level
  let debug_mode = get_env_bool("DEBUG_MODE", False)

  Ok(LoggingConfig(level: log_level, debug_mode: debug_mode))
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/// Get log level as a string
///
/// Converts a LogLevel to its string representation.
/// Useful for displaying current log level or passing to external libraries.
pub fn get_log_level_string(level: LogLevel) -> String {
  case level {
    DebugLevel -> "debug"
    InfoLevel -> "info"
    WarnLevel -> "warn"
    ErrorLevel -> "error"
  }
}

/// Configure logging for the application
///
/// Sets up logging based on the provided configuration.
/// This function can be called at application startup to initialize logging.
///
/// Currently a no-op, but provides a hook for future logging setup
/// (e.g., setting up log files, remote logging, etc.)
pub fn configure_logging(config: LoggingConfig) -> Nil {
  // Future: Setup log files, remote logging, etc.
  // For now, just ensure the config is used to avoid warnings
  let _ = config
  Nil
}
