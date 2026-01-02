//! ATDD Layer 1: Acceptance Test
//! Feature: Add nutritional calories to Tandoor recipes from FatSecret API
//!
//! This test expresses WHAT the system should do in domain language.
//! NO implementation details (SQL, HTTP, FatSecret API calls).
//! Uses DSL (Domain Specific Language) that hides all technical details.

mod helpers;
use helpers::recipe_nutrition_dsl::*;

/// Acceptance Test: Calculate and update recipe nutrition from ingredients
///
/// GIVEN a recipe exists with ingredients
/// WHEN we calculate nutrition for the recipe
/// THEN the recipe should have accurate calorie data from FatSecret
#[test]
fn should_add_calories_to_recipe_when_ingredients_exist() {
    // GIVEN - Setup via DSL (Layer 2)
    let mut dsl = RecipeNutritionDSL::new();

    let recipe = dsl.create_recipe_with_ingredients(
        "Grilled Chicken Salad",
        vec![
            ("chicken breast", 200.0, "g"),
            ("lettuce", 100.0, "g"),
            ("olive oil", 15.0, "ml"),
        ],
    );

    // WHEN - Action via DSL
    let _result = dsl.calculate_and_update_recipe_nutrition(recipe.id);

    // THEN - Verification via DSL
    dsl.verify_recipe_has_calories(recipe.id, |calories| calories > 0.0);
    dsl.verify_recipe_has_protein(recipe.id, |protein| protein > 0.0);
    dsl.verify_nutrition_source(recipe.id, "fatsecret_auto");
}

/// Acceptance Test: Handle missing ingredients gracefully
///
/// GIVEN a recipe with ingredients not in FatSecret database
/// WHEN we calculate nutrition
/// THEN system should calculate from available ingredients and report failures
#[test]
fn should_handle_missing_ingredients_gracefully() {
    // GIVEN
    let mut dsl = RecipeNutritionDSL::new();

    let recipe = dsl.create_recipe_with_ingredients(
        "Mystery Dish",
        vec![
            ("chicken breast", 200.0, "g"),
            ("xyzabc123_nonexistent", 100.0, "g"), // This won't exist in FatSecret
        ],
    );

    // WHEN
    let _result = dsl.calculate_and_update_recipe_nutrition(recipe.id);

    // THEN
    dsl.verify_recipe_has_calories(recipe.id, |calories| calories > 0.0);
    dsl.verify_failed_ingredients(recipe.id, vec!["xyzabc123_nonexistent"]);
}

/// Acceptance Test: Overwrite existing nutrition data
///
/// GIVEN a recipe already has nutrition data
/// WHEN we recalculate nutrition
/// THEN existing data should be overwritten with new calculation
#[test]
fn should_overwrite_existing_nutrition_when_recalculating() {
    // GIVEN
    let mut dsl = RecipeNutritionDSL::new();

    let recipe =
        dsl.create_recipe_with_ingredients("Protein Smoothie", vec![("protein powder", 30.0, "g")]);

    dsl.set_recipe_calories(recipe.id, 999.0); // Set incorrect value

    // WHEN
    dsl.calculate_and_update_recipe_nutrition(recipe.id);

    // THEN
    dsl.verify_recipe_has_calories(recipe.id, |calories| calories != 999.0);
    dsl.verify_nutrition_source(recipe.id, "fatsecret_auto");
}
