//! FatSecret Foods Search - Windmill Lambda
//!
//! Search FatSecret food database by name/brand.
//! Windmill passes input via stdin as JSON and expects JSON output on stdout.

use serde::{Deserialize, Serialize};
use std::io::{self, Read, Write};
use std::time::Instant;

// ============================================================================
// Input Types
// ============================================================================

/// Food search parameters
#[derive(Debug, Deserialize)]
pub struct SearchParams {
    pub query: String,
    #[serde(default = "default_max_results")]
    pub max_results: u32,
    #[serde(default = "default_page_number")]
    pub page_number: u32,
    #[serde(default)]
    pub brand: Option<String>,
}

/// Lambda input wrapper
#[derive(Debug, Deserialize)]
pub struct Input {
    pub params: SearchParams,
    #[serde(default)]
    pub _meta: Option<LambdaMeta>,
}

#[derive(Debug, Deserialize)]
pub struct LambdaMeta {
    pub request_id: Option<String>,
    pub trace_id: Option<String>,
}

fn default_max_results() -> u32 { 50 }
fn default_page_number() -> u32 { 1 }

// ============================================================================
// Output Types
// ============================================================================

/// Pagination metadata
#[derive(Debug, Serialize)]
pub struct PaginationMeta {
    pub total_results: i32,
    pub page: i32,
    pub has_more: bool,
}

/// Food item for search results
#[derive(Debug, Serialize)]
pub struct FoodItem {
    pub food_id: String,
    pub food_name: String,
    pub food_type: String,
    pub food_description: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub brand_name: Option<String>,
    pub food_url: String,
}

/// Search response
#[derive(Debug, Serialize)]
pub struct SearchResponse {
    pub foods: Vec<FoodItem>,
    pub pagination: PaginationMeta,
}

/// Lambda output wrapper
#[derive(Debug, Serialize)]
pub struct Output {
    pub data: SearchResponse,
    #[serde(default)]
    pub meta: Option<ExecutionMeta>,
}

#[derive(Debug, Serialize)]
pub struct ExecutionMeta {
    pub execution_time_ms: u64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub request_id: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub trace_id: Option<String>,
}

/// Error output
#[derive(Debug, Serialize)]
pub struct ErrorOutput {
    pub data: serde_json::Value,
    pub meta: ExecutionMeta,
}

// ============================================================================
// Main Lambda Handler
// ============================================================================

fn main() -> io::Result<()> {
    let start_time = Instant::now();

    // Read JSON input from stdin
    let mut buffer = String::new();
    io::stdin().read_to_string(&mut buffer)?;

    // Parse input
    let input: Input = match serde_json::from_str(&buffer) {
        Ok(i) => i,
        Err(e) => {
            let error_output = ErrorOutput {
                data: serde_json::json!({ "error": format!("Failed to parse input JSON: {}", e) }),
                meta: ExecutionMeta {
                    execution_time_ms: 0,
                    request_id: None,
                    trace_id: None,
                },
            };
            writeln!(
                io::stdout(),
                "{}",
                serde_json::to_string(&error_output).unwrap()
            )?;
            return Ok(());
        }
    };

    // Build search query (include brand filter if provided)
    let search_query = if let Some(brand) = input.params.brand {
        format!("{} {}", input.params.query, brand)
    } else {
        input.params.query.clone()
    };

    // Search foods - TODO: Integrate with actual FatSecret SDK
    match search_query.as_str() {
        _ => {
            let foods = vec![FoodItem {
                food_id: "123".to_string(),
                food_name: "Apple".to_string(),
                food_type: "Generic".to_string(),
                food_description: "Medium apple".to_string(),
                brand_name: None,
                food_url: "https://example.com/food/123".to_string(),
            }];

            let search_response = SearchResponse {
                foods,
                pagination: PaginationMeta {
                    total_results: 1,
                    page: 1,
                    has_more: false,
                },
            };

            let output = Output {
                data: search_response,
                meta: Some(ExecutionMeta {
                    execution_time_ms: start_time.elapsed().as_millis() as u64,
                    request_id: input._meta.as_ref().and_then(|m| m.request_id.clone()),
                    trace_id: input._meta.as_ref().and_then(|m| m.trace_id.clone()),
                }),
            };

            writeln!(
                io::stdout(),
                "{}",
                serde_json::to_string(&output).unwrap()
            )?;
            Ok(())
        }
    }
}
