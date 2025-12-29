//! Analyze trends in nutrition history (first half vs second half).

use serde::Deserialize;
use std::io::{self, Read};
use meal_planner::shared::{NutritionData, NutritionState, TrendAnalysis, TrendDirection};

#[derive(Debug, Deserialize)]
struct Input {
    history: Vec<NutritionState>,
    #[serde(default = "default_threshold")]
    threshold: f64,
}

fn default_threshold() -> f64 {
    5.0
}

fn avg(h: &[NutritionState]) -> NutritionData {
    if h.is_empty() {
        return NutritionData {
            protein: 0.0,
            fat: 0.0,
            carbs: 0.0,
            calories: 0.0,
        };
    }
    let n = h.len() as f64;
    let (p, f, c, cal) = h.iter().fold((0.0, 0.0, 0.0, 0.0), |a, s| {
        (
            a.0 + s.consumed.protein,
            a.1 + s.consumed.fat,
            a.2 + s.consumed.carbs,
            a.3 + s.consumed.calories,
        )
    });
    NutritionData {
        protein: p / n,
        fat: f / n,
        carbs: c / n,
        calories: cal / n,
    }
}

fn pct(first: f64, second: f64) -> f64 {
    if first == 0.0 {
        0.0
    } else {
        ((second - first) / first) * 100.0
    }
}

fn trend(c: f64, t: f64) -> TrendDirection {
    if c > t {
        TrendDirection::Increasing
    } else if c < -t {
        TrendDirection::Decreasing
    } else {
        TrendDirection::Stable
    }
}

#[tokio::main]
async fn main() -> io::Result<()> {
    let mut buf = String::new();
    io::stdin().read_to_string(&mut buf)?;
    let i: Input =
        serde_json::from_str(&buf).map_err(|e| io::Error::new(io::ErrorKind::InvalidInput, e))?;
    let r = if i.history.len() <= 1 {
        TrendAnalysis {
            protein_trend: TrendDirection::Stable,
            fat_trend: TrendDirection::Stable,
            carbs_trend: TrendDirection::Stable,
            calories_trend: TrendDirection::Stable,
            protein_change: 0.0,
            fat_change: 0.0,
            carbs_change: 0.0,
            calories_change: 0.0,
        }
    } else {
        let mid = i.history.len() / 2;
        let first = avg(&i.history[..mid]);
        let second = avg(&i.history[mid..]);
        let pc = pct(first.protein, second.protein);
        let fc = pct(first.fat, second.fat);
        let cc = pct(first.carbs, second.carbs);
        let calc = pct(first.calories, second.calories);
        TrendAnalysis {
            protein_trend: trend(pc, i.threshold),
            fat_trend: trend(fc, i.threshold),
            carbs_trend: trend(cc, i.threshold),
            calories_trend: trend(calc, i.threshold),
            protein_change: pc,
            fat_change: fc,
            carbs_change: cc,
            calories_change: calc,
        }
    };
    println!(
        "{}",
        serde_json::to_string(&r).map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?
    );
    Ok(())
}
