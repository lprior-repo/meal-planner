//! Shopping list core (FUNCTIONAL CORE - PURE)
//!
//! All functions in this module are PURE:
//! - Same inputs → same outputs (deterministic)
//! - No I/O operations
//! - No side effects
//! - No external state dependencies
//!
//! These functions form the FUNCTIONAL CORE.
//! The IMPERATIVE SHELL (binaries) handles all I/O.

use crate::tandoor::types::ShoppingListRecipe;
use serde::{Deserialize, Serialize};

/// Input for adding recipe to shopping list
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct AddRecipeInput {
    /// Tandoor configuration
    pub tandoor: TandoorConfigInput,
    /// Meal plan ID
    pub mealplan_id: i64,
    /// Recipe ID to add
    pub recipe_id: i64,
    /// Number of servings
    pub servings: f64,
}

/// Tandoor configuration (copied to avoid dependency on binary types)
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct TandoorConfigInput {
    /// Base URL of Tandoor API
    pub base_url: String,
    /// API token for authentication
    pub api_token: String,
}

/// Output for adding recipe to shopping list
#[derive(Debug, Serialize)]
pub struct AddRecipeOutput {
    /// Whether operation succeeded
    pub success: bool,
    /// Shopping list entries created (on success)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub entries: Option<Vec<ShoppingListRecipe>>,
    /// Error message (on failure)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
}

/// Parse JSON input string to AddRecipeInput
///
/// # Function Size: 4 lines (≤25 ✓)
pub fn parse_input(json: &str) -> Result<AddRecipeInput, String> {
    serde_json::from_str(json).map_err(|e| e.to_string())
}

/// Validate input fields
///
/// # Function Size: 8 lines (≤25 ✓)
pub fn validate_input(input: &AddRecipeInput) -> Result<(), String> {
    if input.mealplan_id <= 0 {
        return Err("mealplan_id must be positive".to_string());
    }
    if input.recipe_id <= 0 {
        return Err("recipe_id must be positive".to_string());
    }
    if input.servings <= 0.0 {
        return Err("servings must be positive".to_string());
    }
    if input.tandoor.base_url.is_empty() {
        return Err("base_url is required".to_string());
    }
    if input.tandoor.api_token.is_empty() {
        return Err("api_token is required".to_string());
    }
    Ok(())
}

/// Format successful output with shopping list entries
///
/// # Function Size: 7 lines (≤25 ✓)
pub fn format_success(entries: &[ShoppingListRecipe]) -> AddRecipeOutput {
    AddRecipeOutput {
        success: true,
        entries: Some(entries.to_vec()),
        error: None,
    }
}

/// Format error output
///
/// # Function Size: 6 lines (≤25 ✓)
pub fn format_error(message: &str) -> AddRecipeOutput {
    AddRecipeOutput {
        success: false,
        entries: None,
        error: Some(message.to_string()),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_valid_input() {
        let json = r#"{"tandoor":{"base_url":"http://localhost","api_token":"token"},"mealplan_id":1,"recipe_id":2,"servings":4.0}"#;
        let result = parse_input(json);
        assert!(result.is_ok());
        let input = result.unwrap();
        assert_eq!(input.mealplan_id, 1);
        assert_eq!(input.recipe_id, 2);
        assert_eq!(input.servings, 4.0);
    }

    #[test]
    fn test_parse_invalid_json() {
        let result = parse_input("invalid json");
        assert!(result.is_err());
    }

    #[test]
    fn test_validate_valid_input() {
        let input = AddRecipeInput {
            tandoor: TandoorConfigInput {
                base_url: "http://localhost".to_string(),
                api_token: "token".to_string(),
            },
            mealplan_id: 1,
            recipe_id: 2,
            servings: 4.0,
        };
        assert!(validate_input(&input).is_ok());
    }

    #[test]
    fn test_validate_invalid_mealplan_id() {
        let input = AddRecipeInput {
            tandoor: TandoorConfigInput {
                base_url: "http://localhost".to_string(),
                api_token: "token".to_string(),
            },
            mealplan_id: 0,
            recipe_id: 2,
            servings: 4.0,
        };
        assert!(validate_input(&input).is_err());
    }

    #[test]
    fn test_validate_negative_recipe_id() {
        let input = AddRecipeInput {
            tandoor: TandoorConfigInput {
                base_url: "http://localhost".to_string(),
                api_token: "token".to_string(),
            },
            mealplan_id: 1,
            recipe_id: -1,
            servings: 4.0,
        };
        assert!(validate_input(&input).is_err());
    }

    #[test]
    fn test_validate_zero_servings() {
        let input = AddRecipeInput {
            tandoor: TandoorConfigInput {
                base_url: "http://localhost".to_string(),
                api_token: "token".to_string(),
            },
            mealplan_id: 1,
            recipe_id: 2,
            servings: 0.0,
        };
        assert!(validate_input(&input).is_err());
    }

    #[test]
    fn test_validate_empty_base_url() {
        let input = AddRecipeInput {
            tandoor: TandoorConfigInput {
                base_url: "".to_string(),
                api_token: "token".to_string(),
            },
            mealplan_id: 1,
            recipe_id: 2,
            servings: 4.0,
        };
        assert!(validate_input(&input).is_err());
    }

    #[test]
    fn test_validate_empty_api_token() {
        let input = AddRecipeInput {
            tandoor: TandoorConfigInput {
                base_url: "http://localhost".to_string(),
                api_token: "".to_string(),
            },
            mealplan_id: 1,
            recipe_id: 2,
            servings: 4.0,
        };
        assert!(validate_input(&input).is_err());
    }

    #[test]
    fn test_format_success() {
        let entries = vec![ShoppingListRecipe {
            id: 1,
            mealplan: 1,
            recipe: 2,
            recipe_name: "Test".to_string(),
            list: 1,
            servings: 4.0,
            entries: vec![],
        }];
        let output = format_success(&entries);
        assert!(output.success);
        assert!(output.entries.is_some());
        assert_eq!(output.entries.unwrap().len(), 1);
        assert!(output.error.is_none());
    }

    #[test]
    fn test_format_error() {
        let output = format_error("test error");
        assert!(!output.success);
        assert!(output.entries.is_none());
        assert_eq!(output.error, Some("test error".to_string()));
    }
}
