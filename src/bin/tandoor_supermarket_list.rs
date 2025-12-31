//! List supermarkets from Tandoor with pagination support
//!
//! Retrieves a paginated list of supermarkets/stores from the Tandoor API.
//! Supports optional page number and page size parameters.
//!
//! JSON input (CLI arg or stdin, all optional):
//!   `{"tandoor": {...}, "page": 1, "page_size": 10}`
//!
//! JSON stdout: `{"success": true, "count": 42, "supermarkets": [...]}`
//!   or `{"success": false, "error": "..."}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{Supermarket, TandoorClient, TandoorConfig};
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
    supermarkets: Option<Vec<Supermarket>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    let output = match run() {
        Ok(o) => o,
        Err(e) => Output {
            success: false,
            count: None,
            supermarkets: None,
            error: Some(e.to_string()),
        },
    };
    println!("{}", serde_json::to_string(&output).unwrap());
    if !output.success {
        std::process::exit(1);
    }
}

fn run() -> anyhow::Result<Output> {
    let input: Input = if let Some(arg) = std::env::args().nth(1) {
        serde_json::from_str(&arg)?
    } else {
        let mut input_str = String::new();
        io::stdin().read_to_string(&mut input_str)?;
        serde_json::from_str(&input_str)?
    };

    let client = TandoorClient::new(&input.tandoor)?;
    let paginated = client.list_supermarkets(input.page, input.page_size)?;

    Ok(Output {
        success: true,
        count: Some(paginated.count),
        supermarkets: Some(paginated.results),
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
            count: Some(3),
            supermarkets: Some(vec![]),
            error: None,
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"count\":3"));
    }

    #[test]
    fn test_input_parsing_with_pagination() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "page": 1, "page_size": 10}"#;
        let input: Input = serde_json::from_str(json).unwrap();
        assert_eq!(input.page, Some(1));
        assert_eq!(input.page_size, Some(10));
    }
}
