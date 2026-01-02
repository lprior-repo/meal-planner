//! Test Helpers Module - Kent Beck TDD Style
//!
//! This module provides test utilities following TDD best practices:
//! - **Test Builders**: Fluent builders for creating test data with sensible defaults
//! - **Assertion Helpers**: Enhanced assertions using pretty_assertions for better diffs
//! - **Parameterized Test Support**: Templates for rstest-based table-driven tests
//!
//! # Kent Beck's TDD Principles Applied
//!
//! 1. **Arrange-Act-Assert**: Builders help with clear "Arrange" phases
//! 2. **One Assertion Per Test**: Focus tests on single behaviors
//! 3. **Test Data Builders**: Reduce duplication, make intent clear
//! 4. **Parameterized Tests**: Use rstest for table-driven tests
//!
//! # Example Usage
//!
//! ```rust,ignore
//! use crate::test_helpers::*;
//!
//! #[test]
//! fn test_food_entry_creation() {
//!     // Arrange - using builder
//!     let entry = FoodEntryBuilder::default()
//!         .with_food_id("12345")
//!         .with_calories(200.0)
//!         .build();
//!
//!     // Act
//!     let json = serde_json::to_string(&entry).unwrap();
//!
//!     // Assert - clear, focused assertion
//!     assert_contains(&json, "12345");
//! }
//! ```
//!
//! Test code allows certain clippy lints that are too strict for test utilities
#![allow(clippy::indexing_slicing)]
#![allow(clippy::return_self_not_must_use)]
#![allow(clippy::option_if_let_else)]
#![allow(clippy::cast_lossless)]
// Note: #![cfg(test)] is set in mod.rs

// Re-export testing libraries for convenience
pub use pretty_assertions::{assert_eq, assert_ne};
pub use rstest::*;

use crate::fatsecret::foods::{FoodId, Nutrition, ServingId};
use crate::fatsecret::weight::{WeightDaySummary, WeightEntry, WeightMonthSummary, WeightUpdate};

// =============================================================================
// Assertion Helpers
// =============================================================================

/// Assert that a string contains a substring
#[track_caller]
pub fn assert_contains(haystack: &str, needle: &str) {
    assert!(
        haystack.contains(needle),
        "Expected string to contain '{}'\n\nActual string:\n{}",
        needle,
        haystack
    );
}

/// Assert that a Result is Ok and return the value
#[track_caller]
pub fn assert_ok<T, E: std::fmt::Debug>(result: Result<T, E>) -> T {
    match result {
        Ok(value) => value,
        Err(e) => panic!("Expected Ok, got Err: {:?}", e),
    }
}

/// Assert that a Result is Err
#[track_caller]
pub fn assert_err<T: std::fmt::Debug, E>(result: Result<T, E>) -> E {
    match result {
        Ok(value) => panic!("Expected Err, got Ok: {:?}", value),
        Err(e) => e,
    }
}

/// Assert that an Option is Some and return the value
#[track_caller]
pub fn assert_some<T>(option: Option<T>) -> T {
    match option {
        Some(value) => value,
        None => panic!("Expected Some, got None"),
    }
}

/// Assert that an Option is None
#[track_caller]
pub fn assert_none<T: std::fmt::Debug>(option: Option<T>) {
    if let Some(value) = option {
        panic!("Expected None, got Some: {:?}", value);
    }
}

/// Assert that two floats are approximately equal
#[track_caller]
pub fn assert_float_eq(actual: f64, expected: f64) {
    assert!(
        (actual - expected).abs() < f64::EPSILON,
        "Float values not equal\n  actual: {}\n  expected: {}",
        actual,
        expected
    );
}

/// Assert that two floats are approximately equal within a tolerance
#[track_caller]
pub fn assert_float_near(actual: f64, expected: f64, tolerance: f64) {
    assert!(
        (actual - expected).abs() < tolerance,
        "Float values not within tolerance {}\n  actual: {}\n  expected: {}",
        tolerance,
        actual,
        expected
    );
}

// =============================================================================
// Test Builders - Nutrition
// =============================================================================

/// Builder for Nutrition test data
#[derive(Debug, Clone)]
pub struct NutritionBuilder {
    calories: f64,
    carbohydrate: f64,
    protein: f64,
    fat: f64,
    saturated_fat: Option<f64>,
    fiber: Option<f64>,
    sugar: Option<f64>,
    sodium: Option<f64>,
}

