//! Format weekly meal plan output
//!
//! Combines recipes and meal plans into a formatted output.
//!
//! JSON input (CLI arg or stdin):
//!   `{"recipes": [...], "dates": [...], "meal_plans": [...]}`
//!
//! JSON stdout:
//!   Formatted meal plan with full data

#![allow(clippy::expect_used)]

use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    recipes: Vec<Recipe>,
    dates: Vec<String>,
    meal_plans: Vec<MealPlanResult>,
}

#[derive(Deserialize, Serialize)]
struct Recipe {
    id: i64,
    name: String,
    #[serde(default)]
    description: Option<String>,
    #[serde(default)]
    servings: Option<i32>,
    #[serde(default)]
    rating: Option<f64>,
    #[serde(default)]
    keywords: Option<Vec<Keyword>>,
    #[serde(default)]
    working_time: Option<i32>,
    #[serde(default)]
    waiting_time: Option<i32>,
}

#[derive(Deserialize, Serialize)]
struct Keyword {
    id: i64,
    #[serde(default)]
    name: Option<String>,
    #[serde(default)]
    label: Option<String>,
}

#[derive(Deserialize)]
struct MealPlanResult {
    #[allow(dead_code)]
    success: bool,
    #[serde(default)]
    meal_plan: Option<MealPlan>,
}

#[derive(Deserialize, Serialize)]
struct MealPlan {
    id: i64,
    from_date: String,
    to_date: String,
    servings: f64,
    #[serde(default)]
    note: Option<String>,
    #[serde(default)]
    meal_type: Option<MealType>,
    #[serde(default)]
    meal_type_name: Option<String>,
    #[serde(default)]
    recipe_name: String,
}

#[derive(Deserialize, Serialize)]
struct MealType {
    id: i64,
    name: String,
    #[serde(default)]
    time: Option<String>,
    #[serde(default)]
    color: Option<String>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    recipes: Vec<Recipe>,
    meal_plans: Vec<MealPlan>,
    summary: Summary,
}

#[derive(Serialize)]
struct Summary {
    recipes_selected: usize,
    cooking_dates: Vec<String>,
    meal_plan_ids: Vec<i64>,
}

fn main() {
    match run() {
        Ok(output) => {
            println!(
                "{}",
                serde_json::to_string(&output).expect("Failed to serialize output")
            );
        }
        Err(e) => {
            eprintln!("Error: {}", e);
            std::process::exit(1);
        }
    }
}

fn run() -> anyhow::Result<Output> {
    let input: Input = if let Some(arg) = std::env::args().nth(1) {
        serde_json::from_str(&arg)?
    } else {
        let mut input_str = String::new();
        io::stdin().read_to_string(&mut input_str)?;
        serde_json::from_str(&input_str)?
    };

    let meal_plan_ids: Vec<i64> = input
        .meal_plans
        .iter()
        .filter_map(|mp| mp.meal_plan.as_ref().map(|m| m.id))
        .collect();

    let meal_plans: Vec<MealPlan> = input
        .meal_plans
        .into_iter()
        .filter_map(|mp| mp.meal_plan)
        .collect();

    let recipes_selected = input.recipes.len();

    Ok(Output {
        success: true,
        recipes: input.recipes,
        meal_plans,
        summary: Summary {
            recipes_selected,
            cooking_dates: input.dates,
            meal_plan_ids,
        },
    })
}
