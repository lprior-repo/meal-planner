//! Batch update multiple recipes in Tandoor
//!
//! JSON stdin (Windmill format):
//!   `{"tandoor": {...}, "updates": [{"id": 1, "name": "..."}]}`
//!
//! JSON stdin (standalone format):
//!   `{"base_url": "...", "api_token": "...", "updates": [{"id": 1, "name": "..."}]}`
//!
//! JSON stdout:
//!   `{"success": true, "updated_count": N, "updated_ids": [...]}`
//!   `{"success": false, "error": "..."}`

// CLI binaries: exit and unwrap/expect are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::tandoor::{BatchUpdateRecipeRequest, TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

/// Input wrapper supporting both Windmill and standalone formats
#[derive(Deserialize)]
struct Input {
    /// Windmill resource format (optional)
    tandoor: Option<TandoorConfig>,
    /// Standalone format fields (optional)
    base_url: Option<String>,
    api_token: Option<String>,
    /// Recipe updates
    updates: Vec<BatchUpdateRecipeRequest>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    updated_count: Option<i32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    let output = match run() {
        Ok(o) => o,
        Err(e) => Output {
            success: false,
            updated_count: None,
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
    let mut input = String::new();
    io::stdin().read_to_string(&mut input)?;

    let parsed: Input = serde_json::from_str(&input)?;

    // Support both Windmill format (nested) and standalone format (flat)
    let config = match parsed.tandoor {
        Some(c) => c,
        None => TandoorConfig {
            base_url: parsed
                .base_url
                .ok_or_else(|| anyhow::anyhow!("base_url required"))?,
            api_token: parsed
                .api_token
                .ok_or_else(|| anyhow::anyhow!("api_token required"))?,
        },
    };

    if parsed.updates.is_empty() {
        return Err(anyhow::anyhow!(
            "updates array is required and must not be empty"
        ));
    }

    let client = TandoorClient::new(&config)?;
    let updates: Vec<serde_json::Value> = parsed
        .updates
        .into_iter()
        .map(serde_json::to_value)
        .collect::<Result<Vec<_>, _>>()?;
    let count = client.batch_update_recipes(&updates)?;

    Ok(Output {
        success: true,
        updated_count: Some(count),
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
            updated_count: Some(2),
            error: None,
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"updated_count\":2"));
    }

    #[test]
    fn test_error_output_serialization() {
        let output = Output {
            success: false,
            updated_count: None,
            error: Some("Connection failed".to_string()),
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("\"error\":\"Connection failed\""));
        assert!(!json.contains("updated_count"));
    }

    #[test]
    fn test_parse_windmill_input() {
        let json = r#"{
			"tandoor": {
				"base_url": "http://localhost:8090",
				"api_token": "test_token"
			},
			"updates": [{"id": 1, "name": "Updated Recipe"}]
		}"#;
        let parsed: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert!(parsed.tandoor.is_some());
        assert_eq!(parsed.updates.len(), 1);
        assert_eq!(
            parsed
                .updates
                .first()
                .expect("Expected at least one element")
                .id,
            1
        );
    }

    #[test]
    fn test_parse_standalone_input() {
        let json = r#"{
			"base_url": "http://localhost:8090",
			"api_token": "test_token",
			"updates": [{"id": 1, "name": "Updated Recipe"}]
		}"#;
        let parsed: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert!(parsed.tandoor.is_none());
        assert_eq!(parsed.base_url, Some("http://localhost:8090".to_string()));
    }
}
