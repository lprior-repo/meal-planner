//! Check if deviation is within tolerance.

use serde::Deserialize;
use std::io::{self, Read};
use meal_planner::shared::{DeviationResult, ToleranceCheckResult};

#[derive(Debug, Deserialize)]
struct Input {
    deviation: DeviationResult,
    tolerance_pct: f64,
}

#[tokio::main]
async fn main() -> io::Result<()> {
    let mut buf = String::new();
    io::stdin().read_to_string(&mut buf)?;
    let i: Input =
        serde_json::from_str(&buf).map_err(|e| io::Error::new(io::ErrorKind::InvalidInput, e))?;
    let d = &i.deviation;
    let t = i.tolerance_pct;
    let mut v = Vec::new();
    if d.protein_pct.abs() > t {
        v.push(format!("protein: {:.1}%", d.protein_pct));
    }
    if d.fat_pct.abs() > t {
        v.push(format!("fat: {:.1}%", d.fat_pct));
    }
    if d.carbs_pct.abs() > t {
        v.push(format!("carbs: {:.1}%", d.carbs_pct));
    }
    let r = ToleranceCheckResult {
        within_tolerance: v.is_empty(),
        max_deviation: d
            .protein_pct
            .abs()
            .max(d.fat_pct.abs())
            .max(d.carbs_pct.abs()),
        violations: v,
    };
    println!(
        "{}",
        serde_json::to_string(&r).map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?
    );
    Ok(())
}
