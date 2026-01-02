//! Delete a recipe step from Tandoor
//!
//! Deletes an existing recipe step from the Tandoor database.
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "id": 123}`
//!
//! JSON stdout: `{"success": true}`
//!   or `{"success": false, "error": "..."}`

// CLI binaries: exit and unwrap/expect are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::tandoor::{TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    tandoor: TandoorConfig,
    id: i64,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    let output = match run() {
        Ok(o) => o,
        Err(e) => Output {
            success: false,
            error: Some(e.to_string()),
        },
    };
    println!(
        "{}",
        serde_json::to_string(&output).expect("Failed to serialize output JSON")
    );
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
    client.delete_step(input.id)?;

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
        let json =
            r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "id": 7}"#;
        let input: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert_eq!(input.id, 7);
    }

    #[test]
    fn test_output_serialize() {
        let output = Output {
            success: true,
            error: None,
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":true"));
        assert!(!json.contains("error"));
    }
}
