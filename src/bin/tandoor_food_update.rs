//! Update a food in Tandoor
//!
//! Updates an existing food entry in the Tandoor database.
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "food_id": 123, "name": "Chicken", "description": "..."}`
//!
//! JSON stdout:
//!   `{"success": true, "food_id": 123, "name": "Chicken"}`
//!   `{"success": false, "error": "..."}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{TandoorClient, TandoorConfig, UpdateFoodRequest};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    tandoor: TandoorConfig,
    food_id: i64,
    #[serde(default)]
    name: Option<String>,
    #[serde(default)]
    description: Option<String>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    food_id: Option<i64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    let output = match run() {
        Ok(o) => o,
        Err(e) => Output {
            success: false,
            food_id: None,
            name: None,
            error: Some(e.to_string()),
        },
    };
    println!("{}", serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON"));
    if !output.success {
        std::process::exit(1);
    }
}

fn run() -> anyhow::Result<Output> {
    // Read input: prefer CLI arg, fall back to stdin
    let input: Input = if let Some(arg) = std::env::args().nth(1) {
        serde_json::from_str(&arg)?
    } else {
        let mut input_str = String::new();
        io::stdin().read_to_string(&mut input_str)?;
        serde_json::from_str(&input_str)?
    };

    let client = TandoorClient::new(&input.tandoor)?;

    let request = UpdateFoodRequest {
        name: input.name,
        description: input.description,
    };

    let updated = client.update_food(input.food_id, &request)?;

    Ok(Output {
        success: true,
        food_id: Some(updated.id),
        name: Some(updated.name),
        error: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_parsing_partial_update() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "food_id": 42, "name": "Chicken Breast"}"#;
        let input: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert_eq!(input.food_id, 42);
        assert_eq!(input.name, Some("Chicken Breast".to_string()));
        assert_eq!(input.description, None);
    }

    #[test]
    fn test_input_parsing_full_update() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "food_id": 10, "name": "Beef", "description": "Red meat"}"#;
        let input: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert_eq!(input.food_id, 10);
        assert_eq!(input.name, Some("Beef".to_string()));
        assert_eq!(input.description, Some("Red meat".to_string()));
    }
}
