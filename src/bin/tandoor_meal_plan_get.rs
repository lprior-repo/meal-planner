//! Get a specific meal plan from Tandoor
//!
//! Retrieves detailed meal plan information by ID.
//!
//! ## Functional Core / Imperative Shell Architecture
//!
//! - **Core** (pure functions): `parse_input`, `serialize_output`, `create_error_output`
//! - **Shell** (I/O): `main` handles stdin/stdout, `run` orchestrates the flow
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {"base_url": "...", "api_token": "..."}, "id": 123}`
//!
//! JSON stdout:
//!   `{"success": true, "meal_plan": {...}}`
//!   `{"success": false, "error": "..."}`

// CLI binaries: exit and unwrap/expect are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::tandoor::{MealPlan, TandoorClient, TandoorConfig};
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
    meal_plan: Option<MealPlan>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    match run() {
        Ok(output) => println!("{}", serialize_output(&output)),
        Err(e) => {
            let error = create_error_output(e.to_string());
            println!("{}", serialize_output(&error));
            std::process::exit(1);
        }
    }
}

fn run() -> anyhow::Result<Output> {
    let input = parse_input()?;
    let client = TandoorClient::new(&input.tandoor)?;
    let meal_plan = client.get_meal_plan(input.id)?;
    Ok(Output {
        success: true,
        meal_plan: Some(meal_plan),
        error: None,
    })
}

fn parse_input() -> anyhow::Result<Input> {
    let raw = read_input()?;
    Ok(serde_json::from_str(&raw)?)
}

fn read_input() -> anyhow::Result<String> {
    let arg = std::env::args().nth(1);
    match arg {
        Some(json) => Ok(json),
        None => {
            let mut buf = String::new();
            io::stdin().read_to_string(&mut buf)?;
            Ok(buf)
        }
    }
}

fn serialize_output(output: &Output) -> String {
    serde_json::to_string(output).expect("Failed to serialize output JSON")
}

fn create_error_output(error: String) -> Output {
    Output {
        success: false,
        meal_plan: None,
        error: Some(error),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_input_with_id() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "id": 42}"#;
        let input = parse_input_json(json).expect("Failed to parse test JSON");
        assert_eq!(input.id, 42);
    }

    #[test]
    fn test_parse_input_requires_id_field() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "meal_plan_id": 42}"#;
        let result = parse_input_json::<Input>(json);
        assert!(result.is_err(), "Should fail without 'id' field");
    }

    #[test]
    fn test_serialize_success_output() {
        let output = Output {
            success: true,
            meal_plan: Some(MealPlan {
                id: 1,
                title: "Test".to_string(),
                recipe: serde_json::json!({}),
                servings: 2.0,
                note: "".to_string(),
                note_markdown: "".to_string(),
                from_date: "2025-01-01".to_string(),
                to_date: "2025-01-01".to_string(),
                meal_type: serde_json::json!({}),
                created_by: 1,
                shared: vec![],
                recipe_name: "Test Recipe".to_string(),
                meal_type_name: "Breakfast".to_string(),
                shopping: false,
            }),
            error: None,
        };
        let json = serialize_output(&output);
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"id\":1"));
    }

    #[test]
    fn test_create_error_output() {
        let error = create_error_output("Not found".to_string());
        assert!(!error.success);
        assert!(error.meal_plan.is_none());
        assert_eq!(error.error, Some("Not found".to_string()));
    }

    #[test]
    fn test_serialize_error_output() {
        let error = create_error_output("Not found".to_string());
        let json = serialize_output(&error);
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("Not found"));
    }

    fn parse_input_json<T: serde::de::DeserializeOwned>(raw: &str) -> Result<T, serde_json::Error> {
        serde_json::from_str(raw)
    }
}
