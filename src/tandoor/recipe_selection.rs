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

/// Summary of a recipe with key fields for selection
#[derive(Debug, Clone)]
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

    let calories: Vec<f64> = recipes.iter().map(|r| r.calories as f64).collect();
    let total: f64 = calories.iter().sum();
    let count = calories.len();
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
        assert_eq!(stats.total, 2000.0);
        assert!((stats.average - 500.0).abs() < 0.001);
        assert_eq!(stats.min, 400.0);
        assert_eq!(stats.max, 600.0);
    }

    #[test]
    fn test_calculate_stats_empty() {
        let recipes: Vec<RecipeSummary> = vec![];
        let stats = calculate_stats(&recipes);

        assert_eq!(stats.count, 0);
        assert_eq!(stats.total, 0.0);
        assert_eq!(stats.average, 0.0);
        assert_eq!(stats.min, 0.0);
        assert_eq!(stats.max, 0.0);
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
        assert_eq!(stats.total, 750.0);
        assert_eq!(stats.average, 750.0);
        assert_eq!(stats.min, 750.0);
        assert_eq!(stats.max, 750.0);
    }
}
