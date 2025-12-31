//! List users from Tandoor
//!
//! Retrieves a paginated list of all users in the Tandoor database.
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "page": 1, "page_size": 20}`
//!
//! JSON stdout:
//!   `{"success": true, "count": 123, "users": [...]}`
//!   `{"success": false, "error": "..."}`

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
    users: Option<Vec<serde_json::Value>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    let output = match run() {
        Ok(o) => o,
        Err(e) => Output {
            success: false,
            count: None,
            users: None,
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
    let result = client.list_users(input.page, input.page_size)?;

    Ok(Output {
        success: true,
        count: Some(result.count),
        users: Some(
            result
                .results
                .into_iter()
                .map(|u| serde_json::to_value(u).unwrap())
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
        let input: Input = serde_json::from_str(json).unwrap();
        assert_eq!(input.page, Some(1));
        assert_eq!(input.page_size, Some(20));
    }

    #[test]
    fn test_input_parsing_defaults() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}}"#;
        let input: Input = serde_json::from_str(json).unwrap();
        assert_eq!(input.page, None);
        assert_eq!(input.page_size, None);
    }

    #[test]
    fn test_output_serialization_success() {
        let output = Output {
            success: true,
            count: Some(5),
            users: Some(vec![serde_json::json!({"id": 1, "username": "admin"})]),
            error: None,
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("success"));
        assert!(!json.contains("error"));
    }

    #[test]
    fn test_output_serialization_error() {
        let output = Output {
            success: false,
            count: None,
            users: None,
            error: Some("Failed to fetch users".to_string()),
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("success"));
        assert!(json.contains("error"));
    }
}
