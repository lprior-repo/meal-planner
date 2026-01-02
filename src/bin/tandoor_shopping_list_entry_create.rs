//! Create a shopping list entry
//!
//! Adds a new entry to a shopping list for a meal plan.
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "mealplan_id": 123, "entry": {"list": 1, "food": "milk", "amount": 2.0}}`
//!
//! JSON stdout: `{"success": true, "entry": {"id": 3, "food": "milk", ...}}`

// CLI binaries: exit and unwrap/expect are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::tandoor::{
    CreateShoppingListEntryRequest, ShoppingListEntry, TandoorClient, TandoorConfig, TandoorError,
};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Debug, Deserialize, Serialize)]
pub struct Input {
    /// Tandoor configuration
    pub tandoor: TandoorConfig,
    /// Meal plan ID
    pub mealplan_id: i64,
    /// Entry details
    pub entry: CreateShoppingListEntryRequest,
}

#[derive(Debug, Serialize)]
pub struct Output {
    pub success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub entry: Option<ShoppingListEntry>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
}

fn main() {
    let output = match run() {
        Ok(entry) => Output {
            success: true,
            entry: Some(entry),
            error: None,
        },
        Err(e) => Output {
            success: false,
            entry: None,
            error: Some(e.to_string()),
        },
    };
    println!(
        "{}",
        serde_json::to_string(&output).expect("Failed to serialize output JSON")
    );
    if !output.success {
        std::process::exit(1);
    }
}

fn run() -> Result<ShoppingListEntry, Box<dyn std::error::Error>> {
    let input = read_input()?;
    let entry = execute_create(&input)?;
    Ok(entry)
}

fn read_input() -> Result<Input, Box<dyn std::error::Error>> {
    let input_str = std::env::args().nth(1).map(Ok).unwrap_or_else(|| {
        let mut s = String::new();
        io::stdin().read_to_string(&mut s)?;
        Ok(s)
    })?;
    serde_json::from_str(&input_str).map_err(Into::into)
}

fn execute_create(input: &Input) -> Result<ShoppingListEntry, TandoorError> {
    let client = TandoorClient::new(&input.tandoor)?;
    client.create_shopping_list_entry(input.mealplan_id, &input.entry)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_deserialization() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "mealplan_id": 123, "entry": {"list": 1, "food": "milk"}}"#;
        let input: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert_eq!(input.mealplan_id, 123);
        assert_eq!(input.entry.food, Some("milk".to_string()));
    }

    #[test]
    fn test_output_serialization_success() {
        let output = Output {
            success: true,
            entry: None,
            error: None,
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":true"));
    }

    #[test]
    fn test_output_serialization_error() {
        let output = Output {
            success: false,
            entry: None,
            error: Some("Not found".to_string()),
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("Not found"));
    }

    #[test]
    fn test_read_input_from_args() {
        let json = r#"{"tandoor": {"base_url": "http://test", "api_token": "x"}, "mealplan_id": 1, "entry": {"list": 1}}"#;
        let input = read_input_with_args(&json).expect("Should parse");
        assert_eq!(input.mealplan_id, 1);
    }

    fn read_input_with_args(arg: &str) -> Result<Input, Box<dyn std::error::Error>> {
        let _args: Vec<_> = std::env::args().collect();
        let input = serde_json::from_str(arg)?;
        Ok(input)
    }
}
