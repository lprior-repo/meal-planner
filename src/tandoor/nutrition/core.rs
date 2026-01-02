//! Nutrition calculation core (FUNCTIONAL CORE - PURE)
//!
//! All functions in this module are PURE:
//! - Same inputs → same outputs (deterministic)
//! - No I/O operations
//! - No side effects
//! - No external state dependencies
//!
//! These functions form the FUNCTIONAL CORE.
//! The IMPERATIVE SHELL (binaries) handles all I/O.

use serde_json::Value;

/// Ingredient nutrition data from FatSecret
#[derive(Debug, Clone)]
pub struct IngredientNutrition {
    pub food_name: String,
    pub calories_per_100g: f64,
    pub protein_per_100g: f64,
    pub fat_per_100g: f64,
    pub carbohydrate_per_100g: f64,
}

/// Recipe nutrition result
#[derive(Debug, Clone)]
pub struct RecipeNutritionResult {
    pub calories: f64,
    pub protein: f64,
    pub fat: f64,
    pub carbohydrate: f64,
    pub failed_ingredients: Vec<String>,
}

/// Calculate nutrition for a recipe from its ingredients
///
/// # Arguments
/// * `recipe` - Recipe JSON with steps containing ingredients
/// * `nutrition_db` - Map of ingredient name to nutrition data
///
/// # Returns
/// Total nutrition calculated from all ingredients
///
/// # Function Size: 22 lines (≤25 ✓)
pub fn calculate_recipe_nutrition(
    recipe: &Value,
    nutrition_db: &std::collections::HashMap<String, IngredientNutrition>,
) -> RecipeNutritionResult {
    let steps = match recipe.get("steps").and_then(|v| v.as_array()) {
        Some(s) => s,
        None => return RecipeNutritionResult::default(),
    };

    let mut result = RecipeNutritionResult::default();

    for step in steps {
        let ingredients = match step.get("ingredients").and_then(|v| v.as_array()) {
            Some(i) => i,
            None => continue,
        };

        for ingredient in ingredients {
            if let Some(calculated) = calculate_ingredient_nutrition(ingredient, nutrition_db) {
                result.calories += calculated.calories_per_100g;
                result.protein += calculated.protein_per_100g;
                result.fat += calculated.fat_per_100g;
                result.carbohydrate += calculated.carbohydrate_per_100g;
            } else {
                if let Some(name) = extract_ingredient_name(ingredient) {
                    result.failed_ingredients.push(name);
                }
            }
        }
    }

    result
}

/// Calculate nutrition for a single ingredient
///
/// # Function Size: 18 lines (≤25 ✓)
fn calculate_ingredient_nutrition(
    ingredient: &Value,
    nutrition_db: &std::collections::HashMap<String, IngredientNutrition>,
) -> Option<IngredientNutrition> {
    let name = extract_ingredient_name(ingredient)?;
    let amount = ingredient.get("amount")?.as_f64()?;
    let unit = extract_unit(ingredient);

    let nutrition = find_nutrition(&name, nutrition_db)?;

    let grams = convert_to_grams(amount, &unit, &name);
    let multiplier = grams / 100.0;

    Some(IngredientNutrition {
        food_name: name,
        calories_per_100g: nutrition.calories_per_100g * multiplier,
        protein_per_100g: nutrition.protein_per_100g * multiplier,
        fat_per_100g: nutrition.fat_per_100g * multiplier,
        carbohydrate_per_100g: nutrition.carbohydrate_per_100g * multiplier,
    })
}

/// Extract ingredient name from Tandoor JSON
fn extract_ingredient_name(ingredient: &Value) -> Option<String> {
    ingredient
        .get("food")
        .and_then(|f| f.get("name"))
        .and_then(|n| n.as_str())
        .map(|s| s.to_lowercase())
}

/// Extract unit from ingredient
fn extract_unit(ingredient: &Value) -> String {
    ingredient
        .get("unit")
        .and_then(|u| u.get("name"))
        .and_then(|n| n.as_str())
        .unwrap_or("g")
        .to_lowercase()
}

/// Find nutrition data for an ingredient (fuzzy matching)
///
/// # Function Size: 12 lines (≤25 ✓)
fn find_nutrition(
    name: &str,
    nutrition_db: &std::collections::HashMap<String, IngredientNutrition>,
) -> Option<IngredientNutrition> {
    for (key, value) in nutrition_db {
        if name.contains(key) || key.contains(name) {
            return Some(value.clone());
        }
    }
    None
}

/// Convert amount in various units to grams
///
/// # Function Size: 21 lines (≤25 ✓)
pub fn convert_to_grams(amount: f64, unit: &str, _ingredient_name: &str) -> f64 {
    match unit.to_lowercase().as_str() {
        "g" | "gram" | "grams" => amount,
        "kg" | "kilogram" | "kilograms" => amount * 1000.0,
        "ml" | "milliliter" | "milliliters" => amount,
        "l" | "liter" | "liters" => amount * 1000.0,
        "oz" | "ounce" | "ounces" => amount * 28.3495,
        "lb" | "pound" | "pounds" => amount * 453.592,
        "cup" | "cups" => amount * 240.0,
        "tbsp" | "tablespoon" | "tablespoons" => amount * 15.0,
        "tsp" | "teaspoon" | "teaspoons" => amount * 5.0,
        _ => amount,
    }
}

