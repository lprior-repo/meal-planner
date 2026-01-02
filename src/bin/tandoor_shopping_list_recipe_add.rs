//! Add recipe to shopping list
//!
//! Adds all ingredients from a recipe to shopping list for a meal plan.
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "mealplan_id": 123, "recipe_id": 456, "servings": 4.0}`
//!
//! JSON stdout: `{"success": true, "entries": [...]}`

#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::tandoor::{ShoppingListRecipe, TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Debug, Deserialize, Serialize)]
pub struct Input {
    #[serde(flatten)]
    pub tandoor: TandoorConfig,
    pub mealplan_id: i64,
    pub recipe_id: i64,
    pub servings: f64,
}

#[derive(Debug, Serialize)]
pub struct Output {
    pub success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub entries: Option<Vec<ShoppingListRecipe>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
}

fn read_input() -> Result<Input, String> {
    let input_str = std::env::args().nth(1).map_or_else(
        || {
            let mut s = String::new();
            io::stdin()
                .read_to_string(&mut s)
                .map_err(|e| e.to_string())?;
            Ok::<String, String>(s)
        },
        Ok,
    )?;
    serde_json::from_str(&input_str).map_err(|e| e.to_string())
}

fn execute(input: &Input) -> Result<Vec<ShoppingListRecipe>, String> {
    let client = TandoorClient::new(&input.tandoor).map_err(|e| e.to_string())?;
    client
        .add_recipe_to_shopping_list(input.mealplan_id, input.recipe_id, input.servings)
        .map_err(|e| e.to_string())
}

fn format_output(result: Result<Vec<ShoppingListRecipe>, String>) -> Output {
    match result {
        Ok(entries) => Output {
            success: true,
            entries: Some(entries),
            error: None,
        },
        Err(msg) => Output {
            success: false,
            entries: None,
            error: Some(msg),
        },
    }
}

fn print_output(output: &Output) {
    let json = serde_json::to_string(output).expect("Failed to serialize output JSON");
    println!("{}", json);
    if !output.success {
        std::process::exit(1);
    }
}

fn main() {
    let input = match read_input() {
        Ok(i) => i,
        Err(e) => {
            let output = Output {
                success: false,
                entries: None,
                error: Some(e),
            };
            print_output(&output);
            return;
        }
    };

    let result = execute(&input);
    let output = format_output(result);
    print_output(&output);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_deserialization() {
        let json = r#"{"base_url": "http://localhost:8090", "api_token": "test", "mealplan_id": 123, "recipe_id": 456, "servings": 4.0}"#;
        let input: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert_eq!(input.mealplan_id, 123);
        assert_eq!(input.recipe_id, 456);
        assert_eq!(input.servings, 4.0);
    }

    #[test]
    fn test_output_serialization_success() {
        let output = Output {
            success: true,
            entries: Some(vec![]),
            error: None,
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize output JSON");
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
        let json = serde_json::to_string(&output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("Recipe not found"));
    }

    #[test]
    fn test_format_output_success() {
        let recipes = vec![ShoppingListRecipe {
            id: 1,
            mealplan: 123,
            recipe: 456,
            recipe_name: "Test Recipe".to_string(),
            list: 1,
            servings: 4.0,
            entries: vec![],
        }];
        let output = format_output(Ok(recipes));
        assert!(output.success);
        assert!(output.entries.is_some());
        assert_eq!(output.entries.unwrap().len(), 1);
        assert!(output.error.is_none());
    }

    #[test]
    fn test_format_output_error() {
        let output = format_output(Err("API error".to_string()));
        assert!(!output.success);
        assert!(output.entries.is_none());
        assert_eq!(output.error, Some("API error".to_string()));
    }
}
