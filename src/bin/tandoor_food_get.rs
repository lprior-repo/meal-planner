//! Get a specific food from Tandoor
//!
//! ## Functional Core / Imperative Shell
//!
//! - **Core**: Pure functions transforming data
//! - **Shell**: I/O coordination (CLI args, stdin, stdout)
//!
//! ## Input (via CLI arg or stdin)
//!
//! ```json
//! {"tandoor": {"base_url": "...", "api_token": "..."}, "food_id": 42}
//! ```
//!
//! ## Output
//!
//! Success:
//! ```json
//! {"success": true, "food": {"id": 42, "name": "Salmon", "description": "Fish"}}
//! ```
//!
//! Error:
//! ```json
//! {"success": false, "error": "Food not found"}
//! ```

#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::tandoor::{Food, TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize, Debug)]
struct Input {
    tandoor: TandoorConfig,
    food_id: i64,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    food: Option<Food>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    let output = match read_input().and_then(execute) {
        Ok(o) => o,
        Err(e) => Output {
            success: false,
            food: None,
            error: Some(e.to_string()),
        },
    };
    print_output(&output);
    if !output.success {
        std::process::exit(1);
    }
}

fn print_output(output: &Output) {
    println!(
        "{}",
        serde_json::to_string(output).expect("Failed to serialize output JSON")
    );
}

fn read_input() -> Result<Input, String> {
    let arg = std::env::args().nth(1);
    let input_str = match arg {
        Some(a) => a,
        None => read_stdin()?,
    };
    parse_input(&input_str)
}

fn read_stdin() -> Result<String, String> {
    let mut input_str = String::new();
    io::stdin()
        .read_to_string(&mut input_str)
        .map_err(|e| format!("Failed to read stdin: {}", e))?;
    Ok(input_str)
}

fn parse_input(s: &str) -> Result<Input, String> {
    serde_json::from_str(s).map_err(|e| format!("Failed to parse input: {}", e))
}

fn execute(input: Input) -> Result<Output, String> {
    let client = TandoorClient::new(&input.tandoor)
        .map_err(|e| format!("Failed to create client: {}", e))?;
    let food = client
        .get_food(input.food_id)
        .map_err(|e| format!("Failed to get food: {}", e))?;
    Ok(Output {
        success: true,
        food: Some(food),
        error: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_input_valid() {
        let json =
            r#"{"tandoor": {"base_url": "http://localhost", "api_token": "test"}, "food_id": 42}"#;
        let input = parse_input(json).expect("Should parse");
        assert_eq!(input.food_id, 42);
    }

    #[test]
    fn parse_input_invalid_json() {
        let result = parse_input("not json");
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("Failed to parse"));
    }

    #[test]
    fn output_serialize_success() {
        let output = Output {
            success: true,
            food: Some(Food {
                id: 1,
                name: "Test".to_string(),
                description: None,
            }),
            error: None,
        };
        let json = serde_json::to_string(&output).expect("Should serialize");
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("Test"));
    }

    #[test]
    fn output_serialize_error() {
        let output = Output {
            success: false,
            food: None,
            error: Some("Not found".to_string()),
        };
        let json = serde_json::to_string(&output).expect("Should serialize");
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("Not found"));
    }

    #[test]
    fn output_omit_none_fields() {
        let output = Output {
            success: true,
            food: None,
            error: None,
        };
        let json = serde_json::to_string(&output).expect("Should serialize");
        assert!(!json.contains("\"food\":null"));
        assert!(!json.contains("\"error\":null"));
    }
}
