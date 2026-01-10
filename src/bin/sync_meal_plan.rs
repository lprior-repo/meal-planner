//! Sync Tandoor Meal Plan to FatSecret Diary
//!
//! This binary syncs meal plan entries to FatSecret by creating diary entries
//! for each meal in the plan. It handles batch processing and error recovery.
//!
//! This is part of the Tandoor ↔ FatSecret sync layer.
//!
//! JSON input (CLI arg or stdin):
//! ```json
//! {
//!   "fatsecret": {"consumer_key": "...", "consumer_secret": "..."},
//!   "access_token": "...",
//!   "access_secret": "...",
//!   "entries": [
//!     {
//!       "date": "2025-01-01",
//!       "meal_type": "breakfast",
//!       "recipe_name": "Oatmeal",
//!       "servings": 1.0,
//!       "calories": 300,
//!       "protein": 10,
//!       "carbohydrate": 50,
//!       "fat": 5
//!     }
//!   ]
//! }
//! ```
//!
//! JSON stdout:
//! ```json
//! {
//!   "success": true,
//!   "entries_synced": 15,
//!   "entries_failed": 0,
//!   "total_calories": 14000.0,
//!   "days_processed": 7
//! }
//! ```

#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used, clippy::too_many_lines)]

use meal_planner::fatsecret::core::{AccessToken, FatSecretConfig};
use meal_planner::fatsecret::diary::{create_food_entry, date_to_int, FoodEntryInput, MealType};
use meal_planner::sync::types::NutritionData;
use serde::{Deserialize, Serialize};
use std::collections::HashSet;
use std::io::{self, Read};

#[derive(Deserialize)]
struct FatSecretResource {
    consumer_key: String,
    consumer_secret: String,
}

#[derive(Deserialize)]
struct MealPlanEntry {
    /// Date (YYYY-MM-DD)
    date: String,
    /// Meal type: breakfast, lunch, dinner, or snack
    meal_type: String,
    /// Recipe or meal name
    recipe_name: String,
    /// Number of servings
    servings: f64,
    /// Calories per serving
    calories: f64,
    /// Protein per serving (grams)
    protein: f64,
    /// Carbohydrates per serving (grams)
    carbohydrate: f64,
    /// Fat per serving (grams)
    fat: f64,
}

#[derive(Deserialize)]
struct Input {
    /// FatSecret credentials (optional, uses env if not provided)
    fatsecret: Option<FatSecretResource>,
    /// OAuth access token for FatSecret
    access_token: String,
    /// OAuth access token secret for FatSecret
    access_secret: String,
    /// Meal plan entries to sync
    entries: Vec<MealPlanEntry>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    entries_synced: usize,
    entries_failed: usize,
    total_calories: f64,
    total_protein: f64,
    days_processed: usize,
    synced_entries: Vec<SyncedEntry>,
    errors: Vec<String>,
}

#[derive(Serialize)]
struct SyncedEntry {
    date: String,
    meal_type: String,
    recipe_name: String,
    food_entry_id: String,
    calories: f64,
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

    // Set up FatSecret config
    let fs_config = match input.fatsecret {
        Some(r) => FatSecretConfig::new(r.consumer_key, r.consumer_secret)?,
        None => FatSecretConfig::from_env()?,
    };

    let token = AccessToken::new(input.access_token, input.access_secret);

    let mut synced_entries = Vec::new();
    let mut errors = Vec::new();
    let mut total_nutrition = NutritionData::zero();
    let mut days_seen: HashSet<String> = HashSet::new();

    for entry in input.entries {
        // Calculate total nutrition for the entry
        let entry_nutrition = NutritionData {
            calories: entry.calories * entry.servings,
            protein: entry.protein * entry.servings,
            carbohydrate: entry.carbohydrate * entry.servings,
            fat: entry.fat * entry.servings,
            ..NutritionData::zero()
        };

        // Convert meal type
        let meal = match entry.meal_type.to_lowercase().as_str() {
            "breakfast" => MealType::Breakfast,
            "lunch" => MealType::Lunch,
            "dinner" => MealType::Dinner,
            _ => MealType::Snack,
        };

        // Convert date to FatSecret format
        let date_int = match date_to_int(&entry.date) {
            Ok(d) => d,
            Err(e) => {
                errors.push(format!("Invalid date {}: {}", entry.date, e));
                continue;
            }
        };

        // Create food entry
        let entry_input = FoodEntryInput::Custom {
            food_entry_name: format!("{} (Tandoor)", entry.recipe_name),
            serving_description: format!("{} servings", entry.servings),
            number_of_units: 1.0,
            meal,
            date_int,
            calories: entry_nutrition.calories,
            carbohydrate: entry_nutrition.carbohydrate,
            protein: entry_nutrition.protein,
            fat: entry_nutrition.fat,
        };

        match create_food_entry(&fs_config, &token, entry_input).await {
            Ok(entry_id) => {
                synced_entries.push(SyncedEntry {
                    date: entry.date.clone(),
                    meal_type: entry.meal_type.clone(),
                    recipe_name: entry.recipe_name.clone(),
                    food_entry_id: entry_id.to_string(),
                    calories: entry_nutrition.calories,
                });

                total_nutrition = total_nutrition.add(&entry_nutrition);
                days_seen.insert(entry.date.clone());
            }
            Err(e) => {
                errors.push(format!(
                    "Failed to sync {} on {}: {}",
                    entry.recipe_name, entry.date, e
                ));
            }
        }
    }

    Ok(Output {
        success: errors.is_empty(),
        entries_synced: synced_entries.len(),
        entries_failed: errors.len(),
        total_calories: total_nutrition.calories,
        total_protein: total_nutrition.protein,
        days_processed: days_seen.len(),
        synced_entries,
        errors,
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
            entries_synced: 15,
            entries_failed: 0,
            total_calories: 14000.0,
            total_protein: 700.0,
            days_processed: 7,
            synced_entries: vec![],
            errors: vec![],
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize");
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"entries_synced\":15"));
    }

    #[test]
    fn test_error_output_serialize() {
        let error = ErrorOutput {
            success: false,
            error: "Test error".to_string(),
        };
        let json = serde_json::to_string(&error).expect("Failed to serialize");
        assert!(json.contains("\"success\":false"));
    }

    #[test]
    fn test_synced_entry_serialize() {
        let entry = SyncedEntry {
            date: "2025-01-01".to_string(),
            meal_type: "lunch".to_string(),
            recipe_name: "Grilled Chicken".to_string(),
            food_entry_id: "123456".to_string(),
            calories: 450.0,
        };
        let json = serde_json::to_string(&entry).expect("Failed to serialize");
        assert!(json.contains("\"recipe_name\":\"Grilled Chicken\""));
    }
}
