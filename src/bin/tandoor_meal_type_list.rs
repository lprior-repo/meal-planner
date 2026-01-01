//! List all meal types from Tandoor
//!
//! Retrieves all meal types with optional pagination.
//!
//! JSON stdin:
//!   `{"tandoor": {"base_url": "...", "api_token": "..."}, "page": 1, "page_size": 10}`
//!
//! JSON stdout:
//!   `{"success": true, "count": 5, "meal_types": [...]}`
//!   `{"success": false, "error": "..."}`

// CLI binaries: exit and unwrap/expect are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::tandoor::{MealType, TandoorClient, TandoorConfig};
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
    meal_types: Option<Vec<MealType>>,
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
                count: None,
                meal_types: None,
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
    let mut input = String::new();
    io::stdin().read_to_string(&mut input)?;

    let parsed: Input = serde_json::from_str(&input)?;
    let client = TandoorClient::new(&parsed.tandoor)?;

    let result = client.list_meal_types(parsed.page, parsed.page_size)?;

    Ok(Output {
        success: true,
        count: Some(result.count),
        meal_types: Some(result.results),
        error: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_parsing() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}}"#;
        let parsed: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert_eq!(parsed.tandoor.base_url, "http://localhost:8090");
        assert_eq!(parsed.tandoor.api_token, "test");
        assert_eq!(parsed.page, None);
        assert_eq!(parsed.page_size, None);
    }

    #[test]
    fn test_input_with_pagination() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "page": 2, "page_size": 20}"#;
        let parsed: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert_eq!(parsed.page, Some(2));
        assert_eq!(parsed.page_size, Some(20));
    }

    #[test]
    fn test_output_serialization() {
        let output = Output {
            success: true,
            count: Some(5),
            meal_types: Some(vec![]),
            error: None,
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"count\":5"));
    }
}
