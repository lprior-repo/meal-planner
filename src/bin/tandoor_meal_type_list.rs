//! List all meal types from Tandoor
//!
//! Retrieves all meal types with optional pagination.
//!
//! JSON stdin:
//!   `{"tandoor": {"base_url": "...", "api_token": "..."}, "page": 1, "page_size": 10}`
//!
//! JSON stdout:
//!   `{"success": true, "count": 5, "meal_types": [...]}`
//!   `{"success": false, "error": "..."}`

// CLI binaries: exit and unwrap/expect are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::tandoor::{MealType, TandoorClient, TandoorConfig};
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
    meal_types: Option<Vec<MealType>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    let input = match read_input() {
        Ok(i) => i,
        Err(e) => {
            print_output(Err(create_error(&format!("Failed to read input: {}", e))));
        }
    };
    let result = execute(&input);
    print_output(result);
}

fn read_input() -> Result<Input, String> {
    let mut input = String::new();
    io::stdin()
        .read_to_string(&mut input)
        .map_err(|e| e.to_string())?;
    serde_json::from_str(&input).map_err(|e| e.to_string())
}

fn execute(input: &Input) -> Result<Output, Output> {
    let client = TandoorClient::new(&input.tandoor).map_err(|e| create_error(&e.to_string()))?;
    let result = client
        .list_meal_types(input.page, input.page_size)
        .map_err(|e| create_error(&e.to_string()))?;
    Ok(create_success(result.count, result.results))
}

fn create_error(message: &str) -> Output {
    Output {
        success: false,
        count: None,
        meal_types: None,
        error: Some(message.to_string()),
    }
}

fn create_success(count: i64, meal_types: Vec<MealType>) -> Output {
    Output {
        success: true,
        count: Some(count),
        meal_types: Some(meal_types),
        error: None,
    }
}

fn print_output(output: Result<Output, Output>) -> ! {
    let output = output.unwrap_or_else(|e| e);
    let json = serde_json::to_string(&output).expect("Failed to serialize output JSON");
    println!("{}", json);
    let exit_code = if output.success { 0 } else { 1 };
    std::process::exit(exit_code);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_parsing_minimal() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}}"#;
        let parsed: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert_eq!(parsed.tandoor.base_url, "http://localhost:8090");
        assert_eq!(parsed.tandoor.api_token, "test");
        assert!(parsed.page.is_none());
        assert!(parsed.page_size.is_none());
    }

    #[test]
    fn test_input_parsing_with_pagination() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "page": 2, "page_size": 20}"#;
        let parsed: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert_eq!(parsed.page, Some(2));
        assert_eq!(parsed.page_size, Some(20));
    }

    #[test]
    fn test_create_success_output() {
        let meal_types = vec![MealType {
            id: 1,
            name: "Breakfast".to_string(),
            order: 0,
            time: Some("08:00".to_string()),
            color: None,
            default: true,
            created_by: Some(1),
        }];
        let output = create_success(1, meal_types);
        assert!(output.success);
        assert_eq!(output.count, Some(1));
        assert_eq!(output.meal_types.as_ref().unwrap().len(), 1);
        assert_eq!(output.meal_types.as_ref().unwrap()[0].name, "Breakfast");
        assert!(output.error.is_none());
    }

    #[test]
    fn test_create_error_output() {
        let output = create_error("Connection refused");
        assert!(!output.success);
        assert!(output.count.is_none());
        assert!(output.meal_types.is_none());
        assert_eq!(output.error, Some("Connection refused".to_string()));
    }

    #[test]
    fn test_output_serialization_success() {
        let output = create_success(5, vec![]);
        let json = serde_json::to_string(&output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"count\":5"));
    }

    #[test]
    fn test_output_serialization_error() {
        let output = create_error("test error");
        let json = serde_json::to_string(&output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("\"error\""));
    }
}
