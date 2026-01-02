//! Nutrition calculation functions (FUNCTIONAL CORE - PURE)
//!
//! All functions in this module are PURE:
//! - Same inputs → same outputs (deterministic)
//! - No I/O operations
//! - No side effects
//! - No external state dependencies
//!
//! These functions form the FUNCTIONAL CORE.
//! The IMPERATIVE SHELL (binaries) handles all I/O.

pub mod core;

use serde_json::{json, Value};

/// Scale nutrition values from serving size to target amount
///
/// PURE FUNCTION - No I/O, deterministic
///
/// # Arguments
/// * `serving_nutrition` - Nutrition data for serving (per serving_size_grams)
/// * `serving_size_grams` - Size of serving in grams
/// * `target_grams` - Target amount in grams
///
/// # Returns
/// Scaled nutrition values as JSON object
///
/// # Function Size: 18 lines (≤25 ✓)
pub fn scale_nutrition_to_grams(
    serving_nutrition: &Value,
    serving_size_grams: f64,
    target_grams: f64,
) -> Value {
    // Calculate multiplier
    let multiplier = if serving_size_grams > 0.0 {
        target_grams / serving_size_grams
    } else {
        0.0
    };

    // Scale each numeric field
    let mut scaled = json!({});
    if let Some(obj) = serving_nutrition.as_object() {
        for (key, value) in obj {
            if let Some(num) = value.as_f64() {
                if let Some(value) = scaled.as_object_mut() {
                    value.insert(key.clone(), json!(num * multiplier));
                }
            }
        }
    }

    scaled
}

/// Calculate total calories from recipe ingredients
///
/// PURE FUNCTION - No I/O, deterministic
///
/// # Arguments
/// * `recipe` - Recipe JSON with steps containing ingredients
///
/// # Returns
/// Total calories calculated from all ingredients
///
/// # Function Size: 14 lines (≤25 ✓)
pub fn calculate_recipe_calories(recipe: &Value) -> f64 {
    let steps = match recipe.get("steps").and_then(|v| v.as_array()) {
        Some(s) => s,
        None => return 0.0,
    };

    steps
        .iter()
        .filter_map(|step| step.get("ingredients").and_then(|v| v.as_array()))
        .flatten()
        .filter_map(calculate_ingredient_calories)
        .sum()
}

/// Calculate calories for a single ingredient
///
/// PURE FUNCTION - No I/O, deterministic
///
/// # Arguments
/// * `ingredient` - Ingredient JSON with amount and food.energy
///
/// # Returns
/// Calories for this ingredient, or None if data missing
///
/// # Function Size: 8 lines (≤25 ✓)
fn calculate_ingredient_calories(ingredient: &Value) -> Option<f64> {
    let amount = ingredient.get("amount")?.as_f64()?;
    let food = ingredient.get("food")?;
    let energy = food.get("energy")?.as_f64()?;

    Some((amount * energy) / 100.0)
}

/// Extract ingredient information from Tandoor JSON structure
///
/// PURE FUNCTION - No I/O, deterministic
///
/// # Arguments
/// * `ingredient` - Tandoor ingredient JSON with food.name, amount, unit.name
///
/// # Returns
/// Tuple of (name, amount, unit) with defaults for missing fields
///
/// # Function Size: 16 lines (≤25 ✓)
pub fn extract_ingredient_info(ingredient: &Value) -> (String, f64, String) {
    let name = ingredient
        .get("food")
        .and_then(|f| f.get("name"))
        .and_then(|n| n.as_str())
        .unwrap_or("")
        .to_string();

    let amount = ingredient
        .get("amount")
        .and_then(Value::as_f64)
        .unwrap_or(0.0);

    let unit = ingredient
        .get("unit")
        .and_then(|u| u.get("name"))
        .and_then(|n| n.as_str())
        .unwrap_or("")
        .to_string();

    (name, amount, unit)
}

/// Convert amount in various units to grams
///
/// PURE FUNCTION - No I/O, deterministic
///
/// # Arguments
/// * `amount` - Quantity in original unit
/// * `unit` - Unit name (g, ml, etc.)
/// * `ingredient_name` - Name of ingredient (affects density for volume conversions)
///
/// # Returns
/// Amount converted to grams
///
/// # Function Size: 21 lines (≤25 ✓)
#[allow(clippy::match_same_arms)]
pub fn convert_to_grams(amount: f64, unit: &str, ingredient_name: &str) -> f64 {
    match unit.to_lowercase().as_str() {
        "g" | "gram" | "grams" => amount,
        "kg" | "kilogram" | "kilograms" => amount * 1000.0,
        "ml" | "milliliter" | "milliliters" => {
            // Use density lookup for common liquids
            let density = get_liquid_density(ingredient_name);
            amount * density
        }
        "l" | "liter" | "liters" => {
            let density = get_liquid_density(ingredient_name);
            amount * 1000.0 * density
        }
        // Default: treat as grams (conservative approach)
        _ => amount,
    }
}

