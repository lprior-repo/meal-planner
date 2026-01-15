//! Recipe selection core (FUNCTIONAL CORE - PURE)
//!
//! All functions in this module are PURE:
//! - Same inputs → same outputs (deterministic)
//! - No I/O operations
//! - No side effects
//! - No external state dependencies
//!
//! These functions form the FUNCTIONAL CORE.
//! The IMPERATIVE SHELL (binaries) handles all I/O.

#![allow(clippy::cast_precision_loss)]

use serde::{Deserialize, Serialize};

/// Summary of a recipe with key fields for selection
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RecipeSummary {
    pub id: u32,
    pub name: String,
    pub calories: u32,
}

/// Statistics computed from a collection of recipes
#[derive(Debug, PartialEq)]
pub struct CalorieStats {
    pub count: usize,
    pub total: f64,
    pub average: f64,
    pub min: f64,
    pub max: f64,
}

/// Calculate calorie statistics for a collection of recipes
///
/// # Arguments
/// * `recipes` - Slice of recipe summaries
///
/// # Returns
/// Statistics including count, total, average, min, and max calories
///
/// # Function Size: 20 lines (≤25 ✓)
pub fn calculate_stats(recipes: &[RecipeSummary]) -> CalorieStats {
    if recipes.is_empty() {
        return CalorieStats {
            count: 0,
            total: 0.0,
            average: 0.0,
            min: 0.0,
            max: 0.0,
        };
    }

    let calories: Vec<f64> = recipes.iter().map(|r| f64::from(r.calories)).collect();
    let total: f64 = calories.iter().sum();
    let count = calories.len();
    #[allow(clippy::cast_precision_loss)]
    let average = total / count as f64;
    let min = calories.iter().fold(f64::MAX, |m, v| v.min(m));
    let max = calories.iter().fold(f64::MIN, |m, v| v.max(m));

    CalorieStats {
        count,
        total,
        average,
        min,
        max,
    }
}

/// Select N random recipes from collection using seeded RNG for purity
///
/// # Arguments
/// * `recipes` - Slice of recipe summaries to select from
/// * `count` - Number of recipes to select
/// * `seed` - Seed for deterministic RNG (same seed = same selection)
///
/// # Returns
/// Vector of randomly selected recipes (cloned)
///
/// # Function Size: 14 lines (≤25 ✓)
pub fn random_select(recipes: &[RecipeSummary], count: usize, seed: u64) -> Vec<RecipeSummary> {
    let mut rng = fastrand::Rng::with_seed(seed);
    let mut indices: Vec<usize> = (0..recipes.len()).collect();
    rng.shuffle(&mut indices);
    indices
        .into_iter()
        .take(count)
        .filter_map(|i| recipes.get(i).cloned())
        .collect()
}

