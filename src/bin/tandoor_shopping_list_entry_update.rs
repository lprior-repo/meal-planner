//! Update a shopping list entry
//!
//! Updates an existing shopping list entry (e.g., mark as checked, change amount).
//!
//! ## Architecture: Functional Core / Imperative Shell
//!
//! Dave Farley: "Push I/O to the edges. Keep the core pure and testable."
//!
//! - **Core** (pure functions, no I/O):
//!   - `validate_input` - validates input fields
//!   - `parse_input` - deserializes JSON
//!   - `format_success_output` - serializes success response
//!   - `format_error_output` - serializes error response
//!
//! - **Shell** (I/O coordination):
//!   - `read_input` - reads JSON from CLI arg or stdin
//!   - `write_output` - writes JSON to stdout
//!   - `main` - orchestrates the flow
//!
//! ## JSON Contract
//!
//! Input (CLI arg or stdin):
//! ```json
//! {"tandoor": {"base_url": "...", "api_token": "..."}, "mealplan_id": 123, "entry_id": 456, "update": {"checked": true}}
//! ```
//!
//! Output:
//! ```json
//! {"success": true, "entry": {...}}  // or {"success": false, "error": "..."}
//! ```

#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::tandoor::{
    ShoppingListEntry, TandoorClient, TandoorConfig, UpdateShoppingListEntryRequest,
};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

// ========================================
// CORE: Pure Functions (No I/O)
// ========================================

#[derive(Deserialize)]
pub struct Input {
    tandoor: TandoorConfig,
    mealplan_id: i64,
    entry_id: i64,
    update: UpdateShoppingListEntryRequest,
}

#[derive(Serialize)]
pub struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    entry: Option<ShoppingListEntry>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn validate_input(input: &Input) -> Result<(), String> {
    if input.mealplan_id <= 0 {
        return Err("mealplan_id must be positive".to_string());
    }
    if input.entry_id <= 0 {
        return Err("entry_id must be positive".to_string());
    }
    Ok(())
}

fn parse_input(json_str: &str) -> Result<Input, String> {
    serde_json::from_str(json_str).map_err(|e| e.to_string())
}

fn format_success_output(entry: ShoppingListEntry) -> String {
    let output = Output {
        success: true,
        entry: Some(entry),
        error: None,
    };
    serde_json::to_string(&output).expect("serialize success output")
}

fn format_error_output(message: String) -> String {
    let output = Output {
        success: false,
        entry: None,
        error: Some(message),
    };
    serde_json::to_string(&output).expect("serialize error output")
}

fn entry_has_changes(update: &UpdateShoppingListEntryRequest) -> bool {
    update.list.is_some()
        || update.ingredient.is_some()
        || update.unit.is_some()
        || update.amount.is_some()
        || update.food.is_some()
        || update.checked.is_some()
        || update.order.is_some()
}

// ========================================
// SHELL: I/O Operations
// ========================================

fn read_input() -> Result<String, String> {
    if let Some(arg) = std::env::args().nth(1) {
        Ok(arg)
    } else {
        let mut input_str = String::new();
        io::stdin()
            .read_to_string(&mut input_str)
            .map_err(|e| e.to_string())?;
        Ok(input_str)
    }
}

fn write_output(json: &str) {
    println!("{}", json);
}

// ========================================
// SHELL: Main Orchestration
// ========================================

fn main() {
    let result = run();
    if let Err(e) = &result {
        eprintln!("Error: {}", e);
    }
    let output = match result {
        Ok(entry) => format_success_output(entry),
        Err(msg) => format_error_output(msg),
    };
    write_output(&output);
    if output.contains("\"success\":false") {
        std::process::exit(1);
    }
}

fn run() -> Result<ShoppingListEntry, String> {
    let input_str = read_input()?;
    let input = parse_input(&input_str)?;
    validate_input(&input)?;

    if !entry_has_changes(&input.update) {
        return Err("update request has no fields to change".to_string());
    }

    let client =
        TandoorClient::new(&input.tandoor).map_err(|e| format!("client creation failed: {}", e))?;

    client
        .update_shopping_list_entry(input.mealplan_id, input.entry_id, &input.update)
        .map_err(|e| format!("update failed: {}", e))
}

// ========================================
// TESTS
// ========================================

#[cfg(test)]
mod tests {
    use super::*;

    mod validate_input_tests {
        use super::*;

