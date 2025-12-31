//! Update an existing meal plan in Tandoor
//!
//! Updates a meal plan with new values for recipe, meal type, date, servings, or notes.
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "meal_plan_id": 123, "recipe": 456, "servings": 3.0}`
//!
//! JSON stdout:
//!   `{"success": true, "meal_plan": {...}}`
//!   `{"success": false, "error": "..."}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{TandoorClient, TandoorConfig, UpdateMealPlanRequest};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    /// Tandoor configuration
    tandoor: TandoorConfig,
    /// Meal plan ID to update
    meal_plan_id: i64,
    /// Optional recipe ID
    #[serde(default)]
    recipe: Option<i64>,
    /// Optional meal type ID
    #[serde(default)]
    meal_type: Option<i64>,
    /// Optional start date
    #[serde(default)]
    from_date: Option<String>,
    /// Optional end date
    #[serde(default)]
    to_date: Option<String>,
    /// Optional servings
    #[serde(default)]
    servings: Option<f64>,
    /// Optional title
    #[serde(default)]
    title: Option<String>,
    /// Optional note
    #[serde(default)]
    note: Option<String>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    meal_plan: Option<serde_json::Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    match run() {
        Ok(output) => {
            println!("{}", serde_json::to_string(&output).unwrap());
        }
        Err(e) => {
            let error = Output {
                success: false,
                meal_plan: None,
                error: Some(e.to_string()),
            };
            println!("{}", serde_json::to_string(&error).unwrap());
            std::process::exit(1);
        }
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

    // Create update request with only provided fields
    let request = UpdateMealPlanRequest {
        recipe: input.recipe,
        meal_type: input.meal_type,
        from_date: input.from_date,
        to_date: input.to_date,
        servings: input.servings,
        title: input.title,
        note: input.note,
    };

    // Update meal plan
    let meal_plan = client.update_meal_plan(input.meal_plan_id, &request)?;

    Ok(Output {
        success: true,
        meal_plan: Some(serde_json::to_value(meal_plan)?),
        error: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_parsing_minimal() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "meal_plan_id": 42}"#;
        let input: Input = serde_json::from_str(json).unwrap();
        assert_eq!(input.meal_plan_id, 42);
        assert_eq!(input.recipe, None);
    }

    #[test]
    fn test_input_parsing_with_updates() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "meal_plan_id": 42, "servings": 4.0, "title": "Updated"}"#;
        let input: Input = serde_json::from_str(json).unwrap();
        assert_eq!(input.servings, Some(4.0));
        assert_eq!(input.title, Some("Updated".to_string()));
    }

    #[test]
    fn test_output_serialization() {
        let output = Output {
            success: true,
            meal_plan: Some(serde_json::json!({"id": 1})),
            error: None,
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":true"));
    }

    #[test]
    fn test_error_output() {
        let output = Output {
            success: false,
            meal_plan: None,
            error: Some("Update failed".to_string()),
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":false"));
    }
}
