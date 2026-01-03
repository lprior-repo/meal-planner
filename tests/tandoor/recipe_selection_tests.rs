//! Recipe selection core tests (Functional Core)
//!
//! Tests for pure functions that compute statistics over recipes.

use meal_planner::tandoor::recipe_selection::{calculate_stats, CalorieStats, RecipeSummary};

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
