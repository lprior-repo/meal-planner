//! Serde utilities for handling FatSecret API quirks

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

/// FatSecret API success response (for operations like add_favorite, delete_favorite)
///
/// The API returns `{"success": {"value": "1"}}` for successful operations
#[derive(Debug, Deserialize, Serialize)]
pub struct SuccessResponse {
    /// Optional success indicator wrapper
    pub success: Option<SuccessValue>,
}

/// Success value container from FatSecret API
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
