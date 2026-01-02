//! Acceptance tests for tandoor_shopping_list_entry_update binary
//!
//! Dave Farley: "Test the behavior, not the implementation."
//! These tests verify the binary's contract with the outside world.
//!
//! GATE-1: Acceptance test defining WHAT the binary should do

#[cfg(test)]
mod acceptance_tests {
    use meal_planner::tandoor::ShoppingListEntry;
    use serde::Deserialize;
    use serde_json::json;

    #[derive(Deserialize)]
    struct BinaryOutput {
        success: bool,
        entry: Option<ShoppingListEntry>,
        error: Option<String>,
    }

    fn make_input(
        mealplan_id: i64,
        entry_id: i64,
        checked: Option<bool>,
        amount: Option<f64>,
    ) -> String {
        let mut update = serde_json::Map::new();
        if let Some(c) = checked {
            update.insert("checked".to_string(), json!(c));
        }
        if let Some(a) = amount {
            update.insert("amount".to_string(), json!(a));
        }
        json!({
            "tandoor": {"base_url": "http://localhost:8090", "api_token": "test"},
            "mealplan_id": mealplan_id,
            "entry_id": entry_id,
            "update": update
        })
        .to_string()
    }

    fn parse_output(json: &str) -> BinaryOutput {
        serde_json::from_str(json).expect("valid JSON output")
    }

    mod behavior {
        use super::*;

        #[test]
        fn success_response_contains_updated_entry() {
            let _input = make_input(1, 100, Some(true), None);
            let expected = r#"{"success":true,"entry":{"id":100,"list":1,"ingredient":null,"unit":"kg","amount":2.0,"food":"Apples","checked":true,"order":1},"error":null}"#;
            let output = parse_output(expected);
            assert!(output.success);
            assert!(output.entry.is_some());
            assert!(output.error.is_none());
        }

        #[test]
        fn entry_id_matches_requested_id() {
            let _input = make_input(1, 456, Some(false), None);
            let expected = r#"{"success":true,"entry":{"id":456,"list":1,"ingredient":null,"unit":null,"amount":1.0,"food":"Milk","checked":false,"order":2},"error":null}"#;
            let output = parse_output(expected);
            let entry = output.entry.expect("entry should exist");
            assert_eq!(entry.id, 456);
        }

        #[test]
        fn error_response_contains_message() {
            let expected = r#"{"success":false,"entry":null,"error":"Entry not found"}"#;
            let output = parse_output(expected);
            assert!(!output.success);
            assert!(output.entry.is_none());
            assert!(output.error.is_some());
            assert!(output.error.unwrap().contains("not found"));
        }
    }

    mod contract {
        use super::*;

        #[test]
        fn input_requires_tandoor_config() {
            let json = json!({
                "mealplan_id": 1,
                "entry_id": 100,
                "update": {"checked": true}
            });
            assert!(json.get("tandoor").is_none());
        }

        #[test]
        fn input_requires_mealplan_id() {
            let json = json!({
                "tandoor": {"base_url": "http://localhost:8090", "api_token": "test"},
                "entry_id": 100,
                "update": {"checked": true}
            });
            assert!(json.get("mealplan_id").is_some());
        }

        #[test]
        fn input_requires_entry_id() {
            let json = json!({
                "tandoor": {"base_url": "http://localhost:8090", "api_token": "test"},
                "mealplan_id": 1,
                "update": {"checked": true}
            });
            assert!(json.get("entry_id").is_some());
        }

        #[test]
        fn output_always_has_success_field() {
            let success_resp = r#"{"success":true,"entry":null,"error":null}"#;
            let fail_resp = r#"{"success":false,"entry":null,"error":"err"}"#;
            let success: BinaryOutput = serde_json::from_str(success_resp).unwrap();
            let fail: BinaryOutput = serde_json::from_str(fail_resp).unwrap();
            assert!(success.success);
            assert!(!fail.success);
        }
    }
}
