//! Windmill-compatible Meal Planner Library
//!
//! This library provides the core functionality for the meal planner application,
//! converted to Rust and made compatible with Windmill orchestration patterns.

// Re-export modules to make them available at the crate level
pub mod logging;
pub mod web;

// Meal planner domain modules
pub mod meal_planner {
    pub mod infrastructure;
}

// Public API exports
pub use logging::*;
pub use web::*;
