//! Add recipe to shopping list
//!
//! Adds all ingredients from a recipe to the shopping list for a meal plan.
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "mealplan_id": 123, "recipe_id": 456}`
//!
//! JSON stdout: `{"success": true, "entries": [...]}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{ShoppingListEntry, TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    /// Tandoor configuration
    tandoor: TandoorConfig,
    /// Meal plan ID
    mealplan_id: i64,
    /// Recipe ID to add
    recipe_id: i64,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    entries: Option<Vec<ShoppingListEntry>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    let output = match run() {
        Ok(entries) => Output {
            success: true,
            entries: Some(entries),
            error: None,
        },
        Err(e) => Output {
            success: false,
            entries: None,
            error: Some(e.to_string()),
        },
    };
    println!("{}", serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON"));
    if !output.success {
        std::process::exit(1);
    }
}

fn run() -> Result<Vec<ShoppingListEntry>, Box<dyn std::error::Error>> {
    // Read input: prefer CLI arg, fall back to stdin
    let input: Input = if let Some(arg) = std::env::args().nth(1) {
        serde_json::from_str(&arg)?
    } else {
        let mut input_str = String::new();
        io::stdin().read_to_string(&mut input_str)?;
        serde_json::from_str(&input_str)?
    };

    let client = TandoorClient::new(&input.tandoor)?;
    let entries = client.add_recipe_to_shopping_list(input.mealplan_id, input.recipe_id)?;

    Ok(entries)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_deserialization() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "mealplan_id": 123, "recipe_id": 456}"#;
        let input: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert_eq!(input.mealplan_id, 123);
        assert_eq!(input.recipe_id, 456);
    }

    #[test]
    fn test_output_serialization_success() {
        let output = Output {
            success: true,
            entries: Some(vec![]),
            error: None,
        };
        let json = serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"entries\":[]"));
    }

    #[test]
    fn test_output_serialization_error() {
        let output = Output {
            success: false,
            entries: None,
            error: Some("Recipe not found".to_string()),
        };
        let json = serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("Recipe not found"));
    }
}
