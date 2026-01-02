//! Test support modules following Dave Farley's Functional Core / Imperative Shell
//!
//! ## Architecture
//!
//! - `binary_runner`: Execute binaries with JSON I/O (Shell)
//! - `credentials`: Load test credentials (Shell)
//! - `assertions`: Domain-specific test assertions (Core)

pub mod binary_runner;
pub mod credentials;
