//! List keywords from Tandoor
//!
//! Retrieves all keywords with optional pagination.
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {"base_url": "...", "api_token": "..."}, "page": 1, "page_size": 50}`
//!
//! JSON stdout: `{"success": true, "count": N, "keywords": [...]}`
//!   or on error: `{"success": false, "error": "..."}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    /// Tandoor configuration
    tandoor: TandoorConfig,
    /// Page number (optional)
    #[serde(default)]
    page: Option<u32>,
    /// Page size (optional)
    #[serde(default)]
    page_size: Option<u32>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    count: Option<i64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    keywords: Option<Vec<serde_json::Value>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    match run() {
        Ok(output) => {
            println!("{}", serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON"));
        }
        Err(e) => {
            let error = Output {
                success: false,
                count: None,
                keywords: None,
                error: Some(e.to_string()),
            };
            println!("{}", serde_json::to_string(serde_json::to_string(&error).expect("Unexpected None value")error).expect("Failed to serialize error JSON"));
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
    let result = client.list_keywords(input.page, input.page_size)?;

    Ok(Output {
        success: true,
        count: Some(result.count),
        keywords: Some(
            result
                .results
                .into_iter()
                .map(|k| serde_json::to_value(k).expect("Unexpected None value"))
                .collect(),
        ),
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
            count: Some(5),
            keywords: Some(vec![]),
            error: None,
        };
        let json = serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"count\":5"));
    }

    #[test]
    fn test_error_output_serialization() {
        let output = Output {
            success: false,
            count: None,
            keywords: None,
            error: Some("test error".to_string()),
        };
        let json = serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("\"error\""));
    }
}
