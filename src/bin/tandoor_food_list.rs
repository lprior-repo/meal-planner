//! List foods from Tandoor
//!
//! Retrieves a paginated list of all foods in the Tandoor database.
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "page": 1, "page_size": 20}`
//!
//! JSON stdout:
//!   `{"success": true, "count": 123, "foods": [...]}`
//!   `{"success": false, "error": "..."}`

// CLI binaries: exit and unwrap/expect are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

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
    foods: Option<Vec<serde_json::Value>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    let output = match run() {
        Ok(o) => o,
        Err(e) => Output {
            success: false,
            count: None,
            foods: None,
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
    // Read input: prefer CLI arg, fall back to stdin
    let input: Input = if let Some(arg) = std::env::args().nth(1) {
        serde_json::from_str(&arg)?
    } else {
        let mut input_str = String::new();
        io::stdin().read_to_string(&mut input_str)?;
        serde_json::from_str(&input_str)?
    };

    let client = TandoorClient::new(&input.tandoor)?;

    let result = client.list_foods(input.page, input.page_size)?;

    Ok(Output {
        success: true,
        count: Some(result.count),
        foods: Some(
            result
                .results
                .into_iter()
                .map(|f| serde_json::to_value(f).expect("Unexpected None value"))
                .collect(),
        ),
        error: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_parsing_with_page() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "page": 1, "page_size": 20}"#;
        let input: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert_eq!(input.page, Some(1));
        assert_eq!(input.page_size, Some(20));
    }

    #[test]
    fn test_input_parsing_defaults() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}}"#;
        let input: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert_eq!(input.page, None);
        assert_eq!(input.page_size, None);
    }
}
