//! Get recipes related to a given recipe
//!
//! Retrieves recipes that are related/similar to the specified recipe based on shared
//! keywords, ingredients, or other similarity metrics.
//!
//! JSON stdin (Windmill format):
//!   `{"tandoor": {...}, "recipe_id": 123}`
//!
//! JSON stdin (standalone format):
//!   `{"base_url": "...", "api_token": "...", "recipe_id": 123}`
//!
//! JSON stdout:
//!   `{"success": true, "recipes": [...]}`
//!   `{"success": false, "error": "..."}`

// CLI binaries: exit and unwrap/expect are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::tandoor::{RecipeSummary, TandoorClient, TandoorConfig};
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
    /// Recipe ID to get related recipes for
    recipe_id: i64,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    recipes: Option<Vec<RecipeSummary>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    recipe_count: Option<usize>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    let output = match run() {
        Ok(o) => o,
        Err(e) => Output {
            success: false,
            recipes: None,
            recipe_count: None,
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

    let client = TandoorClient::new(&config)?;
    let recipes = client.get_related_recipes(parsed.recipe_id)?;

    let count = recipes.len();

    Ok(Output {
        success: true,
        recipes: Some(recipes),
        recipe_count: Some(count),
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
            recipes: Some(vec![]),
            recipe_count: Some(0),
            error: None,
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"recipe_count\":0"));
        assert!(json.contains("\"recipes\":[]"));
    }

    #[test]
    fn test_error_output_serialization() {
        let output = Output {
            success: false,
            recipes: None,
            recipe_count: None,
            error: Some("Recipe not found".to_string()),
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("\"error\":\"Recipe not found\""));
        assert!(!json.contains("recipe_count"));
    }

    #[test]
    fn test_parse_windmill_input() {
        let json = r#"{
			"tandoor": {
				"base_url": "http://localhost:8090",
				"api_token": "test_token"
			},
			"recipe_id": 42
		}"#;
        let parsed: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert!(parsed.tandoor.is_some());
        assert_eq!(parsed.recipe_id, 42);
    }

    #[test]
    fn test_parse_standalone_input() {
        let json = r#"{
			"base_url": "http://localhost:8090",
			"api_token": "test_token",
			"recipe_id": 123
		}"#;
        let parsed: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert!(parsed.tandoor.is_none());
        assert_eq!(parsed.base_url, Some("http://localhost:8090".to_string()));
        assert_eq!(parsed.recipe_id, 123);
    }
}