impl Default for RecipeNutritionResult {
    fn default() -> Self {
        Self {
            calories: 0.0,
            protein: 0.0,
            fat: 0.0,
            carbohydrate: 0.0,
            failed_ingredients: Vec::new(),
        }
    }
}

/// Create a standard nutrition database for testing
pub fn create_test_nutrition_db() -> std::collections::HashMap<String, IngredientNutrition> {
    let mut db = std::collections::HashMap::new();

    db.insert(
        "chicken breast".to_string(),
        IngredientNutrition {
            food_name: "chicken breast".to_string(),
            calories_per_100g: 165.0,
            protein_per_100g: 31.0,
            fat_per_100g: 3.6,
            carbohydrate_per_100g: 0.0,
        },
    );

    db.insert(
        "lettuce".to_string(),
        IngredientNutrition {
            food_name: "lettuce".to_string(),
            calories_per_100g: 15.0,
            protein_per_100g: 1.3,
            fat_per_100g: 0.2,
            carbohydrate_per_100g: 2.9,
        },
    );

    db.insert(
        "olive oil".to_string(),
        IngredientNutrition {
            food_name: "olive oil".to_string(),
            calories_per_100g: 884.0,
            protein_per_100g: 0.0,
            fat_per_100g: 100.0,
            carbohydrate_per_100g: 0.0,
        },
    );

    db.insert(
        "protein powder".to_string(),
        IngredientNutrition {
            food_name: "protein powder".to_string(),
            calories_per_100g: 370.0,
            protein_per_100g: 90.0,
            fat_per_100g: 2.0,
            carbohydrate_per_100g: 3.0,
        },
    );

    db
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn test_convert_grams_known_units() {
        assert_eq!(convert_to_grams(100.0, "g", ""), 100.0);
        assert_eq!(convert_to_grams(1.0, "kg", ""), 1000.0);
        assert_eq!(convert_to_grams(100.0, "ml", ""), 100.0);
        assert_eq!(convert_to_grams(1.0, "l", ""), 1000.0);
        assert!((convert_to_grams(1.0, "oz", "") - 28.3495).abs() < 0.01);
        assert!((convert_to_grams(1.0, "lb", "") - 453.592).abs() < 0.01);
        assert_eq!(convert_to_grams(1.0, "cup", ""), 240.0);
        assert_eq!(convert_to_grams(1.0, "tbsp", ""), 15.0);
        assert_eq!(convert_to_grams(1.0, "tsp", ""), 5.0);
    }

    #[test]
    fn test_convert_grams_unknown_unit_returns_amount() {
        assert_eq!(convert_to_grams(100.0, "piece", ""), 100.0);
        assert_eq!(convert_to_grams(5.0, "whole", ""), 5.0);
    }

    #[test]
    fn test_calculate_recipe_nutrition_single_ingredient() {
        let db = create_test_nutrition_db();

        let recipe = json!({
            "steps": [{
                "ingredients": [{
                    "food": { "name": "chicken breast" },
                    "amount": 200.0,
                    "unit": { "name": "g" }
                }]
            }]
        });

        let result = calculate_recipe_nutrition(&recipe, &db);

        assert!((result.calories - 330.0).abs() < 0.01);
        assert!((result.protein - 62.0).abs() < 0.01);
        assert!(result.failed_ingredients.is_empty());
    }

    #[test]
    fn test_calculate_recipe_nutrition_multiple_ingredients() {
        let db = create_test_nutrition_db();

        let recipe = json!({
            "steps": [{
                "ingredients": [
                    { "food": { "name": "chicken breast" }, "amount": 200.0, "unit": { "name": "g" } },
                    { "food": { "name": "lettuce" }, "amount": 100.0, "unit": { "name": "g" } },
                    { "food": { "name": "olive oil" }, "amount": 15.0, "unit": { "name": "ml" } }
                ]
            }]
        });

        let result = calculate_recipe_nutrition(&recipe, &db);

        assert!((result.calories - 330.0 - 15.0 - 132.6).abs() < 1.0);
        assert!((result.protein - 62.0 - 1.3).abs() < 0.1);
    }

    #[test]
    fn test_calculate_recipe_nutrition_missing_ingredient() {
        let db = create_test_nutrition_db();

        let recipe = json!({
            "steps": [{
                "ingredients": [
                    { "food": { "name": "chicken breast" }, "amount": 200.0, "unit": { "name": "g" } },
                    { "food": { "name": "xyz_unknown_food" }, "amount": 100.0, "unit": { "name": "g" } }
                ]
            }]
        });

        let result = calculate_recipe_nutrition(&recipe, &db);

        assert!((result.calories - 330.0).abs() < 0.01);
        assert_eq!(result.failed_ingredients.len(), 1);
        assert!(result.failed_ingredients[0].contains("xyz_unknown_food"));
    }

    #[test]
    fn test_calculate_recipe_nutrition_empty_recipe() {
        let db = create_test_nutrition_db();
        let recipe = json!({});
        let result = calculate_recipe_nutrition(&recipe, &db);
        assert_eq!(result.calories, 0.0);
    }

    #[test]
    fn test_calculate_recipe_nutrition_fuzzy_matching() {
        let db = create_test_nutrition_db();

        let recipe = json!({
            "steps": [{
                "ingredients": [{
                    "food": { "name": "Chicken Breast" },
                    "amount": 100.0,
                    "unit": { "name": "g" }
                }]
            }]
        });

        let result = calculate_recipe_nutrition(&recipe, &db);
        assert!((result.calories - 165.0).abs() < 0.01);
    }
}
