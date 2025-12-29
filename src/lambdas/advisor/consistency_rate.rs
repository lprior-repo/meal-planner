//! Calculate percentage of days that met nutrition goals within tolerance.

use serde::Deserialize;
use std::io::{self, Read};
use meal_planner::shared::{ConsistencyResult, NutritionGoals, NutritionState};

#[derive(Debug, Deserialize)]
struct Input {
    history: Vec<NutritionState>,
    goals: NutritionGoals,
    tolerance_pct: f64,
}

fn within(goals: &NutritionGoals, s: &NutritionState, tol: f64) -> bool {
    let dev = |g: f64, a: f64| {
        if g == 0.0 {
            0.0
        } else {
            ((a - g) / g).abs() * 100.0
        }
    };
    dev(goals.daily_protein, s.consumed.protein) <= tol
        && dev(goals.daily_fat, s.consumed.fat) <= tol
        && dev(goals.daily_carbs, s.consumed.carbs) <= tol
}

#[tokio::main]
async fn main() -> io::Result<()> {
    let mut buf = String::new();
    io::stdin().read_to_string(&mut buf)?;
    let i: Input =
        serde_json::from_str(&buf).map_err(|e| io::Error::new(io::ErrorKind::InvalidInput, e))?;
    let total = i.history.len();
    let within_count = i
        .history
        .iter()
        .filter(|s| within(&i.goals, s, i.tolerance_pct))
        .count();
    let r = ConsistencyResult {
        consistency_rate: if total == 0 {
            0.0
        } else {
            (within_count as f64 / total as f64) * 100.0
        },
        days_within_tolerance: within_count,
        total_days: total,
    };
    println!(
        "{}",
        serde_json::to_string(&r).map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?
    );
    Ok(())
}
