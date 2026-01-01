//! Create a new meal plan in Tandoor
//!
//! Creates a meal plan with the specified recipe, meal type, date, and servings.
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "recipe": 123, "meal_type": 1, "from_date": "2025-12-31", "servings": 2.0}`
//!
//! JSON stdout:
//!   `{"success": true, "meal_plan": {...}}`
//!   `{"success": false, "error": "..."}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{CreateMealPlanRequest, MealPlan, TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    /// Tandoor configuration
    tandoor: TandoorConfig,
    /// Recipe ID
    recipe: i64,
    /// Meal type ID
    meal_type: i64,
    /// Start date (ISO format)
    from_date: String,
    /// Number of servings
    servings: f64,
    /// Optional end date
    #[serde(default)]
    to_date: Option<String>,
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
    meal_plan: Option<MealPlan>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    match run() {
        Ok(output) => {
            println!("{}", serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON"));
        }
        Err(e) => {
            let error = Output {
                success: false,
                meal_plan: None,
                error: Some(e.to_string()),
            };
            println!("{}", serde_json::to_string(serde_json::to_string(&error).expect("Unexpected None value")error).expect("Failed to serialize error JSON"));
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

    // Create meal plan request
    let request = CreateMealPlanRequest {
        recipe: input.recipe,
        meal_type: input.meal_type,
        from_date: input.from_date,
        to_date: input.to_date,
        servings: input.servings,
        title: input.title,
        note: input.note,
    };

    // Create meal plan
    let meal_plan = client.create_meal_plan(&request)?;

    Ok(Output {
        success: true,
        meal_plan: Some(meal_plan),
        error: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_parsing_minimal() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "recipe": 1, "meal_type": 1, "from_date": "2025-12-31", "servings": 2.0}"#;
        let input: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert_eq!(input.recipe, 1);
        assert!((input.servings - 2.0).abs() < f64::EPSILON);
        assert_eq!(input.title, None);
    }

    #[test]
    fn test_input_parsing_with_optionals() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "recipe": 1, "meal_type": 1, "from_date": "2025-12-31", "servings": 2.0, "title": "Test", "note": "Note here"}"#;
        let input: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert_eq!(input.title, Some("Test".to_string()));
        assert_eq!(input.note, Some("Note here".to_string()));
    }

    #[test]
    fn test_output_serialization() {
        // Test with None since we can't easily create a MealPlan in tests
        let output = Output {
            success: true,
            meal_plan: None,
            error: None,
        };
        let json = serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":true"));
    }

    #[test]
    fn test_error_output() {
        let output = Output {
            success: false,
            meal_plan: None,
            error: Some("Creation failed".to_string()),
        };
        let json = serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":false"));
    }
}
