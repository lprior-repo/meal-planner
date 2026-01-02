//! Get all recipes from Tandoor with ingredients for nutrition lookup
//!
//! Retrieves all recipes and extracts their ingredients.
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "page_size": 100}`
//!
//! JSON stdout: `{"success": true, "count": 42, "recipes": [...]}`
//!   or `{"success": false, "error": "..."}`
// CLI binaries: exit and unwrap/expect are acceptable at top level
#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::tandoor::{TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    /// Tandoor configuration (URL and token)
    tandoor: TandoorConfig,
    /// Page size (optional, defaults to 50)
    #[serde(default = "default_page_size")]
    page_size: u32,
}

fn default_page_size() -> u32 {
    50
}

#[derive(Serialize)]
struct Ingredient {
    food_name: String,
    amount: Option<f64>,
    unit_name: String,
}

#[derive(Serialize)]
struct RecipeWithIngredients {
    id: i64,
    name: String,
    servings: i32,
    ingredients: Vec<Ingredient>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    count: Option<i64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    recipes: Option<Vec<RecipeWithIngredients>>,
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
                count: None,
                recipes: None,
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
    // Read input: prefer CLI arg, fall back to stdin
    let input: Input = if let Some(arg) = std::env::args().nth(1) {
        serde_json::from_str(&arg)?
    } else {
        let mut input_str = String::new();
        io::stdin().read_to_string(&mut input_str)?;
        if input_str.trim().is_empty() {
            Input {
                tandoor: TandoorConfig::from_env()
                    .ok_or("TANDOOR_BASE_URL and TANDOOR_API_TOKEN required")?,
                page_size: default_page_size(),
            }
        } else {
            serde_json::from_str(&input_str)?
        }
    };

    let client = TandoorClient::new(&input.tandoor)?;

    // Get all recipes
    let paginated = client.list_recipes(None, Some(input.page_size))?;

    // Extract ingredients from each recipe
    let mut recipes_with_ingredients = Vec::new();

    for recipe in paginated.results {
        // Get full recipe details
        let recipe_detail = client.get_recipe(recipe.id)?;

        // Extract ingredients
        let mut ingredients = Vec::new();
        if let Some(steps) = recipe_detail.get("steps").and_then(|v| v.as_array()) {
            for step in steps {
                if let Some(ings) = step.get("ingredients").and_then(|v| v.as_array()) {
                    for ing in ings {
                        if let Some(food) = ing.get("food").and_then(|v| v.as_object()) {
                            if let Some(food_name) = food.get("name").and_then(|v| v.as_str()) {
                                let amount = ing.get("amount").and_then(|v| v.as_f64());
                                let unit_name = ing
                                    .get("unit")
                                    .and_then(|v| v.get("name"))
                                    .and_then(|v| v.as_str())
                                    .unwrap_or("piece")
                                    .to_string();

                                ingredients.push(Ingredient {
                                    food_name: food_name.to_string(),
                                    amount,
                                    unit_name,
                                });
                            }
                        }
                    }
                }
            }
        }

        let servings = recipe_detail
            .get("servings")
            .and_then(|v| v.as_i64())
            .unwrap_or(1) as i32;

        recipes_with_ingredients.push(RecipeWithIngredients {
            id: recipe.id,
            name: recipe.name,
            servings,
            ingredients,
        });
    }

    Ok(Output {
        success: true,
        count: Some(paginated.count),
        recipes: Some(recipes_with_ingredients),
        error: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_output_serialize() {
        let output = Output {
            success: true,
            count: Some(42),
            recipes: Some(vec![]),
            error: None,
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"count\":42"));
        assert!(json.contains("\"recipes\""));
    }

    #[test]
    fn test_error_output_serialize() {
        let output = Output {
            success: false,
            count: None,
            recipes: None,
            error: Some("Connection failed".to_string()),
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize error JSON");
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("\"error\""));
        assert!(!json.contains("\"count\""));
        assert!(!json.contains("\"recipes\""));
    }
}
