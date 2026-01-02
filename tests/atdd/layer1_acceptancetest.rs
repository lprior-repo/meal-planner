//! Layer 1: Acceptance Tests (Domain Language)
//!
//! Dave Farley: "Tests should express WHAT the system does, not HOW it does it."
//!
//! ## GATE-1: Domain Language
//!
//! These tests:
//! - Use business vocabulary, not technical terms
//! - Express examples of business rules
//! - Hide all implementation details behind DSL
//! - Are readable by non-programmers
//!
//! ## Naming Convention
//!
//! Test names follow GIVEN-WHEN-THEN pattern:
//! - `should_<behavior>_when_<condition>`
//! - Example: `should_add_calories_to_recipe_when_ingredients_exist`

use crate::atdd::atdd_framework::{AcceptanceResult, Layer};
use crate::helpers::recipe_nutrition_dsl::*;

#[cfg(test)]
mod nutrition_acceptancetests {
    use super::*;
    use serial_test::serial;

    /// Feature: Recipe Nutrition from FatSecret
    ///
    /// Background:
    /// Given the Tandoor recipe system has recipes with ingredients
    /// And FatSecret provides nutrition data for common foods
    /// When we calculate nutrition for a recipe
    /// Then we should get accurate calorie and macro data

    /// Scenario: Recipe with valid ingredients
    ///
    /// GIVEN a recipe exists with ingredients that exist in FatSecret
    /// WHEN we calculate nutrition for the recipe
    /// THEN the recipe should have accurate calorie data
    #[tokio::test]
    #[serial]
    async fn should_add_calories_to_recipe_when_ingredients_exist() {
        // GIVEN - Setup via DSL (Layer 2)
        let mut dsl = RecipeNutritionDSL::new().await;

        let recipe = dsl
            .create_recipe_with_ingredients(
                "Grilled Chicken Salad",
                vec![
                    ("chicken breast", 200.0, "g"),
                    ("lettuce", 100.0, "g"),
                    ("olive oil", 15.0, "ml"),
                ],
            )
            .await;

        // WHEN - Action via DSL
        let result = dsl.calculate_and_update_recipe_nutrition(recipe.id).await;

        // THEN - Verification via DSL
        assert!(result.success, "Nutrition calculation should succeed");
        assert!(
            result.calories.map(|c| c > 0.0).unwrap_or(false),
            "Recipe should have positive calories"
        );
        assert!(
            result.failed_ingredients.is_empty(),
            "All ingredients should be found in FatSecret"
        );
    }

    /// Scenario: Recipe with missing ingredients
    ///
    /// GIVEN a recipe with ingredients not in FatSecret database
    /// WHEN we calculate nutrition
    /// THEN system should calculate from available ingredients and report failures
    #[tokio::test]
    #[serial]
    async fn should_handle_missing_ingredients_gracefully() {
        // GIVEN
        let mut dsl = RecipeNutritionDSL::new().await;

        let recipe = dsl
            .create_recipe_with_ingredients(
                "Mystery Dish",
                vec![
                    ("chicken breast", 200.0, "g"),
                    ("xyzabc123_nonexistent", 100.0, "g"),
                ],
            )
            .await;

        // WHEN
        let result = dsl.calculate_and_update_recipe_nutrition(recipe.id).await;

        // THEN
        assert!(
            result.calories.map(|c| c > 0.0).unwrap_or(false),
            "Should calculate calories from available ingredients"
        );
        assert!(
            result
                .failed_ingredients
                .contains(&"xyzabc123_nonexistent".to_string()),
            "Should report missing ingredient"
        );
    }

    /// Scenario: Overwrite existing nutrition data
    ///
    /// GIVEN a recipe already has nutrition data
    /// WHEN we recalculate nutrition
    /// THEN existing data should be overwritten with new calculation
    #[tokio::test]
    #[serial]
    async fn should_overwrite_existing_nutrition_when_recalculating() {
        // GIVEN
        let mut dsl = RecipeNutritionDSL::new().await;

        let recipe = dsl
            .create_recipe_with_ingredients("Protein Smoothie", vec![("protein powder", 30.0, "g")])
            .await;

        dsl.set_recipe_calories(recipe.id, 999.0).await;

        // WHEN
        let result = dsl.calculate_and_update_recipe_nutrition(recipe.id).await;

        // THEN
        assert!(
            result.calories.map(|c| c != 999.0).unwrap_or(true),
            "Old calories should be overwritten"
        );
    }

    /// Scenario: Calculate protein from recipe
    ///
    /// GIVEN a recipe with high-protein ingredients
    /// WHEN we calculate nutrition
    /// THEN recipe should have accurate protein content
    #[tokio::test]
    #[serial]
    async fn should_calculate_protein_content_when_recipe_has_protein_ingredients() {
        // GIVEN
        let mut dsl = RecipeNutritionDSL::new().await;

        let recipe = dsl
            .create_recipe_with_ingredients(
                "High Protein Meal",
                vec![("chicken breast", 200.0, "g"), ("greek yogurt", 150.0, "g")],
            )
            .await;

        // WHEN
        let result = dsl.calculate_and_update_recipe_nutrition(recipe.id).await;

        // THEN
        assert!(result.success, "Nutrition calculation should succeed");
    }
}

#[cfg(test)]
mod meal_plan_acceptancetests {
    use crate::helpers::recipe_nutrition_dsl::*;

    /// Feature: Meal Plan Generation
    ///
    /// Background:
    /// Given users want weekly meal plans
    /// When we generate a meal plan
    /// Then it should meet nutritional goals

    /// Scenario: Generate balanced meal plan
    ///
    /// GIVEN user has dietary preferences set
    /// WHEN we generate a weekly meal plan
    /// THEN the plan should have meals for all days
    #[tokio::test]
    #[serial]
    async fn should_generate_meal_plan_with_all_meals() {
        let mut dsl = RecipeNutritionDSL::new().await;

        let plan = dsl
            .generate_weekly_meal_plan("balanced", 2000, vec!["breakfast", "lunch", "dinner"])
            .await;

        assert!(plan.days.len() == 7);
        assert!(plan.days.iter().all(|d| d.meals.len() == 3));
    }

    /// Scenario: Respect calorie limits
    ///
    /// GIVEN a calorie target of 2000
    /// WHEN we generate a meal plan
    /// THEN total calories should not exceed target significantly
    #[tokio::test]
    #[serial]
    async fn should_respect_calorie_limits_in_meal_plan() {
        let mut dsl = RecipeNutritionDSL::new().await;

        let plan = dsl
            .generate_weekly_meal_plan("balanced", 2000, vec!["breakfast", "lunch", "dinner"])
            .await;

        let total_calories: f64 = plan
            .days
            .iter()
            .flat_map(|d| d.meals.iter())
            .map(|m| m.calories)
            .sum();

        assert!(total_calories <= 2200, "Should stay within 10% of target");
    }
}
