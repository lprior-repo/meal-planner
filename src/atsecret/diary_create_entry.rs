//! FatSecret Diary Create Entry - Windmill Lambda
//!
//! Create food diary entry in FatSecret API.
//! Windmill passes input via stdin as JSON and expects JSON output on stdout.

use serde::{Deserialize, Serialize};
use std::io::{self, Read, Write};
use std::time::Instant;

// ============================================================================
// Input Types
// ============================================================================

/// Meal type enum matching FatSecret API
#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ApiMealType {
    Breakfast,
    Lunch,
    Dinner,
    Other,
}

/// Food entry for database food
#[derive(Debug, Deserialize)]
pub struct FoodEntryFromDatabase {
    pub food_id: String,
    pub food_entry_name: String,
    pub serving_id: String,
    pub number_of_units: f64,
    pub meal: ApiMealType,
    pub date: String,
}

/// Food entry for custom food
#[derive(Debug, Deserialize)]
pub struct FoodEntryCustom {
    pub food_entry_name: String,
    pub serving_description: String,
    pub number_of_units: f64,
    pub meal: ApiMealType,
    pub date: String,
    pub calories: f64,
    pub carbohydrate: f64,
    pub protein: f64,
    pub fat: f64,
}

/// Food entry input (variant)
#[derive(Debug, Deserialize)]
#[serde(untagged)]
pub enum FoodEntryInputWrapper {
    #[serde(rename = "food_id")]
    FromDatabase(FoodEntryFromDatabase),
    #[serde(rename = "calories")]
    Custom(FoodEntryCustom),
}

/// Create diary entry parameters
#[derive(Debug, Deserialize)]
pub struct CreateParams {
    /// Date in YYYY-MM-DD format
    pub date: String,

    /// Meal type
    pub meal_type: ApiMealType,

    /// Food entries (can be single or array)
    pub food_entries: Vec<FoodEntryInputWrapper>,
}

/// Lambda input wrapper
#[derive(Debug, Deserialize)]
pub struct Input {
    pub params: CreateParams,

    /// OAuth access token
    pub access_token: String,

    #[serde(default)]
    pub _meta: Option<LambdaMeta>,
}

#[derive(Debug, Deserialize)]
pub struct LambdaMeta {
    pub request_id: Option<String>,
    pub trace_id: Option<String>,
}

// ============================================================================
// Output Types
// ============================================================================

/// Created entry response
#[derive(Debug, Serialize)]
pub struct CreatedEntry {
    pub entry_id: String,
}

/// Create entry response
#[derive(Debug, Serialize)]
pub struct CreateResponse {
    pub entry_id: i64,
}

/// Lambda output wrapper
#[derive(Debug, Serialize)]
pub struct Output {
    pub data: CreateResponse,

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

/// Validation error
#[derive(Debug, Serialize)]
pub struct ValidationErrorResponse {
    pub error: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub field: Option<String>,
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

    // Validate date format
    if input.params.date.len() != 10 || !input.params.date.chars().all(|c| c.is_ascii_digit() || c == '-') {
        let error_output = ErrorOutput {
            data: serde_json::json!({ "error": "Invalid date format. Expected YYYY-MM-DD" }),
            meta: ExecutionMeta {
                execution_time_ms: start_time.elapsed().as_millis() as u64,
                request_id: input._meta.as_ref().and_then(|m| m.request_id.clone()),
                trace_id: input._meta.as_ref().and_then(|m| m.trace_id.clone()),
            },
        };
        writeln!(
            io::stdout(),
            "{}",
            serde_json::to_string(&error_output).unwrap()
        )?;
        return Ok(());
    }

    // Validate food_entries is not empty
    if input.params.food_entries.is_empty() {
        let error_output = ErrorOutput {
            data: serde_json::json!({ "error": "food_entries array cannot be empty" }),
            meta: ExecutionMeta {
                execution_time_ms: start_time.elapsed().as_millis() as u64,
                request_id: input._meta.as_ref().and_then(|m| m.request_id.clone()),
                trace_id: input._meta.as_ref().and_then(|m| m.trace_id.clone()),
            },
        };
        writeln!(
            io::stdout(),
            "{}",
            serde_json::to_string(&error_output).unwrap()
        )?;
        return Ok(());
    }

    // Validate number_of_units for each entry
    for (index, entry) in input.params.food_entries.iter().enumerate() {
        let units = match entry {
            FoodEntryInputWrapper::FromDatabase(ref db) => db.number_of_units,
            FoodEntryInputWrapper::Custom(ref custom) => custom.number_of_units,
        };

        if units <= 0.0 {
            let error_output = ErrorOutput {
                data: serde_json::json!({ "error": format!("Food entry {}: number_of_units must be > 0", index + 1) }),
                meta: ExecutionMeta {
                    execution_time_ms: start_time.elapsed().as_millis() as u64,
                    request_id: input._meta.as_ref().and_then(|m| m.request_id.clone()),
                    trace_id: input._meta.as_ref().and_then(|m| m.trace_id.clone()),
                },
            };
            writeln!(
                io::stdout(),
                "{}",
                serde_json::to_string(&error_output).unwrap()
            )?;
            return Ok(());
        }
    }

    // Validate nutrition values for custom entries
    for (index, entry) in input.params.food_entries.iter().enumerate() {
        if let FoodEntryInputWrapper::Custom(ref custom) = entry {
            if custom.calories < 0.0 || custom.carbohydrate < 0.0 || custom.protein < 0.0 || custom.fat < 0.0 {
                let error_output = ErrorOutput {
                    data: serde_json::json!({ "error": format!("Custom food entry {}: All nutrition values must be >= 0", index + 1) }),
                    meta: ExecutionMeta {
                        execution_time_ms: start_time.elapsed().as_millis() as u64,
                        request_id: input._meta.as_ref().and_then(|m| m.request_id.clone()),
                        trace_id: input._meta.as_ref().and_then(|m| m.trace_id.clone()),
                    },
                };
                writeln!(
                    io::stdout(),
                    "{}",
                    serde_json::to_string(&error_output).unwrap()
                )?;
                return Ok(());
            }
        }
    }

    // TODO: Integrate with FatSecret SDK
    // For now, return placeholder response
    let entry_id = 123456; // Placeholder
    let create_response = CreateResponse { entry_id };

    let output = Output {
        data: create_response,
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
    )
}
