//! Serde utilities for handling `FatSecret` API quirks

use serde::{Deserialize, Deserializer, Serialize};

/// Deserialize a single value, a sequence, or null into a Vec<T>
pub fn deserialize_single_or_vec<'de, T, D>(deserializer: D) -> Result<Vec<T>, D::Error>
where
    T: Deserialize<'de>,
    D: Deserializer<'de>,
{
    #[derive(Deserialize)]
    #[serde(untagged)]
    enum SingleOrVec<T> {
        Single(T),
        Vec(Vec<T>),
    }

    match Option::<SingleOrVec<T>>::deserialize(deserializer)? {
        Some(SingleOrVec::Single(single)) => Ok(vec![single]),
        Some(SingleOrVec::Vec(vec)) => Ok(vec),
        None => Ok(Vec::new()),
    }
}

/// Deserialize a float that might be a string ("95.5") or number (95.5)
pub fn deserialize_flexible_float<'de, D>(deserializer: D) -> Result<f64, D::Error>
where
    D: Deserializer<'de>,
{
    #[derive(Deserialize)]
    #[serde(untagged)]
    enum FlexibleFloat {
        Float(f64),
        String(String),
    }

    match FlexibleFloat::deserialize(deserializer)? {
        FlexibleFloat::Float(f) => Ok(f),
        FlexibleFloat::String(s) => {
            if s.is_empty() {
                Ok(0.0)
            } else {
                s.parse::<f64>().map_err(serde::de::Error::custom)
            }
        }
    }
}

/// Deserialize an optional float that might be a string, number, or missing
pub fn deserialize_optional_flexible_float<'de, D>(deserializer: D) -> Result<Option<f64>, D::Error>
where
    D: Deserializer<'de>,
{
    #[derive(Deserialize)]
    #[serde(untagged)]
    enum FlexibleFloat {
        Float(f64),
        String(String),
    }

    match Option::<FlexibleFloat>::deserialize(deserializer)? {
        Some(FlexibleFloat::Float(f)) => Ok(Some(f)),
        Some(FlexibleFloat::String(s)) => {
            if s.is_empty() || s == "None" || s == "null" {
                Ok(None)
            } else {
                s.parse::<f64>().map(Some).map_err(serde::de::Error::custom)
            }
        }
        _ => Ok(None),
    }
}

/// Deserialize an int that might be a string ("95") or number (95)
pub fn deserialize_flexible_int<'de, D>(deserializer: D) -> Result<i32, D::Error>
where
    D: Deserializer<'de>,
{
    #[derive(Deserialize)]
    #[serde(untagged)]
    enum FlexibleInt {
        Int(i32),
        String(String),
    }

    match FlexibleInt::deserialize(deserializer)? {
        FlexibleInt::Int(i) => Ok(i),
        FlexibleInt::String(s) => {
            if s.is_empty() {
                Ok(0)
            } else {
                s.parse::<i32>().map_err(serde::de::Error::custom)
            }
        }
    }
}

/// Deserialize an optional int that might be a string, number, or missing
pub fn deserialize_optional_flexible_int<'de, D>(deserializer: D) -> Result<Option<i32>, D::Error>
where
    D: Deserializer<'de>,
{
    #[derive(Deserialize)]
    #[serde(untagged)]
    enum FlexibleInt {
        Int(i32),
        String(String),
    }

    match Option::<FlexibleInt>::deserialize(deserializer)? {
        Some(FlexibleInt::Int(i)) => Ok(Some(i)),
        Some(FlexibleInt::String(s)) => {
            if s.is_empty() || s == "None" || s == "null" {
                Ok(None)
            } else {
                s.parse::<i32>().map(Some).map_err(serde::de::Error::custom)
            }
        }
        _ => Ok(None),
    }
}

