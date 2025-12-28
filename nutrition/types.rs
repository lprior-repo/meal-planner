//! Shared types for nutrition domain

#![allow(dead_code)]

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

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeviationResult {
    pub protein_pct: f64,
    pub fat_pct: f64,
    pub carbs_pct: f64,
    pub calories_pct: f64,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct NutritionState {
    pub consumed: NutritionData,
    #[serde(default)]
    pub timestamp: Option<String>,
}

#[derive(Debug, Clone, Serialize)]
pub struct VariabilityResult {
    pub protein_std_dev: f64,
    pub fat_std_dev: f64,
    pub carbs_std_dev: f64,
    pub calories_std_dev: f64,
}

#[derive(Debug, Clone, Serialize)]
pub struct ToleranceCheckResult {
    pub within_tolerance: bool,
    pub max_deviation: f64,
    pub violations: Vec<String>,
}
