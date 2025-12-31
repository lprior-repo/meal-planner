//! Parameter building utilities for FatSecret API requests
//!
//! Provides a fluent builder pattern for constructing API request parameters,
//! reducing boilerplate and improving consistency across client modules.

use std::collections::HashMap;

/// Fluent builder for API request parameters
///
/// # Example
/// ```
/// use meal_planner::fatsecret::core::ParamBuilder;
///
/// let params = ParamBuilder::new()
///     .insert("food_id", "12345")
///     .insert_if("max_results", Some(20))
///     .insert_if("page_number", None::<i32>)
///     .build();
///
/// assert_eq!(params.get("food_id"), Some(&"12345".to_string()));
/// assert_eq!(params.get("max_results"), Some(&"20".to_string()));
/// assert!(params.get("page_number").is_none());
/// ```
#[derive(Debug, Default, Clone)]
pub struct ParamBuilder {
    params: HashMap<String, String>,
}

impl ParamBuilder {
    /// Create a new empty parameter builder
    pub fn new() -> Self {
        Self::default()
    }

    /// Insert a required parameter
    ///
    /// Converts any `ToString` value to string automatically.
    #[must_use]
    pub fn insert(mut self, key: &str, value: impl ToString) -> Self {
        self.params.insert(key.to_string(), value.to_string());
        self
    }

    /// Insert an optional parameter (only if Some)
    ///
    /// If value is None, the parameter is not added.
    #[must_use]
    pub fn insert_if<T: ToString>(mut self, key: &str, value: Option<T>) -> Self {
        if let Some(v) = value {
            self.params.insert(key.to_string(), v.to_string());
        }
        self
    }

    /// Insert a parameter with a mapped value (only if Some)
    ///
    /// Useful for converting enums or complex types.
    #[must_use]
    pub fn insert_mapped<T, F>(mut self, key: &str, value: Option<T>, mapper: F) -> Self
    where
        F: FnOnce(T) -> String,
    {
        if let Some(v) = value {
            self.params.insert(key.to_string(), mapper(v));
        }
        self
    }

    /// Build the final HashMap of parameters
    pub fn build(self) -> HashMap<String, String> {
        self.params
    }

    /// Get the number of parameters
    pub fn len(&self) -> usize {
        self.params.len()
    }

    /// Check if empty
    pub fn is_empty(&self) -> bool {
        self.params.is_empty()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_param_builder_insert() {
        let params = ParamBuilder::new()
            .insert("key1", "value1")
            .insert("key2", 42)
            .build();

        assert_eq!(params.get("key1"), Some(&"value1".to_string()));
        assert_eq!(params.get("key2"), Some(&"42".to_string()));
    }

    #[test]
    fn test_param_builder_insert_if_some() {
        let params = ParamBuilder::new()
            .insert_if("present", Some(100))
            .insert_if("absent", None::<i32>)
            .build();

        assert_eq!(params.get("present"), Some(&"100".to_string()));
        assert!(params.get("absent").is_none());
    }

    #[test]
    fn test_param_builder_insert_mapped() {
        #[derive(Clone, Copy)]
        enum Meal {
            Breakfast,
            Lunch,
        }

        let meal_to_str = |m: Meal| {
            match m {
                Meal::Breakfast => "breakfast",
                Meal::Lunch => "lunch",
            }
            .to_string()
        };

        let params = ParamBuilder::new()
            .insert_mapped("meal1", Some(Meal::Lunch), meal_to_str)
            .insert_mapped("meal2", Some(Meal::Breakfast), meal_to_str)
            .insert_mapped("empty", None::<Meal>, |_| "unused".to_string())
            .build();

        assert_eq!(params.get("meal1"), Some(&"lunch".to_string()));
        assert_eq!(params.get("meal2"), Some(&"breakfast".to_string()));
        assert!(params.get("empty").is_none());
    }

    #[test]
    fn test_param_builder_empty() {
        let builder = ParamBuilder::new();
        assert!(builder.is_empty());
        assert_eq!(builder.len(), 0);
    }

    #[test]
    fn test_param_builder_len() {
        let builder = ParamBuilder::new()
            .insert("a", 1)
            .insert("b", 2)
            .insert("c", 3);
        assert_eq!(builder.len(), 3);
        assert!(!builder.is_empty());
    }
}
