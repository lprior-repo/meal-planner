#![allow(clippy::indexing_slicing)]
#![allow(clippy::panic)]
#![allow(clippy::manual_assert)]
#![allow(clippy::approx_constant)]
#![allow(clippy::expect_used)]
#![allow(clippy::panic)]
#![allow(clippy::manual_assert)]
#![allow(clippy::approx_constant)]
#![allow(clippy::option_if_let_else)]
#![allow(clippy::panic)]
#![allow(clippy::manual_assert)]
#![allow(clippy::approx_constant)]
//! ATDD Layer 1: Acceptance Test
//! Feature: Select recipes from Tandoor matching calorie targets for weekly meal planning
//!
//! This test expresses WHAT the system should do in domain language.
//! NO implementation details (binaries, JSON, file I/O).
//! Uses DSL (Domain Specific Language) that hides all technical details.
//!
//! GATE-1: Write RED acceptance test in domain language

mod helpers;

use helpers::recipe_selection_dsl::RecipeSelectionDSL;

/// Acceptance Test: Select 4 recipes matching calorie target
///
/// GIVEN Tandoor has recipes with various calorie counts
/// WHEN I select 4 recipes with target 500 calories (±150 tolerance)
/// THEN system returns exactly 4 recipes within 350-650 calorie range
/// AND recipes are randomly selected for variety
#[test]
fn should_select_four_recipes_matching_calorie_target() {
    let mut dsl = RecipeSelectionDSL::new();
    dsl.ensure_recipes_with_calories(vec![
        (200, "Low Cal Salad"),
        (350, "Grilled Fish"),
        (500, "Chicken Bowl"),
        (520, "Beef Stir Fry"),
        (480, "Salmon Plate"),
        (650, "Pasta Dish"),
        (800, "Heavy Meal"),
    ]);

    let result = dsl.select_recipes_by_calories(500, 150, 4);

    dsl.verify_recipe_count(&result, 4);
    dsl.verify_all_in_calorie_range(&result, 500, 150);
    dsl.verify_total_calories_close_to(&result, 2000, 200);
}

/// Acceptance Test: Handle insufficient matching recipes gracefully
///
/// GIVEN Tandoor has only 2 recipes in target range
/// WHEN I request 4 recipes
/// THEN system returns the 2 available recipes
/// AND indicates fewer than requested were found
#[test]
fn should_return_available_recipes_when_insufficient_matches() {
    let mut dsl = RecipeSelectionDSL::new();
    dsl.ensure_recipes_with_calories(vec![
        (200, "Too Low"),
        (500, "Match 1"),
        (520, "Match 2"),
        (800, "Too High"),
    ]);

    let result = dsl.select_recipes_by_calories(500, 50, 4);

    dsl.verify_recipe_count(&result, 2);
    dsl.verify_warning_contains(&result, "only 2 recipes found");
}

/// Acceptance Test: Verify random selection provides variety
///
/// GIVEN Tandoor has 10 recipes in target range
/// WHEN I select 4 recipes multiple times
/// THEN different combinations are returned (randomness)
#[test]
fn should_provide_variety_through_random_selection() {
    let mut dsl = RecipeSelectionDSL::new();
    dsl.ensure_recipes_with_calories(vec![
        (480, "Recipe 1"),
        (490, "Recipe 2"),
        (500, "Recipe 3"),
        (510, "Recipe 4"),
        (520, "Recipe 5"),
        (530, "Recipe 6"),
        (480, "Recipe 7"),
        (500, "Recipe 8"),
        (510, "Recipe 9"),
        (520, "Recipe 10"),
    ]);

    let result1 = dsl.select_recipes_by_calories(500, 150, 4);
    let result2 = dsl.select_recipes_by_calories(500, 150, 4);

    dsl.verify_different_selections(&result1, &result2);
}
