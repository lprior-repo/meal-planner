//! Core functionality shared across the application
//!
//! This module contains foundational utilities including error handling and logging.

pub mod errors;
pub mod logging;

// Re-export commonly used items for convenience
pub use errors::{Error, Result as CoreResult};
pub use logging::init_logging;