/// Deserialize an i64 that might be a string ("95") or number (95)
pub fn deserialize_flexible_i64<'de, D>(deserializer: D) -> Result<i64, D::Error>
where
    D: Deserializer<'de>,
{
    #[derive(Deserialize)]
    #[serde(untagged)]
    enum FlexibleI64 {
        Int(i64),
        String(String),
    }

    match FlexibleI64::deserialize(deserializer)? {
        FlexibleI64::Int(i) => Ok(i),
        FlexibleI64::String(s) => {
            if s.is_empty() {
                Ok(0)
            } else {
                s.parse::<i64>().map_err(serde::de::Error::custom)
            }
        }
    }
}

/// Deserialize an optional i64 that might be a string, number, or missing
pub fn deserialize_optional_flexible_i64<'de, D>(deserializer: D) -> Result<Option<i64>, D::Error>
where
    D: Deserializer<'de>,
{
    #[derive(Deserialize)]
    #[serde(untagged)]
    enum FlexibleI64 {
        Int(i64),
        String(String),
    }

    match Option::<FlexibleI64>::deserialize(deserializer)? {
        Some(FlexibleI64::Int(i)) => Ok(Some(i)),
        Some(FlexibleI64::String(s)) => {
            if s.is_empty() || s == "None" || s == "null" {
                Ok(None)
            } else {
                s.parse::<i64>().map(Some).map_err(serde::de::Error::custom)
            }
        }
        _ => Ok(None),
    }
}

/// `FatSecret` API success response (for operations like `add_favorite`, `delete_favorite`)
///
/// The API returns `{"success": {"value": "1"}}` for successful operations
#[derive(Debug, Deserialize, Serialize)]
pub struct SuccessResponse {
    /// Optional success indicator wrapper
    pub success: Option<SuccessValue>,
}

/// Success value container from `FatSecret` API
#[derive(Debug, Deserialize, Serialize)]
pub struct SuccessValue {
    /// String value indicating success ("1") or failure ("0")
    pub value: String,
}