impl Default for NutritionBuilder {
    fn default() -> Self {
        Self {
            calories: 100.0,
            carbohydrate: 10.0,
            protein: 5.0,
            fat: 3.0,
            saturated_fat: None,
            fiber: None,
            sugar: None,
            sodium: None,
        }
    }
}

impl NutritionBuilder {
    /// Create a new builder with default values
    pub fn new() -> Self {
        Self::default()
    }

    /// Set calories
    pub fn with_calories(mut self, calories: f64) -> Self {
        self.calories = calories;
        self
    }

    /// Set carbohydrates
    pub fn with_carbohydrate(mut self, carbohydrate: f64) -> Self {
        self.carbohydrate = carbohydrate;
        self
    }

    /// Set protein
    pub fn with_protein(mut self, protein: f64) -> Self {
        self.protein = protein;
        self
    }

    /// Set fat
    pub fn with_fat(mut self, fat: f64) -> Self {
        self.fat = fat;
        self
    }

    /// Set saturated fat
    pub fn with_saturated_fat(mut self, saturated_fat: f64) -> Self {
        self.saturated_fat = Some(saturated_fat);
        self
    }

    /// Set fiber
    pub fn with_fiber(mut self, fiber: f64) -> Self {
        self.fiber = Some(fiber);
        self
    }

    /// Set sugar
    pub fn with_sugar(mut self, sugar: f64) -> Self {
        self.sugar = Some(sugar);
        self
    }

    /// Set sodium
    pub fn with_sodium(mut self, sodium: f64) -> Self {
        self.sodium = Some(sodium);
        self
    }

    /// Build the Nutrition struct
    pub fn build(self) -> Nutrition {
        Nutrition {
            calories: self.calories,
            carbohydrate: self.carbohydrate,
            protein: self.protein,
            fat: self.fat,
            saturated_fat: self.saturated_fat,
            polyunsaturated_fat: None,
            monounsaturated_fat: None,
            trans_fat: None,
            cholesterol: None,
            sodium: self.sodium,
            potassium: None,
            fiber: self.fiber,
            sugar: self.sugar,
            added_sugars: None,
            vitamin_a: None,
            vitamin_c: None,
            vitamin_d: None,
            calcium: None,
            iron: None,
        }
    }

    /// Build as JSON string
    pub fn build_json(self) -> String {
        serde_json::to_string(&self.build()).expect("Failed to serialize nutrition")
    }
}

// =============================================================================
// Test Builders - Weight
// =============================================================================

/// Builder for WeightEntry test data
#[derive(Debug, Clone)]
pub struct WeightEntryBuilder {
    date_int: i32,
    weight_kg: f64,
    weight_comment: Option<String>,
}

impl Default for WeightEntryBuilder {
    fn default() -> Self {
        Self {
            date_int: 19723, // A default date (days since epoch)
            weight_kg: 75.0,
            weight_comment: None,
        }
    }
}

impl WeightEntryBuilder {
    /// Create a new builder with default values
    pub fn new() -> Self {
        Self::default()
    }

    /// Set the date as days since Unix epoch
    pub fn with_date_int(mut self, date_int: i32) -> Self {
        self.date_int = date_int;
        self
    }

    /// Set the weight in kilograms
    pub fn with_weight_kg(mut self, weight_kg: f64) -> Self {
        self.weight_kg = weight_kg;
        self
    }

    /// Set an optional comment
    pub fn with_comment(mut self, comment: impl Into<String>) -> Self {
        self.weight_comment = Some(comment.into());
        self
    }

    /// Build the WeightEntry struct
    pub fn build(self) -> WeightEntry {
        WeightEntry {
            date_int: self.date_int,
            weight_kg: self.weight_kg,
            weight_comment: self.weight_comment,
        }
    }

