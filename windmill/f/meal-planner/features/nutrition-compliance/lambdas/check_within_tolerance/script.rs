//! Check if deviations are within tolerance - Windmill Rust Lambda
//!
//! Windmill passes input via stdin as JSON and expects JSON output on stdout.

use serde::Deserialize;
use std::io::{self, Read};
use windmill_lambdas::{DeviationResult, ToleranceCheckResult};

#[derive(Debug, Deserialize)]
struct Input {
    deviation: DeviationResult,
    tolerance_pct: f64,
}

fn check_tolerance(input: Input) -> ToleranceCheckResult {
    let mut violations = Vec::new();
    
    if input.deviation.protein_pct.abs() > input.tolerance_pct {
        violations.push(format!(
            "Protein deviation {:.1}% exceeds tolerance",
            input.deviation.protein_pct
        ));
    }
    
    if input.deviation.fat_pct.abs() > input.tolerance_pct {
        violations.push(format!(
            "Fat deviation {:.1}% exceeds tolerance",
            input.deviation.fat_pct
        ));
    }
    
    if input.deviation.carbs_pct.abs() > input.tolerance_pct {
        violations.push(format!(
            "Carbs deviation {:.1}% exceeds tolerance",
            input.deviation.carbs_pct
        ));
    }
    
    let within_tolerance = violations.is_empty();
    
    let max_deviation = input
        .deviation
        .protein_pct
        .abs()
        .max(input.deviation.fat_pct.abs())
        .max(input.deviation.carbs_pct.abs());
    
    ToleranceCheckResult {
        within_tolerance,
        max_deviation,
        violations,
    }
}

fn main() -> io::Result<()> {
    // Read JSON input from stdin
    let mut buffer = String::new();
    io::stdin().read_to_string(&mut buffer)?;
    
    // Parse input
    let input: Input = serde_json::from_str(&buffer)
        .map_err(|e| io::Error::new(io::ErrorKind::InvalidInput, e))?;
    
    // Check tolerance
    let result = check_tolerance(input);
    
    // Output JSON to stdout
    println!("{}", serde_json::to_string(&result)
        .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?);
    
    Ok(())
}
