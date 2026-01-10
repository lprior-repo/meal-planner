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

async fn run() -> Result<Output, Box<dyn std::error::Error>> {
    let input: Input = read_input()?;

    // Validate base_url is not empty (BEAD-006)
    if input.tandoor.base_url.trim().is_empty() {
        return Err("base_url cannot be empty".into());
    }

    // Validate api_token is not empty (BEAD-006)
    if input.tandoor.api_token.trim().is_empty() {
        return Err("api_token cannot be empty".into());
    }

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

    // Validate recipe_name is not empty (BEAD-006)
    if recipe_name.trim().is_empty() {
        return Err("recipe_name cannot be empty".into());
    }

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

fn print_help() {
    println!(
        r#"log_recipe_to_fatsecret - Log a Tandoor recipe to FatSecret food diary

USAGE
    echo '{{...}}' | log_recipe_to_fatsecret
    log_recipe_to_fatsecret --help
    log_recipe_to_fatsecret -h
    log_recipe_to_fatsecret help

    This binary logs a Tandoor recipe to FatSecret by creating a custom food diary
    entry. It fetches the recipe from Tandoor and uses its nutrition data to create
    the FatSecret entry. Part of the Tandoor ↔ FatSecret sync layer.

INPUT SCHEMA
    JSON input via stdin (or first command-line argument):
    {{
        "tandoor": {{                  // Required: Tandoor configuration
            "base_url": "...",          // Tandoor API base URL
            "api_token": "..."          // Tandoor API token
        }},
        "fatsecret": {{               // Optional: FatSecret credentials
            "consumer_key": "...",     // (if not provided, uses env vars)
            "consumer_secret": "..."
        }},
        "access_token": "...",        // Required: OAuth access token
        "access_secret": "...",       // Required: OAuth access secret
        "recipe_id": 123,             // Required: Tandoor recipe ID
        "servings": 2.0,              // Optional: Number of servings
        "meal": "dinner",             // Required: breakfast|lunch|dinner|other
        "date": "2025-01-01"          // Required: YYYY-MM-DD format
    }}

OUTPUT SCHEMA
    Success response (JSON on stdout):
    {{
        "success": true,
        "food_entry_id": "123456789",
        "recipe_name": "Grilled Chicken",
        "calories": 450.0,
        "protein": 40.0,
        "carbohydrate": 5.0,
        "fat": 25.0
    }}

    Error response (JSON on stdout):
    {{
        "success": false,
        "error": "Error description"
    }}

EXAMPLES
    1. Log a recipe with default servings:
       $ echo '{{"tandoor":{{"base_url":"https://tandoor.example.com","api_token":"token"}},"access_token":"token","access_secret":"secret","recipe_id":123,"meal":"dinner","date":"2025-01-15"}}' | log_recipe_to_fatsecret

    2. Log a recipe with custom servings:
       $ echo '{{"tandoor":{{"base_url":"https://tandoor.example.com","api_token":"token"}},"access_token":"token","access_secret":"secret","recipe_id":456,"servings":2.5,"meal":"lunch","date":"2025-01-15"}}' | log_recipe_to_fatsecret

    3. Display help:
       $ log_recipe_to_fatsecret --help

EXIT CODES
    0 - Success (recipe logged to FatSecret)
    1 - Error (invalid input, recipe not found, or API failure)

NOTES
    - Recipe must have nutrition data calculated in Tandoor
    - Nutrition values are scaled by the servings parameter
    - Entry is created as a custom food in FatSecret with "(Tandoor)" suffix
"#
    );
}

fn print_schema() {
    use meal_planner::schema::SchemaBuilder;

    let schema = SchemaBuilder::new("log_recipe_to_fatsecret", env!("CARGO_PKG_VERSION"))
        .description("Log a Tandoor recipe to FatSecret food diary")
        .input_schema(serde_json::json!({
            "type": "object",
            "properties": {
                "tandoor": {
                    "type": "object",
                    "properties": {
                        "base_url": {"type": "string", "format": "uri"},
                        "api_token": {"type": "string"}
                    },
                    "required": ["base_url", "api_token"]
                },
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
                "recipe_id": {"type": "integer", "minimum": 1},
                "servings": {"type": "number", "minimum": 0},
                "meal": {"type": "string", "enum": ["breakfast", "lunch", "dinner", "other"]},
                "date": {"type": "string", "pattern": "^\\d{4}-\\d{2}-\\d{2}$"}
            },
            "required": ["tandoor", "access_token", "access_secret", "recipe_id", "meal", "date"]
        }))
        .output_success_schema(serde_json::json!({
            "type": "object",
            "properties": {
                "success": {"type": "boolean", "const": true},
                "food_entry_id": {"type": "string"},
                "recipe_name": {"type": "string"},
                "calories": {"type": "number"},
                "protein": {"type": "number"},
                "carbohydrate": {"type": "number"},
                "fat": {"type": "number"}
            },
            "required": ["success", "food_entry_id", "recipe_name", "calories", "protein", "carbohydrate", "fat"]
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
            "Log recipe with default servings",
            serde_json::json!({
                "tandoor": {
                    "base_url": "https://recipes.example.com",
                    "api_token": "tandoor_token"
                },
                "fatsecret": {
                    "consumer_key": "fs_consumer_key",
                    "consumer_secret": "fs_consumer_secret"
                },
                "access_token": "user_oauth_token",
                "access_secret": "user_oauth_secret",
                "recipe_id": 42,
                "meal": "dinner",
                "date": "2025-01-15"
            }),
            serde_json::json!({
                "success": true,
                "food_entry_id": "123456",
                "recipe_name": "Grilled Chicken",
                "calories": 450.0,
                "protein": 40.0,
                "carbohydrate": 5.0,
                "fat": 25.0
            })
        )
        .example(
            "Log recipe with custom servings",
            serde_json::json!({
                "tandoor": {
                    "base_url": "https://recipes.example.com",
                    "api_token": "tandoor_token"
                },
                "access_token": "user_oauth_token",
                "access_secret": "user_oauth_secret",
                "recipe_id": 100,
                "servings": 2.5,
                "meal": "lunch",
                "date": "2025-01-15"
            }),
            serde_json::json!({
                "success": true,
                "food_entry_id": "789012",
                "recipe_name": "Pasta Salad",
                "calories": 750.0,
                "protein": 25.0,
                "carbohydrate": 90.0,
                "fat": 20.0
            })
        )
        .build();

    println!(
        "{}",
        serde_json::to_string_pretty(&schema).expect("Failed to serialize schema")
    );
}
