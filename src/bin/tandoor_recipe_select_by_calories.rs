//! Select recipes from Tandoor by calorie range
#![allow(
    clippy::too_many_lines,
    clippy::needless_pass_by_value,
    clippy::redundant_closure_for_method_calls,
    clippy::cast_lossless,
    clippy::indexing_slicing
)]
//!
//! Filters recipes by calorie range and randomly selects N recipes.
//!
//! JSON input: {"recipes": [...], "target_calories": 2000, "min_calories": 300, "max_calories": 800, "count": 4}
//! JSON output: {"selected_recipes": [...], "stats": {...}, "warning": null | "Insufficient matching recipes"}

use meal_planner::tandoor::recipe_selection::{
    calculate_stats, filter_by_calorie_range, random_select, RecipeSummary,
};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    recipes: Vec<RecipeInput>,
    target_calories: u32,
    min_calories: u32,
    max_calories: u32,
    count: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct RecipeInput {
    id: u32,
    name: String,
    calories: u32,
}

#[derive(Serialize)]
struct Output {
    selected_recipes: Vec<RecipeSummary>,
    stats: CalorieStatsOutput,
    warning: Option<String>,
}

#[derive(Serialize)]
struct CalorieStatsOutput {
    count: usize,
    total: f64,
    average: f64,
    min: f64,
    max: f64,
}

fn main() {
    let input = match read_input() {
        Ok(i) => i,
        Err(e) => {
            print_error(e);
            return;
        }
    };

    let recipes: Vec<RecipeSummary> = input
        .recipes
        .into_iter()
        .map(|r| RecipeSummary {
            id: r.id,
            name: r.name,
            calories: r.calories,
        })
        .collect();

    let filtered = filter_by_calorie_range(&recipes, input.min_calories, input.max_calories);

    let (selected, warning) = if filtered.len() <= input.count {
        (filtered, None)
    } else {
        let seed = input.target_calories as u64;
        let selected = random_select(&filtered, input.count, seed);
        let warning = if selected.len() < input.count {
            Some("Insufficient matching recipes".to_string())
        } else {
            None
        };
        (selected, warning)
    };

    let stats = calculate_stats(&selected);

    let output = Output {
        selected_recipes: selected,
        stats: CalorieStatsOutput {
            count: stats.count,
            total: stats.total,
            average: stats.average,
            min: stats.min,
            max: stats.max,
        },
        warning,
    };

    if let Ok(json) = serde_json::to_string(&output) {
        println!("{json}");
    }
}

fn read_input() -> Result<Input, String> {
    let args: Vec<String> = std::env::args().collect();
    if args.len() > 1 {
        serde_json::from_str(&args[1]).map_err(|e| format!("Failed to parse JSON: {}", e))
    } else {
        let mut s = String::new();
        io::stdin()
            .read_to_string(&mut s)
            .map_err(|e| format!("Failed to read stdin: {}", e))?;
        serde_json::from_str(&s).map_err(|e| format!("Failed to parse JSON: {}", e))
    }
}

fn print_error(msg: String) {
    let output = Output {
        selected_recipes: Vec::new(),
        stats: CalorieStatsOutput {
            count: 0,
            total: 0.0,
            average: 0.0,
            min: 0.0,
            max: 0.0,
        },
        warning: Some(msg),
    };
    if let Ok(json) = serde_json::to_string(&output) {
        println!("{json}");
    }
}
