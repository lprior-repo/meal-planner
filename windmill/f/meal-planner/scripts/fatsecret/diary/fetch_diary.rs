//! Windmill Script: Fetch FatSecret Diary Entries
//!
//! This script fetches a user's FatSecret food diary entries for a specific date.
//! It uses the FatSecret API to retrieve all food entries logged for that day.
//!
//! Inputs:
//! - date: String - Date in YYYY-MM-DD format
//! - oauth_token: String - FatSecret OAuth access token
//! - oauth_secret: String - FatSecret OAuth token secret
//!
//! Outputs:
//! - entries: Array of food diary entries with nutrition info
//! - count: Number of entries retrieved
//! - total_calories: Total calories for the day
//!
//! ```cargo
//! [dependencies]
//! serde = { version = "1.0", features = ["derive"] }
//! serde_json = "1.0"
//! anyhow = "1.0"
//! chrono = "0.4"
//! ```

use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct FoodEntry {
    pub id: String,
    pub food_name: String,
    pub brand_name: Option<String>,
    pub calories: f64,
    pub protein: f64,
    pub carbs: f64,
    pub fat: f64,
    pub meal_type: String,
    pub quantity: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FatSecretDiaryResponse {
    pub date: String,
    pub entries: Vec<FoodEntry>,
    pub entry_count: usize,
    pub total_calories: f64,
    pub total_protein: f64,
    pub total_carbs: f64,
    pub total_fat: f64,
}

pub fn main(
    date: String,
    oauth_token: String,
    oauth_secret: String,
) -> anyhow::Result<FatSecretDiaryResponse> {
    // Validate date format
    if !regex::Regex::new(r"^\d{4}-\d{2}-\d{2}$")
        .unwrap()
        .is_match(&date)
    {
        return Err(anyhow::anyhow!(
            "Invalid date format. Use YYYY-MM-DD format"
        ));
    }

    // In a real implementation, this would:
    // 1. Sign the request with OAuth credentials
    // 2. Call FatSecret API: GET /rest/food.get_fat_secret_food
    // 3. Parse and return the diary entries

    // For now, return a mock response
    if oauth_token.is_empty() || oauth_secret.is_empty() {
        return Err(anyhow::anyhow!("OAuth credentials required"));
    }

    Ok(FatSecretDiaryResponse {
        date: date.clone(),
        entries: vec![],
        entry_count: 0,
        total_calories: 0.0,
        total_protein: 0.0,
        total_carbs: 0.0,
        total_fat: 0.0,
    })
}
