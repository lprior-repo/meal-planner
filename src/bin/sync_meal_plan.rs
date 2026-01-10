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
    // Check for help and schema flags first
    let args: Vec<String> = std::env::args().collect();
    if args.len() > 1 {
        let arg = &args[1];
        if arg == "--help" || arg == "-h" || arg == "help" {
            print_help();
            std::process::exit(0);
        }
        if arg == "--schema" {
            print_schema();
            std::process::exit(0);
        }
    }

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

/// Validate numeric bounds for a meal plan entry (BEAD-004)
fn validate_numeric_bounds(entry: &MealPlanEntry) -> Result<(), String> {
    // Validate servings (must be > 0 and <= 1000)
    if entry.servings <= 0.0 {
        return Err(format!(
            "servings must be greater than 0, got {}",
            entry.servings
        ));
    }
    if entry.servings > 1000.0 {
        return Err(format!(
            "servings exceeds maximum of 1000, got {}",
            entry.servings
        ));
    }

    // Validate calories (0 <= value <= 100000)
    if entry.calories < 0.0 {
        return Err(format!(
            "calories must be >= 0, got {}",
            entry.calories
        ));
    }
    if entry.calories > 100000.0 {
        return Err(format!(
            "calories exceeds maximum of 100000, got {}",
            entry.calories
        ));
    }

    // Validate protein (0 <= value <= 10000)
    if entry.protein < 0.0 {
        return Err(format!(
            "protein must be >= 0, got {}",
            entry.protein
        ));
    }
    if entry.protein > 10000.0 {
        return Err(format!(
            "protein exceeds maximum of 10000, got {}",
            entry.protein
        ));
    }

    // Validate carbohydrate (0 <= value <= 10000)
    if entry.carbohydrate < 0.0 {
        return Err(format!(
            "carbohydrate must be >= 0, got {}",
            entry.carbohydrate
        ));
    }
    if entry.carbohydrate > 10000.0 {
        return Err(format!(
            "carbohydrate exceeds maximum of 10000, got {}",
            entry.carbohydrate
        ));
    }

    // Validate fat (0 <= value <= 10000)
    if entry.fat < 0.0 {
        return Err(format!(
            "fat must be >= 0, got {}",
            entry.fat
        ));
    }
    if entry.fat > 10000.0 {
        return Err(format!(
            "fat exceeds maximum of 10000, got {}",
            entry.fat
        ));
    }

    Ok(())
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
        // Validate numeric bounds (BEAD-004)
        if let Err(e) = validate_numeric_bounds(&entry) {
            errors.push(e);
            continue;
        }

        // Validate recipe_name is not empty (BEAD-006)
        if entry.recipe_name.trim().is_empty() {
            errors.push("recipe_name cannot be empty".to_string());
            continue;
        }

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
            "snack" => MealType::Snack,
            _ => {
                errors.push(format!(
                    "Invalid meal_type {}: must be breakfast, lunch, dinner, or snack",
                    entry.meal_type
                ));
                continue;
            }
        };

        // Convert date to FatSecret format (with strict YYYY-MM-DD validation)
        let date_int = match date_to_int(&entry.date) {
            Ok(d) => d,
            Err(e) => {
                errors.push(format!("Invalid date '{}': {}", entry.date, e));
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

fn print_help() {
    println!(
        r#"sync_meal_plan - Sync Tandoor Meal Plan to FatSecret Diary

USAGE
    echo '{{...}}' | sync_meal_plan
    sync_meal_plan --help
    sync_meal_plan -h
    sync_meal_plan help

    This binary syncs Tandoor meal plan entries to FatSecret by creating diary
    entries for each meal. It handles batch processing and error recovery as part
    of the Tandoor ↔ FatSecret sync layer.

INPUT SCHEMA
    JSON input via stdin (or first command-line argument):
    {{
        "fatsecret": {{               // Optional: FatSecret credentials
            "consumer_key": "...",     // (if not provided, uses env vars)
            "consumer_secret": "..."
        }},
        "access_token": "...",        // Required: OAuth access token
        "access_secret": "...",       // Required: OAuth access secret
        "entries": [                  // Required: Meal plan entries to sync
            {{
                "date": "2025-01-01",        // YYYY-MM-DD format
                "meal_type": "breakfast",    // breakfast|lunch|dinner|snack
                "recipe_name": "Oatmeal",    // Recipe/meal name
                "servings": 1.0,             // Number of servings
                "calories": 300,             // Calories per serving
                "protein": 10,               // Protein (g) per serving
                "carbohydrate": 50,          // Carbs (g) per serving
                "fat": 5                     // Fat (g) per serving
            }}
        ]
    }}

OUTPUT SCHEMA
    Success response (JSON on stdout):
    {{
        "success": true,
        "entries_synced": 15,
        "entries_failed": 0,
        "total_calories": 14000.0,
        "total_protein": 700.0,
        "days_processed": 7,
        "synced_entries": [...],
        "errors": []
    }}

EXAMPLES
    1. Sync a single breakfast entry:
       $ echo '{{"access_token":"token","access_secret":"secret","entries":[{{"date":"2025-01-15","meal_type":"breakfast","recipe_name":"Oatmeal","servings":1.0,"calories":300,"protein":10,"carbohydrate":50,"fat":5}}]}}' | sync_meal_plan

    2. Sync multiple meals from a file:
       $ cat meal_plan.json | sync_meal_plan

    3. Display help:
       $ sync_meal_plan --help

EXIT CODES
    0 - Success (all entries processed, check 'success' field for sync status)
    1 - Error (invalid input, authentication failure, or system error)
"#
    );
}

fn print_schema() {
    use meal_planner::schema::SchemaBuilder;

    let schema = SchemaBuilder::new("sync_meal_plan", env!("CARGO_PKG_VERSION"))
        .description("Sync Tandoor meal plan entries to FatSecret food diary")
        .input_schema(serde_json::json!({
            "type": "object",
            "properties": {
                "fatsecret": {
                    "type": "object",
                    "properties": {
                        "consumer_key": {"type": "string"},
                        "consumer_secret": {"type": "string"}
                    },
                    "required": ["consumer_key", "consumer_secret"]
                },
                "access_token": {"type": "string"},
                "access_secret": {"type": "string"},
                "entries": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "date": {"type": "string", "pattern": "^\\d{4}-\\d{2}-\\d{2}$"},
                            "meal_type": {"type": "string", "enum": ["breakfast", "lunch", "dinner", "snack"]},
                            "recipe_name": {"type": "string"},
                            "servings": {"type": "number", "minimum": 0},
                            "calories": {"type": "number", "minimum": 0},
                            "protein": {"type": "number", "minimum": 0},
                            "carbohydrate": {"type": "number", "minimum": 0},
                            "fat": {"type": "number", "minimum": 0}
                        },
                        "required": ["date", "meal_type", "recipe_name", "servings", "calories", "protein", "carbohydrate", "fat"]
                    }
                }
            },
            "required": ["access_token", "access_secret", "entries"]
        }))
        .output_success_schema(serde_json::json!({
            "type": "object",
            "properties": {
                "success": {"type": "boolean"},
                "entries_synced": {"type": "integer", "minimum": 0},
                "entries_failed": {"type": "integer", "minimum": 0},
                "total_calories": {"type": "number"},
                "total_protein": {"type": "number"},
                "days_processed": {"type": "integer", "minimum": 0},
                "synced_entries": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "date": {"type": "string"},
                            "meal_type": {"type": "string"},
                            "recipe_name": {"type": "string"},
                            "food_entry_id": {"type": "string"},
                            "calories": {"type": "number"}
                        },
                        "required": ["date", "meal_type", "recipe_name", "food_entry_id", "calories"]
                    }
                },
                "errors": {"type": "array", "items": {"type": "string"}}
            },
            "required": ["success", "entries_synced", "entries_failed", "total_calories", "total_protein", "days_processed", "synced_entries", "errors"]
        }))
        .output_error_schema(serde_json::json!({
            "type": "object",
            "properties": {
                "success": {"type": "boolean", "const": false},
                "error": {"type": "string"}
            },
            "required": ["success", "error"]
        }))
        .example(
            "Sync one day's meals",
            serde_json::json!({
                "fatsecret": {
                    "consumer_key": "your_consumer_key",
                    "consumer_secret": "your_consumer_secret"
                },
                "access_token": "user_oauth_token",
                "access_secret": "user_oauth_secret",
                "entries": [
                    {
                        "date": "2025-01-15",
                        "meal_type": "breakfast",
                        "recipe_name": "Oatmeal",
                        "servings": 1.0,
                        "calories": 300.0,
                        "protein": 10.0,
                        "carbohydrate": 50.0,
                        "fat": 5.0
                    }
                ]
            }),
            serde_json::json!({
                "success": true,
                "entries_synced": 1,
                "entries_failed": 0,
                "total_calories": 300.0,
                "total_protein": 10.0,
                "days_processed": 1,
                "synced_entries": [
                    {
                        "date": "2025-01-15",
                        "meal_type": "breakfast",
                        "recipe_name": "Oatmeal",
                        "food_entry_id": "123456",
                        "calories": 300.0
                    }
                ],
                "errors": []
            })
        )
        .example(
            "Sync multiple meals",
            serde_json::json!({
                "access_token": "user_oauth_token",
                "access_secret": "user_oauth_secret",
                "entries": [
                    {
                        "date": "2025-01-15",
                        "meal_type": "lunch",
                        "recipe_name": "Grilled Chicken",
                        "servings": 1.5,
                        "calories": 450.0,
                        "protein": 40.0,
                        "carbohydrate": 5.0,
                        "fat": 25.0
                    },
                    {
                        "date": "2025-01-15",
                        "meal_type": "dinner",
                        "recipe_name": "Pasta",
                        "servings": 2.0,
                        "calories": 600.0,
                        "protein": 20.0,
                        "carbohydrate": 80.0,
                        "fat": 15.0
                    }
                ]
            }),
            serde_json::json!({
                "success": true,
                "entries_synced": 2,
                "entries_failed": 0,
                "total_calories": 1050.0,
                "total_protein": 60.0,
                "days_processed": 1,
                "synced_entries": [
                    {
                        "date": "2025-01-15",
                        "meal_type": "lunch",
                        "recipe_name": "Grilled Chicken",
                        "food_entry_id": "123456",
                        "calories": 675.0
                    },
                    {
                        "date": "2025-01-15",
                        "meal_type": "dinner",
                        "recipe_name": "Pasta",
                        "food_entry_id": "123457",
                        "calories": 1200.0
                    }
                ],
                "errors": []
            })
        )
        .build();

    println!(
        "{}",
        serde_json::to_string_pretty(&schema).expect("Failed to serialize schema")
    );
}
