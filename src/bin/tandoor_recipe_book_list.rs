//! List recipe books from Tandoor with pagination
//!
//! Retrieves all recipe books with optional pagination.
//!
//! JSON stdin:
//!   {"tandoor": {"base_url": "...", "api_token": "..."}, "page": 1, "page_size": 10}
//!
//! JSON stdout:
//!   {"success": true, "count": 5, "recipe_books": [...]}
//!   {"success": false, "error": "..."}

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{RecipeBook, TandoorClient, TandoorConfig};
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
    recipe_books: Option<Vec<RecipeBook>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    match run() {
        Ok(output) => println!("{}", serde_json::to_string(&output).unwrap()),
        Err(e) => {
            let error = Output {
                success: false,
                count: None,
                recipe_books: None,
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

    let response = client.list_recipe_books(parsed.page, parsed.page_size)?;

    Ok(Output {
        success: true,
        count: Some(response.count),
        recipe_books: Some(response.results),
        error: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_parsing() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "page": 1, "page_size": 10}"#;
        let parsed: Input = serde_json::from_str(json).unwrap();
        assert_eq!(parsed.page, Some(1));
        assert_eq!(parsed.page_size, Some(10));
    }

    #[test]
    fn test_input_parsing_no_pagination() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}}"#;
        let parsed: Input = serde_json::from_str(json).unwrap();
        assert_eq!(parsed.page, None);
        assert_eq!(parsed.page_size, None);
    }

    #[test]
    fn test_output_serialization() {
        let output = Output {
            success: true,
            count: Some(5),
            recipe_books: None,
            error: None,
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"count\":5"));
    }
}
