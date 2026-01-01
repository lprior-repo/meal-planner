//! Create a new recipe book entry in Tandoor
//!
//! Adds a recipe to a recipe book.
//!
//! JSON stdin:
//!   {"tandoor": {...}, "`recipe_book"`: 1, "recipe": 2, "position": 0}
//!
//! JSON stdout:
//!   {"success": true, "`recipe_book_entry"`: {...}}
//!   {"success": false, "error": "..."}

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{CreateRecipeBookEntryRequest, TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    tandoor: TandoorConfig,
    recipe_book: i64,
    recipe: i64,
    #[serde(default)]
    position: Option<i32>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    recipe_book_entry: Option<serde_json::Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    match run() {
        Ok(output) => println!("{}", serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON")),
        Err(e) => {
            let error = Output {
                success: false,
                recipe_book_entry: None,
                error: Some(e.to_string()),
            };
            println!("{}", serde_json::to_string(serde_json::to_string(&error).expect("Unexpected None value")error).expect("Failed to serialize error JSON"));
            std::process::exit(1);
        }
    }
}

fn run() -> anyhow::Result<Output> {
    let mut input = String::new();
    io::stdin().read_to_string(&mut input)?;

    let parsed: Input = serde_json::from_str(&input)?;
    let client = TandoorClient::new(&parsed.tandoor)?;

    let request = CreateRecipeBookEntryRequest {
        recipe_book: parsed.recipe_book,
        recipe: parsed.recipe,
        position: parsed.position,
    };

    let recipe_book_entry = client.create_recipe_book_entry(&serde_json::to_value(&request)?)?;

    Ok(Output {
        success: true,
        recipe_book_entry: Some(recipe_book_entry),
        error: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_parsing() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "recipe_book": 1, "recipe": 2}"#;
        let parsed: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert_eq!(parsed.recipe_book, 1);
        assert_eq!(parsed.recipe, 2);
        assert_eq!(parsed.position, None);
    }

    #[test]
    fn test_input_parsing_with_position() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "recipe_book": 1, "recipe": 2, "position": 5}"#;
        let parsed: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert_eq!(parsed.recipe_book, 1);
        assert_eq!(parsed.recipe, 2);
        assert_eq!(parsed.position, Some(5));
    }

    #[test]
    fn test_output_serialization() {
        let output = Output {
            success: true,
            recipe_book_entry: None,
            error: None,
        };
        let json = serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":true"));
    }
}
