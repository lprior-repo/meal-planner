//! FatSecret Diary Get Entry - Windmill Lambda
//!
//! Get single food diary entry from FatSecret API.
//! Windmill passes input via stdin as JSON and expects JSON output on stdout.

use serde::{Deserialize, Serialize};
use std::io::{self, Read, Write};
use std::time::Instant;

// ============================================================================
// Input Types
// ============================================================================

/// Entry lookup parameters
#[derive(Debug, Deserialize)]
pub struct EntryParams {
    #[serde(default)]
    pub date: Option<String>,

    #[serde(default)]
    pub entry_id: Option<i32>,
}

/// Lambda input wrapper
#[derive(Debug, Deserialize)]
pub struct Input {
    pub params: EntryParams,

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

/// Entry response
#[derive(Debug, Serialize)]
pub struct EntryResponse {
    pub entry: String, // Placeholder - full entry structure
}

/// Not found error
#[derive(Debug, Serialize)]
pub struct NotFoundError {
    pub error: String,
    pub code: i32,
}

/// Lambda output wrapper
#[derive(Debug, Serialize)]
pub struct Output {
    pub data: EntryResponse,

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
        Err(_e) => {
            let output = Output {
                data: EntryResponse {
                    entry: "Not implemented - waiting for FatSecret SDK integration".to_string(),
                },
                meta: Some(ExecutionMeta {
                    execution_time_ms: 0,
                    request_id: None,
                    trace_id: None,
                }),
            };
            writeln!(
                io::stdout(),
                "{}",
                serde_json::to_string(&output).unwrap()
            )?;
            return Ok(());
        }
    };

    // Validate exactly one lookup parameter is provided
    if input.params.date.is_some() && input.params.entry_id.is_some() {
        let error_output = Output {
                data: EntryResponse {
                    entry: "Invalid: Must provide either 'date' OR 'entry_id', not both".to_string(),
                },
                meta: Some(ExecutionMeta {
                    execution_time_ms: start_time.elapsed().as_millis() as u64,
                    request_id: input._meta.as_ref().and_then(|m| m.request_id.clone()),
                    trace_id: input._meta.as_ref().and_then(|m| m.trace_id.clone()),
                }),
            };
        writeln!(
            io::stdout(),
            "{}",
            serde_json::to_string(&error_output).unwrap()
        )?;
        return Ok(());
    }

    if input.params.date.is_none() && input.params.entry_id.is_none() {
        let error_output = Output {
                data: EntryResponse {
                    entry: "Invalid: Must provide either 'date' OR 'entry_id'".to_string(),
                },
                meta: Some(ExecutionMeta {
                    execution_time_ms: start_time.elapsed().as_millis() as u64,
                    request_id: input._meta.as_ref().and_then(|m| m.request_id.clone()),
                    trace_id: input._meta.as_ref().and_then(|m| m.trace_id.clone()),
                }),
            };
        writeln!(
            io::stdout(),
            "{}",
            serde_json::to_string(&error_output).unwrap()
        )?;
        return Ok(());
    }

    // TODO: Integrate with FatSecret SDK once available
    // For now, return placeholder response
    let output = Output {
        data: EntryResponse {
            entry: format!("Entry for date {:?} or ID {:?}", input.params.date, input.params.entry_id),
        },
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