    /// Build as JSON string
    pub fn build_json(self) -> String {
        format!(
            r#"{{"date_int": "{}", "weight_kg": "{}"{}}}"#,
            self.date_int,
            self.weight_kg,
            self.weight_comment
                .as_ref()
                .map_or(String::new(), |c| format!(r#", "weight_comment": "{}""#, c))
        )
    }
}

/// Builder for WeightUpdate test data
#[derive(Debug, Clone)]
pub struct WeightUpdateBuilder {
    current_weight_kg: f64,
    date_int: i32,
    goal_weight_kg: Option<f64>,
    height_cm: Option<f64>,
    comment: Option<String>,
}

impl Default for WeightUpdateBuilder {
    fn default() -> Self {
        Self {
            current_weight_kg: 75.0,
            date_int: 19723,
            goal_weight_kg: None,
            height_cm: None,
            comment: None,
        }
    }
}

impl WeightUpdateBuilder {
    /// Create a new builder with default values
    pub fn new() -> Self {
        Self::default()
    }

    /// Set the current weight in kilograms
    pub fn with_current_weight_kg(mut self, weight: f64) -> Self {
        self.current_weight_kg = weight;
        self
    }

    /// Set the date as days since Unix epoch
    pub fn with_date_int(mut self, date_int: i32) -> Self {
        self.date_int = date_int;
        self
    }

    /// Set the goal weight
    pub fn with_goal_weight_kg(mut self, goal: f64) -> Self {
        self.goal_weight_kg = Some(goal);
        self
    }

    /// Set the height
    pub fn with_height_cm(mut self, height: f64) -> Self {
        self.height_cm = Some(height);
        self
    }

    /// Set a comment
    pub fn with_comment(mut self, comment: impl Into<String>) -> Self {
        self.comment = Some(comment.into());
        self
    }

    /// Build the WeightUpdate struct
    pub fn build(self) -> WeightUpdate {
        WeightUpdate {
            current_weight_kg: self.current_weight_kg,
            date_int: self.date_int,
            goal_weight_kg: self.goal_weight_kg,
            height_cm: self.height_cm,
            comment: self.comment,
        }
    }
}

/// Builder for WeightMonthSummary test data
#[derive(Debug, Clone)]
pub struct WeightMonthSummaryBuilder {
    from_date_int: i32,
    to_date_int: i32,
    days: Vec<WeightDaySummary>,
}

impl Default for WeightMonthSummaryBuilder {
    fn default() -> Self {
        Self {
            from_date_int: 19723,
            to_date_int: 19753,
            days: Vec::new(),
        }
    }
}

impl WeightMonthSummaryBuilder {
    /// Create a new builder with default values
    pub fn new() -> Self {
        Self::default()
    }

    /// Set the date range
    pub fn with_date_range(mut self, from: i32, to: i32) -> Self {
        self.from_date_int = from;
        self.to_date_int = to;
        self
    }

    /// Add a day's weight measurement
    pub fn with_day(mut self, date_int: i32, weight_kg: f64) -> Self {
        self.days.push(WeightDaySummary {
            date_int,
            weight_kg,
        });
        self
    }

    /// Add multiple days with linear weight progression
    pub fn with_linear_progression(
        mut self,
        start_weight: f64,
        end_weight: f64,
        days: i32,
    ) -> Self {
        let weight_change_per_day = (end_weight - start_weight) / (days as f64 - 1.0);
        for i in 0..days {
            self.days.push(WeightDaySummary {
                date_int: self.from_date_int + i,
                weight_kg: start_weight + (weight_change_per_day * i as f64),
            });
        }
        self
    }

    /// Build the WeightMonthSummary struct
    pub fn build(self) -> WeightMonthSummary {
        WeightMonthSummary {
            from_date_int: self.from_date_int,
            to_date_int: self.to_date_int,
            days: self.days,
        }
    }
}

// =============================================================================
// ID Helpers
// =============================================================================

/// Create a FoodId for testing
pub fn food_id(id: &str) -> FoodId {
    FoodId::new(id)
}

/// Create a ServingId for testing
pub fn serving_id(id: &str) -> ServingId {
    ServingId::new(id)
}

// =============================================================================
// JSON Fixtures Module
// =============================================================================

/// Pre-built JSON fixtures for common test scenarios
pub mod fixtures {
    /// A minimal valid Nutrition JSON
    pub const MINIMAL_NUTRITION_JSON: &str = r#"{
        "calories": 100,
        "carbohydrate": 10,
        "protein": 5,
        "fat": 3
    }"#;

    /// A complete Nutrition JSON with all fields
    pub const FULL_NUTRITION_JSON: &str = r#"{
        "calories": 200.0,
        "carbohydrate": 25.0,
        "protein": 20.0,
        "fat": 8.0,
        "saturated_fat": 2.0,
        "polyunsaturated_fat": 3.0,
        "monounsaturated_fat": 2.5,
        "trans_fat": 0.1,
        "cholesterol": 50.0,
        "sodium": 400.0,
        "potassium": 300.0,
        "fiber": 5.0,
        "sugar": 10.0,
        "added_sugars": 5.0,
        "vitamin_a": 10.0,
        "vitamin_c": 50.0,
        "vitamin_d": 25.0,
        "calcium": 15.0,
        "iron": 8.0
    }"#;

