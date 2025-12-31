//! Bulk create/update shopping list entries
//!
//! Creates or updates multiple shopping list entries for a meal plan.
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "mealplan_id": 123, "entries": [...]}`
//!
//! JSON stdout:
//!   `{"success": true, "count": N}`
//!   `{"success": false, "error": "..."}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{CreateShoppingListEntryRequest, TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    /// Tandoor configuration
    tandoor: TandoorConfig,
    /// Meal plan ID
    mealplan_id: i64,
    /// Entries to create/update
    entries: Vec<CreateShoppingListEntryRequest>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    count: Option<i32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    let output = match run() {
        Ok(count) => Output {
            success: true,
            count: Some(count),
            error: None,
        },
        Err(e) => Output {
            success: false,
            count: None,
            error: Some(e.to_string()),
        },
    };
    println!("{}", serde_json::to_string(&output).unwrap());
    if !output.success {
        std::process::exit(1);
    }
}

fn run() -> Result<i32, Box<dyn std::error::Error>> {
    // Read input: prefer CLI arg, fall back to stdin
    let input: Input = if let Some(arg) = std::env::args().nth(1) {
        serde_json::from_str(&arg)?
    } else {
        let mut input_str = String::new();
        io::stdin().read_to_string(&mut input_str)?;
        serde_json::from_str(&input_str)?
    };

    let client = TandoorClient::new(&input.tandoor)?;
    let entries: Vec<serde_json::Value> = input
        .entries
        .iter()
        .map(serde_json::to_value)
        .collect::<Result<Vec<_>, _>>()?;
    let count = client.bulk_create_shopping_list_entries(input.mealplan_id, &entries)?;

    Ok(count)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_deserialization_empty() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "mealplan_id": 123, "entries": []}"#;
        let input: Input = serde_json::from_str(json).unwrap();
        assert_eq!(input.mealplan_id, 123);
        assert_eq!(input.entries.len(), 0);
    }

    #[test]
    fn test_input_deserialization_with_entries() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "mealplan_id": 123, "entries": [{"list": 1, "food": "apples", "amount": 5.0}]}"#;
        let input: Input = serde_json::from_str(json).unwrap();
        assert_eq!(input.mealplan_id, 123);
        assert_eq!(input.entries.len(), 1);
    }

    #[test]
    fn test_output_serialization_success() {
        let output = Output {
            success: true,
            count: Some(5),
            error: None,
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"count\":5"));
    }

    #[test]
    fn test_output_serialization_error() {
        let output = Output {
            success: false,
            count: None,
            error: Some("Invalid list ID".to_string()),
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("Invalid list ID"));
    }
}
