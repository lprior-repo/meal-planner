//! Common types used across infrastructure lambdas

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

/// Nutrition state - a point in time with consumed nutrition
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct NutritionState {
    pub consumed: NutritionData,
    #[serde(default)]
    pub timestamp: Option<String>,
}

/// Variability result - standard deviation for each macro
#[derive(Debug, Clone, Serialize)]
pub struct VariabilityResult {
    pub protein_std_dev: f64,
    pub fat_std_dev: f64,
    pub carbs_std_dev: f64,
    pub calories_std_dev: f64,
}

/// Trend direction for nutrition metrics
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum TrendDirection {
    Increasing,
    Decreasing,
    Stable,
}

/// Trend analysis result for nutrition history
#[derive(Debug, Clone, Serialize)]
pub struct TrendAnalysis {
    pub protein_trend: TrendDirection,
    pub fat_trend: TrendDirection,
    pub carbs_trend: TrendDirection,
    pub calories_trend: TrendDirection,
    pub protein_change: f64,
    pub fat_change: f64,
    pub carbs_change: f64,
    pub calories_change: f64,
}

/// Consistency rate result
#[derive(Debug, Clone, Serialize)]
pub struct ConsistencyResult {
    pub consistency_rate: f64,
    pub days_within_tolerance: usize,
    pub total_days: usize,
}

/// Tolerance check output
#[derive(Debug, Clone, Serialize)]
pub struct ToleranceCheckResult {
    pub within_tolerance: bool,
    pub max_deviation: f64,
    pub violations: Vec<String>,
}
