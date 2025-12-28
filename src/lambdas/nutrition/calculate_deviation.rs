//! NCP Calculate Deviation - Windmill Rust Lambda
//!
//! Calculates percentage deviation between actual nutrition and goals.
//! Windmill passes input via stdin as JSON and expects JSON output on stdout.

use meal_planner::meal_planner::infrastructure::{DeviationResult, NutritionData, NutritionGoals};
use serde::Deserialize;
use std::io::{self, Read};

#[derive(Debug, Deserialize)]
struct Input {
    goals: NutritionGoals,
    actual: NutritionData,
}

fn calc_pct_deviation(goal: f64, actual: f64) -> f64 {
    if goal == 0.0 {
        0.0
    } else {
        ((actual - goal) / goal) * 100.0
    }
}

fn calculate_deviation(input: Input) -> DeviationResult {
    DeviationResult {
        protein_pct: calc_pct_deviation(input.goals.daily_protein, input.actual.protein),
        fat_pct: calc_pct_deviation(input.goals.daily_fat, input.actual.fat),
        carbs_pct: calc_pct_deviation(input.goals.daily_carbs, input.actual.carbs),
        calories_pct: calc_pct_deviation(input.goals.daily_calories, input.actual.calories),
    }
}

fn main() -> io::Result<()> {
    // Read JSON input from stdin
    let mut buffer = String::new();
    io::stdin().read_to_string(&mut buffer)?;

    // Parse input
    let input: Input = serde_json::from_str(&buffer)
        .map_err(|e| io::Error::new(io::ErrorKind::InvalidInput, e))?;

    // Calculate deviation
    let result = calculate_deviation(input);

    // Output JSON to stdout
    println!(
        "{}",
        serde_json::to_string(&result)
            .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?
    );

    Ok(())
}
