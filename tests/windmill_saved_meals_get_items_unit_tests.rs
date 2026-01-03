//! Unit tests for fatsecret_saved_meals_get_items flow logic
//!
//! Dave Farley: "Functional Core / Imperative Shell"
//!
//! Tests pure core functions for input validation and output formatting.

#![allow(clippy::unwrap_used, clippy::indexing_slicing)]

use serde_json::json;

const VALID_INPUT: &str = r#"{"saved_meal_id": "12345", "access_token": "token", "access_secret": "secret"}"#;
const MISSING_ID_INPUT: &str = r#"{"access_token": "token", "access_secret": "secret"}"#;

#[derive(Debug, PartialEq)]
pub enum ValidationResult {
    Valid,
    MissingSavedMealId,
    MissingAuth,
    InvalidJson,
}

fn parse_input(input_str: &str) -> Result<serde_json::Value, ValidationResult> {
    serde_json::from_str(input_str).map_err(|_| ValidationResult::InvalidJson)
}

fn validate_saved_meal_id(input: &serde_json::Value) -> ValidationResult {
    if input.get("saved_meal_id").is_none() {
        return ValidationResult::MissingSavedMealId;
    }
    ValidationResult::Valid
}

fn validate_auth_fields(input: &serde_json::Value) -> ValidationResult {
    if input.get("access_token").is_none() || input.get("access_secret").is_none() {
        return ValidationResult::MissingAuth;
    }
    ValidationResult::Valid
}

fn validate_input(input: &serde_json::Value) -> ValidationResult {
    match validate_auth_fields(input) {
        ValidationResult::MissingAuth => ValidationResult::MissingAuth,
        _ => validate_saved_meal_id(input),
    }
}

fn format_success_response(items: &[serde_json::Value]) -> serde_json::Value {
    json!({"success": true, "items": items})
}

fn format_error_response(error: &str) -> serde_json::Value {
    json!({"success": false, "error": error})
}

fn count_items_in_response(response: &serde_json::Value) -> usize {
    response.get("items").and_then(|i| i.as_array().map(|a| a.len())).unwrap_or(0)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_valid_input() {
        let input = parse_input(VALID_INPUT).unwrap();
        assert!(input.get("saved_meal_id").is_some());
    }

    #[test]
    fn test_parse_invalid_json() {
        let result = parse_input("not valid json");
        assert!(result.is_err());
    }

    #[test]
    fn test_validate_missing_saved_meal_id() {
        let input = parse_input(MISSING_ID_INPUT).unwrap();
        assert_eq!(validate_input(&input), ValidationResult::MissingSavedMealId);
    }

    #[test]
    fn test_validate_valid_input() {
        let input = parse_input(VALID_INPUT).unwrap();
        assert_eq!(validate_input(&input), ValidationResult::Valid);
    }

    #[test]
    fn test_format_success_response() {
        let items = vec![json!({"id": "1"})];
        let response = format_success_response(&items);
        assert_eq!(response["success"], true);
    }

    #[test]
    fn test_format_error_response() {
        let response = format_error_response("Test error");
        assert_eq!(response["success"], false);
    }

    #[test]
    fn test_count_items_in_response() {
        let items = vec![json!({"id": "1"}), json!({"id": "2"})];
        let response = format_success_response(&items);
        assert_eq!(count_items_in_response(&response), 2);
    }
}
