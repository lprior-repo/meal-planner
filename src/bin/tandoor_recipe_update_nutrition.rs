//! Update nutrition values for a Tandoor recipe
//!
//! Updates the nutrition information (calories, protein, carbohydrates, fat)
//! for a recipe in Tandoor Recipes.
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "recipe_id": 123, "nutrition": {"calories": 450, "protein": 25}}`
//!
//! JSON stdout: `{"success": true, "recipe_id": 123, "recipe": {...}}`
//!   or `{"success": false, "error": "..."}`

#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::tandoor::nutrition::{build_nutrition_update_request, validate_nutrition_input};
use meal_planner::tandoor::TandoorClient;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::io::{self, Read};

#[derive(Deserialize, Serialize)]
struct NutritionInput {
    calories: Option<f64>,
    protein: Option<f64>,
    carbohydrates: Option<f64>,
    fat: Option<f64>,
}

#[derive(Deserialize)]
struct Input {
    tandoor: meal_planner::tandoor::TandoorConfig,
    recipe_id: i64,
    nutrition: NutritionInput,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    recipe_id: i64,
    #[serde(skip_serializing_if = "Option::is_none")]
    recipe: Option<Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    match run() {
        Ok(output) => {
            println!(
                "{}",
                serde_json::to_string(&output).expect("Failed to serialize output JSON")
            );
        }
        Err(e) => {
            let output = Output {
                success: false,
                recipe_id: 0,
                recipe: None,
                error: Some(e.to_string()),
            };
            println!(
                "{}",
                serde_json::to_string(&output).expect("Failed to serialize error JSON")
            );
            std::process::exit(1);
        }
    }
}

fn run() -> Result<Output, Box<dyn std::error::Error>> {
    let input = read_input()?;
    validate_input(&input)?;
    let client = TandoorClient::new(&input.tandoor)?;
    let request = build_update_request(&input)?;
    let recipe = client.update_recipe(input.recipe_id, &request)?;
    Ok(success_output(input.recipe_id, recipe))
}

fn read_input() -> Result<Input, Box<dyn std::error::Error>> {
    let input_str = if let Some(arg) = std::env::args().nth(1) {
        arg
    } else {
        let mut s = String::new();
        io::stdin().read_to_string(&mut s)?;
        s
    };
    serde_json::from_str(&input_str).map_err(|e| e.into())
}

fn validate_input(input: &Input) -> Result<(), Box<dyn std::error::Error>> {
    let nutrition_value = serde_json::to_value(&input.nutrition)?;
    if !validate_nutrition_input(&nutrition_value) {
        return Err("At least one valid nutrition field required".into());
    }
    Ok(())
}

fn build_update_request(input: &Input) -> Result<Value, Box<dyn std::error::Error>> {
    let nutrition_value = serde_json::to_value(&input.nutrition)?;
    Ok(build_nutrition_update_request(&nutrition_value))
}

fn success_output(recipe_id: i64, recipe: Value) -> Output {
    Output {
        success: true,
        recipe_id,
        recipe: Some(recipe),
        error: None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_nutrition_input_parsing() {
        let json = r#"{"tandoor": {"base_url": "http://localhost", "api_token": "token"}, "recipe_id": 123, "nutrition": {"calories": 450.0, "protein": 25.0}}"#;
        let input: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert_eq!(input.recipe_id, 123);
        assert_eq!(input.nutrition.calories, Some(450.0));
        assert_eq!(input.nutrition.protein, Some(25.0));
    }

    #[test]
    fn test_nutrition_input_partial() {
        let json = r#"{"tandoor": {"base_url": "http://localhost", "api_token": "token"}, "recipe_id": 456, "nutrition": {"calories": 300.0}}"#;
        let input: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert_eq!(input.recipe_id, 456);
        assert_eq!(input.nutrition.calories, Some(300.0));
        assert!(input.nutrition.protein.is_none());
    }

    #[test]
    fn test_output_serialize() {
        let output = success_output(
            123,
            json!({"id": 123, "name": "Test Recipe", "nutrition": {}}),
        );
        let json = serde_json::to_string(&output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"recipe_id\":123"));
    }

    #[test]
    fn test_error_output_serialize() {
        let output = Output {
            success: false,
            recipe_id: 0,
            recipe: None,
            error: Some("Update failed".to_string()),
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("\"error\""));
    }
}
