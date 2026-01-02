//! Calculate total nutrition for a Tandoor recipe
//!
//! ## Binary Contract (FUNCTIONAL CORE / IMPERATIVE SHELL)
//!
//! ### Input (JSON stdin):
//! ```json
//! {
//!   "tandoor": {"base_url": "...", "api_token": "..."},
//!   "recipe_id": 123
//! }
//! ```
//!
//! ### Output (JSON stdout):
//! ```json
//! {
//!   "success": true,
//!   "recipe_id": 123,
//!   "recipe_name": "Recipe Name",
//!   "nutrition": {"calories": 0.0, "protein": 0.0, "carbohydrate": 0.0, "fat": 0.0},
//!   "ingredient_count": 0,
//!   "failed_ingredients": []
//! }
//! ```
//!
//! ## Architecture
//!
//! - **FUNCTIONAL CORE**: Pure calculation functions in `tandoor::nutrition` module
//! - **IMPERATIVE SHELL**: This binary handles all I/O (API calls, JSON parsing)
//!
//! ## Nutrition Sources
//!
//! This binary calculates nutrition using stored properties in the recipe.

#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::tandoor::nutrition::{extract_ingredient_info, scale_nutrition_to_grams};
use meal_planner::tandoor::{TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use serde_json::json;
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    tandoor: TandoorConfig,
    recipe_id: i64,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    recipe_id: i64,
    recipe_name: String,
    nutrition: Nutrition,
    ingredient_count: usize,
    failed_ingredients: Vec<String>,
}

#[derive(Serialize, Default)]
struct Nutrition {
    calories: f64,
    protein: f64,
    carbohydrate: f64,
    fat: f64,
}

fn main() {
    match run() {
        Ok(output) => println!(
            "{}",
            serde_json::to_string(&output).expect("Failed to serialize output JSON")
        ),
        Err(e) => {
            println!("{{\"success\":false,\"error\":\"{}\"}}", e);
            std::process::exit(1);
        }
    }
}

fn run() -> Result<Output, String> {
    let input = read_input()?;
    let client = TandoorClient::new(&input.tandoor).map_err(|e| e.to_string())?;
    let recipe = client
        .get_recipe(input.recipe_id)
        .map_err(|e| e.to_string())?;
    let recipe_name = get_recipe_name(&recipe);
    let steps = recipe
        .get("steps")
        .and_then(|s| s.as_array())
        .ok_or("No steps found in recipe")?;

    let (nutrition, ingredient_count, failed_ingredients) =
        calculate_recipe_nutrition(&recipe, steps)?;

    Ok(Output {
        success: true,
        recipe_id: input.recipe_id,
        recipe_name,
        nutrition,
        ingredient_count,
        failed_ingredients,
    })
}

fn read_input() -> Result<Input, String> {
    let mut s = String::new();
    io::stdin()
        .read_to_string(&mut s)
        .map_err(|e| e.to_string())?;
    serde_json::from_str(&s).map_err(|e| e.to_string())
}

fn get_recipe_name(recipe: &serde_json::Value) -> String {
    recipe
        .get("name")
        .and_then(|n| n.as_str())
        .unwrap_or("Unknown")
        .to_string()
}

fn calculate_recipe_nutrition(
    recipe: &serde_json::Value,
    steps: &[serde_json::Value],
) -> Result<(Nutrition, usize, Vec<String>), String> {
    let mut nutrition = Nutrition::default();
    let mut ingredient_count = 0usize;
    let mut failed_ingredients = Vec::new();

    for step in steps {
        let ingredients = step.get("ingredients").and_then(|i| i.as_array());
        if let Some(ings) = ingredients {
            for ingredient in ings {
                ingredient_count += 1;
                match calculate_single_ingredient_nutrition(recipe, ingredient) {
                    Ok(ing_nutrition) => add_nutrition(&mut nutrition, ing_nutrition),
                    Err(_) => add_failed_ingredient(ingredient, &mut failed_ingredients),
                }
            }
        }
    }

    Ok((nutrition, ingredient_count, failed_ingredients))
}

fn calculate_single_ingredient_nutrition(
    recipe: &serde_json::Value,
    ingredient: &serde_json::Value,
) -> Result<Nutrition, String> {
    let amount = ingredient
        .get("amount")
        .and_then(|a| a.as_f64())
        .unwrap_or(0.0);
    let _food = ingredient.get("food").ok_or("Ingredient has no food")?;

    let properties = get_food_properties(recipe)?;
    let serving_size = get_serving_size(&properties);
    let serving_nutrition = build_serving_nutrition(&properties);
    let scaled = scale_nutrition_to_grams(&serving_nutrition, serving_size, amount);

    extract_nutrition_from_scaled(&scaled)
}

