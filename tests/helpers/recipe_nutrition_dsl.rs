//! ATDD Layer 2: Domain Specific Language (DSL)
//!
//! Shared vocabulary that hides all technical implementation.
//! Tests use this DSL - if implementation changes, only Layer 3 (Protocol Drivers) changes.
//!
//! This layer provides:
//! - Domain methods (create_recipe, calculate_nutrition, verify_calories)
//! - Test data builders (valid ingredients, test recipes)
//! - Meaningful error messages
//!
//! This layer does NOT:
//! - Make HTTP calls directly
//! - Access database directly
//! - Know about FatSecret API endpoints
//! - Reference Tandoor API structure

use crate::helpers::support::binary_runner::run_binary;
use serde_json::{json, Value};

/// DSL for recipe nutrition acceptance tests
pub struct RecipeNutritionDSL {
    tandoor_resource: Value,
    fatsecret_resource: Value,
}

impl RecipeNutritionDSL {
    pub fn new() -> Self {
        let tandoor = json!({
            "base_url": "http://localhost:8090",
            "api_token": "test_token"
        });
        let fatsecret = json!({
            "consumer_key": "test_key",
            "consumer_secret": "test_secret"
        });
        Self {
            tandoor_resource: tandoor,
            fatsecret_resource: fatsecret,
        }
    }

    pub fn create_recipe_with_ingredients(
        &mut self,
        name: &str,
        ingredients: Vec<(&str, f64, &str)>,
    ) -> TestRecipe {
        let input = json!({
            "tandoor": self.tandoor_resource,
            "name": name,
            "servings": 4,
            "ingredients": ingredients.iter().map(|(name, amount, unit)| {
                json!({
                    "food_name": name,
                    "amount": amount,
                    "unit": unit
                })
            }).collect::<Vec<_>>()
        });

        let output =
            run_binary("create_test_recipe", &input).expect("Failed to create test recipe");

        TestRecipe {
            id: output.get("id").unwrap().as_i64().unwrap(),
            name: name.to_string(),
        }
    }

    pub fn calculate_and_update_recipe_nutrition(&mut self, recipe_id: i64) -> NutritionResult {
        let input = json!({
            "tandoor": self.tandoor_resource,
            "fatsecret": self.fatsecret_resource,
            "recipe_id": recipe_id
        });

        let output = run_binary("tandoor_recipe_calculate_nutrition", &input)
            .expect("Failed to calculate nutrition");

        NutritionResult {
            success: output.get("success").unwrap().as_bool().unwrap(),
            calories: output.get("calories").and_then(|v| v.as_f64()),
            failed_ingredients: output
                .get("failed_ingredients")
                .and_then(|v| v.as_array())
                .map(|arr| {
                    arr.iter()
                        .map(|s| s.as_str().unwrap().to_string())
                        .collect()
                })
                .unwrap_or_default(),
        }
    }

    pub fn verify_recipe_has_calories<F>(&self, recipe_id: i64, condition: F)
    where
        F: Fn(f64) -> bool,
    {
        let input = json!({
            "tandoor": self.tandoor_resource,
            "recipe_id": recipe_id
        });

        let output =
            run_binary("get_recipe_nutrition", &input).expect("Failed to get recipe nutrition");

        let calories = output.get("calories").unwrap().as_f64().unwrap();
        assert!(
            condition(calories),
            "Recipe {} calories {} did not satisfy condition",
            recipe_id,
            calories
        );
    }

    pub fn verify_recipe_has_protein<F>(&self, recipe_id: i64, condition: F)
    where
        F: Fn(f64) -> bool,
    {
        let input = json!({
            "tandoor": self.tandoor_resource,
            "recipe_id": recipe_id
        });

        let output =
            run_binary("get_recipe_nutrition", &input).expect("Failed to get recipe nutrition");

        let protein = output.get("protein").unwrap().as_f64().unwrap();
        assert!(
            condition(protein),
            "Recipe {} protein {} did not satisfy condition",
            recipe_id,
            protein
        );
    }

    pub fn verify_nutrition_source(&self, recipe_id: i64, expected: &str) {
        let input = json!({
            "tandoor": self.tandoor_resource,
            "recipe_id": recipe_id
        });

        let output =
            run_binary("get_recipe_nutrition", &input).expect("Failed to get recipe nutrition");

        let source = output.get("source").unwrap().as_str().unwrap();
        assert_eq!(
            source, expected,
            "Recipe {} nutrition source was {} expected {}",
            recipe_id, source, expected
        );
    }

    pub fn verify_failed_ingredients(&self, recipe_id: i64, expected: Vec<&str>) {
        let input = json!({
            "tandoor": self.tandoor_resource,
            "recipe_id": recipe_id
        });

        let output =
            run_binary("get_recipe_nutrition", &input).expect("Failed to get recipe nutrition");

        let failed: Vec<String> = output
            .get("failed_ingredients")
            .and_then(|v| v.as_array())
            .map(|arr| {
                arr.iter()
                    .map(|s| s.as_str().unwrap().to_string())
                    .collect()
            })
            .unwrap_or_default();

        let expected_strings: Vec<String> = expected.iter().map(|s| s.to_string()).collect();
        assert_eq!(
            failed, expected_strings,
            "Recipe {} failed ingredients mismatch: expected {:?}, got {:?}",
            recipe_id, expected_strings, failed
        );
    }

    pub fn set_recipe_calories(&mut self, recipe_id: i64, calories: f64) {
        let input = json!({
            "tandoor": self.tandoor_resource,
            "recipe_id": recipe_id,
            "calories": calories
        });

        run_binary("set_recipe_calories", &input).expect("Failed to set recipe calories");
    }
}

/// Domain object: Recipe returned from DSL
#[allow(dead_code)]
pub struct TestRecipe {
    pub id: i64,
    pub name: String,
}

/// Domain object: Nutrition calculation result
#[allow(dead_code)]
pub struct NutritionResult {
    pub success: bool,
    pub calories: Option<f64>,
    pub protein: Option<f64>,
    pub fat: Option<f64>,
    pub carbohydrate: Option<f64>,
    pub failed_ingredients: Vec<String>,
}
