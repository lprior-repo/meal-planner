//! Find minimum values across nutrition history.

mod types;
use types::{NutritionData, NutritionState};
use serde::Deserialize;
use std::io::{self, Read};

#[derive(Debug, Deserialize)]
struct Input { history: Vec<NutritionState> }

fn main() -> io::Result<()> {
    let mut buf = String::new();
    io::stdin().read_to_string(&mut buf)?;
    let i: Input = serde_json::from_str(&buf).map_err(|e| io::Error::new(io::ErrorKind::InvalidInput, e))?;
    let r = if i.history.is_empty() {
        NutritionData { protein: 0.0, fat: 0.0, carbs: 0.0, calories: 0.0 }
    } else {
        let f = &i.history[0].consumed;
        i.history[1..].iter().fold(
            NutritionData { protein: f.protein, fat: f.fat, carbs: f.carbs, calories: f.calories },
            |m, s| NutritionData {
                protein: m.protein.min(s.consumed.protein),
                fat: m.fat.min(s.consumed.fat),
                carbs: m.carbs.min(s.consumed.carbs),
                calories: m.calories.min(s.consumed.calories),
            },
        )
    };
    println!("{}", serde_json::to_string(&r).map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?);
    Ok(())
}
