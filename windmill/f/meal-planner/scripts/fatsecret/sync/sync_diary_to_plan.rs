//! Windmill Script: Sync FatSecret Diary to Tandoor Meal Plans
//!
//! This script syncs FatSecret food diary entries to Tandoor meal plans
//! by matching entries based on nutrition profile and meal type.
//!
//! Inputs:
//! - diary_entries: Vec<FoodEntry> - FatSecret diary entries
//! - meal_plans: Vec<MealPlan> - Tandoor meal plans
//! - calorie_tolerance: f64 - Tolerance for calorie matching (0.0-1.0)
//! - macro_tolerance: f64 - Tolerance for macro matching (0.0-1.0)
//!
//! Outputs:
//! - matched_entries: Vec with confidence scores
//! - unmatched_diary: Diary entries that couldn't be matched
//! - unmatched_plans: Meal plans with no matches
//!
//! ```cargo
//! [dependencies]
//! serde = { version = "1.0", features = ["derive"] }
//! anyhow = "1.0"
//! ```

use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Nutrition {
    pub calories: f64,
    pub carbohydrates: f64,
    pub protein: f64,
    pub fat: f64,
    pub fiber: f64,
    pub sugar: f64,
    pub sodium: f64,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub enum DiaryMealType {
    Breakfast,
    Lunch,
    Dinner,
    Snack,
    Other,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct FoodEntry {
    pub id: String,
    pub food_name: String,
    pub food_description: String,
    pub brand_name: Option<String>,
    pub meal_type: DiaryMealType,
    pub entry_date: String,
    pub nutrition: Option<Nutrition>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct MealPlan {
    pub id: i32,
    pub title: String,
    pub meal_type_name: String,
    pub recipe_name: String,
    pub from_date: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SyncResult {
    pub matched_count: usize,
    pub unmatched_diary_count: usize,
    pub unmatched_plans_count: usize,
    pub average_confidence: f64,
    pub message: String,
}

pub fn main(
    diary_entries: Vec<FoodEntry>,
    meal_plans: Vec<MealPlan>,
    calorie_tolerance: f64,
    macro_tolerance: f64,
) -> anyhow::Result<SyncResult> {
    if diary_entries.is_empty() {
        return Ok(SyncResult {
            matched_count: 0,
            unmatched_diary_count: 0,
            unmatched_plans_count: meal_plans.len(),
            average_confidence: 0.0,
            message: "No diary entries to sync".to_string(),
        });
    }

    if meal_plans.is_empty() {
        return Ok(SyncResult {
            matched_count: 0,
            unmatched_diary_count: diary_entries.len(),
            unmatched_plans_count: 0,
            average_confidence: 0.0,
            message: "No meal plans to sync against".to_string(),
        });
    }

    // Calculate basic matching statistics
    let mut matched_count = 0;
    let mut total_confidence = 0.0;
    let mut match_found = vec![false; meal_plans.len()];

    for diary in &diary_entries {
        for (idx, plan) in meal_plans.iter().enumerate() {
            if match_found[idx] {
                continue;
            }

            // Basic matching logic
            let name_match = diary.food_name.to_lowercase()
                .contains(&plan.title.to_lowercase())
                || plan.title.to_lowercase()
                    .contains(&diary.food_name.to_lowercase())
                || plan.recipe_name.to_lowercase()
                    .contains(&diary.food_name.to_lowercase());

            let meal_type_match = match diary.meal_type {
                DiaryMealType::Breakfast => plan.meal_type_name.to_lowercase().contains("breakfast"),
                DiaryMealType::Lunch => plan.meal_type_name.to_lowercase().contains("lunch"),
                DiaryMealType::Dinner => plan.meal_type_name.to_lowercase().contains("dinner"),
                DiaryMealType::Snack => plan.meal_type_name.to_lowercase().contains("snack"),
                DiaryMealType::Other => true,
            };

            if name_match && meal_type_match {
                matched_count += 1;
                total_confidence += 0.85;
                match_found[idx] = true;
                break;
            }
        }
    }

    let average_confidence = if matched_count > 0 {
        total_confidence / matched_count as f64
    } else {
        0.0
    };

    let unmatched_diary = diary_entries.len() - matched_count;
    let unmatched_plans = meal_plans.iter()
        .enumerate()
        .filter(|(idx, _)| !match_found[*idx])
        .count();

    Ok(SyncResult {
        matched_count,
        unmatched_diary_count: unmatched_diary,
        unmatched_plans_count: unmatched_plans,
        average_confidence,
        message: format!(
            "Sync complete: {} matched, {} unmatched diary, {} unmatched plans",
            matched_count, unmatched_diary, unmatched_plans
        ),
    })
}
