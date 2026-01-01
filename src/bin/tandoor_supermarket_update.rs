//! Update a supermarket in Tandoor
//!
//! Updates an existing supermarket/store in the Tandoor database.
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "id": 123, "name": "Whole Foods Market"}`
//!
//! JSON stdout: `{"success": true, "id": 123}`
//!   or `{"success": false, "error": "..."}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{TandoorClient, TandoorConfig, UpdateSupermarketRequest};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    tandoor: TandoorConfig,
    id: i64,
    name: String,
    #[serde(default)]
    description: Option<String>,
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
    let output = match run() {
        Ok(o) => o,
        Err(e) => Output {
            success: false,
            id: None,
            error: Some(e.to_string()),
        },
    };
    println!("{}", serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON"));
    if !output.success {
        std::process::exit(1);
    }
}

fn run() -> anyhow::Result<Output> {
    let input: Input = if let Some(arg) = std::env::args().nth(1) {
        serde_json::from_str(&arg)?
    } else {
        let mut input_str = String::new();
        io::stdin().read_to_string(&mut input_str)?;
        serde_json::from_str(&input_str)?
    };

    let client = TandoorClient::new(&input.tandoor)?;
    let request = UpdateSupermarketRequest {
        name: Some(input.name),
        description: input.description,
    };

    client.update_supermarket(input.id, &serde_json::to_value(&request)?)?;

    Ok(Output {
        success: true,
        id: Some(input.id),
        error: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_parsing() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "id": 2, "name": "Target"}"#;
        let input: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert_eq!(input.id, 2);
        assert_eq!(input.name, "Target");
    }

    #[test]
    fn test_output_serialize() {
        let output = Output {
            success: true,
            id: Some(2),
            error: None,
        };
        let json = serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"id\":2"));
    }
}
