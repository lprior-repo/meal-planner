//! List recipe steps from Tandoor with pagination support
//!
//! Retrieves a paginated list of recipe steps from the Tandoor API.
//! Supports optional page number and page size parameters.
//!
//! JSON input (CLI arg or stdin, all optional):
//!   `{"tandoor": {...}, "page": 1, "page_size": 10}`
//!
//! JSON stdout: `{"success": true, "count": 42, "steps": [...]}`
//!   or `{"success": false, "error": "..."}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    tandoor: TandoorConfig,
    #[serde(default)]
    page: Option<u32>,
    #[serde(default)]
    page_size: Option<u32>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    count: Option<i64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    steps: Option<Vec<serde_json::Value>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    let output = match run() {
        Ok(o) => o,
        Err(e) => Output {
            success: false,
            count: None,
            steps: None,
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
    let paginated = client.list_steps(input.page, input.page_size)?;

    Ok(Output {
        success: true,
        count: Some(paginated.count),
        steps: Some(paginated.results),
        error: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_output_serialize() {
        let output = Output {
            success: true,
            count: Some(5),
            steps: Some(vec![]),
            error: None,
        };
        let json = serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"count\":5"));
    }

    #[test]
    fn test_input_parsing_with_pagination() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "page": 2, "page_size": 20}"#;
        let input: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert_eq!(input.page, Some(2));
        assert_eq!(input.page_size, Some(20));
    }
}
