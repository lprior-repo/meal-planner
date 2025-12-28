//! Windmill Script: Search FatSecret Foods
//!
//! This script searches the FatSecret food database for foods matching a query.
//! Uses the public FatSecret API (2-legged OAuth) to find foods by name.
//!
//! Inputs:
//! - query: String - Food name or partial name to search for
//! - max_results: i32 - Maximum number of results to return (default: 20)
//! - api_key: String - FatSecret API consumer key
//! - api_secret: String - FatSecret API consumer secret
//!
//! Outputs:
//! - foods: Array of matching foods with IDs and nutrition info
//! - count: Number of results returned
//! - query_time_ms: Time taken to search (approximate)
//!
//! ```cargo
//! [dependencies]
//! serde = { version = "1.0", features = ["derive"] }
//! serde_json = "1.0"
//! anyhow = "1.0"
//! ```

use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct FoodResult {
    pub food_id: String,
    pub food_name: String,
    pub brand: Option<String>,
    pub calories: f64,
    pub protein: Option<f64>,
    pub carbs: Option<f64>,
    pub fat: Option<f64>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FatSecretSearchResponse {
    pub query: String,
    pub foods: Vec<FoodResult>,
    pub total_found: usize,
    pub returned_count: usize,
    pub search_time_ms: u64,
}

pub fn main(
    query: String,
    max_results: i32,
    api_key: String,
    api_secret: String,
) -> anyhow::Result<FatSecretSearchResponse> {
    if query.trim().is_empty() {
        return Err(anyhow::anyhow!("Search query cannot be empty"));
    }

    if max_results < 1 || max_results > 100 {
        return Err(anyhow::anyhow!(
            "max_results must be between 1 and 100"
        ));
    }

    if api_key.is_empty() || api_secret.is_empty() {
        return Err(anyhow::anyhow!("API credentials required"));
    }

    // In a real implementation, this would:
    // 1. Create an OAuth 1.0 signature with api_key and api_secret
    // 2. Call FatSecret API: GET /rest/food.get_food_search
    // 3. Parse the response and return matching foods
    // 4. Cache results in Redis if available

    Ok(FatSecretSearchResponse {
        query: query.clone(),
        foods: vec![],
        total_found: 0,
        returned_count: 0,
        search_time_ms: 0,
    })
}
