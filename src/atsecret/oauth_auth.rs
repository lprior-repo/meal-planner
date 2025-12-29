//! FatSecret OAuth Token Management - Windmill Lambda
//!
//! OAuth 1.0a authentication lambda for FatSecret API token management.
//! Windmill passes input via stdin as JSON and expects JSON output on stdout.

use serde::{Deserialize, Serialize};
use std::io::{self, Read, Write};
use std::time::Instant;

// ============================================================================
// Input Types
// ============================================================================

/// Action to perform on OAuth token
#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum OAuthAction {
    GetToken,
    RefreshToken,
    ValidateToken,
}

/// OAuth authentication parameters
#[derive(Debug, Deserialize)]
pub struct OAuthParams {
    pub action: OAuthAction,
}

/// Lambda input wrapper
#[derive(Debug, Deserialize)]
pub struct Input {
    pub params: OAuthParams,
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

/// OAuth token response
#[derive(Debug, Clone, Serialize)]
pub struct TokenResponse {
    pub access_token: String,
    pub refresh_token: String,
    pub expires_at: String,
    pub token_type: String,
}

/// Lambda output wrapper
#[derive(Debug, Serialize)]
pub struct Output {
    pub data: OutputData,
    #[serde(default)]
    pub meta: Option<ExecutionMeta>,
}

#[derive(Debug, Serialize)]
#[serde(untagged)]
pub enum OutputData {
    Token(TokenResponse),
    Error { message: String },
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
        Err(e) => {
            let error_output = Output {
                data: OutputData::Error {
                    message: format!("Failed to parse input JSON: {}", e),
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
                serde_json::to_string(&error_output).unwrap()
            )?;
            return Ok(());
        }
    };

    let output = Output {
        data: OutputData::Error {
            message: "FatSecret SDK not implemented yet".to_string(),
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
