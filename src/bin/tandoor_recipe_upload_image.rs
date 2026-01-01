//! Upload an image for a recipe
//!
//! Uploads an image file to a recipe in Tandoor, converting it to multipart form-data
//! and handling the image file from the filesystem.
//!
//! JSON stdin (Windmill format):
//!   `{"tandoor": {...}, "recipe_id": 123, "image_path": "/path/to/image.jpg"}`
//!
//! JSON stdin (standalone format):
//!   `{"base_url": "...", "api_token": "...", "recipe_id": 123, "image_path": "/path/to/image.jpg"}`
//!
//! JSON stdout:
//!   `{"success": true, "image": "...", "image_url": "..."}`
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
    /// Recipe ID to upload image for
    recipe_id: i64,
    /// Path to the image file
    image_path: String,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    image: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    image_url: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    let output = match run() {
        Ok(o) => o,
        Err(e) => Output {
            success: false,
            image: None,
            image_url: None,
            error: Some(e.to_string()),
        },
    };
    println!("{}", serde_json::to_string(&output).unwrap());
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

    // Validate image path exists
    if !std::path::Path::new(&parsed.image_path).exists() {
        return Err(anyhow::anyhow!(
            "Image file not found: {}",
            parsed.image_path
        ));
    }

    // Create client and upload image
    let client = TandoorClient::new(&config)?;
    let result = client.upload_recipe_image(parsed.recipe_id, &parsed.image_path)?;

    Ok(Output {
        success: true,
        image: result.image,
        image_url: result.image_url,
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
            image: Some("/media/recipes/123.jpg".to_string()),
            image_url: None,
            error: None,
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"image\":\"/media/recipes/123.jpg\""));
        assert!(!json.contains("error"));
        assert!(!json.contains("image_url"));
    }

    #[test]
    fn test_error_output_serialization() {
        let output = Output {
            success: false,
            image: None,
            image_url: None,
            error: Some("File not found".to_string()),
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("\"error\":\"File not found\""));
        assert!(!json.contains("image"));
    }

    #[test]
    fn test_parse_windmill_input() {
        let json = r#"{
			"tandoor": {
				"base_url": "http://localhost:8090",
				"api_token": "test_token"
			},
			"recipe_id": 42,
			"image_path": "/tmp/recipe.jpg"
		}"#;
        let parsed: Input = serde_json::from_str(json).unwrap();
        assert!(parsed.tandoor.is_some());
        assert_eq!(parsed.recipe_id, 42);
        assert_eq!(parsed.image_path, "/tmp/recipe.jpg");
    }

    #[test]
    fn test_parse_standalone_input() {
        let json = r#"{
			"base_url": "http://localhost:8090",
			"api_token": "test_token",
			"recipe_id": 123,
			"image_path": "/home/user/dish.png"
		}"#;
        let parsed: Input = serde_json::from_str(json).unwrap();
        assert!(parsed.tandoor.is_none());
        assert_eq!(parsed.base_url, Some("http://localhost:8090".to_string()));
        assert_eq!(parsed.recipe_id, 123);
        assert_eq!(parsed.image_path, "/home/user/dish.png");
    }
}
