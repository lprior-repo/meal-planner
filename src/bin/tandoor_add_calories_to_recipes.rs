//! Add calories to Tandoor recipes
//!
//! Fetches all recipes, calculates calories from ingredients, updates nutrition field.
//! BORING CODE: Standard libs, strict typing, obvious logic.
//!
//! JSON input: `{"tandoor": {"base_url": "...", "api_token": "..."}}`
//! JSON stdout: `{"success": true, "updated": 10, "failed": 2, "recipes": [...]}`

#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::tandoor::{TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    tandoor: TandoorConfig,
}

#[derive(Serialize)]
struct RecipeUpdate {
    id: i64,
    name: String,
    calories: f64,
    status: String,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    total: i32,
    updated: i32,
    failed: i32,
    recipes: Vec<RecipeUpdate>,
}

#[derive(Serialize)]
struct ErrorOutput {
    success: bool,
    error: String,
}

fn main() {
    match run() {
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

fn run() -> Result<Output, Box<dyn std::error::Error>> {
    // Parse input
    let input: Input = if let Some(arg) = std::env::args().nth(1) {
        serde_json::from_str(&arg)?
    } else {
        let mut input_str = String::new();
        io::stdin().read_to_string(&mut input_str)?;
        serde_json::from_str(&input_str)?
    };

    let client = TandoorClient::new(&input.tandoor)?;

    // Fetch ALL recipes (handle pagination)
    let mut all_recipes = Vec::new();
    let mut page = 1u32;
    let page_size = 100u32;

    loop {
        let paginated = client.list_recipes(Some(page), Some(page_size))?;
        all_recipes.extend(paginated.results);

        if paginated.next.is_none() {
            break;
        }
        page += 1;
    }

    let total = i32::try_from(all_recipes.len()).unwrap_or(i32::MAX);
    let mut updated = 0;
    let mut failed = 0;
    let mut recipe_updates = Vec::new();

    // Process each recipe
    for recipe in all_recipes {
        eprintln!("Processing recipe {}: {}", recipe.id, recipe.name);

        // Get full recipe details
        let recipe_detail = match client.get_recipe(recipe.id) {
            Ok(r) => r,
            Err(e) => {
                eprintln!("  Failed to fetch recipe {}: {}", recipe.id, e);
                failed += 1;
                recipe_updates.push(RecipeUpdate {
                    id: recipe.id,
                    name: recipe.name.clone(),
                    calories: 0.0,
                    status: format!("fetch_failed: {}", e),
                });
                continue;
            }
        };

        // Calculate total calories from ingredients
        let total_calories = calculate_recipe_calories(&recipe_detail);

        eprintln!("  Calculated calories: {}", total_calories);

        // Build update request with nutrition object
        let update_request = json!({
            "nutrition": {
                "calories": total_calories,
                "source": "auto_calculated"
            }
        });

        // Update recipe
        match client.update_recipe(recipe.id, &update_request) {
            Ok(_) => {
                updated += 1;
                recipe_updates.push(RecipeUpdate {
                    id: recipe.id,
                    name: recipe.name.clone(),
                    calories: total_calories,
                    status: "updated".to_string(),
                });
                eprintln!("  ✓ Updated");
            }
            Err(e) => {
                failed += 1;
                recipe_updates.push(RecipeUpdate {
                    id: recipe.id,
                    name: recipe.name.clone(),
                    calories: total_calories,
                    status: format!("update_failed: {}", e),
                });
                eprintln!("  ✗ Update failed: {}", e);
            }
        }
    }

    Ok(Output {
        success: true,
        total,
        updated,
        failed,
        recipes: recipe_updates,
    })
}

/// Calculate total calories from recipe ingredients
/// BORING LOGIC: Sum up calories from each ingredient's food item
fn calculate_recipe_calories(recipe: &Value) -> f64 {
    let steps = match recipe.get("steps").and_then(|v| v.as_array()) {
        Some(s) => s,
        None => return 0.0,
    };

    let mut total_calories = 0.0;

    for step in steps {
        let ingredients = match step.get("ingredients").and_then(|v| v.as_array()) {
            Some(i) => i,
            None => continue,
        };

        for ingredient in ingredients {
            // Get amount (default 1.0)
            let amount = ingredient
                .get("amount")
                .and_then(|v| v.as_f64())
                .unwrap_or(1.0);

            // Get food energy (kcal per 100g or per unit)
            let food = match ingredient.get("food") {
                Some(f) => f,
                None => continue,
            };

            let energy = food.get("energy").and_then(|v| v.as_f64()).unwrap_or(0.0);

            // Calculate calories for this ingredient
            // Assuming 'energy' is kcal per 100g and amount is in grams
            // This is a SIMPLIFIED calculation - real-world needs unit conversions
            let ingredient_calories = (amount * energy) / 100.0;

            total_calories += ingredient_calories;
        }
    }

    total_calories
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_calculate_calories_empty_recipe() {
        let recipe = json!({"steps": []});
        let calories = calculate_recipe_calories(&recipe);
        assert_eq!(calories, 0.0);
    }

    #[test]
    fn test_calculate_calories_no_steps() {
        let recipe = json!({});
        let calories = calculate_recipe_calories(&recipe);
        assert_eq!(calories, 0.0);
    }

    #[test]
    fn test_calculate_calories_with_ingredients() {
        let recipe = json!({
            "steps": [
                {
                    "ingredients": [
                        {
                            "amount": 200.0,
                            "food": {"energy": 150.0}
                        },
                        {
                            "amount": 100.0,
                            "food": {"energy": 200.0}
                        }
                    ]
                }
            ]
        });
        // (200 * 150 / 100) + (100 * 200 / 100) = 300 + 200 = 500
        let calories = calculate_recipe_calories(&recipe);
        assert_eq!(calories, 500.0);
    }

    #[test]
    fn test_output_serialize() {
        let output = Output {
            success: true,
            total: 10,
            updated: 8,
            failed: 2,
            recipes: vec![],
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize");
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"total\":10"));
        assert!(json.contains("\"updated\":8"));
        assert!(json.contains("\"failed\":2"));
    }
}
