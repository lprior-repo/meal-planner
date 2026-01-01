//! Get a specific keyword from Tandoor
//!
//! Retrieves detailed information about a specific keyword by ID.
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "keyword_id": 123}`
//!
//! JSON stdout:
//!   `{"success": true, "keyword": {...}}`
//!   `{"success": false, "error": "..."}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    tandoor: TandoorConfig,
    keyword_id: i64,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    keyword: Option<serde_json::Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    let output = match run() {
        Ok(o) => o,
        Err(e) => Output {
            success: false,
            keyword: None,
            error: Some(e.to_string()),
        },
    };
    println!("{}", serde_json::to_string(&output).unwrap());
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
    let keyword = client.get_keyword(input.keyword_id)?;

    Ok(Output {
        success: true,
        keyword: Some(serde_json::to_value(keyword)?),
        error: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_parsing() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "keyword_id": 42}"#;
        let input: Input = serde_json::from_str(json).unwrap();
        assert_eq!(input.keyword_id, 42);
    }

    #[test]
    fn test_output_serialization() {
        let output = Output {
            success: true,
            keyword: Some(serde_json::json!({"id": 1, "name": "dinner"})),
            error: None,
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"keyword\""));
        assert!(!json.contains("error"));
    }

    #[test]
    fn test_error_output_serialization() {
        let output = Output {
            success: false,
            keyword: None,
            error: Some("Keyword not found".to_string()),
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("\"error\":\"Keyword not found\""));
        assert!(!json.contains("keyword"));
    }
}
