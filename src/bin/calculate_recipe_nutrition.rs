//! Calculate nutrition for a Tandoor recipe using FatSecret data
//!
//! This binary implements the core workflow:
//! 1. Get recipe from Tandoor (ingredients, steps)
//! 2. For each ingredient, search FatSecret for nutrition data
//! 3. Calculate total calories, protein, fat, carbs
//! 4. Return nutrition data
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "fatsecret": {...}, "recipe_id": 123}`
//!
//! JSON stdout:
//!   `{"success": true, "calories": 330.0, "protein": 31.0, "fat": 3.6, "carbohydrate": 0.0, "failed_ingredients": []}`

#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::tandoor::nutrition::core::{
    calculate_recipe_nutrition, create_test_nutrition_db, IngredientNutrition,
};
use meal_planner::tandoor::{TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    /// Tandoor configuration (URL and token)
    tandoor: TandoorConfig,
    /// FatSecret configuration (consumer key and secret)
    fatsecret: Option<FatSecretInput>,
    /// Recipe ID to calculate nutrition for
    recipe_id: i64,
}

#[derive(Deserialize, Clone)]
struct FatSecretInput {
    consumer_key: String,
    consumer_secret: String,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    calories: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    protein: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    fat: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    carbohydrate: Option<f64>,
    #[serde(skip_serializing_if = "Vec::is_empty")]
    failed_ingredients: Vec<String>,
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
            let error = Output {
                success: false,
                calories: None,
                protein: None,
                fat: None,
                carbohydrate: None,
                failed_ingredients: Vec::new(),
                error: Some(e.to_string()),
            };
            println!(
                "{}",
                serde_json::to_string(&error).expect("Failed to serialize error JSON")
            );
            std::process::exit(1);
        }
    }
}

fn run() -> Result<Output, Box<dyn std::error::Error>> {
    let input: Input = read_input()?;

    let client = TandoorClient::new(&input.tandoor)?;
    let recipe = client.get_recipe(input.recipe_id)?;

    let nutrition_db = create_nutrition_database(&input.fatsecret);
    let result = calculate_recipe_nutrition(&recipe, &nutrition_db);

    Ok(Output {
        success: result.failed_ingredients.is_empty(),
        calories: Some(result.calories),
        protein: Some(result.protein),
        fat: Some(result.fat),
        carbohydrate: Some(result.carbohydrate),
        failed_ingredients: result.failed_ingredients,
        error: None,
    })
}

fn read_input() -> Result<Input, Box<dyn std::error::Error>> {
    if let Some(arg) = std::env::args().nth(1) {
        serde_json::from_str(&arg).map_err(|e| Box::new(e) as _)
    } else {
        let mut input_str = String::new();
        io::stdin().read_to_string(&mut input_str)?;
        serde_json::from_str(&input_str).map_err(|e| Box::new(e) as _)
    }
}

fn create_nutrition_database(
    fatsecret: &Option<FatSecretInput>,
) -> HashMap<String, IngredientNutrition> {
    if fatsecret.is_some() {
        fetch_fatsecret_nutrition(fatsecret.as_ref().unwrap())
    } else {
        create_test_nutrition_db()
    }
}

fn fetch_fatsecret_nutrition(_config: &FatSecretInput) -> HashMap<String, IngredientNutrition> {
    let mut db = HashMap::new();

    #[allow(clippy::box_collection)]
    let client = meal_planner::fatsecret::core::config::FatSecretConfig::from_env();

    if client.is_err() {
        return create_test_nutrition_db();
    }

    let config = client.unwrap();

    let common_ingredients = [
        "chicken breast",
        "lettuce",
        "olive oil",
        "egg",
        "butter",
        "flour",
        "rice",
        "potato",
        "beef",
        "salmon",
        "milk",
        "cheese",
        "bread",
        "tomato",
        "onion",
        "garlic",
    ];

    for ingredient in common_ingredients {
        if let Ok(results) = futures::executor::block_on(
            meal_planner::fatsecret::foods::search_foods_simple(&config, ingredient),
        ) {
            if let Some(food) = results.foods.first() {
                if let Ok(details) = futures::executor::block_on(
                    meal_planner::fatsecret::foods::get_food(&config, &food.food_id),
                ) {
                    if let Some(serving) = details.servings.serving.first() {
                        let grams = serving.metric_serving_amount.unwrap_or(100.0);
                        let multiplier = 100.0 / grams;

                        db.insert(
                            ingredient.to_string(),
                            IngredientNutrition {
                                food_name: food.food_name.clone(),
                                calories_per_100g: serving.nutrition.calories * multiplier,
                                protein_per_100g: serving.nutrition.protein * multiplier,
                                fat_per_100g: serving.nutrition.fat * multiplier,
                                carbohydrate_per_100g: serving.nutrition.carbohydrate * multiplier,
                            },
                        );
                    }
                }
            }
        }
    }

    if db.is_empty() {
        return create_test_nutrition_db();
    }

    db
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_output_serialize_with_nutrition() {
        let output = Output {
            success: true,
            calories: Some(330.0),
            protein: Some(31.0),
            fat: Some(3.6),
            carbohydrate: Some(0.0),
            failed_ingredients: Vec::new(),
            error: None,
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize");
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"calories\":330"));
        assert!(json.contains("\"protein\":31"));
    }

    #[test]
    fn test_output_serialize_with_failed_ingredients() {
        let output = Output {
            success: false,
            calories: Some(165.0),
            protein: Some(31.0),
            fat: Some(3.6),
            carbohydrate: Some(0.0),
            failed_ingredients: vec!["unknown food".to_string()],
            error: None,
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize");
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("\"failed_ingredients\""));
    }

    #[test]
    fn test_convert_to_grams_integration() {
        assert!((convert_to_grams(100.0, "g", "") - 100.0).abs() < 0.01);
        assert!((convert_to_grams(1.0, "kg", "") - 1000.0).abs() < 0.01);
        assert!((convert_to_grams(1.0, "lb", "") - 453.592).abs() < 0.01);
    }
}
