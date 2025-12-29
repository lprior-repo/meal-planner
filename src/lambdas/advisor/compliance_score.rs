//! Calculate overall compliance score (0-100).

use serde::{Deserialize, Serialize};
use std::io::{self, Read};
use meal_planner::shared::{NutritionData, NutritionGoals};

#[derive(Debug, Deserialize)]
struct Input {
    goals: NutritionGoals,
    actual: NutritionData,
}

#[derive(Debug, Serialize)]
struct Output {
    compliance_score: f64,
    protein_score: f64,
    fat_score: f64,
    carbs_score: f64,
    calories_score: f64,
    grade: String,
}

fn score(g: f64, a: f64) -> f64 {
    if g == 0.0 {
        100.0
    } else {
        (100.0 - ((a - g) / g).abs() * 100.0).max(0.0)
    }
}

fn grade(s: f64) -> &'static str {
    match s as u32 {
        90..=100 => "A",
        80..=89 => "B",
        70..=79 => "C",
        60..=69 => "D",
        _ => "F",
    }
}

#[tokio::main]
async fn main() -> io::Result<()> {
    let mut buf = String::new();
    io::stdin().read_to_string(&mut buf)?;
    let i: Input =
        serde_json::from_str(&buf).map_err(|e| io::Error::new(io::ErrorKind::InvalidInput, e))?;
    let ps = score(i.goals.daily_protein, i.actual.protein);
    let fs = score(i.goals.daily_fat, i.actual.fat);
    let cs = score(i.goals.daily_carbs, i.actual.carbs);
    let cals = score(i.goals.daily_calories, i.actual.calories);
    let total = ps * 0.3 + fs * 0.25 + cs * 0.25 + cals * 0.2;
    let r = Output {
        compliance_score: total,
        protein_score: ps,
        fat_score: fs,
        carbs_score: cs,
        calories_score: cals,
        grade: grade(total).to_string(),
    };
    println!(
        "{}",
        serde_json::to_string(&r).map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?
    );
    Ok(())
}
