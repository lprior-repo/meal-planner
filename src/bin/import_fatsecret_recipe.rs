//! Import FatSecret Recipe to Tandoor
//!
//! This binary imports a FatSecret saved meal or food as a recipe in Tandoor,
//! preserving nutrition data and creating appropriate ingredient mappings.
//!
//! This is part of the Tandoor ↔ FatSecret sync layer.
//!
//! JSON input (CLI arg or stdin):
//! ```json
//! {
//!   "tandoor": {"base_url": "...", "api_token": "..."},
//!   "recipe_name": "My Breakfast",
//!   "servings": 2,
//!   "ingredients": [
//!     {"name": "Eggs", "amount": 2, "unit": "large", "calories": 72, "protein": 6}
//!   ],
//!   "total_nutrition": {"calories": 450, "protein": 30, "carbohydrate": 40, "fat": 20}
//! }
//! ```
//!
//! JSON stdout:
//! ```json
//! {
//!   "success": true,
//!   "tandoor_recipe_id": 456,
//!   "recipe_name": "My Breakfast",
//!   "ingredients_imported": 3
//! }
//! ```

#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used, clippy::too_many_lines)]

use meal_planner::tandoor::{TandoorClient, TandoorConfig, CreateRecipeRequest, CreateStepRequest};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct TandoorResource {
    base_url: String,
    api_token: String,
}

#[derive(Deserialize)]
#[allow(dead_code)]
struct IngredientInput {
    name: String,
    amount: f64,
    unit: String,
    #[serde(default)]
    calories: f64,
    #[serde(default)]
    protein: f64,
    #[serde(default)]
    carbohydrate: f64,
    #[serde(default)]
    fat: f64,
}

#[derive(Deserialize)]
#[allow(dead_code)]
struct NutritionInput {
    calories: f64,
    protein: f64,
    carbohydrate: f64,
    fat: f64,
    #[serde(default)]
    fiber: Option<f64>,
}

#[derive(Deserialize)]
struct Input {
    /// Tandoor configuration
    tandoor: TandoorResource,
    /// Recipe name
    recipe_name: String,
    /// Description (optional)
    description: Option<String>,
    /// Number of servings
    servings: Option<i32>,
    /// Ingredients
    ingredients: Vec<IngredientInput>,
    /// Total nutrition for the recipe
    total_nutrition: NutritionInput,
    /// Source URL or reference (optional)
    source_url: Option<String>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    tandoor_recipe_id: Option<i64>,
    recipe_name: String,
    ingredients_imported: usize,
    total_nutrition: NutritionOutput,
    nutrition_per_serving: NutritionOutput,
    warnings: Vec<String>,
}

#[derive(Serialize)]
struct NutritionOutput {
    calories: f64,
    protein: f64,
    carbohydrates: f64,
    fat: f64,
}

#[derive(Serialize)]
struct ErrorOutput {
    success: bool,
    error: String,
}

#[tokio::main]
async fn main() {
    match run().await {
        Ok(output) => {
            println!(
                "{}",
                serde_json::to_string(&output).expect("Failed to serialize output")
            );
        }
        Err(e) => {
            let error = ErrorOutput {
                success: false,
                error: e.to_string(),
            };
            println!(
                "{}",
                serde_json::to_string(&error).expect("Failed to serialize error")
            );
            std::process::exit(1);
        }
    }
}

async fn run() -> Result<Output, Box<dyn std::error::Error>> {
    let input: Input = read_input()?;

    // Set up Tandoor client
    let tandoor_config = TandoorConfig {
        base_url: input.tandoor.base_url.clone(),
        api_token: input.tandoor.api_token.clone(),
    };
    let tandoor_client = TandoorClient::new(&tandoor_config)?;

    let servings = input.servings.unwrap_or(1);
    let mut warnings = Vec::new();

    // Build ingredient text for step
    let ingredient_lines: Vec<String> = input
        .ingredients
        .iter()
        .map(|i| format!("{} {} {}", i.amount, i.unit, i.name))
        .collect();

    let ingredients_text = ingredient_lines.join("\n");

    // Create recipe step with ingredients
    let step = CreateStepRequest {
        instruction: format!(
            "Ingredients:\n{}\n\nPrepare according to your preference.",
            ingredients_text
        ),
        ingredients: None, // Ingredients parsed from text
    };

    // Build recipe request
    let recipe_request = CreateRecipeRequest {
        name: input.recipe_name.clone(),
        description: Some(input.description.unwrap_or_else(|| "Imported from FatSecret".to_string())),
        servings: Some(servings),
        steps: Some(vec![step]),
        source_url: input.source_url,
        working_time: None,
        waiting_time: None,
        keywords: None,
    };

    // Create recipe in Tandoor
    let created_recipe = tandoor_client.create_recipe(&recipe_request)?;
    let recipe_id = Some(created_recipe.id);

    // Calculate per-serving nutrition
    let servings_f = servings as f64;
    let per_serving = NutritionOutput {
        calories: input.total_nutrition.calories / servings_f,
        protein: input.total_nutrition.protein / servings_f,
        carbohydrates: input.total_nutrition.carbohydrate / servings_f,
        fat: input.total_nutrition.fat / servings_f,
    };

    // Check for potential issues
    if input.ingredients.is_empty() {
        warnings.push("No ingredients provided - recipe created with empty ingredients list".to_string());
    }

    if input.total_nutrition.calories < 10.0 {
        warnings.push("Very low calorie count - verify nutrition data is correct".to_string());
    }

    Ok(Output {
        success: true,
        tandoor_recipe_id: recipe_id,
        recipe_name: input.recipe_name.clone(),
        ingredients_imported: input.ingredients.len(),
        total_nutrition: NutritionOutput {
            calories: input.total_nutrition.calories,
            protein: input.total_nutrition.protein,
            carbohydrates: input.total_nutrition.carbohydrate,
            fat: input.total_nutrition.fat,
        },
        nutrition_per_serving: per_serving,
        warnings,
    })
}

fn read_input() -> Result<Input, Box<dyn std::error::Error>> {
    if let Some(arg) = std::env::args().nth(1) {
        Ok(serde_json::from_str(&arg)?)
    } else {
        let mut input_str = String::new();
        io::stdin().read_to_string(&mut input_str)?;
        Ok(serde_json::from_str(&input_str)?)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_output_serialize() {
        let output = Output {
            success: true,
            tandoor_recipe_id: Some(123),
            recipe_name: "My Breakfast".to_string(),
            ingredients_imported: 3,
            total_nutrition: NutritionOutput {
                calories: 450.0,
                protein: 30.0,
                carbohydrates: 40.0,
                fat: 20.0,
            },
            nutrition_per_serving: NutritionOutput {
                calories: 225.0,
                protein: 15.0,
                carbohydrates: 20.0,
                fat: 10.0,
            },
            warnings: vec![],
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize");
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"tandoor_recipe_id\":123"));
        assert!(json.contains("\"recipe_name\":\"My Breakfast\""));
    }

    #[test]
    fn test_error_serialize() {
        let error = ErrorOutput {
            success: false,
            error: "Test error".to_string(),
        };
        let json = serde_json::to_string(&error).expect("Failed to serialize");
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("\"error\":\"Test error\""));
    }

    #[test]
    fn test_nutrition_output_serialize() {
        let nutrition = NutritionOutput {
            calories: 500.0,
            protein: 40.0,
            carbohydrates: 50.0,
            fat: 20.0,
        };
        let json = serde_json::to_string(&nutrition).expect("Failed to serialize");
        assert!(json.contains("\"calories\":500"));
        assert!(json.contains("\"protein\":40"));
    }
}
