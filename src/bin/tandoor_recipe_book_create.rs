//! Create a new recipe book in Tandoor
//!
//! JSON stdin:
//!   {"tandoor": {...}, "name": "My Recipes", "description": "...", "icon": "...", "color": "..."}
//!
//! JSON stdout:
//!   {"success": true, "recipe_book": {...}}
//!   {"success": false, "error": "..."}

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{CreateRecipeBookRequest, TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    tandoor: TandoorConfig,
    name: String,
    #[serde(default)]
    description: Option<String>,
    #[serde(default)]
    icon: Option<String>,
    #[serde(default)]
    color: Option<String>,
    #[serde(default)]
    filter: Option<serde_json::Value>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    recipe_book: Option<serde_json::Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    match run() {
        Ok(output) => println!("{}", serde_json::to_string(&output).unwrap()),
        Err(e) => {
            let error = Output {
                success: false,
                recipe_book: None,
                error: Some(e.to_string()),
            };
            println!("{}", serde_json::to_string(&error).unwrap());
            std::process::exit(1);
        }
    }
}

fn run() -> anyhow::Result<Output> {
    let mut input = String::new();
    io::stdin().read_to_string(&mut input)?;

    let parsed: Input = serde_json::from_str(&input)?;
    let client = TandoorClient::new(&parsed.tandoor)?;

    let request = CreateRecipeBookRequest {
        name: parsed.name,
        description: parsed.description,
        icon: parsed.icon,
        color: parsed.color,
        filter: parsed.filter,
    };

    let recipe_book = client.create_recipe_book(&serde_json::to_value(&request)?)?;

    Ok(Output {
        success: true,
        recipe_book: Some(recipe_book),
        error: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_parsing() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "name": "My Recipes"}"#;
        let parsed: Input = serde_json::from_str(json).unwrap();
        assert_eq!(parsed.name, "My Recipes");
        assert_eq!(parsed.description, None);
    }

    #[test]
    fn test_input_parsing_with_details() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "name": "My Recipes", "description": "Test book", "icon": "book", "color": "red"}"#;
        let parsed: Input = serde_json::from_str(json).unwrap();
        assert_eq!(parsed.name, "My Recipes");
        assert_eq!(parsed.description, Some("Test book".to_string()));
        assert_eq!(parsed.icon, Some("book".to_string()));
        assert_eq!(parsed.color, Some("red".to_string()));
    }

    #[test]
    fn test_output_serialization() {
        let output = Output {
            success: true,
            recipe_book: None,
            error: None,
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":true"));
    }
}
