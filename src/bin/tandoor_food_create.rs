//! Create a new food in Tandoor
//!
//! Creates a new food entry in the Tandoor database.
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "name": "Chicken", "description": "..."}`
//!
//! JSON stdout:
//!   `{"success": true, "food_id": 123, "name": "Chicken"}`
//!   `{"success": false, "error": "..."}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{CreateFoodRequestData, TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    tandoor: TandoorConfig,
    name: String,
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
    println!("{}", serde_json::to_string(&output).unwrap());
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

    let request = CreateFoodRequestData {
        name: input.name.clone(),
        description: input.description,
    };

    let created = client.create_food(&request)?;

    Ok(Output {
        success: true,
        food_id: Some(created.id),
        name: Some(created.name),
        error: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_parsing_with_description() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "name": "Chicken", "description": "A poultry"}"#;
        let input: Input = serde_json::from_str(json).unwrap();
        assert_eq!(input.name, "Chicken");
        assert_eq!(input.description, Some("A poultry".to_string()));
    }

    #[test]
    fn test_input_parsing_minimal() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "name": "Beef"}"#;
        let input: Input = serde_json::from_str(json).unwrap();
        assert_eq!(input.name, "Beef");
        assert_eq!(input.description, None);
    }
}
