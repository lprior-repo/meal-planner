//! Track Exercise and Meal Balance
//!
//! This binary calculates the balance between calorie intake and expenditure
//! from exercise and BMR, providing daily and weekly summaries.
//!
//! This is part of the Tandoor ↔ FatSecret sync layer.
//!
//! JSON input (CLI arg or stdin):
//! ```json
//! {
//!   "fatsecret": {"consumer_key": "...", "consumer_secret": "..."},
//!   "access_token": "...",
//!   "access_secret": "...",
//!   "date": "2025-01-15",
//!   "bmr": 1800,
//!   "activity_multiplier": 1.375,
//!   "goal": "deficit",
//!   "target_adjustment": -500
//! }
//! ```
//!
//! JSON stdout:
//! ```json
//! {
//!   "success": true,
//!   "balance": {
//!     "calories_in": 1800,
//!     "calories_out_exercise": 300,
//!     "tdee": 2475,
//!     "net_balance": -675,
//!     "goal_met": true
//!   }
//! }
//! ```

#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used, clippy::too_many_lines)]

use meal_planner::fatsecret::core::{AccessToken, FatSecretConfig};
use meal_planner::fatsecret::diary::{get_food_entries, date_to_int};
use meal_planner::sync::exercise::{
    ExerciseBalanceTracker, ExerciseConfig, BalanceGoal, MealIntake, ExerciseEntry,
};
use meal_planner::fatsecret::diary::MealType;
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct FatSecretResource {
    consumer_key: String,
    consumer_secret: String,
}

#[derive(Deserialize)]
struct Input {
    /// FatSecret credentials (optional, uses env if not provided)
    fatsecret: Option<FatSecretResource>,
    /// OAuth access token for FatSecret
    access_token: String,
    /// OAuth access token secret for FatSecret
    access_secret: String,
    /// Date to analyze (YYYY-MM-DD)
    date: String,
    /// Base metabolic rate in calories
    bmr: f64,
    /// Activity multiplier (1.2-1.9)
    activity_multiplier: Option<f64>,
    /// Goal: "deficit", "maintenance", or "surplus"
    goal: Option<String>,
    /// Target calorie adjustment from TDEE
    target_adjustment: Option<f64>,
    /// User weight in kg (for protein targets)
    weight_kg: Option<f64>,
    /// Manual exercise entries (if not pulling from FatSecret)
    exercises: Option<Vec<ExerciseInput>>,
}

#[derive(Deserialize)]
struct ExerciseInput {
    name: String,
    calories: f64,
    minutes: i32,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    balance: BalanceOutput,
    meals: MealBreakdown,
    exercises: Vec<ExerciseOutput>,
    recommendations: Vec<String>,
}

#[derive(Serialize)]
struct BalanceOutput {
    /// Total calories consumed
    calories_in: f64,
    /// Calories from exercise
    calories_out_exercise: f64,
    /// Base metabolic rate
    bmr: f64,
    /// Total daily energy expenditure
    tdee: f64,
    /// Net calorie balance (intake - TDEE)
    net_balance: f64,
    /// Target calories for the day
    target_calories: f64,
    /// Calories remaining to target
    calories_remaining: f64,
    /// Whether goal was met
    goal_met: bool,
    /// Goal description
    goal: String,
}

#[derive(Serialize)]
struct MealBreakdown {
    breakfast: Option<f64>,
    lunch: Option<f64>,
    dinner: Option<f64>,
    snacks: Option<f64>,
    total_protein: f64,
    total_carbs: f64,
    total_fat: f64,
}

#[derive(Serialize)]
struct ExerciseOutput {
    name: String,
    calories_burned: f64,
    duration_minutes: i32,
    calories_per_minute: f64,
}

#[derive(Serialize)]
struct ErrorOutput {
    success: bool,
    error: String,
}

#[tokio::main]
async fn main() {
    match run().await {
        Ok(output) => {
            println!(
                "{}",
                serde_json::to_string(&output).expect("Failed to serialize output")
            );
        }
        Err(e) => {
            let error = ErrorOutput {
                success: false,
                error: e.to_string(),
            };
            println!(
                "{}",
                serde_json::to_string(&error).expect("Failed to serialize error")
            );
            std::process::exit(1);
        }
    }
}

