//! Recipe selection functions (FUNCTIONAL CORE - PURE)
//!
//! All functions in this module are PURE:
//! - Same inputs → same outputs (deterministic)
//! - No I/O operations
//! - No side effects
//! - No external state dependencies
//!
//! These functions form the FUNCTIONAL CORE for recipe selection by calorie range.
//! The IMPERATIVE SHELL (binaries) handles all I/O.

/// Simple recipe representation for selection operations
///
/// # Function Size: 8 lines (≤25 ✓)
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Recipe {
    pub id: u32,
    pub name: String,
    pub calories: u32,
}

/// Filter recipes that fall within calorie range [min, max]
///
/// PURE FUNCTION - No I/O, deterministic
///
/// # Arguments
/// * `recipes` - Slice of recipes to filter
/// * `min` - Minimum calories (inclusive)
/// * `max` - Maximum calories (inclusive)
///
/// # Returns
/// Vector of recipes with calories in range [min, max]
///
/// # Function Size: 7 lines (≤25 ✓)
pub fn filter_by_calorie_range(recipes: &[Recipe], min: u32, max: u32) -> Vec<Recipe> {
    recipes
        .iter()
        .filter(|r| r.calories >= min && r.calories <= max)
        .cloned()
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_filter_by_calorie_range_basic() {
        let recipes = vec![
            Recipe { id: 1, name: "Low cal".to_string(), calories: 200 },
            Recipe { id: 2, name: "Medium cal".to_string(), calories: 500 },
            Recipe { id: 3, name: "High cal".to_string(), calories: 800 },
        ];

        let result = filter_by_calorie_range(&recipes, 300, 600);

        assert_eq!(result.len(), 1);
        assert_eq!(result[0].id, 2);
        assert_eq!(result[0].name, "Medium cal");
        assert_eq!(result[0].calories, 500);
    }

    #[test]
    fn test_filter_by_calorie_range_empty() {
        let recipes = vec![
            Recipe { id: 1, name: "Low cal".to_string(), calories: 200 },
        ];

        let result = filter_by_calorie_range(&recipes, 500, 1000);

        assert!(result.is_empty());
    }

    #[test]
    fn test_filter_by_calorie_range_all_match() {
        let recipes = vec![
            Recipe { id: 1, name: "A".to_string(), calories: 300 },
            Recipe { id: 2, name: "B".to_string(), calories: 400 },
            Recipe { id: 3, name: "C".to_string(), calories: 500 },
        ];

        let result = filter_by_calorie_range(&recipes, 0, 1000);

        assert_eq!(result.len(), 3);
    }

    #[test]
    fn test_filter_by_calorie_range_boundary() {
        let recipes = vec![
            Recipe { id: 1, name: "Min".to_string(), calories: 100 },
            Recipe { id: 2, name: "Just right".to_string(), calories: 500 },
            Recipe { id: 3, name: "Max".to_string(), calories: 1000 },
        ];

        let result = filter_by_calorie_range(&recipes, 100, 1000);

        assert_eq!(result.len(), 3);
    }

    #[test]
    fn test_filter_by_calorie_range_empty_input() {
        let recipes: Vec<Recipe> = vec![];
        let result = filter_by_calorie_range(&recipes, 0, 1000);
        assert!(result.is_empty());
    }
}
