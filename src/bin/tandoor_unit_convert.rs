//! Convert between different units of measurement for recipe ingredients
//!
//! JSON stdin:
//!   `{"from_unit": "cup", "to_unit": "ml", "amount": 2.5}`
//!
//! JSON stdout:
//!   `{"success": true, "converted_amount": 600.0, "from_unit": "cup", "to_unit": "ml"}`
//!   `{"success": false, "error": "..."}`
//!
//! This binary allows converting between different units of measurement for recipe ingredients.
//!
//! # Schema
//!
//! ## Input
//! ```json
//! {
//!   "from_unit": "string",
//!   "to_unit": "string",
//!   "amount": "number"
//! }
//! ```
//!
//! ## Output (success)
//! ```json
//! {
//!   "success": true,
//!   "converted_amount": "number",
//!   "from_unit": "string",
//!   "to_unit": "string"
//! }
//! ```
//!
//! ## Output (error)
//! ```json
//! {
//!   "success": false,
//!   "error": "string"
//! }
//! ```

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    from_unit: String,
    to_unit: String,
    amount: f64,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    converted_amount: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    from_unit: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    to_unit: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    match run() {
        Ok(output) => {
            println!(
                "{}",
                serde_json::to_string(&output).expect("Failed to serialize output JSON")
            );
        }
        Err(e) => {
            let error = Output {
                success: false,
                converted_amount: None,
                from_unit: None,
                to_unit: None,
                error: Some(e.to_string()),
            };
            println!(
                "{}",
                serde_json::to_string(&error).expect("Failed to serialize error JSON")
            );
            std::process::exit(1);
        }
    }
}

fn run() -> Result<Output, Box<dyn std::error::Error>> {
    let mut input = String::new();
    io::stdin().read_to_string(&mut input)?;

    let parsed: Input = serde_json::from_str(&input)?;

    // Validate amount is non-negative
    if parsed.amount < 0.0 {
        return Err("Amount cannot be negative".into());
    }

    // For demonstration purposes, we'll simulate the conversion
    // In a real implementation, this would query the Tandoor API for unit conversions

    // Simple hardcoded conversion factors for common units
    let converted_amount = match (parsed.from_unit.as_str(), parsed.to_unit.as_str()) {
        ("cup", "ml") => parsed.amount * 240.0,
        ("ml", "cup") => parsed.amount / 240.0,
        ("oz", "g") => parsed.amount * 28.35,
        ("g", "oz") => parsed.amount / 28.35,
        ("tbsp", "ml") => parsed.amount * 15.0,
        ("ml", "tbsp") => parsed.amount / 15.0,
        ("lb", "g") => parsed.amount * 453.592,
        ("g", "lb") => parsed.amount / 453.592,
        ("pt", "ml") => parsed.amount * 473.176,
        ("ml", "pt") => parsed.amount / 473.176,
        ("qt", "ml") => parsed.amount * 946.353,
        ("ml", "qt") => parsed.amount / 946.353,
        _ => {
            return Err(format!(
                "Conversion not supported between '{}' and '{}'",
                parsed.from_unit, parsed.to_unit
            )
            .into());
        }
    };

    Ok(Output {
        success: true,
        converted_amount: Some(converted_amount),
        from_unit: Some(parsed.from_unit),
        to_unit: Some(parsed.to_unit),
        error: None,
    })
}