fn get_food_properties(recipe: &serde_json::Value) -> Result<serde_json::Value, String> {
    let nutrition_prop = recipe.get("nutrition");
    if let Some(nut) = nutrition_prop {
        if nut.is_object() && !nut.is_null() {
            return Ok(nut.clone());
        }
    }
    Ok(json!({}))
}

fn get_serving_size(properties: &serde_json::Value) -> f64 {
    properties
        .get("serving_size_grams")
        .and_then(|s| s.as_f64())
        .unwrap_or(100.0)
}

fn build_serving_nutrition(properties: &serde_json::Value) -> serde_json::Value {
    json!({
        "calories": properties.get("calories").and_then(|c| c.as_f64()).unwrap_or(0.0),
        "protein": properties.get("protein").and_then(|p| p.as_f64()).unwrap_or(0.0),
        "carbohydrate": properties.get("carbohydrate").and_then(|c| c.as_f64()).unwrap_or(0.0),
        "fat": properties.get("fat").and_then(|f| f.as_f64()).unwrap_or(0.0),
    })
}

fn extract_nutrition_from_scaled(scaled: &serde_json::Value) -> Result<Nutrition, String> {
    Ok(Nutrition {
        calories: scaled
            .get("calories")
            .and_then(|c| c.as_f64())
            .unwrap_or(0.0),
        protein: scaled
            .get("protein")
            .and_then(|p| p.as_f64())
            .unwrap_or(0.0),
        carbohydrate: scaled
            .get("carbohydrate")
            .and_then(|c| c.as_f64())
            .unwrap_or(0.0),
        fat: scaled.get("fat").and_then(|f| f.as_f64()).unwrap_or(0.0),
    })
}

fn add_nutrition(total: &mut Nutrition, addition: Nutrition) {
    total.calories += addition.calories;
    total.protein += addition.protein;
    total.carbohydrate += addition.carbohydrate;
    total.fat += addition.fat;
}

fn add_failed_ingredient(ingredient: &serde_json::Value, failed: &mut Vec<String>) {
    let (name, _, _) = extract_ingredient_info(ingredient);
    if !name.is_empty() {
        failed.push(name);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_parsing_minimal() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "recipe_id": 123}"#;
        let parsed: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert_eq!(parsed.tandoor.base_url, "http://localhost:8090");
        assert_eq!(parsed.tandoor.api_token, "test");
        assert_eq!(parsed.recipe_id, 123);
    }

    #[test]
    fn test_output_serialization_success() {
        let output = Output {
            success: true,
            recipe_id: 123,
            recipe_name: "Test Recipe".to_string(),
            nutrition: Nutrition {
                calories: 100.0,
                protein: 10.0,
                carbohydrate: 20.0,
                fat: 5.0,
            },
            ingredient_count: 5,
            failed_ingredients: vec!["salt".to_string()],
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"recipe_name\":\"Test Recipe\""));
        assert!(json.contains("\"calories\":100"));
        assert!(json.contains("\"ingredient_count\":5"));
    }

    #[test]
    fn test_nutrition_default() {
        let nutrition = Nutrition::default();
        assert_eq!(nutrition.calories, 0.0);
        assert_eq!(nutrition.protein, 0.0);
        assert_eq!(nutrition.carbohydrate, 0.0);
        assert_eq!(nutrition.fat, 0.0);
    }

    #[test]
    fn test_read_input_from_json() {
        let json = r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "token"}, "recipe_id": 42}"#;
        let result = serde_json::from_str::<Input>(json);
        assert!(result.is_ok());
        let input = result.unwrap();
        assert_eq!(input.recipe_id, 42);
    }

    #[test]
    fn test_get_recipe_name() {
        let recipe = json!({"name": "Test Recipe"});
        assert_eq!(get_recipe_name(&recipe), "Test Recipe");
    }

    #[test]
    fn test_get_recipe_name_unknown() {
        let recipe = json!({});
        assert_eq!(get_recipe_name(&recipe), "Unknown");
    }

    #[test]
    fn test_add_nutrition() {
        let mut total = Nutrition::default();
        let addition = Nutrition {
            calories: 100.0,
            protein: 10.0,
            carbohydrate: 20.0,
            fat: 5.0,
        };
        add_nutrition(&mut total, addition);
        assert_eq!(total.calories, 100.0);
        assert_eq!(total.protein, 10.0);
    }

    #[test]
    fn test_add_failed_ingredient() {
        let ingredient = json!({
            "food": {"name": "salt"},
            "amount": 5.0,
            "unit": {"name": "g"}
        });
        let mut failed = Vec::new();
        add_failed_ingredient(&ingredient, &mut failed);
        assert_eq!(failed.len(), 1);
        assert_eq!(failed[0], "salt");
    }
}
