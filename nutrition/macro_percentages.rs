//! Calculate macro percentages from nutrition data.

mod types;
use serde::Serialize;
use std::io::{self, Read};
use types::NutritionData;

#[derive(Debug, Serialize)]
struct Output {
    protein_pct: f64,
    fat_pct: f64,
    carbs_pct: f64,
}

fn main() -> io::Result<()> {
    let mut buf = String::new();
    io::stdin().read_to_string(&mut buf)?;
    let i: NutritionData =
        serde_json::from_str(&buf).map_err(|e| io::Error::new(io::ErrorKind::InvalidInput, e))?;
    let r = if i.calories == 0.0 {
        Output {
            protein_pct: 0.0,
            fat_pct: 0.0,
            carbs_pct: 0.0,
        }
    } else {
        Output {
            protein_pct: (i.protein * 4.0) / i.calories * 100.0,
            fat_pct: (i.fat * 9.0) / i.calories * 100.0,
            carbs_pct: (i.carbs * 4.0) / i.calories * 100.0,
        }
    };
    println!(
        "{}",
        serde_json::to_string(&r).map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?
    );
    Ok(())
}
