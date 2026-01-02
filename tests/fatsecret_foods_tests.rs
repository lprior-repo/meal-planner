//! Unit tests for `FatSecret` Foods domain
//!
//! This module provides comprehensive test coverage for the foods domain including:
//! - Food type deserialization from JSON fixtures
//! - Serving calculation logic
//! - Nutrition data handling
//! - Error cases (missing fields, invalid data)
//! - Opaque ID type safety

#![allow(clippy::unwrap_used)]

pub mod fatsecret;

pub use fatsecret::*;
