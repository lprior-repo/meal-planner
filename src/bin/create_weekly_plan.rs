//! Create a new weekly meal plan with recipes and grocery list
//!
//! JSON input:
//!   `{"tandoor": {...}, "recipes": [...], "config": {...}}`
//!
//! JSON stdout:
//!   `{"success": true, "plan": {...}, "grocery_list": [...]}`
//!   or `{"success": false, "error": "..."}`
//!
//! # Planning Configuration
//!
//! The config supports:
//! - days: Number of days to plan (default: 7)
//! - meals_per_day: Number of meals per day (default: 3)
//! - allow_repeats: Whether to allow recipe repeats (default: true)
//! - repeat_gap_days: Minimum days between same recipe repeats (default: 2)
//!
//! # Nutrition Targets
//!
//! Nutrition targets are specified as daily values:
//! - calories: Target calories per day
//! - protein: Target protein (grams) per day  
//! - fat: Target fat (grams) per day
//! - carbohydrate: Target carbohydrates (grams) per day

// CLI binaries: exit and unwrap/expect are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::sync::types::{MealCategory, TandoorRecipe};
use meal_planner::sync::weekly::SlotRecipe;
use meal_planner::sync::{
    NutritionTarget, NutritionTargetSet, WeeklyPlan, WeeklyPlanConfig, WeeklyPlanner,
};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

/// Input for creating a weekly plan
#[derive(Deserialize)]
struct Input {
    /// Recipes to use for planning
    recipes: Vec<TandoorRecipe>,
    /// Planning configuration
    config: PlanConfig,
}

/// Planning configuration
#[derive(Deserialize, Default)]
struct PlanConfig {
    /// Number of days in the plan (default: 7)
    #[serde(default = "default_days")]
    days: usize,
    /// Number of meals per day (default: 3)
    #[serde(default = "default_meals_per_day")]
    meals_per_day: usize,
    /// Allow recipes to repeat (default: true)
    #[serde(default = "default_allow_repeats")]
    allow_repeats: bool,
    /// Minimum days between repeats (default: 2)
    #[serde(default = "default_repeat_gap_days")]
    repeat_gap_days: usize,
    /// Target calories per day
    #[serde(default)]
    target_calories: f64,
    /// Target protein per day (grams)
    #[serde(default)]
    target_protein: f64,
    /// Target fat per day (grams)
    #[serde(default)]
    target_fat: f64,
    /// Target carbohydrates per day (grams)
    #[serde(default)]
    target_carbohydrate: f64,
}

fn default_days() -> usize {
    7
}
fn default_meals_per_day() -> usize {
    3
}
fn default_allow_repeats() -> bool {
    true
}
fn default_repeat_gap_days() -> usize {
    2
}

/// Output containing the plan and grocery list
#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    plan: Option<WeeklyPlan>,
    #[serde(skip_serializing_if = "Option::is_none")]
    grocery_list: Option<Vec<GroceryItem>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

/// Grocery list item
#[derive(Serialize, Deserialize, Clone)]
struct GroceryItem {
    /// Ingredient name
    ingredient: String,
    /// Total amount needed
    amount: f64,
    /// Unit of measurement
    unit: Option<String>,
}

fn main() {
    let output = match run() {
        Ok(o) => o,
        Err(e) => Output {
            success: false,
            plan: None,
            grocery_list: None,
            error: Some(e.to_string()),
        },
    };
    println!(
        "{}",
        serde_json::to_string(&output).expect("Failed to serialize output JSON")
    );
    if !output.success {
        std::process::exit(1);
    }
}

fn run() -> Result<Output, Box<dyn std::error::Error>> {
    let mut input = String::new();
    io::stdin().read_to_string(&mut input)?;

    let parsed: Input = serde_json::from_str(&input)?;

    // Create planning configuration
    let config = WeeklyPlanConfig {
        days: parsed.config.days,
        meals_per_day: parsed.config.meals_per_day,
        allow_repeats: parsed.config.allow_repeats,
        repeat_gap_days: parsed.config.repeat_gap_days,
        max_deviation_percent: 15.0,
        balance_macros: true,
    };

    // Create nutrition targets
    let daily_target = NutritionTarget {
        calories: parsed.config.target_calories,
        protein: parsed.config.target_protein,
        fat: parsed.config.target_fat,
        carbohydrate: parsed.config.target_carbohydrate,
        fiber: None,
        sodium: None,
    };

    let targets = NutritionTargetSet::from_daily(daily_target);

    // Create planner and plan
    let planner = WeeklyPlanner::new(config);
    let mut plan = planner.create_empty_plan(targets);

    // Assign recipes to slots (simple round-robin assignment for now)
    let mut recipe_idx = 0;
    _ = plan.config.total_slots(); // Use the value to avoid unused warning

    for day in 0..plan.config.days {
        for meal_idx in 0..plan.config.meals_per_day.min(3) {
            let meal_category = match meal_idx {
                0 => MealCategory::Breakfast,
                1 => MealCategory::Lunch,
                _ => MealCategory::Dinner,
            };

            if recipe_idx < parsed.recipes.len() {
                let recipe = &parsed.recipes[recipe_idx];
                if let Some(slot_recipe) = SlotRecipe::from_recipe(recipe, 1.0) {
                    plan.assign_recipe(day, meal_category, slot_recipe);
                }
                recipe_idx += 1;
            }
        }
    }

    // Generate grocery list
    let grocery_list = generate_grocery_list(&plan);

    Ok(Output {
        success: true,
        plan: Some(plan),
        grocery_list: Some(grocery_list),
        error: None,
    })
}

fn generate_grocery_list(plan: &WeeklyPlan) -> Vec<GroceryItem> {
    let mut ingredients: std::collections::HashMap<String, f64> = std::collections::HashMap::new();

    // Collect all ingredients from assigned recipes
    for day in &plan.days {
        for slot in &day.slots {
            if let Some(recipe) = &slot.recipe {
                // For simplicity, we'll just create a basic grocery list based on
                // recipe name and assume 1 unit per recipe (in reality would need
                // to extract actual ingredients)
                let key = format!("Recipe: {}", recipe.name);
                *ingredients.entry(key).or_insert(0.0) += 1.0;
            }
        }
    }

    // Convert to grocery list items
    ingredients
        .into_iter()
        .map(|(ingredient, amount)| GroceryItem {
            ingredient,
            amount,
            unit: Some("recipe".to_string()),
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_output_serialization() {
        let output = Output {
            success: true,
            plan: None,
            grocery_list: Some(vec![]),
            error: None,
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"grocery_list\":[]"));
    }

    #[test]
    fn test_error_output_serialization() {
        let output = Output {
            success: false,
            plan: None,
            grocery_list: None,
            error: Some("Plan failed".to_string()),
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("\"error\":\"Plan failed\""));
    }
}
