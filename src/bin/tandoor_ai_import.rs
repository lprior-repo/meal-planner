//! Import a recipe from an image or PDF using AI
//!
//! Uses Tandoor's AI import endpoint to extract recipe data from images or PDF files.
//! Requires an AI provider to be configured in Tandoor.
//!
//! JSON stdin (Windmill format):
//!   `{"tandoor": {...}, "file_path": "/path/to/recipe.jpg", "ai_provider_id": 1}`
//!
//! JSON stdin (standalone format):
//!   `{"base_url": "...", "api_token": "...", "file_path": "/path/to/recipe.pdf", "ai_provider_id": 1, "recipe_id": 123}`
//!
//! JSON stdout:
//!   `{"success": true, "recipe": {...}, "recipe_id": 123, "images": [...]}`
//!   `{"success": false, "error": "..."}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{TandoorClient, TandoorConfig};
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
    /// Path to the image or PDF file
    file_path: String,
    /// AI provider ID to use for import
    ai_provider_id: i64,
    /// Optional recipe ID to update (instead of creating new)
    recipe_id: Option<i64>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    recipe: Option<serde_json::Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    recipe_id: Option<i64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    images: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    duplicates: Option<Vec<serde_json::Value>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    message: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    let output = match run() {
        Ok(o) => o,
        Err(e) => Output {
            success: false,
            recipe: None,
            recipe_id: None,
            images: None,
            duplicates: None,
            message: None,
            error: Some(e.to_string()),
        },
    };
    println!("{}", serde_json::to_string(&output).unwrap());
    if !output.success {
        std::process::exit(1);
    }
}

#[allow(clippy::too_many_lines)]
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

    // Validate file path exists
    if !std::path::Path::new(&parsed.file_path).exists() {
        return Err(anyhow::anyhow!("File not found: {}", parsed.file_path));
    }

    // Create client and call AI import
    let client = TandoorClient::new(&config)?;
    let result = client.ai_import(&parsed.file_path, parsed.ai_provider_id, parsed.recipe_id)?;

    if result.error {
        return Ok(Output {
            success: false,
            recipe: None,
            recipe_id: None,
            images: None,
            duplicates: None,
            message: Some(result.msg),
            error: Some("AI import failed".to_string()),
        });
    }

    // Convert recipe to JSON value for output
    let recipe_json = result
        .recipe
        .map(|r| serde_json::to_value(r).unwrap_or(serde_json::Value::Null));

    // Convert duplicates to JSON values
    let duplicates_json: Option<Vec<serde_json::Value>> = if result.duplicates.is_empty() {
        None
    } else {
        Some(
            result
                .duplicates
                .into_iter()
                .filter_map(|d| serde_json::to_value(d).ok())
                .collect(),
        )
    };

    Ok(Output {
        success: true,
        recipe: recipe_json,
        recipe_id: result.recipe_id,
        images: if result.images.is_empty() {
            None
        } else {
            Some(result.images)
        },
        duplicates: duplicates_json,
        message: if result.msg.is_empty() {
            None
        } else {
            Some(result.msg)
        },
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
            recipe: Some(serde_json::json!({"name": "Test Recipe"})),
            recipe_id: Some(123),
            images: Some(vec!["https://example.com/image.jpg".to_string()]),
            duplicates: None,
            message: None,
            error: None,
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"recipe_id\":123"));
        assert!(json.contains("\"name\":\"Test Recipe\""));
        assert!(!json.contains("error"));
    }

    #[test]
    fn test_error_output_serialization() {
        let output = Output {
            success: false,
            recipe: None,
            recipe_id: None,
            images: None,
            duplicates: None,
            message: None,
            error: Some("AI provider not configured".to_string()),
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("\"error\":\"AI provider not configured\""));
        assert!(!json.contains("recipe"));
    }

    #[test]
    fn test_parse_windmill_input() {
        let json = r#"{
			"tandoor": {
				"base_url": "http://localhost:8090",
				"api_token": "test_token"
			},
			"file_path": "/tmp/recipe.jpg",
			"ai_provider_id": 1
		}"#;
        let parsed: Input = serde_json::from_str(json).unwrap();
        assert!(parsed.tandoor.is_some());
        assert_eq!(parsed.file_path, "/tmp/recipe.jpg");
        assert_eq!(parsed.ai_provider_id, 1);
        assert!(parsed.recipe_id.is_none());
    }

    #[test]
    fn test_parse_standalone_input() {
        let json = r#"{
			"base_url": "http://localhost:8090",
			"api_token": "test_token",
			"file_path": "/home/user/recipe.pdf",
			"ai_provider_id": 2,
			"recipe_id": 456
		}"#;
        let parsed: Input = serde_json::from_str(json).unwrap();
        assert!(parsed.tandoor.is_none());
        assert_eq!(parsed.base_url, Some("http://localhost:8090".to_string()));
        assert_eq!(parsed.file_path, "/home/user/recipe.pdf");
        assert_eq!(parsed.ai_provider_id, 2);
        assert_eq!(parsed.recipe_id, Some(456));
    }
}
