//! List recipes from Tandoor with pagination support
//!
//! Retrieves a paginated list of recipes from the Tandoor API.
//! Supports optional page number and page size parameters.
//!
//! JSON input (CLI arg or stdin, all optional):
//!   `{"tandoor": {...}, "page": 1, "page_size": 10}`
//!
//! JSON stdout: `{"success": true, "count": 42, "recipes": [...]}`
//!   or `{"success": false, "error": "..."}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{RecipeSummary, TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    /// Tandoor configuration (URL and token)
    tandoor: TandoorConfig,
    /// Page number (optional, defaults to 1)
    #[serde(default)]
    page: Option<u32>,
    /// Page size (optional, defaults to API default)
    #[serde(default)]
    page_size: Option<u32>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    count: Option<i64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    recipes: Option<Vec<RecipeSummary>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    match run() {
        Ok(output) => {
            println!("{}", serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON"));
        }
        Err(e) => {
            let error = Output {
                success: false,
                count: None,
                recipes: None,
                error: Some(e.to_string()),
            };
            println!("{}", serde_json::to_string(serde_json::to_string(&error).expect("Unexpected None value")error).expect("Failed to serialize error JSON"));
            std::process::exit(1);
        }
    }
}

fn run() -> Result<Output, Box<dyn std::error::Error>> {
    // Read input: prefer CLI arg, fall back to stdin
    let input: Input = if let Some(arg) = std::env::args().nth(1) {
        serde_json::from_str(&arg)?
    } else {
        let mut input_str = String::new();
        io::stdin().read_to_string(&mut input_str)?;
        if input_str.trim().is_empty() {
            Input {
                tandoor: TandoorConfig::from_env()
                    .ok_or("TANDOOR_BASE_URL and TANDOOR_API_TOKEN required")?,
                page: None,
                page_size: None,
            }
        } else {
            serde_json::from_str(&input_str)?
        }
    };

    let client = TandoorClient::new(&input.tandoor)?;
    let paginated = client.list_recipes(input.page, input.page_size)?;

    Ok(Output {
        success: true,
        count: Some(paginated.count),
        recipes: Some(paginated.results),
        error: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_output_serialize() {
        let output = Output {
            success: true,
            count: Some(5),
            recipes: Some(vec![]),
            error: None,
        };
        let json = serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"count\":5"));
    }

    #[test]
    fn test_error_output_serialize() {
        let output = Output {
            success: false,
            count: None,
            recipes: None,
            error: Some("Connection failed".to_string()),
        };
        let json = serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("\"error\""));
        assert!(!json.contains("\"count\""));
    }
}
