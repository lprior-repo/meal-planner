//! Logging configuration for the Meal Planner application
//!
//! Provides structured logging utilities for the Windmill orchestration patterns.

use log::{info, warn, error, debug, trace};

/// Initialize application logging
pub fn init_logging() {
    // Initialize the basic logging system
    env_logger::init();
    info!("Logging initialized successfully");
}

/// Initialize logging with custom configuration
pub fn init_logging_with_config(log_level: &str, _log_format: &str) {
    // Set the log level via environment variable
    std::env::set_var("RUST_LOG", log_level);
    env_logger::init();
    info!("Logging initialized with custom configuration at level: {}", log_level);
}

/// Log application startup
pub fn log_startup() {
    info!("Meal Planner application starting up");
}

/// Log application shutdown
pub fn log_shutdown() {
    info!("Meal Planner application shutting down");
}

/// Log configuration loading
pub fn log_config_loading() {
    info!("Loading application configuration");
}

/// Log database connection
pub fn log_database_connection() {
    info!("Database connection established");
}

/// Log error
pub fn log_error(error: &dyn std::error::Error) {
    error!("Application error: {}", error);
}

/// Log warning
pub fn log_warning(message: &str) {
    warn!("Warning: {}", message);
}

/// Log debug information
pub fn log_debug(message: &str) {
    debug!("Debug: {}", message);
}

/// Log trace information
pub fn log_trace(message: &str) {
    trace!("Trace: {}", message);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_log_functions() {
        // These tests just ensure the functions compile and work
        log_startup();
        log_shutdown();
        log_config_loading();
        log_database_connection();
        log_error(&std::io::Error::other("test"));
        log_warning("test warning");
        log_debug("test debug");
        log_trace("test trace");
    }
}