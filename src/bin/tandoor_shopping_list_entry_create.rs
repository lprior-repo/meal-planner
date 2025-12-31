//! Create a shopping list entry
//!
//! Adds a new entry to a shopping list for a meal plan.
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "mealplan_id": 123, "entry": {...}}`
//!
//! JSON stdout: `{"success": true, "entry": {...}}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{
    CreateShoppingListEntryRequest, ShoppingListEntry, TandoorClient, TandoorConfig,
};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    /// Tandoor configuration
    tandoor: TandoorConfig,
    /// Meal plan ID
    mealplan_id: i64,
    /// Entry details
    entry: CreateShoppingListEntryRequest,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    entry: Option<ShoppingListEntry>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
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
    println!("{}", serde_json::to_string(&output).unwrap());
    if !output.success {
        std::process::exit(1);
    }
}

fn run() -> Result<ShoppingListEntry, Box<dyn std::error::Error>> {
    // Read input: prefer CLI arg, fall back to stdin
    let input: Input = if let Some(arg) = std::env::args().nth(1) {
        serde_json::from_str(&arg)?
    } else {
        let mut input_str = String::new();
        io::stdin().read_to_string(&mut input_str)?;
        serde_json::from_str(&input_str)?
    };

    let client = TandoorClient::new(&input.tandoor)?;
    let entry = client.create_shopping_list_entry(input.mealplan_id, &input.entry)?;

    Ok(entry)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_deserialization() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "mealplan_id": 123, "entry": {"list": 1}}"#;
        let input: Input = serde_json::from_str(json).unwrap();
        assert_eq!(input.mealplan_id, 123);
        assert_eq!(input.entry.list, 1);
    }

    #[test]
    fn test_output_serialization_success() {
        // Test with None since we can't easily create a ShoppingListEntry in tests
        let output = Output {
            success: true,
            entry: None,
            error: None,
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":true"));
    }
}
