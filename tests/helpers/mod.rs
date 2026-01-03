//! Test helpers module
//!
//! Rust integration test convention: Code in `tests/helpers/` is NOT itself a test,
//! but provides utilities for other tests.
//!
//! Use in test files: `mod helpers;` then `use helpers::common::*;`

pub mod common;
pub mod recipe_nutrition_dsl;
pub mod recipe_selection_dsl;
pub mod recipe_selection_driver;
pub mod support;
