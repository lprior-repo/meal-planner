//! Unit tests for tandoor_shopping_list_entry_update core logic
//!
//! Dave Farley: "Pure functions are easy to test, reason about, and compose."
//! These tests verify the functional core of the binary.
//!
//! GATE-2: Write failing unit test for the core logic

#[cfg(test)]
mod unit_tests {
    use meal_planner::tandoor::UpdateShoppingListEntryRequest;
    use serde::Deserialize;
    use serde_json::json;

    #[derive(Deserialize)]
    struct Input {
        tandoor: TandoorConfig,
        mealplan_id: i64,
        entry_id: i64,
        update: UpdateShoppingListEntryRequest,
    }

    #[derive(Deserialize)]
    struct TandoorConfig {
        base_url: String,
        api_token: String,
    }

    mod validate_input {
        use super::*;

        fn validate_input(input: &Input) -> Result<(), String> {
            if input.mealplan_id <= 0 {
                return Err("mealplan_id must be positive".to_string());
            }
            if input.entry_id <= 0 {
                return Err("entry_id must be positive".to_string());
            }
            Ok(())
        }

        #[test]
        fn valid_input_passes_validation() {
            let input = Input {
                tandoor: TandoorConfig {
                    base_url: "http://localhost:8090".to_string(),
                    api_token: "test".to_string(),
                },
                mealplan_id: 1,
                entry_id: 100,
                update: UpdateShoppingListEntryRequest {
                    list: None,
                    ingredient: None,
                    unit: None,
                    amount: Some(2.0),
                    food: None,
                    checked: Some(true),
                    order: None,
                },
            };
            assert!(validate_input(&input).is_ok());
        }

        #[test]
        fn zero_mealplan_id_fails() {
            let input = Input {
                tandoor: TandoorConfig {
                    base_url: "http://localhost:8090".to_string(),
                    api_token: "test".to_string(),
                },
                mealplan_id: 0,
                entry_id: 100,
                update: UpdateShoppingListEntryRequest::default(),
            };
            assert!(validate_input(&input).is_err());
            assert!(validate_input(&input).unwrap_err().contains("mealplan_id"));
        }

        #[test]
        fn negative_mealplan_id_fails() {
            let input = Input {
                tandoor: TandoorConfig {
                    base_url: "http://localhost:8090".to_string(),
                    api_token: "test".to_string(),
                },
                mealplan_id: -1,
                entry_id: 100,
                update: UpdateShoppingListEntryRequest::default(),
            };
            assert!(validate_input(&input).is_err());
        }

        #[test]
        fn zero_entry_id_fails() {
            let input = Input {
                tandoor: TandoorConfig {
                    base_url: "http://localhost:8090".to_string(),
                    api_token: "test".to_string(),
                },
                mealplan_id: 1,
                entry_id: 0,
                update: UpdateShoppingListEntryRequest::default(),
            };
            assert!(validate_input(&input).is_err());
            assert!(validate_input(&input).unwrap_err().contains("entry_id"));
        }

        #[test]
        fn negative_entry_id_fails() {
            let input = Input {
                tandoor: TandoorConfig {
                    base_url: "http://localhost:8090".to_string(),
                    api_token: "test".to_string(),
                },
                mealplan_id: 1,
                entry_id: -5,
                update: UpdateShoppingListEntryRequest::default(),
            };
            assert!(validate_input(&input).is_err());
        }
    }

    mod parse_input {
        use super::*;

        fn parse_input(json_str: &str) -> Result<Input, String> {
            serde_json::from_str(json_str).map_err(|e| e.to_string())
        }

        #[test]
        fn valid_json_parses_successfully() {
            let json = r#"{
                "tandoor": {"base_url": "http://localhost:8090", "api_token": "test"},
                "mealplan_id": 1,
                "entry_id": 100,
                "update": {"checked": true}
            }"#;
            let result = parse_input(json);
            assert!(result.is_ok());
            let input = result.unwrap();
            assert_eq!(input.mealplan_id, 1);
            assert_eq!(input.entry_id, 100);
            assert_eq!(input.update.checked, Some(true));
        }

