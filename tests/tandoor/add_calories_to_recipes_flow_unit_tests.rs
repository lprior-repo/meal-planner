//! ATDD Layer 2: Unit Tests for add_calories_to_recipes Flow Logic
//!
//! Tests the pure core functions for flow logic.
//! All functions ≤25 lines, no I/O, fully deterministic.

use serde_json::json;

#[derive(Debug, Clone)]
pub struct Ingredient {
    pub food_name: String,
    pub amount: f64,
    pub unit: String,
}

#[derive(Debug, Clone)]
pub struct NutritionData {
    pub calories: f64,
    pub protein: f64,
    pub fat: f64,
    pub carbs: f64,
}

#[derive(Debug)]
pub struct RecipeNutrition {
    pub recipe_id: i64,
    pub nutrition: NutritionData,
    pub failed_ingredients: Vec<String>,
}

/// Extract unique ingredient names from recipe ingredients list
fn unique_ingredient_names(ingredients: &[Ingredient]) -> Vec<String> {
    ingredients
        .iter()
        .map(|i| i.food_name.clone())
        .collect::<std::collections::HashSet<_>>()
        .into_iter()
        .collect()
}

#[test]
fn test_unique_ingredient_names() {
    let ingredients = vec![
        Ingredient {
            food_name: "chicken breast".to_string(),
            amount: 200.0,
            unit: "g".to_string(),
        },
        Ingredient {
            food_name: "lettuce".to_string(),
            amount: 100.0,
            unit: "g".to_string(),
        },
        Ingredient {
            food_name: "chicken breast".to_string(),
            amount: 50.0,
            unit: "g".to_string(),
        },
    ];

    let unique = unique_ingredient_names(&ingredients);
    assert_eq!(unique.len(), 2);
    assert!(unique.contains(&"chicken breast".to_string()));
    assert!(unique.contains(&"lettuce".to_string()));
}

/// Calculate calories per serving from nutrition data
fn calories_per_serving(total_calories: f64, servings: f64) -> f64 {
    if servings <= 0.0 {
        0.0
    } else {
        total_calories / servings
    }
}

#[test]
fn test_calories_per_serving() {
    assert_eq!(calories_per_serving(800.0, 4.0), 200.0);
    assert_eq!(calories_per_serving(1000.0, 2.0), 500.0);
    assert_eq!(calories_per_serving(0.0, 4.0), 0.0);
    assert_eq!(calories_per_serving(800.0, 0.0), 0.0);
}

/// Calculate nutrition for a single ingredient based on FatSecret data
fn ingredient_nutrition(
    amount: f64,
    cals_per_100g: f64,
    protein_per_100g: f64,
) -> NutritionData {
    let multiplier = amount / 100.0;
    NutritionData {
        calories: cals_per_100g * multiplier,
        protein: protein_per_100g * multiplier,
        fat: 0.0,
        carbs: 0.0,
    }
}

#[test]
fn test_ingredient_nutrition() {
    let nutrition = ingredient_nutrition(200.0, 165.0, 31.0);
    assert_eq!(nutrition.calories, 330.0);
    assert_eq!(nutrition.protein, 62.0);
}

/// Aggregate nutrition from multiple ingredients
fn aggregate_nutrition(items: Vec<NutritionData>) -> NutritionData {
    items.into_iter().fold(
        NutritionData {
            calories: 0.0,
            protein: 0.0,
            fat: 0.0,
            carbs: 0.0,
        },
        |mut acc, item| {
            acc.calories += item.calories;
            acc.protein += item.protein;
            acc.fat += item.fat;
            acc.carbs += item.carbs;
            acc
        },
    )
}

#[test]
fn test_aggregate_nutrition() {
    let items = vec![
        NutritionData {
            calories: 330.0,
            protein: 62.0,
            fat: 0.0,
            carbs: 0.0,
        },
        NutritionData {
            calories: 15.0,
            protein: 1.0,
            fat: 0.0,
            carbs: 0.0,
        },
    ];

    let aggregated = aggregate_nutrition(items);
    assert_eq!(aggregated.calories, 345.0);
    assert_eq!(aggregated.protein, 63.0);
}

