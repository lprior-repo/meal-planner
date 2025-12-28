//! Common types used across Windmill lambdas

use serde::{Deserialize, Serialize};

/// Nutrition goals with daily targets
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct NutritionGoals {
    pub daily_protein: f64,
    pub daily_fat: f64,
    pub daily_carbs: f64,
    pub daily_calories: f64,
}

/// Actual nutrition data consumed
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct NutritionData {
    pub protein: f64,
    pub fat: f64,
    pub carbs: f64,
    pub calories: f64,
}

/// Deviation result with percentage deviations
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeviationResult {
    pub protein_pct: f64,
    pub fat_pct: f64,
    pub carbs_pct: f64,
    pub calories_pct: f64,
}

/// Tolerance check output
#[derive(Debug, Clone, Serialize)]
pub struct ToleranceCheckResult {
    pub within_tolerance: bool,
    pub max_deviation: f64,
    pub violations: Vec<String>,
}

/// Standard error response
#[derive(Debug, Serialize)]
pub struct ErrorResponse {
    pub error: bool,
    pub message: String,
    pub details: Option<String>,
}

impl ErrorResponse {
    pub fn new(message: impl Into<String>) -> Self {
        Self {
            error: true,
            message: message.into(),
            details: None,
        }
    }

    pub fn with_details(message: impl Into<String>, details: impl Into<String>) -> Self {
        Self {
            error: true,
            message: message.into(),
            details: Some(details.into()),
        }
    }
}
