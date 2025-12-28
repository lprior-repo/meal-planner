//! Nutrition Handler - Calculate and track nutrition
//!
//! Computes nutrition for recipes, meals, and plans
//!
//! ```cargo
//! [dependencies]
//! anyhow = "1.0"
//! serde = { version = "1.0", features = ["derive"] }
//! serde_json = "1.0"
//! uuid = { version = "1.0", features = ["v4", "serde"] }
//! chrono = { version = "0.4", features = ["serde"] }
//! ```

use anyhow::Result;
use serde::{Deserialize, Serialize};

#[derive(Deserialize)]
pub struct SetNutritionGoalInput {
    pub user_id: String,
    pub goal_type: String,        // "calories", "protein", "carbs", "fat"
    pub target_value: f64,
    pub period: String,           // "daily", "weekly"
    pub start_date: String,       // ISO 8601
}

#[derive(Serialize)]
pub struct SetNutritionGoalOutput {
    pub success: bool,
    pub goal_id: String,
    pub message: String,
}

#[derive(Deserialize)]
pub struct CheckGoalProgressInput {
    pub user_id: String,
    pub goal_type: String,
    pub date: String,            // ISO 8601
}

#[derive(Serialize)]
pub struct CheckGoalProgressOutput {
    pub success: bool,
    pub goal_type: String,
    pub target: f64,
    pub actual: f64,
    pub progress_percent: f64,
    pub is_met: bool,
    pub message: String,
}

/// Set a nutrition goal for a user
///
/// Business logic:
/// 1. Validate goal type and value
/// 2. Store in nutrition_goals table
/// 3. Emit NutritionGoalSet event
/// 4. Trigger progress check
pub fn set_nutrition_goal(input: SetNutritionGoalInput) -> Result<SetNutritionGoalOutput> {
    use uuid::Uuid;

    eprintln!("[nutrition] Setting goal for user {}: {} = {} ({})",
        input.user_id, input.goal_type, input.target_value, input.period);

    // Validate goal type
    let valid_goal_types = vec!["calories", "protein", "carbs", "fiber"];
    if !valid_goal_types.contains(&input.goal_type.as_str()) {
        return Err(anyhow!("Invalid goal_type: {}. Must be one of: {:?}",
            input.goal_type, valid_goal_types));
    }

    // Validate target value
    if input.target_value <= 0.0 {
        return Err(anyhow!("target_value must be positive"));
    }

    // Validate period
    let valid_periods = vec!["daily", "weekly"];
    if !valid_periods.contains(&input.period.as_str()) {
        return Err(anyhow!("Invalid period: {}. Must be one of: {:?}",
            input.period, valid_periods));
    }

    // Generate goal ID
    let goal_id = Uuid::new_v4().to_string();

    // In production, would:
    // 1. INSERT INTO nutrition_goals (user_id, goal_type, target_value, period, start_date)
    // 2. Emit NutritionGoalSet event
    // 3. Trigger goal progress monitoring

    eprintln!("[nutrition] Goal created: {}", goal_id);

    Ok(SetNutritionGoalOutput {
        success: true,
        goal_id,
        message: format!("{} goal set to {} {}", input.goal_type, input.target_value, input.period),
    })
}

/// Check progress toward a nutrition goal
///
/// Business logic:
/// 1. Fetch goal from nutrition_goals table
/// 2. Calculate actual consumption for period
/// 3. Compute progress percentage
/// 4. Determine if goal is met
/// 5. Emit NutritionGoalMet event if achieved
pub fn check_goal_progress(input: CheckGoalProgressInput) -> Result<CheckGoalProgressOutput> {
    eprintln!("[nutrition] Checking {} progress for user {} on {}",
        input.goal_type, input.user_id, input.date);

    // In production, would:
    // 1. SELECT * FROM nutrition_goals WHERE user_id = ? AND goal_type = ? AND active = true
    // 2. Calculate actual consumption for period (query food_logs, meal_plans)
    // 3. Compute progress_percent = (actual / target) * 100
    // 4. If progress_percent >= 100, emit NutritionGoalMet event

    // Placeholder values
    let target = match input.goal_type.as_str() {
        "calories" => 2000.0,
        "protein" => 150.0,
        "carbs" => 250.0,
        "fiber" => 30.0,
        _ => return Err(anyhow!("Unknown goal_type: {}", input.goal_type)),
    };

    let actual = target * 0.92; // 92% of target
    let progress_percent = (actual / target) * 100.0;
    let is_met = progress_percent >= 100.0;

    eprintln!("[nutrition] Progress: {} / {} ({}%)",
        actual, target, progress_percent);

    Ok(CheckGoalProgressOutput {
        success: true,
        goal_type: input.goal_type.clone(),
        target,
        actual,
        progress_percent,
        is_met,
        message: if is_met {
            "Goal achieved! 🎉".to_string()
        } else {
            format!("Progress: {:.1}%", progress_percent)
        },
    })
}

/// Calculate nutrition for multiple recipes (batch operation)
///
/// Business logic:
/// 1. Fetch recipes from database
/// 2. Calculate nutrition for each
/// 3. Return array of results
#[derive(Deserialize)]
pub struct BatchCalculateNutritionInput {
    pub recipe_ids: Vec<String>,
}

#[derive(Serialize)]
pub struct RecipeNutritionResult {
    pub recipe_id: String,
    pub calories: f64,
    pub protein: f64,
    pub carbs: f64,
    pub fat: f64,
    pub fiber: Option<f64>,
}

#[derive(Serialize)]
pub struct BatchCalculateNutritionOutput {
    pub success: bool,
    pub results: Vec<RecipeNutritionResult>,
    pub message: String,
}

pub fn batch_calculate_nutrition(input: BatchCalculateNutritionInput) -> Result<BatchCalculateNutritionOutput> {
    eprintln!("[nutrition] Batch calculating nutrition for {} recipes",
        input.recipe_ids.len());

    // In production, would:
    // 1. SELECT * FROM recipes WHERE id IN (?)
    // 2. For each recipe, calculate nutrition from ingredients
    // 3. Emit NutritionCalculated events
    // 4. Return array of results

    // Placeholder results
    let results: Vec<RecipeNutritionResult> = input.recipe_ids
        .iter()
        .enumerate()
        .map(|(i, recipe_id)| {
            let base = 500.0 + (i as f64) * 50.0;
            RecipeNutritionResult {
                recipe_id: recipe_id.clone(),
                calories: base,
                protein: base * 0.15,
                carbs: base * 0.10,
                fat: base * 0.30,
                fiber: Some(base * 0.05),
            }
        })
        .collect();

    eprintln!("[nutrition] Calculated nutrition for {} recipes", results.len());

    Ok(BatchCalculateNutritionOutput {
        success: true,
        results,
        message: format!("Nutrition calculated for {} recipes", results.len()),
    })
}