/// Map FatSecret serving data to nutrition structure
fn parse_fatsecret_serving(serving: &serde_json::Value) -> Option<NutritionData> {
    Some(NutritionData {
        calories: serving.get("calories")?.as_str()?.parse().ok()?.unwrap_or(0.0),
        protein: serving.get("protein")?.as_str()?.parse().ok()?.unwrap_or(0.0),
        fat: serving.get("fat")?.as_str()?.parse().ok()?.unwrap_or(0.0),
        carbs: serving.get("carbohydrate")?.as_str()?.parse().ok()?.unwrap_or(0.0),
    })
}

#[test]
fn test_parse_fatsecret_serving() {
    let serving = json!({
        "calories": "165",
        "protein": "31",
        "fat": "3.6",
        "carbohydrate": "0"
    });

    let nutrition = parse_fatsecret_serving(&serving).unwrap();
    assert_eq!(nutrition.calories, 165.0);
    assert_eq!(nutrition.protein, 31.0);
}

/// Build recipe nutrition result for flow output
fn build_nutrition_result(
    recipe_id: i64,
    nutrition: NutritionData,
    failed: Vec<String>,
) -> RecipeNutrition {
    RecipeNutrition {
        recipe_id,
        nutrition,
        failed_ingredients: failed,
    }
}

#[test]
fn test_build_nutrition_result() {
    let result = build_nutrition_result(
        123,
        NutritionData {
            calories: 500.0,
            protein: 40.0,
            fat: 20.0,
            carbs: 30.0,
        },
        vec!["unknown_food".to_string()],
    );

    assert_eq!(result.recipe_id, 123);
    assert_eq!(result.nutrition.calories, 500.0);
    assert_eq!(result.failed_ingredients.len(), 1);
}

/// Determine if a food search should be retried with different query
fn should_retry_search(food_name: &str, search_result: &serde_json::Value) -> bool {
    let has_results = search_result
        .get("foods")
        .and_then(|f| f.get("food"))
        .map(|f| !f.as_array().unwrap_or_default().is_empty())
        .unwrap_or(false);

    !has_results && (food_name.contains('(') || food_name.contains(','))
}

#[test]
fn test_should_retry_search() {
    let no_results = json!({"foods": {"food": []}});
    assert!(should_retry_search("chicken (fresh)", &no_results));
    assert!(should_retry_search("chicken, organic", &no_results));

    let with_results = json!({"foods": {"food": [{"food_id": "123"}]}});
    assert!(!should_retry_search("chicken", &with_results));
    assert!(!should_retry_search("chicken (fresh)", &with_results));
}

/// Clean food name for FatSecret search
fn clean_food_name(name: &str) -> String {
    name.split('(')
        .next()
        .unwrap_or(name)
        .split(',')
        .next()
        .unwrap_or(name)
        .trim_end_matches(" fresh")
        .trim_end_matches(" s")
        .to_string()
}

#[test]
fn test_clean_food_name() {
    assert_eq!(clean_food_name("chicken breast"), "chicken breast");
    assert_eq!(clean_food_name("chicken (organic)"), "chicken");
    assert_eq!(clean_food_name("chicken, organic"), "chicken");
    assert_eq!(clean_food_name("spinach fresh"), "spinach");
}

/// Validate recipe has required fields for nutrition calculation
fn validate_recipe_for_nutrition(recipe: &serde_json::Value) -> bool {
    recipe.get("id").is_some()
        && recipe.get("servings").is_some()
        && recipe.get("ingredients").is_some()
}

#[test]
fn test_validate_recipe_for_nutrition() {
    let valid = json!({
        "id": 123,
        "servings": 4,
        "ingredients": []
    });
    assert!(validate_recipe_for_nutrition(&valid));

    let missing_id = json!({
        "servings": 4,
        "ingredients": []
    });
    assert!(!validate_recipe_for_nutrition(&missing_id));
}
