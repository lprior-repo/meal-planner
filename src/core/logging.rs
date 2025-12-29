//! Core logging configuration
//!
//! Provides centralized logging setup using tracing.

pub fn init_logging() {
    // Initialize simple logging
    // Use RUST_LOG environment variable for filtering
    tracing_subscriber::fmt()
        .init();
}
