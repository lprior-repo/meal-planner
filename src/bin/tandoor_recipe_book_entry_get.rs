//! Get a specific recipe book entry from Tandoor
//!
//! Retrieves a recipe book entry by ID.
//!
//! JSON stdin:
//!   {"tandoor": {"`base_url"`: "...", "`api_token"`: "..."}, "id": 1}
//!
//! JSON stdout:
//!   {"success": true, "`recipe_book_entry"`: {...}}
//!   {"success": false, "error": "..."}

// CLI binaries: exit and unwrap/expect are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::tandoor::{TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    tandoor: TandoorConfig,
    id: i64,
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
        Ok(output) => println!(
            "{}",
            serde_json::to_string(&output).expect("Failed to serialize output JSON")
        ),
        Err(e) => {
            let error = Output {
                success: false,
                recipe_book_entry: None,
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

    let recipe_book_entry = client.get_recipe_book_entry(parsed.id)?;

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
        let json =
            r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "id": 1}"#;
        let parsed: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert_eq!(parsed.id, 1);
        assert_eq!(parsed.tandoor.base_url, "http://localhost:8090");
    }

    #[test]
    fn test_output_serialization() {
        let output = Output {
            success: true,
            recipe_book_entry: None,
            error: None,
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":true"));
    }
}
