//! Recipe selection core tests (Functional Core)
//!
//! Tests for pure functions that compute statistics over recipes.

use meal_planner::tandoor::recipe_selection::{filter_by_calorie_range, random_select, RecipeSummary};

fn make_recipe(id: u32, name: &str, calories: u32) -> RecipeSummary {
    RecipeSummary {
        id,
        name: name.to_string(),
        calories,
    }
}

#[cfg(test)]
mod filter_by_calorie_range_tests {
    use super::*;

    #[test]
    fn test_filter_by_calorie_range_basic() {
        let recipes = vec![
            make_recipe(1, "Low cal", 200),
            make_recipe(2, "Medium cal", 500),
            make_recipe(3, "High cal", 800),
        ];

        let result = filter_by_calorie_range(&recipes, 300, 600);

        assert_eq!(result.len(), 1);
        assert_eq!(result[0].id, 2);
        assert_eq!(result[0].name, "Medium cal");
        assert_eq!(result[0].calories, 500);
    }

    #[test]
    fn test_filter_by_calorie_range_empty() {
        let recipes = vec![make_recipe(1, "Low cal", 200)];

        let result = filter_by_calorie_range(&recipes, 500, 1000);

        assert!(result.is_empty());
    }

    #[test]
    fn test_filter_by_calorie_range_all_match() {
        let recipes = vec![
            make_recipe(1, "A", 300),
            make_recipe(2, "B", 400),
            make_recipe(3, "C", 500),
        ];

        let result = filter_by_calorie_range(&recipes, 0, 1000);

        assert_eq!(result.len(), 3);
    }

    #[test]
    fn test_filter_by_calorie_range_boundary() {
        let recipes = vec![
            make_recipe(1, "Min", 100),
            make_recipe(2, "Just right", 500),
            make_recipe(3, "Max", 1000),
        ];

        let result = filter_by_calorie_range(&recipes, 100, 1000);

        assert_eq!(result.len(), 3);
    }

    #[test]
    fn test_filter_by_calorie_range_empty_input() {
        let recipes: Vec<RecipeSummary> = vec![];
        let result = filter_by_calorie_range(&recipes, 0, 1000);
        assert!(result.is_empty());
    }
}

#[cfg(test)]
mod random_select_tests {
    use super::*;

    #[test]
    fn test_random_select_returns_exact_count() {
        let recipes = vec![
            make_recipe(1, "Recipe 1", 400),
            make_recipe(2, "Recipe 2", 500),
            make_recipe(3, "Recipe 3", 600),
            make_recipe(4, "Recipe 4", 500),
            make_recipe(5, "Recipe 5", 700),
            make_recipe(6, "Recipe 6", 450),
            make_recipe(7, "Recipe 7", 550),
            make_recipe(8, "Recipe 8", 650),
            make_recipe(9, "Recipe 9", 350),
            make_recipe(10, "Recipe 10", 750),
        ];
        
        let result = random_select(&recipes, 4, 42);
        
        assert_eq!(result.len(), 4, "Expected exactly 4 recipes");
    }

    #[test]
    fn test_random_select_returns_deterministic_results_with_same_seed() {
        let recipes = vec![
            make_recipe(1, "Recipe 1", 400),
            make_recipe(2, "Recipe 2", 500),
            make_recipe(3, "Recipe 3", 600),
            make_recipe(4, "Recipe 4", 500),
        ];
        
        let result1 = random_select(&recipes, 2, 12345);
        let result2 = random_select(&recipes, 2, 12345);
        
        assert_eq!(result1, result2, "Same seed should produce same selection");
    }

    #[test]
    fn test_random_select_returns_different_results_with_different_seeds() {
        let recipes = vec![
            make_recipe(1, "Recipe 1", 400),
            make_recipe(2, "Recipe 2", 500),
            make_recipe(3, "Recipe 3", 600),
            make_recipe(4, "Recipe 4", 500),
        ];
        
        let result1 = random_select(&recipes, 2, 11111);
        let result2 = random_select(&recipes, 2, 99999);
        
        assert_ne!(result1, result2, "Different seeds should produce different selections");
    }

    #[test]
    fn test_random_select_returns_all_when_count_exceeds_length() {
        let recipes = vec![
            make_recipe(1, "Recipe 1", 400),
            make_recipe(2, "Recipe 2", 500),
        ];
        
        let result = random_select(&recipes, 10, 42);
        
        assert_eq!(result.len(), 2, "Should return all recipes when count exceeds length");
    }

    #[test]
    fn test_random_select_returns_empty_when_count_is_zero() {
        let recipes = vec![
            make_recipe(1, "Recipe 1", 400),
            make_recipe(2, "Recipe 2", 500),
        ];
        
        let result = random_select(&recipes, 0, 42);
        
        assert!(result.is_empty(), "Should return empty vec when count is 0");
    }

    #[test]
    fn test_random_select_returns_empty_when_input_is_empty() {
        let recipes: Vec<RecipeSummary> = vec![];
        
        let result = random_select(&recipes, 3, 42);
        
        assert!(result.is_empty(), "Should return empty vec when input is empty");
    }
}
