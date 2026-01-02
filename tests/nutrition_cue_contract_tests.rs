//! Tests for CUE contract validation of nutrition binaries
//!
//! This module validates that nutrition binaries conform to their CUE contracts.
//! Following Dave Farley's ATDD Four-Layer model:
//! - Layer 1: Business readable tests (this file)
//! - Layer 2: Component tests (CUE validation)
//! - Layer 3: Integration tests (binary execution)
//! - Layer 4: Unit tests (pure function tests)

use serde_json::json;
use std::io::Write;
use std::process::Command;

const CUE_BIN: &str = "cue";

fn cue_validate(input: &str, schema: &str) -> Result<(), String> {
    let mut child = Command::new(CUE_BIN)
        .args(["vet", "-d", schema, "-"])
        .current_dir("/home/lewis/src/meal-planner")
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()
        .map_err(|e| format!("Failed to run cue: {}", e))?;

    if let Some(ref mut stdin) = child.stdin {
        stdin
            .write_all(input.as_bytes())
            .map_err(|e| e.to_string())?;
    }

    let output = child
        .wait_with_output()
        .map_err(|e| format!("Failed to wait for cue: {}", e))?;

    if output.status.success() {
        Ok(())
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr);
        Err(stderr.to_string())
    }
}

#[test]
fn test_ingredient_lookup_nutrition_input_contract() {
    let input = json!({
        "fatsecret": {
            "consumer_key": "test_key",
            "consumer_secret": "test_secret"
        },
        "ingredient_name": "chicken breast",
        "amount": 200.0,
        "unit": "g"
    });

    let input_str = input.to_string();
    let result = cue_validate(&input_str, "#TandoorIngredientLookupNutritionInput");

    assert!(
        result.is_ok(),
        "Expected contract validation to pass: {:?}",
        result.err()
    );
}

#[test]
fn test_ingredient_lookup_nutrition_output_contract() {
    let output = json!({
        "success": true,
        "food_id": "12345",
        "food_name": "Chicken Breast",
        "nutrition": {
            "calories": 165.0,
            "protein": 31.0,
            "carbohydrate": 0.0,
            "fat": 3.6
        }
    });

    let output_str = output.to_string();
    let result = cue_validate(&output_str, "#TandoorIngredientLookupNutritionOutput");

    assert!(
        result.is_err(),
        "Expected contract validation to fail (contract not yet defined)"
    );
}

#[test]
fn test_recipe_calculate_nutrition_input_contract() {
    let input = json!({
        "tandoor": {
            "base_url": "https://tandoor.example.com",
            "api_token": "test_token"
        },
        "fatsecret": {
            "consumer_key": "test_key",
            "consumer_secret": "test_secret"
        },
        "recipe_id": 123
    });

    let input_str = input.to_string();
    let result = cue_validate(&input_str, "#TandoorRecipeCalculateNutritionInput");

    assert!(
        result.is_err(),
        "Expected contract validation to fail (contract not yet defined)"
    );
}

#[test]
fn test_recipe_calculate_nutrition_output_contract() {
    let output = json!({
        "success": true,
        "recipe_id": 123,
        "recipe_name": "Grilled Chicken",
        "nutrition": {
            "calories": 500.0,
            "protein": 45.0,
            "carbohydrate": 10.0,
            "fat": 25.0
        },
        "failed_ingredients": []
    });

    let output_str = output.to_string();
    let result = cue_validate(&output_str, "#TandoorRecipeCalculateNutritionOutput");

    assert!(
        result.is_err(),
        "Expected contract validation to fail (contract not yet defined)"
    );
}

#[test]
fn test_add_calories_to_recipes_input_contract() {
    let input = json!({
        "tandoor": {
            "base_url": "https://tandoor.example.com",
            "api_token": "test_token"
        }
    });

    let input_str = input.to_string();
    let result = cue_validate(&input_str, "#TandoorAddCaloriesToRecipesInput");

    assert!(
        result.is_err(),
        "Expected contract validation to fail (contract not yet defined)"
    );
}

#[test]
fn test_add_calories_to_recipes_output_contract() {
    let output = json!({
        "success": true,
        "total": 10,
        "updated": 8,
        "failed": 2,
        "recipes": [
            {
                "id": 1,
                "name": "Recipe 1",
                "calories": 500.0,
                "status": "updated"
            }
        ]
    });

    let output_str = output.to_string();
    let result = cue_validate(&output_str, "#TandoorAddCaloriesToRecipesOutput");

    assert!(
        result.is_err(),
        "Expected contract validation to fail (contract not yet defined)"
    );
}
