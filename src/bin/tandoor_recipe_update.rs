//! Update a recipe in Tandoor
//!
//! Updates recipe fields like name, description, servings, and timing.
//! Only specified fields are updated (null/missing fields are left unchanged).
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "recipe_id": 123, "name": "New Name", "servings": 4}`
//!
//! JSON stdout: `{"success": true, "recipe": {...}}`
//!   or `{"success": false, "error": "..."}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    /// Tandoor configuration (URL and token)
    tandoor: TandoorConfig,
    /// Recipe ID to update
    recipe_id: i64,
    /// Recipe name (optional)
    #[serde(default)]
    name: Option<String>,
    /// Recipe description (optional)
    #[serde(default)]
    description: Option<String>,
    /// Source URL (optional)
    #[serde(default)]
    source_url: Option<String>,
    /// Number of servings (optional)
    #[serde(default)]
    servings: Option<i32>,
    /// Active cooking time in minutes (optional)
    #[serde(default)]
    working_time: Option<i32>,
    /// Passive time in minutes (optional)
    #[serde(default)]
    waiting_time: Option<i32>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    recipe: Option<Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

#[tokio::main]
async fn main() {
    match run().await {
        Ok(output) => {
            println!("{}", serde_json::to_string(&output).unwrap());
        }
        Err(e) => {
            let error = Output {
                success: false,
                recipe: None,
                error: Some(e.to_string()),
            };
            println!("{}", serde_json::to_string(&error).unwrap());
            std::process::exit(1);
        }
    }
}

async fn run() -> Result<Output, Box<dyn std::error::Error>> {
    // Read input: prefer CLI arg, fall back to stdin
    let input: Input = if let Some(arg) = std::env::args().nth(1) {
        serde_json::from_str(&arg)?
    } else {
        let mut input_str = String::new();
        io::stdin().read_to_string(&mut input_str)?;
        serde_json::from_str(&input_str)?
    };

    let client = TandoorClient::new(&input.tandoor)?;

    // Build update request with only non-empty fields
    let mut update_request = json!({});
    if let Some(name) = input.name {
        update_request["name"] = json!(name);
    }
    if let Some(description) = input.description {
        update_request["description"] = json!(description);
    }
    if let Some(source_url) = input.source_url {
        update_request["source_url"] = json!(source_url);
    }
    if let Some(servings) = input.servings {
        update_request["servings"] = json!(servings);
    }
    if let Some(working_time) = input.working_time {
        update_request["working_time"] = json!(working_time);
    }
    if let Some(waiting_time) = input.waiting_time {
        update_request["waiting_time"] = json!(waiting_time);
    }

    let recipe = client.update_recipe(input.recipe_id, &update_request)?;

    Ok(Output {
        success: true,
        recipe: Some(recipe),
        error: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_parsing_minimal() {
        let json = r#"{"tandoor": {"base_url": "http://localhost", "api_token": "token"}, "recipe_id": 123}"#;
        let input: Input = serde_json::from_str(json).unwrap();
        assert_eq!(input.recipe_id, 123);
        assert!(input.name.is_none());
    }

    #[test]
    fn test_input_parsing_with_updates() {
        let json = r#"{"tandoor": {"base_url": "http://localhost", "api_token": "token"}, "recipe_id": 123, "name": "Updated", "servings": 6}"#;
        let input: Input = serde_json::from_str(json).unwrap();
        assert_eq!(input.recipe_id, 123);
        assert_eq!(input.name, Some("Updated".to_string()));
        assert_eq!(input.servings, Some(6));
    }

    #[test]
    fn test_output_serialize() {
        let output = Output {
            success: true,
            recipe: None,
            error: None,
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":true"));
        assert!(!json.contains("\"recipe\""));
    }

    #[test]
    fn test_error_output_serialize() {
        let output = Output {
            success: false,
            recipe: None,
            error: Some("Update failed".to_string()),
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("\"error\""));
    }
}