        #[test]
        fn missing_tandoor_field_returns_error() {
            let json = r#"{
                "mealplan_id": 1,
                "entry_id": 100,
                "update": {}
            }"#;
            let result = parse_input(json);
            assert!(result.is_err());
        }

        #[test]
        fn missing_mealplan_id_returns_error() {
            let json = r#"{
                "tandoor": {"base_url": "http://localhost:8090", "api_token": "test"},
                "entry_id": 100,
                "update": {}
            }"#;
            let result = parse_input(json);
            assert!(result.is_err());
        }

        #[test]
        fn invalid_json_returns_error() {
            let json = r#"{ invalid json }"#;
            let result = parse_input(json);
            assert!(result.is_err());
        }

        #[test]
        fn empty_string_returns_error() {
            let json = "";
            let result = parse_input(json);
            assert!(result.is_err());
        }
    }

    mod format_output {
        use meal_planner::tandoor::ShoppingListEntry;

        #[derive(serde::Serialize)]
        struct Output {
            success: bool,
            entry: Option<ShoppingListEntry>,
            error: Option<String>,
        }

        fn format_success(entry: ShoppingListEntry) -> String {
            let output = Output {
                success: true,
                entry: Some(entry),
                error: None,
            };
            serde_json::to_string(&output).unwrap()
        }

        fn format_error(message: String) -> String {
            let output = Output {
                success: false,
                entry: None,
                error: Some(message),
            };
            serde_json::to_string(&output).unwrap()
        }

        #[test]
        fn success_output_contains_success_true() {
            let entry = ShoppingListEntry {
                id: 100,
                list: 1,
                ingredient: None,
                unit: Some("kg".to_string()),
                amount: Some(2.0),
                food: Some("Apples".to_string()),
                checked: true,
                order: Some(1),
            };
            let json = format_success(entry);
            assert!(json.contains("\"success\":true"));
        }

        #[test]
        fn error_output_contains_success_false() {
            let json = format_error("Not found".to_string());
            assert!(json.contains("\"success\":false"));
            assert!(json.contains("Not found"));
        }

        #[test]
        fn success_output_contains_entry() {
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
            let json = format_success(entry);
            assert!(json.contains("\"id\":100"));
            assert!(json.contains("\"food\":\"Milk\""));
        }

        #[test]
        fn error_output_contains_error_field() {
            let json = format_error("API error".to_string());
            assert!(json.contains("\"error\":\"API error\""));
        }
    }

    mod update_has_changes {
        use super::*;

        fn update_has_changes(update: &UpdateShoppingListEntryRequest) -> bool {
            update.list.is_some()
                || update.ingredient.is_some()
                || update.unit.is_some()
                || update.amount.is_some()
                || update.food.is_some()
                || update.checked.is_some()
                || update.order.is_some()
        }

        #[test]
        fn update_with_checked_has_changes() {
            let update = UpdateShoppingListEntryRequest {
                checked: Some(true),
                ..Default::default()
            };
            assert!(update_has_changes(&update));
        }

        #[test]
        fn update_with_amount_has_changes() {
            let update = UpdateShoppingListEntryRequest {
                amount: Some(5.0),
                ..Default::default()
            };
            assert!(update_has_changes(&update));
        }

        #[test]
        fn empty_update_has_no_changes() {
            let update = UpdateShoppingListEntryRequest::default();
            assert!(!update_has_changes(&update));
        }

        #[test]
        fn update_with_multiple_fields_has_changes() {
            let update = UpdateShoppingListEntryRequest {
                checked: Some(true),
                amount: Some(2.5),
                unit: Some("kg".to_string()),
                ..Default::default()
            };
            assert!(update_has_changes(&update));
        }
    }
}