async fn run() -> Result<Output, Box<dyn std::error::Error>> {
    let input: Input = read_input()?;

    // Set up FatSecret config
    let fs_config = match input.fatsecret {
        Some(r) => FatSecretConfig::new(r.consumer_key, r.consumer_secret)?,
        None => FatSecretConfig::from_env()?,
    };

    let token = AccessToken::new(input.access_token, input.access_secret);

    // Convert date to int
    let date_int = date_to_int(&input.date)?;

    // Get food entries for the date
    let entries = get_food_entries(&fs_config, &token, date_int).await?;

    // Calculate meal nutrition
    let mut total_calories = 0.0;
    let mut total_protein = 0.0;
    let mut total_carbs = 0.0;
    let mut total_fat = 0.0;
    let mut breakfast_cal = 0.0;
    let mut lunch_cal = 0.0;
    let mut dinner_cal = 0.0;
    let mut snacks_cal = 0.0;

    for entry in &entries {
        let cal = entry.calories;
        total_calories += cal;
        total_protein += entry.protein;
        total_carbs += entry.carbohydrate;
        total_fat += entry.fat;

        match entry.meal {
            MealType::Breakfast => breakfast_cal += cal,
            MealType::Lunch => lunch_cal += cal,
            MealType::Dinner => dinner_cal += cal,
            MealType::Snack => snacks_cal += cal,
        }
    }

    // Set up exercise tracker config
    let goal = match input.goal.as_deref() {
        Some("deficit") => BalanceGoal::Deficit,
        Some("surplus") => BalanceGoal::Surplus,
        _ => BalanceGoal::Maintenance,
    };

    let config = ExerciseConfig {
        bmr: input.bmr,
        activity_multiplier: input.activity_multiplier.unwrap_or(1.375),
        goal,
        daily_calorie_target: input.target_adjustment.unwrap_or(0.0),
        weight_kg: input.weight_kg,
        ..ExerciseConfig::default()
    };

    let tracker = ExerciseBalanceTracker::new(config.clone());

    // Get or create exercise entries
    let exercises: Vec<ExerciseEntry> = input
        .exercises
        .unwrap_or_default()
        .into_iter()
        .map(|e| ExerciseEntry::new(e.name, e.calories, e.minutes))
        .collect();

    let total_exercise_calories: f64 = exercises.iter().map(|e| e.calories_burned).sum();

    // Create meal intake
    let meals = MealIntake::new(total_calories, total_protein, total_carbs, total_fat);

    // Calculate daily balance
    let balance = tracker.calculate_daily_balance(&input.date, &exercises, &meals);

    // Generate recommendations
    let mut recommendations = Vec::new();

    if balance.calories_remaining > 500.0 {
        recommendations.push(format!(
            "You have {:.0} calories remaining. Consider a protein-rich snack.",
            balance.calories_remaining
        ));
    } else if balance.calories_remaining < -200.0 {
        recommendations.push(format!(
            "You've exceeded your target by {:.0} calories. Consider additional exercise tomorrow.",
            balance.calories_remaining.abs()
        ));
    }

    // Protein recommendation
    if let Some(target) = balance.target_protein {
        if total_protein < target * 0.8 {
            recommendations.push(format!(
                "Protein intake ({:.0}g) is below target ({:.0}g). Add lean protein sources.",
                total_protein, target
            ));
        }
    }

    // Exercise recommendation
    if exercises.is_empty() {
        recommendations.push(
            "No exercise logged today. Even light activity helps with energy balance.".to_string()
        );
    }

    let exercise_outputs: Vec<ExerciseOutput> = exercises
        .iter()
        .map(|e| ExerciseOutput {
            name: e.name.clone(),
            calories_burned: e.calories_burned,
            duration_minutes: e.duration_minutes,
            calories_per_minute: e.calories_per_minute(),
        })
        .collect();

    Ok(Output {
        success: true,
        balance: BalanceOutput {
            calories_in: total_calories,
            calories_out_exercise: total_exercise_calories,
            bmr: config.bmr,
            tdee: balance.tdee,
            net_balance: balance.net_balance,
            target_calories: balance.target_calories,
            calories_remaining: balance.calories_remaining,
            goal_met: balance.goal_met,
            goal: goal_name(&goal),
        },
        meals: MealBreakdown {
            breakfast: if breakfast_cal > 0.0 { Some(breakfast_cal) } else { None },
            lunch: if lunch_cal > 0.0 { Some(lunch_cal) } else { None },
            dinner: if dinner_cal > 0.0 { Some(dinner_cal) } else { None },
            snacks: if snacks_cal > 0.0 { Some(snacks_cal) } else { None },
            total_protein,
            total_carbs,
            total_fat,
        },
        exercises: exercise_outputs,
        recommendations,
    })
}

fn goal_name(goal: &BalanceGoal) -> String {
    match goal {
        BalanceGoal::Deficit => "Weight Loss (Deficit)".to_string(),
        BalanceGoal::Maintenance => "Maintenance".to_string(),
        BalanceGoal::Surplus => "Muscle Gain (Surplus)".to_string(),
    }
}

fn read_input() -> Result<Input, Box<dyn std::error::Error>> {
    if let Some(arg) = std::env::args().nth(1) {
        Ok(serde_json::from_str(&arg)?)
    } else {
        let mut input_str = String::new();
        io::stdin().read_to_string(&mut input_str)?;
        Ok(serde_json::from_str(&input_str)?)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_output_serialize() {
        let output = Output {
            success: true,
            balance: BalanceOutput {
                calories_in: 1800.0,
                calories_out_exercise: 300.0,
                bmr: 1800.0,
                tdee: 2475.0,
                net_balance: -675.0,
                target_calories: 1975.0,
                calories_remaining: 175.0,
                goal_met: true,
                goal: "Weight Loss (Deficit)".to_string(),
            },
            meals: MealBreakdown {
                breakfast: Some(400.0),
                lunch: Some(600.0),
                dinner: Some(700.0),
                snacks: Some(100.0),
                total_protein: 120.0,
                total_carbs: 180.0,
                total_fat: 65.0,
            },
            exercises: vec![
                ExerciseOutput {
                    name: "Running".to_string(),
                    calories_burned: 300.0,
                    duration_minutes: 30,
                    calories_per_minute: 10.0,
                }
            ],
            recommendations: vec!["Keep up the good work!".to_string()],
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize");
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"goal_met\":true"));
        assert!(json.contains("\"net_balance\":-675"));
    }

    #[test]
    fn test_goal_name() {
        assert_eq!(goal_name(&BalanceGoal::Deficit), "Weight Loss (Deficit)");
        assert_eq!(goal_name(&BalanceGoal::Maintenance), "Maintenance");
        assert_eq!(goal_name(&BalanceGoal::Surplus), "Muscle Gain (Surplus)");
    }

    #[test]
    fn test_error_serialize() {
        let error = ErrorOutput {
            success: false,
            error: "Test error".to_string(),
        };
        let json = serde_json::to_string(&error).expect("Failed to serialize");
        assert!(json.contains("\"success\":false"));
    }
}
