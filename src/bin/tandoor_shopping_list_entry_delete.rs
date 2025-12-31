//! Delete a shopping list entry
//!
//! Removes an entry from a shopping list.
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "mealplan_id": 123, "entry_id": 456}`
//!
//! JSON stdout: `{"success": true}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    /// Tandoor configuration
    tandoor: TandoorConfig,
    /// Meal plan ID
    mealplan_id: i64,
    /// Entry ID to delete
    entry_id: i64,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    let output = match run() {
        Ok(()) => Output {
            success: true,
            error: None,
        },
        Err(e) => Output {
            success: false,
            error: Some(e.to_string()),
        },
    };
    println!("{}", serde_json::to_string(&output).unwrap());
    if !output.success {
        std::process::exit(1);
    }
}

fn run() -> Result<(), Box<dyn std::error::Error>> {
    // Read input: prefer CLI arg, fall back to stdin
    let input: Input = if let Some(arg) = std::env::args().nth(1) {
        serde_json::from_str(&arg)?
    } else {
        let mut input_str = String::new();
        io::stdin().read_to_string(&mut input_str)?;
        serde_json::from_str(&input_str)?
    };

    let client = TandoorClient::new(&input.tandoor)?;
    client.delete_shopping_list_entry(input.mealplan_id, input.entry_id)?;

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_deserialization() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "mealplan_id": 123, "entry_id": 456}"#;
        let input: Input = serde_json::from_str(json).unwrap();
        assert_eq!(input.mealplan_id, 123);
        assert_eq!(input.entry_id, 456);
    }

    #[test]
    fn test_output_serialization_success() {
        let output = Output {
            success: true,
            error: None,
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":true"));
    }

    #[test]
    fn test_output_serialization_error() {
        let output = Output {
            success: false,
            error: Some("Not found".to_string()),
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("Not found"));
    }
}
