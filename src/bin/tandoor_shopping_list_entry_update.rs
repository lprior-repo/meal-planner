//! Update a shopping list entry
//!
//! Updates an existing shopping list entry (e.g., mark as checked, change amount).
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "mealplan_id": 123, "entry_id": 456, "update": {...}}`
//!
//! JSON stdout: `{"success": true, "entry": {...}}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{
    ShoppingListEntry, TandoorClient, TandoorConfig, UpdateShoppingListEntryRequest,
};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    /// Tandoor configuration
    tandoor: TandoorConfig,
    /// Meal plan ID
    mealplan_id: i64,
    /// Entry ID to update
    entry_id: i64,
    /// Update details
    update: UpdateShoppingListEntryRequest,
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
    let entry =
        client.update_shopping_list_entry(input.mealplan_id, input.entry_id, &input.update)?;

    Ok(entry)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_deserialization() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "mealplan_id": 123, "entry_id": 456, "update": {"checked": true}}"#;
        let input: Input = serde_json::from_str(json).unwrap();
        assert_eq!(input.mealplan_id, 123);
        assert_eq!(input.entry_id, 456);
        assert_eq!(input.update.checked, Some(true));
    }

    #[test]
    fn test_output_serialization_success() {
        let entry = ShoppingListEntry {
            id: 456,
            list: 1,
            ingredient: None,
            unit: None,
            amount: Some(5.0),
            food: Some("apples".to_string()),
            checked: true,
            order: None,
        };
        let output = Output {
            success: true,
            entry: Some(entry),
            error: None,
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"checked\":true"));
    }
}
