//! Sum nutrition from multiple meals.

mod types;
use serde::Deserialize;
use std::io::{self, Read};
use types::{NutritionData, NutritionState};

#[derive(Debug, Deserialize)]
struct Input {
    meals: Vec<NutritionState>,
}

fn main() -> io::Result<()> {
    let mut buf = String::new();
    io::stdin().read_to_string(&mut buf)?;
    let i: Input =
        serde_json::from_str(&buf).map_err(|e| io::Error::new(io::ErrorKind::InvalidInput, e))?;
    let r = i.meals.iter().fold(
        NutritionData {
            protein: 0.0,
            fat: 0.0,
            carbs: 0.0,
            calories: 0.0,
        },
        |a, m| NutritionData {
            protein: a.protein + m.consumed.protein,
            fat: a.fat + m.consumed.fat,
            carbs: a.carbs + m.consumed.carbs,
            calories: a.calories + m.consumed.calories,
        },
    );
    println!(
        "{}",
        serde_json::to_string(&r).map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?
    );
    Ok(())
}
