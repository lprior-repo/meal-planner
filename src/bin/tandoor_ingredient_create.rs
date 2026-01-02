//! Create a new ingredient in Tandoor
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "food": 1, "unit": 2, "amount": 3.5}`
//!
//! JSON stdout: `{"success": true, "id": 123}`
//!   or on error: `{"success": false, "error": "..."}`

// CLI binaries: exit and unwrap/expect are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::tandoor::{CreateIngredientRequestData, TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    /// Tandoor configuration
    tandoor: TandoorConfig,
    /// Food ID
    food: i64,
    /// Unit ID (optional)
    #[serde(default)]
    unit: Option<i64>,
    /// Amount (optional)
    #[serde(default)]
    amount: Option<f64>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    id: Option<i64>,
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
                id: None,
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

fn run() -> anyhow::Result<Output> {
    // Read input: prefer CLI arg, fall back to stdin
    let input: Input = if let Some(arg) = std::env::args().nth(1) {
        serde_json::from_str(&arg)?
    } else {
        let mut input_str = String::new();
        io::stdin().read_to_string(&mut input_str)?;
        serde_json::from_str(&input_str)?
    };

    let client = TandoorClient::new(&input.tandoor)?;

    let request = CreateIngredientRequestData {
        food: input.food,
        unit: input.unit,
        amount: input.amount,
    };

    let created = client.create_ingredient(&request)?;

    Ok(Output {
        success: true,
        id: Some(created.id),
        error: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_output_serialization() {
        let output = Output {
            success: true,
            id: Some(42),
            error: None,
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"id\":42"));
    }

    #[test]
    fn test_error_output_serialization() {
        let output = Output {
            success: false,
            id: None,
            error: Some("invalid food id".to_string()),
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("invalid food id"));
    }
}
