//! Calculate percentage deviation between actual nutrition and goals.

mod types;
use types::{DeviationResult, NutritionData, NutritionGoals};
use serde::Deserialize;
use std::io::{self, Read};

#[derive(Debug, Deserialize)]
struct Input { goals: NutritionGoals, actual: NutritionData }

fn pct(goal: f64, actual: f64) -> f64 {
    if goal == 0.0 { 0.0 } else { ((actual - goal) / goal) * 100.0 }
}

fn main() -> io::Result<()> {
    let mut buf = String::new();
    io::stdin().read_to_string(&mut buf)?;
    let i: Input = serde_json::from_str(&buf).map_err(|e| io::Error::new(io::ErrorKind::InvalidInput, e))?;
    let r = DeviationResult {
        protein_pct: pct(i.goals.daily_protein, i.actual.protein),
        fat_pct: pct(i.goals.daily_fat, i.actual.fat),
        carbs_pct: pct(i.goals.daily_carbs, i.actual.carbs),
        calories_pct: pct(i.goals.daily_calories, i.actual.calories),
    };
    println!("{}", serde_json::to_string(&r).map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?);
    Ok(())
}