    /// A minimal WeightEntry JSON
    pub const MINIMAL_WEIGHT_ENTRY_JSON: &str = r#"{
        "date_int": "19723",
        "weight_kg": "75.5"
    }"#;

    /// A WeightEntry JSON with comment
    pub const WEIGHT_ENTRY_WITH_COMMENT_JSON: &str = r#"{
        "date_int": "19723",
        "weight_kg": "75.5",
        "weight_comment": "Morning weigh-in"
    }"#;
}

// =============================================================================
// Parameterized Test Templates
// =============================================================================

/// Common test case for string-or-number deserialization
#[derive(Debug)]
pub struct FlexibleNumberTestCase<'a> {
    pub name: &'a str,
    pub json_value: &'a str,
    pub expected: f64,
}

/// Common test cases for flexible number parsing
pub const FLEXIBLE_NUMBER_CASES: &[FlexibleNumberTestCase] = &[
    FlexibleNumberTestCase {
        name: "integer as number",
        json_value: "100",
        expected: 100.0,
    },
    FlexibleNumberTestCase {
        name: "float as number",
        json_value: "100.5",
        expected: 100.5,
    },
    FlexibleNumberTestCase {
        name: "integer as string",
        json_value: r#""100""#,
        expected: 100.0,
    },
    FlexibleNumberTestCase {
        name: "float as string",
        json_value: r#""100.5""#,
        expected: 100.5,
    },
    FlexibleNumberTestCase {
        name: "zero",
        json_value: "0",
        expected: 0.0,
    },
    FlexibleNumberTestCase {
        name: "negative",
        json_value: "-50.5",
        expected: -50.5,
    },
];

// =============================================================================
// Module Tests
// =============================================================================

#[cfg(test)]
mod tests {
    // Import specific items to avoid conflict with assert_eq from super::*
    use super::{
        assert_contains, assert_err, assert_float_eq, assert_float_near, assert_ok,
        NutritionBuilder, WeightEntryBuilder, WeightMonthSummaryBuilder,
    };
    use pretty_assertions::assert_eq;

    #[test]
    fn test_nutrition_builder_defaults() {
        let nutrition = NutritionBuilder::new().build();

        assert_float_eq(nutrition.calories, 100.0);
        assert_float_eq(nutrition.carbohydrate, 10.0);
        assert_float_eq(nutrition.protein, 5.0);
        assert_float_eq(nutrition.fat, 3.0);
    }

    #[test]
    fn test_nutrition_builder_fluent() {
        let nutrition = NutritionBuilder::new()
            .with_calories(200.0)
            .with_protein(30.0)
            .with_fiber(5.0)
            .build();

        assert_float_eq(nutrition.calories, 200.0);
        assert_float_eq(nutrition.protein, 30.0);
        assert_eq!(nutrition.fiber, Some(5.0));
    }

    #[test]
    fn test_weight_entry_builder() {
        let entry = WeightEntryBuilder::new()
            .with_date_int(20000)
            .with_weight_kg(80.5)
            .with_comment("After workout")
            .build();

        assert_eq!(entry.date_int, 20000);
        assert_float_eq(entry.weight_kg, 80.5);
        assert_eq!(entry.weight_comment, Some("After workout".to_string()));
    }

    #[test]
    fn test_weight_month_summary_builder_with_progression() {
        let summary = WeightMonthSummaryBuilder::new()
            .with_date_range(19723, 19733)
            .with_linear_progression(80.0, 78.0, 5)
            .build();

        assert_eq!(summary.days.len(), 5);
        assert_float_eq(summary.days[0].weight_kg, 80.0);
        // Last day should be 78.0 (linear from 80 to 78 in 5 steps)
        assert_float_near(summary.days[4].weight_kg, 78.0, 0.01);
    }

    #[test]
    fn test_assert_float_eq_passes() {
        assert_float_eq(100.0, 100.0);
    }

    #[test]
    #[should_panic(expected = "Float values not equal")]
    fn test_assert_float_eq_fails() {
        assert_float_eq(100.0, 101.0);
    }

    #[test]
    fn test_assert_contains_passes() {
        assert_contains("hello world", "world");
    }

    #[test]
    #[should_panic(expected = "Expected string to contain")]
    fn test_assert_contains_fails() {
        assert_contains("hello world", "foo");
    }

    #[test]
    fn test_assert_ok() {
        let result: Result<i32, &str> = Ok(42);
        assert_eq!(assert_ok(result), 42);
    }

    #[test]
    fn test_assert_err() {
        let result: Result<i32, &str> = Err("error");
        assert_eq!(assert_err(result), "error");
    }
}
