//! Get a specific keyword from Tandoor
//!
//! Retrieves detailed information about a specific keyword by ID.
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "id": 123}`
//!
//! JSON stdout:
//!   `{"success": true, "keyword": {...}}`
//!   `{"success": false, "error": "..."}`

// CLI binaries: exit and unwrap/expect are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::tandoor::{Keyword, TandoorClient, TandoorConfig};
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
    keyword: Option<Keyword>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    match run() {
        Ok(output) => println!(
            "{}",
            serde_json::to_string(&output).expect("Failed to serialize output JSON")
        ),
        Err(e) => {
            let error = Output {
                success: false,
                keyword: None,
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
    let keyword = client.get_keyword(input.id)?;

    Ok(Output {
        success: true,
        keyword: Some(keyword),
        error: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_parsing() {
        let json =
            r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "id": 42}"#;
        let input: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert_eq!(input.id, 42);
        assert_eq!(input.tandoor.base_url, "http://localhost:8090");
    }

    #[test]
    fn test_output_serialization() {
        let output = Output {
            success: true,
            keyword: None,
            error: None,
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":true"));
    }

    #[test]
    fn test_error_output_serialization() {
        let output = Output {
            success: false,
            keyword: None,
            error: Some("Keyword not found".to_string()),
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("\"error\":\"Keyword not found\""));
    }
}