impl SuccessResponse {
    /// Check if the response indicates success (value is "1")
    pub fn is_success(&self) -> bool {
        self.success.as_ref().is_some_and(|s| s.value == "1")
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde::Deserialize;

    // ============================================================================
    // deserialize_single_or_vec tests
    // ============================================================================

    #[derive(Debug, Deserialize, PartialEq)]
    struct TestVec {
        #[serde(default, deserialize_with = "deserialize_single_or_vec")]
        items: Vec<String>,
    }

    #[test]
    fn test_single_or_vec_with_single() {
        let json = r#"{"items": "single"}"#;
        let result: TestVec = serde_json::from_str(json).unwrap();
        assert_eq!(result.items, vec!["single".to_string()]);
    }

    #[test]
    fn test_single_or_vec_with_vec() {
        let json = r#"{"items": ["a", "b", "c"]}"#;
        let result: TestVec = serde_json::from_str(json).unwrap();
        assert_eq!(result.items, vec!["a".to_string(), "b".to_string(), "c".to_string()]);
    }

    #[test]
    fn test_single_or_vec_with_null() {
        let json = r#"{"items": null}"#;
        let result: TestVec = serde_json::from_str(json).unwrap();
        assert!(result.items.is_empty());
    }

    #[test]
    fn test_single_or_vec_with_empty_array() {
        let json = r#"{"items": []}"#;
        let result: TestVec = serde_json::from_str(json).unwrap();
        assert!(result.items.is_empty());
    }

    // ============================================================================
    // deserialize_flexible_float tests
    // ============================================================================

    #[derive(Debug, Deserialize)]
    struct TestFloat {
        #[serde(deserialize_with = "deserialize_flexible_float")]
        value: f64,
    }

    #[test]
    fn test_flexible_float_from_number() {
        let json = r#"{"value": 12.5}"#;
        let result: TestFloat = serde_json::from_str(json).unwrap();
        assert!((result.value - 12.5).abs() < 0.001);
    }

    #[test]
    fn test_flexible_float_from_string() {
        let json = r#"{"value": "95.5"}"#;
        let result: TestFloat = serde_json::from_str(json).unwrap();
        assert!((result.value - 95.5).abs() < 0.001);
    }

    #[test]
    fn test_flexible_float_from_empty_string() {
        let json = r#"{"value": ""}"#;
        let result: TestFloat = serde_json::from_str(json).unwrap();
        assert!((result.value - 0.0).abs() < 0.001);
    }

    #[test]
    fn test_flexible_float_from_integer_number() {
        let json = r#"{"value": 42}"#;
        let result: TestFloat = serde_json::from_str(json).unwrap();
        assert!((result.value - 42.0).abs() < 0.001);
    }

    // ============================================================================
    // deserialize_optional_flexible_float tests
    // ============================================================================

    #[derive(Debug, Deserialize)]
    struct TestOptionalFloat {
        #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
        value: Option<f64>,
    }

    #[test]
    fn test_optional_float_from_number() {
        let json = r#"{"value": 12.5}"#;
        let result: TestOptionalFloat = serde_json::from_str(json).unwrap();
        assert!((result.value.unwrap() - 12.5).abs() < 0.001);
    }

    #[test]
    fn test_optional_float_from_string() {
        let json = r#"{"value": "95.5"}"#;
        let result: TestOptionalFloat = serde_json::from_str(json).unwrap();
        assert!((result.value.unwrap() - 95.5).abs() < 0.001);
    }

    #[test]
    fn test_optional_float_from_empty_string() {
        let json = r#"{"value": ""}"#;
        let result: TestOptionalFloat = serde_json::from_str(json).unwrap();
        assert!(result.value.is_none());
    }

    #[test]
    fn test_optional_float_from_null() {
        let json = r#"{"value": null}"#;
        let result: TestOptionalFloat = serde_json::from_str(json).unwrap();
        assert!(result.value.is_none());
    }

    #[test]
    fn test_optional_float_from_none_string() {
        let json = r#"{"value": "None"}"#;
        let result: TestOptionalFloat = serde_json::from_str(json).unwrap();
        assert!(result.value.is_none());
    }

    // ============================================================================
    // deserialize_flexible_int tests
    // ============================================================================

    #[derive(Debug, Deserialize)]
    struct TestInt {
        #[serde(deserialize_with = "deserialize_flexible_int")]
        value: i32,
    }

    #[test]
    fn test_flexible_int_from_number() {
        let json = r#"{"value": 42}"#;
        let result: TestInt = serde_json::from_str(json).unwrap();
        assert_eq!(result.value, 42);
    }

    #[test]
    fn test_flexible_int_from_string() {
        let json = r#"{"value": "123"}"#;
        let result: TestInt = serde_json::from_str(json).unwrap();
        assert_eq!(result.value, 123);
    }

    #[test]
    fn test_flexible_int_from_empty_string() {
        let json = r#"{"value": ""}"#;
        let result: TestInt = serde_json::from_str(json).unwrap();
        assert_eq!(result.value, 0);
    }

    #[test]
    fn test_flexible_int_negative() {
        let json = r#"{"value": "-99"}"#;
        let result: TestInt = serde_json::from_str(json).unwrap();
        assert_eq!(result.value, -99);
    }

    // ============================================================================
    // deserialize_optional_flexible_int tests
    // ============================================================================

    #[derive(Debug, Deserialize)]
    struct TestOptionalInt {
        #[serde(default, deserialize_with = "deserialize_optional_flexible_int")]
        value: Option<i32>,
    }

    #[test]
    fn test_optional_int_from_number() {
        let json = r#"{"value": 42}"#;
        let result: TestOptionalInt = serde_json::from_str(json).unwrap();
        assert_eq!(result.value, Some(42));
    }

    #[test]
    fn test_optional_int_from_string() {
        let json = r#"{"value": "123"}"#;
        let result: TestOptionalInt = serde_json::from_str(json).unwrap();
        assert_eq!(result.value, Some(123));
    }

    #[test]
    fn test_optional_int_from_null() {
        let json = r#"{"value": null}"#;
        let result: TestOptionalInt = serde_json::from_str(json).unwrap();
        assert!(result.value.is_none());
    }

    #[test]
    fn test_optional_int_from_empty_string() {
        let json = r#"{"value": ""}"#;
        let result: TestOptionalInt = serde_json::from_str(json).unwrap();
        assert!(result.value.is_none());
    }

    #[test]
    fn test_optional_int_from_null_string() {
        let json = r#"{"value": "null"}"#;
        let result: TestOptionalInt = serde_json::from_str(json).unwrap();
        assert!(result.value.is_none());
    }

    // ============================================================================
    // deserialize_flexible_i64 tests
    // ============================================================================

    #[derive(Debug, Deserialize)]
    struct TestI64 {
        #[serde(deserialize_with = "deserialize_flexible_i64")]
        value: i64,
    }

    #[test]
    fn test_flexible_i64_from_number() {
        let json = r#"{"value": 9999999999}"#;
        let result: TestI64 = serde_json::from_str(json).unwrap();
        assert_eq!(result.value, 9999999999);
    }

    #[test]
    fn test_flexible_i64_from_string() {
        let json = r#"{"value": "9999999999"}"#;
        let result: TestI64 = serde_json::from_str(json).unwrap();
        assert_eq!(result.value, 9999999999);
    }

    #[test]
    fn test_flexible_i64_from_empty_string() {
        let json = r#"{"value": ""}"#;
        let result: TestI64 = serde_json::from_str(json).unwrap();
        assert_eq!(result.value, 0);
    }

    // ============================================================================
    // deserialize_optional_flexible_i64 tests
    // ============================================================================

    #[derive(Debug, Deserialize)]
    struct TestOptionalI64 {
        #[serde(default, deserialize_with = "deserialize_optional_flexible_i64")]
        value: Option<i64>,
    }

    #[test]
    fn test_optional_i64_from_number() {
        let json = r#"{"value": 9999999999}"#;
        let result: TestOptionalI64 = serde_json::from_str(json).unwrap();
        assert_eq!(result.value, Some(9999999999));
    }

    #[test]
    fn test_optional_i64_from_string() {
        let json = r#"{"value": "9999999999"}"#;
        let result: TestOptionalI64 = serde_json::from_str(json).unwrap();
        assert_eq!(result.value, Some(9999999999));
    }

    #[test]
    fn test_optional_i64_from_null() {
        let json = r#"{"value": null}"#;
        let result: TestOptionalI64 = serde_json::from_str(json).unwrap();
        assert!(result.value.is_none());
    }

    #[test]
    fn test_optional_i64_from_empty_string() {
        let json = r#"{"value": ""}"#;
        let result: TestOptionalI64 = serde_json::from_str(json).unwrap();
        assert!(result.value.is_none());
    }

    // ============================================================================
    // SuccessResponse tests
    // ============================================================================

    #[test]
    fn test_success_response_success() {
        let json = r#"{"success": {"value": "1"}}"#;
        let result: SuccessResponse = serde_json::from_str(json).unwrap();
        assert!(result.is_success());
    }

    #[test]
    fn test_success_response_failure() {
        let json = r#"{"success": {"value": "0"}}"#;
        let result: SuccessResponse = serde_json::from_str(json).unwrap();
        assert!(!result.is_success());
    }

    #[test]
    fn test_success_response_missing() {
        let json = r#"{}"#;
        let result: SuccessResponse = serde_json::from_str(json).unwrap();
        assert!(!result.is_success());
    }

    #[test]
    fn test_success_response_null() {
        let json = r#"{"success": null}"#;
        let result: SuccessResponse = serde_json::from_str(json).unwrap();
        assert!(!result.is_success());
    }
}