        fn make_test_input(mealplan_id: i64, entry_id: i64) -> Input {
            Input {
                tandoor: TandoorConfig {
                    base_url: "http://localhost:8090".to_string(),
                    api_token: "test".to_string(),
                },
                mealplan_id,
                entry_id,
                update: UpdateShoppingListEntryRequest::default(),
            }
        }

        #[test]
        fn valid_input_passes() {
            let input = make_test_input(1, 100);
            assert!(validate_input(&input).is_ok());
        }

        #[test]
        fn zero_mealplan_id_fails() {
            let input = make_test_input(0, 100);
            assert!(validate_input(&input).is_err());
        }

        #[test]
        fn negative_mealplan_id_fails() {
            let input = make_test_input(-1, 100);
            assert!(validate_input(&input).is_err());
        }

        #[test]
        fn zero_entry_id_fails() {
            let input = make_test_input(1, 0);
            assert!(validate_input(&input).is_err());
        }

        #[test]
        fn negative_entry_id_fails() {
            let input = make_test_input(1, -5);
            assert!(validate_input(&input).is_err());
        }
    }

    mod parse_input_tests {
        use super::*;

        #[test]
        fn valid_json_parses() {
            let json = r#"{"tandoor":{"base_url":"http://localhost:8090","api_token":"test"},"mealplan_id":1,"entry_id":100,"update":{"checked":true}}"#;
            let result = parse_input(json);
            assert!(result.is_ok());
            let input = result.unwrap();
            assert_eq!(input.mealplan_id, 1);
            assert_eq!(input.entry_id, 100);
        }

        #[test]
        fn invalid_json_fails() {
            let json = "{ invalid }";
            assert!(parse_input(json).is_err());
        }

        #[test]
        fn empty_string_fails() {
            assert!(parse_input("").is_err());
        }
    }

    mod format_output_tests {
        use super::*;

        #[test]
        fn success_contains_true() {
            let entry = ShoppingListEntry {
                id: 100,
                list: 1,
                ingredient: None,
                unit: None,
                amount: Some(1.0),
                food: Some("Milk".to_string()),
                checked: false,
                order: None,
            };
            let json = format_success_output(entry);
            assert!(json.contains("\"success\":true"));
            assert!(json.contains("\"id\":100"));
        }

        #[test]
        fn error_contains_false() {
            let json = format_error_output("test error".to_string());
            assert!(json.contains("\"success\":false"));
            assert!(json.contains("test error"));
        }
    }

    mod entry_has_changes_tests {
        use super::*;

        #[test]
        fn empty_update_has_no_changes() {
            let update = UpdateShoppingListEntryRequest::default();
            assert!(!entry_has_changes(&update));
        }

        #[test]
        fn checked_has_changes() {
            let update = UpdateShoppingListEntryRequest {
                checked: Some(true),
                ..Default::default()
            };
            assert!(entry_has_changes(&update));
        }

        #[test]
        fn amount_has_changes() {
            let update = UpdateShoppingListEntryRequest {
                amount: Some(5.0),
                ..Default::default()
            };
            assert!(entry_has_changes(&update));
        }

        #[test]
        fn multiple_fields_have_changes() {
            let update = UpdateShoppingListEntryRequest {
                checked: Some(true),
                amount: Some(2.5),
                unit: Some("kg".to_string()),
                ..Default::default()
            };
            assert!(entry_has_changes(&update));
        }
    }

    mod integration_tests {
        use super::*;

        #[test]
        fn full_flow_success() {
            let json = r#"{"tandoor":{"base_url":"http://localhost:8090","api_token":"test"},"mealplan_id":1,"entry_id":100,"update":{"checked":true}}"#;
            let input = parse_input(json).expect("parse");
            validate_input(&input).expect("validate");
            assert!(entry_has_changes(&input.update));
        }

        #[test]
        fn full_flow_invalid_id_fails_validation() {
            let json = r#"{"tandoor":{"base_url":"http://localhost:8090","api_token":"test"},"mealplan_id":0,"entry_id":100,"update":{"checked":true}}"#;
            let input = parse_input(json).expect("parse");
            assert!(validate_input(&input).is_err());
        }

        #[test]
        fn full_flow_empty_update_fails() {
            let json = r#"{"tandoor":{"base_url":"http://localhost:8090","api_token":"test"},"mealplan_id":1,"entry_id":100,"update":{}}"#;
            let input = parse_input(json).expect("parse");
            assert!(!entry_has_changes(&input.update));
        }
    }
}
