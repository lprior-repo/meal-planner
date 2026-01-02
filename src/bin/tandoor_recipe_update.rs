//! Update a recipe in Tandoor
//!
//! Updates recipe fields like name, description, servings, and timing.
//! Only specified fields are updated (null/missing fields are left unchanged).
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "recipe_id": 123, "name": "New Name", "servings": 4}`
//!
//! JSON stdout: `{"success": true, "recipe": {...}}`
//!   or `{"success": false, "error": "..."}`

#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::tandoor::{TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    tandoor: TandoorConfig,
    recipe_id: i64,
    #[serde(default)]
    name: Option<String>,
    #[serde(default)]
    description: Option<String>,
    #[serde(default)]
    source_url: Option<String>,
    #[serde(default)]
    servings: Option<i32>,
    #[serde(default)]
    working_time: Option<i32>,
    #[serde(default)]
    waiting_time: Option<i32>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    recipe: Option<Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    match run() {
        Ok(output) => println!("{}", serde_json::to_string(&output).unwrap()),
        Err(e) => {
            let error = Output {
                success: false,
                recipe: None,
                error: Some(e.to_string()),
            };
            println!("{}", serde_json::to_string(&error).unwrap());
            std::process::exit(1);
        }
    }
}

fn read_input() -> Result<Input, Box<dyn std::error::Error>> {
    let input_str = std::env::args().nth(1).map_or_else(
        || {
            let mut s = String::new();
            io::stdin().read_to_string(&mut s)?;
            Ok::<String, Box<dyn std::error::Error>>(s)
        },
        Ok,
    )?;
    serde_json::from_str(&input_str).map_err(Into::into)
}

fn build_update_request(input: &Input) -> Value {
    let mut request = json!({});
    let obj = request.as_object_mut().unwrap();
    if let Some(name) = &input.name {
        obj.insert("name".to_string(), json!(name));
    }
    if let Some(desc) = &input.description {
        obj.insert("description".to_string(), json!(desc));
    }
    if let Some(url) = &input.source_url {
        obj.insert("source_url".to_string(), json!(url));
    }
    if let Some(serv) = input.servings {
        obj.insert("servings".to_string(), json!(serv));
    }
    if let Some(wt) = input.working_time {
        obj.insert("working_time".to_string(), json!(wt));
    }
    if let Some(wt) = input.waiting_time {
        obj.insert("waiting_time".to_string(), json!(wt));
    }
    request
}

fn run() -> Result<Output, Box<dyn std::error::Error>> {
    let input = read_input()?;
    let client = TandoorClient::new(&input.tandoor)?;
    let recipe = client.update_recipe(input.recipe_id, &build_update_request(&input))?;
    Ok(Output {
        success: true,
        recipe: Some(recipe),
        error: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_parsing_minimal() {
        let json = r#"{"tandoor": {"base_url": "http://localhost", "api_token": "token"}, "recipe_id": 123}"#;
        let input: Input = serde_json::from_str(json).unwrap();
        assert_eq!(input.recipe_id, 123);
        assert!(input.name.is_none());
    }

    #[test]
    fn test_input_parsing_with_updates() {
        let json = r#"{"tandoor": {"base_url": "http://localhost", "api_token": "token"}, "recipe_id": 123, "name": "Updated", "servings": 6}"#;
        let input: Input = serde_json::from_str(json).unwrap();
        assert_eq!(input.recipe_id, 123);
        assert_eq!(input.name, Some("Updated".to_string()));
        assert_eq!(input.servings, Some(6));
    }

    #[test]
    fn test_output_serialize() {
        let output = Output {
            success: true,
            recipe: None,
            error: None,
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":true"));
        assert!(!json.contains("\"recipe\""));
    }

    #[test]
    fn test_error_output_serialize() {
        let output = Output {
            success: false,
            recipe: None,
            error: Some("Update failed".to_string()),
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("\"error\""));
    }

    #[test]
    fn test_build_update_request_name_only() {
        let input: Input = serde_json::from_str(
            r#"{"tandoor": {"base_url": "http://localhost", "api_token": "x"}, "recipe_id": 1, "name": "Test"}"#
        ).unwrap();
        let request = build_update_request(&input);
        assert_eq!(request["name"], "Test");
        assert_eq!(request.as_object().unwrap().len(), 1);
    }

    #[test]
    fn test_build_update_request_all_fields() {
        let input: Input = serde_json::from_str(
            r#"{"tandoor": {"base_url": "http://localhost", "api_token": "x"}, "recipe_id": 1, "name": "N", "description": "D", "source_url": "http://x.com", "servings": 4, "working_time": 30, "waiting_time": 60}"#
        ).unwrap();
        let request = build_update_request(&input);
        let obj = request.as_object().unwrap();
        assert_eq!(obj.len(), 6);
        assert_eq!(obj["name"], "N");
        assert_eq!(obj["servings"], 4);
        assert_eq!(obj["working_time"], 30);
    }

    #[test]
    fn test_build_update_request_empty() {
        let input: Input = serde_json::from_str(
            r#"{"tandoor": {"base_url": "http://localhost", "api_token": "x"}, "recipe_id": 1}"#,
        )
        .unwrap();
        let request = build_update_request(&input);
        assert_eq!(request.as_object().unwrap().len(), 0);
    }
}
