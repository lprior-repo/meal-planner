//! Log a Tandoor recipe to FatSecret food diary
//!
//! This binary syncs a Tandoor recipe to FatSecret by logging it as a custom diary entry.
//! It uses the recipe's nutrition data (calories, protein, carbs, fat) directly.
//!
//! This is part of the Tandoor ↔ FatSecret sync layer.
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "fatsecret": {...}, "access_token": "...", "access_secret": "...",
//!     "recipe_id": 123, "servings": 2.0, "meal": "dinner", "date": "2025-01-01"}`
//!
//! JSON stdout:
//!   `{"success": true, "food_entry_id": "123456789", "recipe_name": "Grilled Chicken",
//!     "calories": 450.0, "protein": 40.0, "carbohydrate": 5.0, "fat": 25.0}`

#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used, clippy::too_many_lines)]

use meal_planner::fatsecret::core::{AccessToken, FatSecretConfig};
use meal_planner::fatsecret::diary::{create_food_entry, date_to_int, FoodEntryInput, MealType};
use meal_planner::tandoor::{TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct TandoorResource {
    base_url: String,
    api_token: String,
}

#[derive(Deserialize)]
struct FatSecretResource {
    consumer_key: String,
    consumer_secret: String,
}

#[derive(Deserialize)]
struct Input {
    /// Tandoor configuration
    tandoor: TandoorResource,
    /// FatSecret credentials
    fatsecret: Option<FatSecretResource>,
    /// OAuth access token for FatSecret
    access_token: String,
    /// OAuth access token secret for FatSecret
    access_secret: String,
    /// Tandoor recipe ID to log
    recipe_id: i64,
    /// Number of servings consumed (defaults to recipe's default servings)
    servings: Option<f64>,
    /// Meal type: breakfast, lunch, dinner, or other
    meal: String,
    /// Date in YYYY-MM-DD format
    date: String,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    food_entry_id: String,
    recipe_name: String,
    calories: f64,
    protein: f64,
    carbohydrate: f64,
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

    // Get recipe from Tandoor
    let tandoor_config = TandoorConfig {
        base_url: input.tandoor.base_url.clone(),
        api_token: input.tandoor.api_token.clone(),
    };
    let tandoor_client = TandoorClient::new(&tandoor_config)?;
    let recipe = tandoor_client.get_recipe(input.recipe_id)?;

    // Extract recipe name
    let recipe_name = recipe
        .get("name")
        .and_then(serde_json::Value::as_str)
        .ok_or("Recipe has no name")?
        .to_string();

    // Extract nutrition from recipe (as JSON Value)
    let nutrition = recipe
        .get("nutrition")
        .ok_or("Recipe has no nutrition data. Run nutrition calculation first.")?;

    // Calculate per-serving nutrition scaled by requested servings
    // Note: servings are typically small integers, safe to convert to f64
    #[allow(clippy::cast_precision_loss)]
    let recipe_servings = recipe
        .get("servings")
        .and_then(serde_json::Value::as_i64)
        .unwrap_or(1) as f64;
    let requested_servings = input.servings.unwrap_or(recipe_servings);
    let multiplier = if recipe_servings > 0.0 {
        requested_servings / recipe_servings
    } else {
        1.0
    };

    // Extract nutrition values (Tandoor uses "calories", "proteins", "carbohydrates", "fats")
    let calories = nutrition
        .get("calories")
        .and_then(serde_json::Value::as_f64)
        .unwrap_or(0.0)
        * multiplier;
    let protein = nutrition
        .get("proteins")
        .and_then(serde_json::Value::as_f64)
        .unwrap_or(0.0)
        * multiplier;
    let carbohydrate = nutrition
        .get("carbohydrates")
        .and_then(serde_json::Value::as_f64)
        .unwrap_or(0.0)
        * multiplier;
    let fat = nutrition
        .get("fats")
        .and_then(serde_json::Value::as_f64)
        .unwrap_or(0.0)
        * multiplier;

    // Get FatSecret config
    let fs_config = match input.fatsecret {
        Some(r) => FatSecretConfig::new(r.consumer_key, r.consumer_secret)?,
        None => FatSecretConfig::from_env()?,
    };

    // Build access token
    let token = AccessToken::new(input.access_token, input.access_secret);

    // Parse meal type
    let meal = MealType::from_api_string(&input.meal).ok_or_else(|| {
        format!(
            "Invalid meal type: {}. Expected: breakfast, lunch, dinner, or other",
            input.meal
        )
    })?;

    // Convert date to FatSecret date_int
    let date_int = date_to_int(&input.date)?;

    // Build serving description
    let serving_desc = format!("{} servings from Tandoor recipe", requested_servings);

    // Create custom food entry (uses recipe nutrition directly)
    let entry_input = FoodEntryInput::Custom {
        food_entry_name: recipe_name.clone(),
        serving_description: serving_desc,
        number_of_units: 1.0, // 1 unit = the calculated serving amount
        meal,
        date_int,
        calories,
        carbohydrate,
        protein,
        fat,
    };

    // Create the diary entry
    let entry_id = create_food_entry(&fs_config, &token, entry_input).await?;

    Ok(Output {
        success: true,
        food_entry_id: entry_id.to_string(),
        recipe_name,
        calories,
        protein,
        carbohydrate,
        fat,
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
            food_entry_id: "123456".to_string(),
            recipe_name: "Grilled Chicken".to_string(),
            calories: 450.0,
            protein: 40.0,
            carbohydrate: 5.0,
            fat: 25.0,
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize");
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"recipe_name\":\"Grilled Chicken\""));
        assert!(json.contains("\"calories\":450"));
    }

    #[test]
    fn test_error_output_serialize() {
        let error = ErrorOutput {
            success: false,
            error: "Test error".to_string(),
        };
        let json = serde_json::to_string(&error).expect("Failed to serialize");
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("\"error\":\"Test error\""));
    }
}
