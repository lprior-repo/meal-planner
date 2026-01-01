//! Get a specific keyword from Tandoor
//!
//! Retrieves a keyword by ID.
//!
//! JSON stdin:
//!   `{"tandoor": {"base_url": "...", "api_token": "..."}, "id": 1}`
//!
//! JSON stdout:
//!   `{"success": true, "keyword": {...}}`
//!   `{"success": false, "error": "..."}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

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
        Ok(output) => println!("{}", serde_json::to_string(&output).unwrap()),
        Err(e) => {
            let error = Output {
                success: false,
                keyword: None,
                error: Some(e.to_string()),
            };
            println!("{}", serde_json::to_string(&error).unwrap());
            std::process::exit(1);
        }
    }
}

fn run() -> anyhow::Result<Output> {
    let mut input = String::new();
    io::stdin().read_to_string(&mut input)?;

    let parsed: Input = serde_json::from_str(&input)?;
    let client = TandoorClient::new(&parsed.tandoor)?;

    let keyword = client.get_keyword(parsed.id)?;

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
            r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "id": 1}"#;
        let parsed: Input = serde_json::from_str(json).unwrap();
        assert_eq!(parsed.id, 1);
        assert_eq!(parsed.tandoor.base_url, "http://localhost:8090");
    }

    #[test]
    fn test_output_serialization() {
        let output = Output {
            success: true,
            keyword: None,
            error: None,
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":true"));
    }
}
