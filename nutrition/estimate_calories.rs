//! Estimate calories from macros (4/9/4 cal per gram).

use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Debug, Deserialize)]
struct Input { protein: f64, fat: f64, carbs: f64 }

#[derive(Debug, Serialize)]
struct Output { estimated_calories: f64, from_protein: f64, from_fat: f64, from_carbs: f64 }

fn main() -> io::Result<()> {
    let mut buf = String::new();
    io::stdin().read_to_string(&mut buf)?;
    let i: Input = serde_json::from_str(&buf).map_err(|e| io::Error::new(io::ErrorKind::InvalidInput, e))?;
    let fp = i.protein * 4.0;
    let ff = i.fat * 9.0;
    let fc = i.carbs * 4.0;
    let r = Output { estimated_calories: fp + ff + fc, from_protein: fp, from_fat: ff, from_carbs: fc };
    println!("{}", serde_json::to_string(&r).map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?);
    Ok(())
}
