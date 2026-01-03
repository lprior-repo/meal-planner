//! Core validation functions for fatsecret_exercise_month_summary
//!
//! Dave Farley: "Functional Core / Imperative Shell"
//!
//! Pure functions (no I/O) for input validation and response processing.
//! Each function is ≤25 lines as required.

use serde_json::Value;

const MIN_YEAR: i32 = 2000;
const MAX_YEAR: i32 = 2100;
const MIN_MONTH: i32 = 1;
const MAX_MONTH: i32 = 12;

pub fn validate_year(year: i64) -> Result<i32, String> {
    i32::try_from(year)
        .ok()
        .filter(|&y| (MIN_YEAR..=MAX_YEAR).contains(&y))
        .ok_or_else(|| format!("Year must be between {} and {}", MIN_YEAR, MAX_YEAR))
}

pub fn validate_month(month: i64) -> Result<i32, String> {
    i32::try_from(month)
        .ok()
        .filter(|&m| (MIN_MONTH..=MAX_MONTH).contains(&m))
        .ok_or_else(|| format!("Month must be between {} and {}", MIN_MONTH, MAX_MONTH))
}

pub fn validate_oauth_tokens(input: &Value) -> Result<(), String> {
    let has_token = input
        .get("access_token")
        .and_then(|v| v.as_str())
        .filter(|s| !s.is_empty())
        .is_some();

    let has_secret = input
        .get("access_secret")
        .and_then(|v| v.as_str())
        .filter(|s| !s.is_empty())
        .is_some();

    if has_token && has_secret {
        Ok(())
    } else {
        Err("OAuth access_token and access_secret are required".to_string())
    }
}

pub fn validate_input(input: &Value) -> Result<(), String> {
    let year = input["year"].as_i64().ok_or("year is required")?;
    let month = input["month"].as_i64().ok_or("month is required")?;
    match (validate_year(year), validate_month(month)) {
        (Ok(_), Ok(_)) => validate_oauth_tokens(input),
        (Err(e), _) | (_, Err(e)) => Err(e),
    }
}

pub fn extract_summary(response: &Value) -> Option<&Value> {
    response.get("month_summary")
}

pub fn is_success(response: &Value) -> bool {
    response
        .get("success")
        .and_then(Value::as_bool)
        .unwrap_or(false)
}

pub fn has_days_data(summary: &Value) -> bool {
    summary
        .get("days")
        .is_some_and(|v| v.as_array().is_some_and(|a| !a.is_empty()))
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn validate_year_accepts_valid_years() {
        assert!(validate_year(2025).is_ok());
        assert!(validate_year(2000).is_ok());
        assert!(validate_year(2100).is_ok());
    }

    #[test]
    fn validate_year_rejects_invalid_years() {
        assert!(validate_year(1999).is_err());
        assert!(validate_year(2101).is_err());
        assert!(validate_year(i64::MAX).is_err());
    }

    #[test]
    fn validate_month_accepts_valid_months() {
        assert!(validate_month(1).is_ok());
        assert!(validate_month(6).is_ok());
        assert!(validate_month(12).is_ok());
    }

    #[test]
    fn validate_month_rejects_invalid_months() {
        assert!(validate_month(0).is_err());
        assert!(validate_month(13).is_err());
        assert!(validate_month(i64::MAX).is_err());
    }

    #[test]
    fn validate_oauth_tokens_accepts_valid_tokens() {
        let input = json!({
            "access_token": "token123",
            "access_secret": "secret456"
        });
        assert!(validate_oauth_tokens(&input).is_ok());
    }

    #[test]
    fn validate_oauth_tokens_rejects_missing_tokens() {
        let input = json!({
            "access_token": "token123"
        });
        assert!(validate_oauth_tokens(&input).is_err());

        let input = json!({
            "access_secret": "secret456"
        });
        assert!(validate_oauth_tokens(&input).is_err());
    }

    #[test]
    fn validate_input_accepts_complete_input() {
        let input = json!({
            "year": 2025,
            "month": 12,
            "access_token": "token",
            "access_secret": "secret"
        });
        assert!(validate_input(&input).is_ok());
    }

    #[test]
    fn validate_input_rejects_incomplete_input() {
        let input = json!({
            "year": "invalid",
            "month": 12,
            "access_token": "token",
            "access_secret": "secret"
        });
        assert!(validate_input(&input).is_err());
    }

    #[test]
    fn is_success_detects_success() {
        assert!(is_success(&json!({"success": true})));
        assert!(!is_success(&json!({"success": false})));
        assert!(!is_success(&json!({})));
    }

    #[test]
    fn extract_summary_works() {
        let response = json!({
            "success": true,
            "month_summary": {"days": []}
        });
        assert!(extract_summary(&response).is_some());
    }
}
