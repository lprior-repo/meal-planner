//! Get a specific user from Tandoor by ID
//!
//! Retrieves detailed information about a specific user including profile data.
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "user_id": 123}`
//!
//! JSON stdout:
//!   `{"success": true, "user": {...}}`
//!   `{"success": false, "error": "..."}`

// CLI binaries: exit and unwrap/expect are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::tandoor::{TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    tandoor: TandoorConfig,
    user_id: i64,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    user: Option<serde_json::Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    let output = match run() {
        Ok(o) => o,
        Err(e) => Output {
            success: false,
            user: None,
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
    let user = client.get_user(input.user_id)?;

    Ok(Output {
        success: true,
        user: Some(serde_json::to_value(user)?),
        error: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_parsing() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "user_id": 42}"#;
        let input: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert_eq!(input.user_id, 42);
    }

    #[test]
    fn test_output_serialization_success() {
        let output = Output {
            success: true,
            user: Some(serde_json::json!({"id": 1, "username": "admin"})),
            error: None,
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize output JSON");
        assert!(json.contains("success"));
        assert!(!json.contains("error"));
    }

    #[test]
    fn test_output_serialization_error() {
        let output = Output {
            success: false,
            user: None,
            error: Some("User not found".to_string()),
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize output JSON");
        assert!(json.contains("success"));
        assert!(json.contains("error"));
    }
}
