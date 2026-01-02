//! Lookup nutrition data for a Tandoor ingredient from FatSecret API
//!
//! This binary is part of the IMPERATIVE SHELL - it handles all I/O.
//! Pure logic lives in meal_planner::tandoor::nutrition (FUNCTIONAL CORE).

#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::fatsecret::core::FatSecretConfig;
use meal_planner::fatsecret::foods::{get_food, search_foods_simple};
use meal_planner::tandoor::nutrition::{convert_to_grams, scale_nutrition_to_grams};
use serde::{Deserialize, Serialize};
use serde_json::json;
use std::io::{self, Read};

#[derive(Deserialize)]
struct FatSecretResource {
    consumer_key: String,
    consumer_secret: String,
}

#[derive(Deserialize)]
struct Input {
    fatsecret: Option<FatSecretResource>,
    ingredient_name: String,
    amount: f64,
    unit: String,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    food_id: String,
    food_name: String,
    nutrition: serde_json::Value,
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
                serde_json::to_string(&output).expect("Serialization failed")
            );
        }
        Err(e) => {
            let error = ErrorOutput {
                success: false,
                error: e.to_string(),
            };
            eprintln!(
                "{}",
                serde_json::to_string(&error).expect("Serialization failed")
            );
            std::process::exit(1);
        }
    }
}

async fn run() -> Result<Output, Box<dyn std::error::Error>> {
    // Read input
    let input: Input = if let Some(arg) = std::env::args().nth(1) {
        serde_json::from_str(&arg)?
    } else {
        let mut s = String::new();
        io::stdin().read_to_string(&mut s)?;
        serde_json::from_str(&s)?
    };

    // Get config
    let config = match input.fatsecret {
        Some(r) => FatSecretConfig::new(r.consumer_key, r.consumer_secret)?,
        None => FatSecretConfig::from_env()?,
    };

    // Search for food
    let search_results = search_foods_simple(&config, &input.ingredient_name).await?;
    let first_food = search_results.foods.first().ok_or("No foods found")?;

    // Get detailed food info
    let food = get_food(&config, &first_food.food_id).await?;

    // Find default serving or use first
    let serving = food
        .servings
        .serving
        .iter()
        .find(|s| s.is_default == Some(1))
        .or_else(|| food.servings.serving.first())
        .ok_or("No servings found")?;

    // Convert to grams (FUNCTIONAL CORE)
    let target_grams = convert_to_grams(input.amount, &input.unit, &input.ingredient_name);

    // Get serving size in grams
    let serving_size_grams = serving
        .metric_serving_amount
        .ok_or("No metric serving amount")?;

    // Build serving nutrition
    let serving_nutrition = json!({
        "calories": serving.nutrition.calories,
        "protein": serving.nutrition.protein,
        "carbohydrate": serving.nutrition.carbohydrate,
        "fat": serving.nutrition.fat,
    });

    // Scale nutrition (FUNCTIONAL CORE)
    let scaled_nutrition =
        scale_nutrition_to_grams(&serving_nutrition, serving_size_grams, target_grams);

    Ok(Output {
        success: true,
        food_id: first_food.food_id.to_string(),
        food_name: first_food.food_name.clone(),
        nutrition: scaled_nutrition,
    })
}
