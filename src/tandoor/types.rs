//! Tandoor API types

use serde::{Deserialize, Serialize};

/// Configuration for Tandoor API client
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct TandoorConfig {
    pub base_url: String,
    pub api_token: String,
}

/// Paginated response wrapper
#[derive(Debug, Deserialize)]
pub struct PaginatedResponse<T> {
    pub count: i64,
    pub next: Option<String>,
    pub previous: Option<String>,
    pub results: Vec<T>,
}

/// Recipe summary (list view)
#[derive(Debug, Deserialize, Serialize)]
pub struct RecipeSummary {
    pub id: i64,
    pub name: String,
    pub description: Option<String>,
    pub keywords: Option<Vec<Keyword>>,
    pub working_time: Option<i32>,
    pub waiting_time: Option<i32>,
    pub rating: Option<f64>,
    pub servings: Option<i32>,
}

/// Keyword/tag
#[derive(Debug, Deserialize, Serialize)]
pub struct Keyword {
    pub id: i64,
    pub name: String,
}

/// Test connection result
#[derive(Debug, Serialize)]
pub struct ConnectionTestResult {
    pub success: bool,
    pub message: String,
    pub recipe_count: i64,
}

/// Error response from Tandoor
#[derive(Debug, Deserialize)]
pub struct TandoorErrorResponse {
    pub detail: Option<String>,
    pub error: Option<String>,
}
