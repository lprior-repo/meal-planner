//! NCP Calculate Deviation - Windmill Rust Lambda
//!
//! Calculates percentage deviation between actual nutrition and goals.

use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize)]
struct Input {
    goals: NutritionGoals,
    actual: NutritionData,
}

#[derive(Debug, Deserialize)]
struct NutritionGoals {
    daily_protein: f64,
    daily_fat: f64,
    daily_carbs: f64,
    daily_calories: f64,
}

#[derive(Debug, Deserialize)]
struct NutritionData {
    protein: f64,
    fat: f64,
    carbs: f64,
    calories: f64,
}

#[derive(Debug, Serialize)]
struct DeviationResult {
    protein_pct: f64,
    fat_pct: f64,
    carbs_pct: f64,
    calories_pct: f64,
}

fn calc_pct_deviation(goal: f64, actual: f64) -> f64 {
    if goal == 0.0 {
        0.0
    } else {
        ((actual - goal) / goal) * 100.0
    }
}

pub fn main(input: Input) -> DeviationResult {
    DeviationResult {
        protein_pct: calc_pct_deviation(input.goals.daily_protein, input.actual.protein),
        fat_pct: calc_pct_deviation(input.goals.daily_fat, input.actual.fat),
        carbs_pct: calc_pct_deviation(input.goals.daily_carbs, input.actual.carbs),
        calories_pct: calc_pct_deviation(input.goals.daily_calories, input.actual.calories),
    }
}
