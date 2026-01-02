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

// CLI binaries: exit and unwrap/expect are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::tandoor::{PaginatedResponse, RecipeSummary, TandoorClient, TandoorConfig};
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
            println!(
                "{}",
                serde_json::to_string(&output).expect("Failed to serialize output JSON")
            );
        }
        Err(e) => {
            let error = Output {
                success: false,
                count: None,
                recipes: None,
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

fn run() -> Result<Output, Box<dyn std::error::Error>> {
    let input = parse_input()?;
    let paginated = execute_list(&input.tandoor, input.page, input.page_size)?;
    Ok(create_success_output(paginated.count, paginated.results))
}

fn parse_input() -> Result<Input, Box<dyn std::error::Error>> {
    if let Some(arg) = std::env::args().nth(1) {
        return serde_json::from_str(&arg).map_err(Into::into);
    }
    let mut input_str = String::new();
    io::stdin().read_to_string(&mut input_str)?;
    if input_str.trim().is_empty() {
        Ok(Input {
            tandoor: TandoorConfig::from_env()
                .ok_or("TANDOOR_BASE_URL and TANDOOR_API_TOKEN required")?,
            page: None,
            page_size: None,
        })
    } else {
        serde_json::from_str(&input_str).map_err(Into::into)
    }
}

fn execute_list(
    config: &TandoorConfig,
    page: Option<u32>,
    page_size: Option<u32>,
) -> Result<PaginatedResponse<RecipeSummary>, Box<dyn std::error::Error>> {
    let client = TandoorClient::new(config)?;
    client.list_recipes(page, page_size).map_err(Into::into)
}

fn create_success_output(count: i64, recipes: Vec<RecipeSummary>) -> Output {
    Output {
        success: true,
        count: Some(count),
        recipes: Some(recipes),
        error: None,
    }
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
        let json = serde_json::to_string(&output).expect("Failed to serialize");
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
        let json = serde_json::to_string(&output).expect("Failed to serialize");
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("\"error\""));
        assert!(!json.contains("\"count\""));
    }

    #[test]
    fn test_input_parse_with_pagination() {
        let json =
            r#"{"tandoor":{"base_url":"http://test","api_token":"test"},"page":2,"page_size":10}"#;
        let input: Input = serde_json::from_str(json).expect("Failed to parse");
        assert_eq!(input.page, Some(2));
        assert_eq!(input.page_size, Some(10));
    }

    #[test]
    fn test_input_parse_without_pagination() {
        let json = r#"{"tandoor":{"base_url":"http://test","api_token":"test"}}"#;
        let input: Input = serde_json::from_str(json).expect("Failed to parse");
        assert_eq!(input.page, None);
        assert_eq!(input.page_size, None);
    }

    #[test]
    fn test_create_success_output() {
        let output = create_success_output(42, vec![]);
        assert!(output.success);
        assert_eq!(output.count, Some(42));
        assert!(output.recipes.is_some());
        assert!(output.error.is_none());
    }

    #[test]
    fn test_output_format_keys() {
        let output = Output {
            success: true,
            count: Some(1),
            recipes: Some(vec![]),
            error: None,
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize");
        assert!(json.contains("\"success\""));
        assert!(json.contains("\"count\""));
        assert!(json.contains("\"recipes\""));
    }

    #[test]
    fn test_error_output_no_extra_fields() {
        let output = Output {
            success: false,
            count: None,
            recipes: None,
            error: Some("test".to_string()),
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize");
        assert!(!json.contains("\"count\""));
        assert!(!json.contains("\"recipes\""));
    }
}