pub fn filter_by_calorie_range(
    recipes: &[RecipeSummary],
    min_calories: u32,
    max_calories: u32,
) -> Vec<RecipeSummary> {
    recipes
        .iter()
        .filter(|r| r.calories >= min_calories && r.calories <= max_calories)
        .cloned()
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_calculate_stats_basic() {
        let recipes = vec![
            RecipeSummary {
                id: 1,
                name: "Recipe 1".to_string(),
                calories: 400,
            },
            RecipeSummary {
                id: 2,
                name: "Recipe 2".to_string(),
                calories: 500,
            },
            RecipeSummary {
                id: 3,
                name: "Recipe 3".to_string(),
                calories: 600,
            },
            RecipeSummary {
                id: 4,
                name: "Recipe 4".to_string(),
                calories: 500,
            },
        ];

        let stats = calculate_stats(&recipes);

        assert_eq!(stats.count, 4);
        assert!((stats.total - 2000.0).abs() < 0.001);
        assert!((stats.average - 500.0).abs() < 0.001);
        assert!((stats.min - 400.0).abs() < 0.001);
        assert!((stats.max - 600.0).abs() < 0.001);
    }

    #[test]
    fn test_calculate_stats_empty() {
        let recipes: Vec<RecipeSummary> = vec![];
        let stats = calculate_stats(&recipes);

        assert_eq!(stats.count, 0);
        assert!((stats.total - 0.0).abs() < 0.001);
        assert!((stats.average - 0.0).abs() < 0.001);
        assert!((stats.min - 0.0).abs() < 0.001);
        assert!((stats.max - 0.0).abs() < 0.001);
    }

    #[test]
    fn test_calculate_stats_single() {
        let recipes = vec![RecipeSummary {
            id: 1,
            name: "Single".to_string(),
            calories: 750,
        }];

        let stats = calculate_stats(&recipes);

        assert_eq!(stats.count, 1);
        assert!((stats.total - 750.0).abs() < 0.001);
        assert!((stats.average - 750.0).abs() < 0.001);
        assert!((stats.min - 750.0).abs() < 0.001);
        assert!((stats.max - 750.0).abs() < 0.001);
    }

    #[test]
    #[allow(clippy::too_many_lines)] // Test setup requires many test cases
    fn test_random_select_returns_exact_count() {
        let recipes = vec![
            RecipeSummary {
                id: 1,
                name: "Recipe 1".to_string(),
                calories: 400,
            },
            RecipeSummary {
                id: 2,
                name: "Recipe 2".to_string(),
                calories: 500,
            },
            RecipeSummary {
                id: 3,
                name: "Recipe 3".to_string(),
                calories: 600,
            },
            RecipeSummary {
                id: 4,
                name: "Recipe 4".to_string(),
                calories: 500,
            },
            RecipeSummary {
                id: 5,
                name: "Recipe 5".to_string(),
                calories: 700,
            },
            RecipeSummary {
                id: 6,
                name: "Recipe 6".to_string(),
                calories: 450,
            },
            RecipeSummary {
                id: 7,
                name: "Recipe 7".to_string(),
                calories: 550,
            },
            RecipeSummary {
                id: 8,
                name: "Recipe 8".to_string(),
                calories: 650,
            },
            RecipeSummary {
                id: 9,
                name: "Recipe 9".to_string(),
                calories: 350,
            },
            RecipeSummary {
                id: 10,
                name: "Recipe 10".to_string(),
                calories: 750,
            },
        ];

        let result = random_select(&recipes, 4, 42);

        assert_eq!(result.len(), 4, "Expected exactly 4 recipes");
    }

    #[test]
    fn test_random_select_deterministic_with_same_seed() {
        let recipes = vec![
            RecipeSummary {
                id: 1,
                name: "Recipe 1".to_string(),
                calories: 400,
            },
            RecipeSummary {
                id: 2,
                name: "Recipe 2".to_string(),
                calories: 500,
            },
            RecipeSummary {
                id: 3,
                name: "Recipe 3".to_string(),
                calories: 600,
            },
            RecipeSummary {
                id: 4,
                name: "Recipe 4".to_string(),
                calories: 500,
            },
        ];

        let result1 = random_select(&recipes, 2, 12345);
        let result2 = random_select(&recipes, 2, 12345);

        assert_eq!(result1, result2, "Same seed should produce same selection");
    }

    #[test]
    fn test_random_select_different_with_different_seeds() {
        let recipes = vec![
            RecipeSummary {
                id: 1,
                name: "Recipe 1".to_string(),
                calories: 400,
            },
            RecipeSummary {
                id: 2,
                name: "Recipe 2".to_string(),
                calories: 500,
            },
            RecipeSummary {
                id: 3,
                name: "Recipe 3".to_string(),
                calories: 600,
            },
            RecipeSummary {
                id: 4,
                name: "Recipe 4".to_string(),
                calories: 500,
            },
        ];

        let result1 = random_select(&recipes, 2, 11111);
        let result2 = random_select(&recipes, 2, 99999);

        assert_ne!(
            result1, result2,
            "Different seeds should produce different selections"
        );
    }

    #[test]
    fn test_random_select_returns_all_when_count_exceeds_length() {
        let recipes = vec![
            RecipeSummary {
                id: 1,
                name: "Recipe 1".to_string(),
                calories: 400,
            },
            RecipeSummary {
                id: 2,
                name: "Recipe 2".to_string(),
                calories: 500,
            },
        ];

        let result = random_select(&recipes, 10, 42);

        assert_eq!(
            result.len(),
            2,
            "Should return all recipes when count exceeds length"
        );
    }

    #[test]
    fn test_random_select_returns_empty_when_count_is_zero() {
        let recipes = vec![
            RecipeSummary {
                id: 1,
                name: "Recipe 1".to_string(),
                calories: 400,
            },
            RecipeSummary {
                id: 2,
                name: "Recipe 2".to_string(),
                calories: 500,
            },
        ];

        let result = random_select(&recipes, 0, 42);

        assert!(result.is_empty(), "Should return empty vec when count is 0");
    }

    #[test]
    fn test_random_select_returns_empty_when_input_is_empty() {
        let recipes: Vec<RecipeSummary> = vec![];

        let result = random_select(&recipes, 3, 42);

        assert!(
            result.is_empty(),
            "Should return empty vec when input is empty"
        );
    }
}
