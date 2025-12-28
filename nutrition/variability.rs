//! Calculate standard deviation for each macro.

mod types;
use types::{NutritionState, VariabilityResult};
use serde::Deserialize;
use std::io::{self, Read};

#[derive(Debug, Deserialize)]
struct Input { history: Vec<NutritionState> }

fn std_dev(vals: &[f64], mean: f64) -> f64 {
    if vals.len() <= 1 { return 0.0; }
    (vals.iter().map(|v| (v - mean).powi(2)).sum::<f64>() / vals.len() as f64).sqrt()
}

fn main() -> io::Result<()> {
    let mut buf = String::new();
    io::stdin().read_to_string(&mut buf)?;
    let i: Input = serde_json::from_str(&buf).map_err(|e| io::Error::new(io::ErrorKind::InvalidInput, e))?;
    let r = if i.history.is_empty() {
        VariabilityResult { protein_std_dev: 0.0, fat_std_dev: 0.0, carbs_std_dev: 0.0, calories_std_dev: 0.0 }
    } else {
        let n = i.history.len() as f64;
        let p: Vec<f64> = i.history.iter().map(|s| s.consumed.protein).collect();
        let f: Vec<f64> = i.history.iter().map(|s| s.consumed.fat).collect();
        let c: Vec<f64> = i.history.iter().map(|s| s.consumed.carbs).collect();
        let cal: Vec<f64> = i.history.iter().map(|s| s.consumed.calories).collect();
        VariabilityResult {
            protein_std_dev: std_dev(&p, p.iter().sum::<f64>() / n),
            fat_std_dev: std_dev(&f, f.iter().sum::<f64>() / n),
            carbs_std_dev: std_dev(&c, c.iter().sum::<f64>() / n),
            calories_std_dev: std_dev(&cal, cal.iter().sum::<f64>() / n),
        }
    };
    println!("{}", serde_json::to_string(&r).map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?);
    Ok(())
}
