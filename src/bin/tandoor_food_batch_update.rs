//! Batch update foods in Tandoor
//!
//! Updates multiple foods in the Tandoor database with specified changes.
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "updates": [{"id": 123, "name": "New Name", "description": "..."}]}`
//!
//! JSON stdout:
//!   `{"success": true, "count": 5}`
//!   `{"success": false, "error": "..."}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{BatchUpdateFoodRequest, TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    tandoor: TandoorConfig,
    updates: Vec<BatchUpdateFoodRequest>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    count: Option<i32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    let output = match run() {
        Ok(o) => o,
        Err(e) => Output {
            success: false,
            count: None,
            error: Some(e.to_string()),
        },
    };
    println!("{}", serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON"));
    if !output.success {
        std::process::exit(1);
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
    let updates: Vec<serde_json::Value> = input
        .updates
        .into_iter()
        .map(serde_json::to_value)
        .collect::<Result<Vec<_>, _>>()?;
    let count = client.batch_update_foods(&updates)?;

    Ok(Output {
        success: true,
        count: Some(count),
        error: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_parsing() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "updates": [{"id": 1, "name": "Updated Food"}]}"#;
        let input: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert_eq!(input.updates.len(), 1);
        assert_eq!(input.updates.first().expect("Expected at least one element").id, 1);
        assert_eq!(
            input.updates.first().expect("Expected at least one element").name,
            Some("Updated Food".to_string())
        );
    }

    #[test]
    fn test_input_parsing_multiple_updates() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "updates": [{"id": 1, "name": "Food 1"}, {"id": 2, "description": "Food 2"}]}"#;
        let input: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert_eq!(input.updates.len(), 2);
    }

    #[test]
    fn test_output_serialization_success() {
        let output = Output {
            success: true,
            count: Some(3),
            error: None,
        };
        let json = serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON");
        assert!(json.contains("success"));
        assert!(json.contains("count"));
        assert!(!json.contains("error"));
    }

    #[test]
    fn test_output_serialization_error() {
        let output = Output {
            success: false,
            count: None,
            error: Some("Batch update failed".to_string()),
        };
        let json = serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON");
        assert!(json.contains("success"));
        assert!(json.contains("error"));
    }
}
