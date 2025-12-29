/// Shared types for advisor domain

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct NutritionGoals {
    pub daily_protein: f64,
    pub daily_fat: f64,
    pub daily_carbs: f64,
    pub daily_calories: f64,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct NutritionData {
    pub protein: f64,
    pub fat: f64,
    pub carbs: f64,
    pub calories: f64,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct NutritionState {
    pub consumed: NutritionData,
    #[serde(default)]
    pub timestamp: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum TrendDirection {
    Increasing,
    Decreasing,
    Stable,
}

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

#[derive(Debug, Clone, Serialize)]
pub struct ConsistencyResult {
    pub consistency_rate: f64,
    pub days_within_tolerance: usize,
    pub total_days: usize,
}
