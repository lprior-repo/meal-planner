//! Pure core functions for fatsecret_saved_meals_get_items flow validation
//!
//! Dave Farley: "Functional Core / Imperative Shell"
//!
//! These functions are:
//! - Pure (no I/O, no side effects)
//! - Total (defined for all inputs)
//! - ≤25 lines each
//! - Testable without mocks

use serde_json::{json, Value};

#[derive(Debug, Clone, PartialEq)]
pub struct SavedMealItemOutput {
    pub saved_meal_item_id: String,
    pub food_id: String,
    pub food_entry_name: String,
    pub serving_id: String,
    pub number_of_units: f64,
    pub calories: f64,
    pub carbohydrate: f64,
    pub protein: f64,
    pub fat: f64,
}

#[derive(Debug, PartialEq)]
pub enum InputValidationError {
    MissingSavedMealId,
    MissingAccessToken,
    MissingAccessSecret,
    MissingConsumerKey,
    MissingConsumerSecret,
}

pub fn validate_input(input: &Value) -> Result<(), InputValidationError> {
    if !input.get("saved_meal_id").map(|v| v.is_string()).unwrap_or(false) {
        return Err(InputValidationError::MissingSavedMealId);
    }
    if !input.get("access_token").map(|v| v.is_string()).unwrap_or(false) {
        return Err(InputValidationError::MissingAccessToken);
    }
    if !input.get("access_secret").map(|v| v.is_string()).unwrap_or(false) {
        return Err(InputValidationError::MissingAccessSecret);
    }
    Ok(())
}

pub fn extract_saved_meal_id(input: &Value) -> Option<String> {
    input.get("saved_meal_id").and_then(|v| v.as_str().map(|s| s.to_string()))
}

pub fn extract_oauth_tokens(input: &Value) -> Option<(String, String)> {
    let token = input.get("access_token").and_then(|v| v.as_str())?;
    let secret = input.get("access_secret").and_then(|v| v.as_str())?;
    Some((token.to_string(), secret.to_string()))
}

pub fn format_output_response(items: &[SavedMealItemOutput]) -> Value {
    let item_values: Vec<Value> = items
        .iter()
        .map(|item| {
            json!({
                "saved_meal_item_id": item.saved_meal_item_id,
                "food_id": item.food_id,
                "food_entry_name": item.food_entry_name,
                "serving_id": item.serving_id,
                "number_of_units": item.number_of_units,
                "calories": item.calories,
                "carbohydrate": item.carbohydrate,
                "protein": item.protein,
                "fat": item.fat
            })
        })
        .collect();
    json!({"success": true, "items": item_values})
}

pub fn format_error_response(error: &str) -> Value {
    json!({"success": false, "error": error})
}

pub fn parse_json_input(input_str: &str) -> Result<Value, String> {
    serde_json::from_str(input_str).map_err(|e| e.to_string())
}

pub fn count_items_in_response(response: &Value) -> usize {
    response.get("items").and_then(|v| v.as_array()).map(|a| a.len()).unwrap_or(0)
}

pub fn is_success_response(response: &Value) -> bool {
    response.get("success").and_then(|v| v.as_bool()).unwrap_or(false)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_validate_valid_input() {
        let input = json!({
            "saved_meal_id": "123",
            "access_token": "token",
            "access_secret": "secret"
        });
        assert_eq!(validate_input(&input), Ok(()));
    }

    #[test]
    fn test_validate_missing_id() {
        let input = json!({"access_token": "token", "access_secret": "secret"});
        assert_eq!(validate_input(&input), Err(InputValidationError::MissingSavedMealId));
    }

    #[test]
    fn test_extract_saved_meal_id() {
        let input = json!({"saved_meal_id": "test-id"});
        assert_eq!(extract_saved_meal_id(&input), Some("test-id".to_string()));
    }

    #[test]
    fn test_format_output_response() {
        let items = vec![SavedMealItemOutput {
            saved_meal_item_id: "1".to_string(),
            food_id: "100".to_string(),
            food_entry_name: "Apple".to_string(),
            serving_id: "200".to_string(),
            number_of_units: 1.0,
            calories: 95.0,
            carbohydrate: 25.0,
            protein: 0.5,
            fat: 0.3,
        }];
        let response = format_output_response(&items);
        assert_eq!(response["success"], true);
    }

    #[test]
    fn test_format_error_response() {
        let response = format_error_response("Test error");
        assert_eq!(response["success"], false);
    }

    #[test]
    fn test_parse_json_input() {
        let input = r#"{"saved_meal_id": "123"}"#;
        assert!(parse_json_input(input).is_ok());
    }

    #[test]
    fn test_count_items_in_response() {
        let response = json!({"success": true, "items": [{"id": "1"}, {"id": "2"}]});
        assert_eq!(count_items_in_response(&response), 2);
    }
}
