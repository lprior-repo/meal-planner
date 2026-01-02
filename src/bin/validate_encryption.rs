//! Validate OAuth encryption configuration at startup
//!
//! This utility validates that the OAUTH_ENCRYPTION_KEY environment variable
//! is properly configured and functional before starting any services that
//! require encryption for OAuth token storage.
//!
//! # Usage
//!
//! ```bash
//! # Validate current configuration
//! cargo run --bin validate_encryption
//!
//! # Use in startup scripts
//! if ! cargo run --bin validate_encryption; then
//!     echo "Encryption validation failed - aborting startup"
//!     exit 1
//! fi
//! ```

#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::fatsecret::crypto::{
    validate_encryption_at_startup, validate_encryption_detailed,
};
use serde::{Deserialize, Serialize};
use std::env;

#[derive(Deserialize)]
struct Input {
    /// Whether to return detailed validation information
    detailed: Option<bool>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    details: Option<ValidationInfo>,
}

#[derive(Serialize)]
struct ValidationInfo {
    key_is_set: bool,
    key_length: usize,
    key_is_valid_hex: bool,
    key_correct_length: bool,
}

#[derive(Serialize)]
struct ErrorOutput {
    success: bool,
    error: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    details: Option<ValidationInfo>,
}

#[tokio::main]
async fn main() {
    match run() {
        Ok(output) => {
            println!(
                "{}",
                serde_json::to_string(&output).expect("Failed to serialize output JSON")
            );
        }
        Err(e) => {
            // Try to get detailed info even on error if requested
            let mut error_details = None;
            if let Some(arg) = env::args().nth(1) {
                if let Ok(input) = serde_json::from_str::<Input>(&arg) {
                    if input.detailed.unwrap_or(false) {
                        if let Ok(details) = validate_encryption_detailed() {
                            error_details = Some(ValidationInfo {
                                key_is_set: details.key_is_set,
                                key_length: details.key_length,
                                key_is_valid_hex: details.key_is_valid_hex,
                                key_correct_length: details.key_correct_length,
                            });
                        }
                    }
                }
            }

            let error = ErrorOutput {
                success: false,
                error: e.to_string(),
                details: error_details,
            };
            eprintln!(
                "{}",
                serde_json::to_string(&error).expect("Failed to serialize error JSON")
            );
            std::process::exit(1);
        }
    }
}

fn run() -> Result<Output, Box<dyn std::error::Error>> {
    // Parse input for detailed mode
    let mut detailed = false;
    if let Some(arg) = env::args().nth(1) {
        if let Ok(input) = serde_json::from_str::<Input>(&arg) {
            detailed = input.detailed.unwrap_or(false);
        }
    }

    if detailed {
        // Use detailed validation
        match validate_encryption_detailed() {
            Ok(details) => Ok(Output {
                success: true,
                message: "Encryption configuration is valid and functional".to_string(),
                details: Some(ValidationInfo {
                    key_is_set: details.key_is_set,
                    key_length: details.key_length,
                    key_is_valid_hex: details.key_is_valid_hex,
                    key_correct_length: details.key_correct_length,
                }),
            }),
            Err(e) => Err(e.into()),
        }
    } else {
        // Use simple validation
        validate_encryption_at_startup()?;
        Ok(Output {
            success: true,
            message: "Encryption configuration is valid and functional".to_string(),
            details: None,
        })
    }
}
