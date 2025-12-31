//! Update an existing ingredient in Tandoor
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "id": 123, "food": 1, "unit": 2, "amount": 3.5}`
//!
//! JSON stdout: `{"success": true, "id": 123}`
//!   or on error: `{"success": false, "error": "..."}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{TandoorClient, TandoorConfig, UpdateIngredientRequest};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    /// Tandoor configuration
    tandoor: TandoorConfig,
    /// Ingredient ID to update
    id: i64,
    /// Food ID (optional)
    #[serde(default)]
    food: Option<i64>,
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
            println!("{}", serde_json::to_string(&output).unwrap());
        }
        Err(e) => {
            let error = Output {
                success: false,
                id: None,
                error: Some(e.to_string()),
            };
            println!("{}", serde_json::to_string(&error).unwrap());
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

    let request = UpdateIngredientRequest {
        food: input.food,
        unit: input.unit,
        amount: input.amount,
    };

    let updated = client.update_ingredient(input.id, &request)?;

    Ok(Output {
        success: true,
        id: Some(updated.id),
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
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"id\":42"));
    }

    #[test]
    fn test_error_output_serialization() {
        let output = Output {
            success: false,
            id: None,
            error: Some("ingredient not found".to_string()),
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("ingredient not found"));
    }
}
