//! Delete a meal plan from Tandoor
//!
//! Removes a meal plan by ID.
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "meal_plan_id": 123}`
//!
//! JSON stdout:
//!   `{"success": true}`
//!   `{"success": false, "error": "..."}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    /// Tandoor configuration
    tandoor: TandoorConfig,
    /// Meal plan ID to delete
    meal_plan_id: i64,
}

#[derive(Serialize)]
struct Output {
    success: bool,
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

    // Delete meal plan
    client.delete_meal_plan(input.meal_plan_id)?;

    Ok(Output {
        success: true,
        error: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_parsing() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "meal_plan_id": 42}"#;
        let input: Input = serde_json::from_str(json).unwrap();
        assert_eq!(input.meal_plan_id, 42);
    }

    #[test]
    fn test_output_serialization() {
        let output = Output {
            success: true,
            error: None,
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":true"));
        assert!(!json.contains("\"error\""));
    }

    #[test]
    fn test_error_output() {
        let output = Output {
            success: false,
            error: Some("Not found".to_string()),
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("Not found"));
    }
}
