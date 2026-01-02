//! Get a specific meal plan from Tandoor
//!
//! Retrieves detailed meal plan information by ID.
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "meal_plan_id": 123}`
//!
//! JSON stdout:
//!   `{"success": true, "meal_plan": {...}}`
//!   `{"success": false, "error": "..."}`

// CLI binaries: exit and unwrap/expect are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::tandoor::{TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    /// Tandoor configuration
    tandoor: TandoorConfig,
    /// Meal plan ID to retrieve
    meal_plan_id: i64,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    meal_plan: Option<serde_json::Value>,
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
                meal_plan: None,
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

    // Get meal plan
    let meal_plan = client.get_meal_plan(input.meal_plan_id)?;

    Ok(Output {
        success: true,
        meal_plan: Some(serde_json::to_value(meal_plan)?),
        error: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_parsing() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "meal_plan_id": 42}"#;
        let input: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert_eq!(input.meal_plan_id, 42);
    }

    #[test]
    fn test_output_serialization() {
        let output = Output {
            success: true,
            meal_plan: Some(serde_json::json!({"id": 1, "recipe_name": "Test"})),
            error: None,
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"id\":1"));
    }

    #[test]
    fn test_error_output() {
        let output = Output {
            success: false,
            meal_plan: None,
            error: Some("Not found".to_string()),
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("Not found"));
    }
}