/// Get density factor for liquid ingredients (g/ml)
///
/// PURE FUNCTION - No I/O, deterministic
///
/// # Function Size: 8 lines (≤25 ✓)
fn get_liquid_density(ingredient_name: &str) -> f64 {
    let name_lower = ingredient_name.to_lowercase();
    if name_lower.contains("milk") {
        1.03
    } else {
        // Default to water density
        1.0
    }
}

/// Build nutrition update request payload for Tandoor API
///
/// PURE FUNCTION - No I/O, deterministic
///
/// Maps input nutrition fields to Tandoor's expected field names:
/// - calories → calories
/// - protein → proteins
/// - carbohydrates → carbohydrates
/// - fat → fats
///
/// # Arguments
/// * `input_nutrition` - Nutrition input with camelCase field names
///
/// # Returns
/// JSON object with Tandoor-compatible field names for PATCH request
///
/// # Function Size: 14 lines (≤25 ✓)
pub fn build_nutrition_update_request(input_nutrition: &Value) -> Value {
    let mut nutrition = json!({});

    if let Some(calories) = input_nutrition.get("calories").and_then(Value::as_f64) {
        nutrition["calories"] = json!(calories);
    }
    if let Some(protein) = input_nutrition.get("protein").and_then(Value::as_f64) {
        nutrition["proteins"] = json!(protein);
    }
    if let Some(carbs) = input_nutrition.get("carbohydrates").and_then(Value::as_f64) {
        nutrition["carbohydrates"] = json!(carbs);
    }
    if let Some(fat) = input_nutrition.get("fat").and_then(Value::as_f64) {
        nutrition["fats"] = json!(fat);
    }

    json!({ "nutrition": nutrition })
}

/// Validate nutrition input has at least one valid field
///
/// PURE FUNCTION - No I/O, deterministic
///
/// # Arguments
/// * `nutrition` - Nutrition input to validate
///
/// # Returns
/// true if at least one valid numeric field is present
///
/// # Function Size: 8 lines (≤25 ✓)
pub fn validate_nutrition_input(nutrition: &Value) -> bool {
    let fields = ["calories", "protein", "carbohydrates", "fat"];
    fields.iter().any(|field| {
        nutrition
            .get(*field)
            .and_then(Value::as_f64)
            .map(|v| v >= 0.0)
            .unwrap_or(false)
    })
}

#[cfg(test)]
mod nutrition_update_tests {
    use super::*;

    #[test]
    fn test_build_nutrition_update_full() {
        let input = json!({
            "calories": 450.0,
            "protein": 25.0,
            "carbohydrates": 55.0,
            "fat": 12.0
        });

        let result = build_nutrition_update_request(&input);

        let nutrition = &result["nutrition"];
        assert_eq!(nutrition["calories"], 450.0);
        assert_eq!(nutrition["proteins"], 25.0);
        assert_eq!(nutrition["carbohydrates"], 55.0);
        assert_eq!(nutrition["fats"], 12.0);
    }

    #[test]
    fn test_build_nutrition_update_partial() {
        let input = json!({
            "calories": 300.0
        });

        let result = build_nutrition_update_request(&input);

        let nutrition = &result["nutrition"];
        assert_eq!(nutrition["calories"], 300.0);
        assert!(nutrition["proteins"].is_null());
        assert!(nutrition["carbohydrates"].is_null());
        assert!(nutrition["fats"].is_null());
    }

    #[test]
    fn test_build_nutrition_update_empty() {
        let input = json!({});

        let result = build_nutrition_update_request(&input);

        let nutrition = &result["nutrition"];
        assert!(nutrition["calories"].is_null());
        assert!(nutrition["proteins"].is_null());
        assert!(nutrition["carbohydrates"].is_null());
        assert!(nutrition["fats"].is_null());
    }

    #[test]
    fn test_validate_nutrition_input_valid() {
        let valid = json!({
            "calories": 450.0,
            "protein": 25.0
        });
        assert!(validate_nutrition_input(&valid));
    }

    #[test]
    fn test_validate_nutrition_input_empty() {
        let empty = json!({});
        assert!(!validate_nutrition_input(&empty));
    }

    #[test]
    fn test_validate_nutrition_input_negative() {
        let negative = json!({
            "calories": -100.0
        });
        assert!(!validate_nutrition_input(&negative));
    }

    #[test]
    fn test_validate_nutrition_input_null_fields() {
        let nulls = json!({
            "calories": null,
            "protein": null
        });
        assert!(!validate_nutrition_input(&nulls));
    }
}
