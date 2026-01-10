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
    // Check for help and schema flags first
    let args: Vec<String> = env::args().collect();
    if args.len() > 1 {
        let arg = &args[1];
        if arg == "--help" || arg == "-h" || arg == "help" {
            print_help();
            std::process::exit(0);
        }
        if arg == "--schema" {
            print_schema();
            std::process::exit(0);
        }
    }

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

fn print_help() {
    println!(
        r#"validate_encryption - Validate OAuth encryption configuration

USAGE
    echo '{{}}' | validate_encryption
    echo '{{"detailed": true}}' | validate_encryption
    validate_encryption --help
    validate_encryption -h
    validate_encryption help

    This utility validates that the OAUTH_ENCRYPTION_KEY environment variable
    is properly configured and functional before starting services that require
    encryption for OAuth token storage.

INPUT SCHEMA
    JSON input via stdin (optional):
    {{
        "detailed": boolean  // Optional: return detailed validation info (default: false)
    }}

    Command-line arguments:
    - --help, -h, help: Display this help message

    Environment variables (required):
    - OAUTH_ENCRYPTION_KEY: 64-character hex string (32 bytes for AES-256-GCM)

OUTPUT SCHEMA
    Success response (JSON on stdout):
    {{
        "success": true,
        "message": "Encryption configuration is valid and functional"
    }}

    Success response with detailed=true:
    {{
        "success": true,
        "message": "Encryption configuration is valid and functional",
        "details": {{
            "key_is_set": true,
            "key_length": 64,
            "key_is_valid_hex": true,
            "key_correct_length": true
        }}
    }}

    Error response (JSON on stderr):
    {{
        "success": false,
        "error": "Error description"
    }}

    Common error messages:
    - "OAUTH_ENCRYPTION_KEY environment variable not set"
    - "OAUTH_ENCRYPTION_KEY must be exactly 64 hex characters"
    - "OAUTH_ENCRYPTION_KEY contains invalid hex characters"

EXAMPLES
    1. Simple validation (checks key is set and valid):
       $ echo '{{}}' | validate_encryption
       {{"success":true,"message":"Encryption configuration is valid and functional"}}

    2. Detailed validation (returns key analysis):
       $ echo '{{"detailed": true}}' | validate_encryption
       {{"success":true,"message":"...","details":{{...}}}}

    3. Use in startup scripts:
       $ if echo '{{}}' | validate_encryption; then
           echo "Encryption OK, starting service..."
         else
           echo "Encryption validation failed!"
           exit 1
         fi

    4. Display help:
       $ validate_encryption --help

EXIT CODES
    0 - Success (encryption key is valid and functional)
    1 - Error (encryption key missing, invalid, or non-functional)

NOTES
    - This binary reads JSON from stdin (not command-line arguments)
    - The OAUTH_ENCRYPTION_KEY must be set before running
    - Key format: 64 hexadecimal characters (32 bytes / 256 bits)
    - Used to validate configuration at service startup
    - Performs a round-trip encryption test to verify functionality
    - Safe to run repeatedly - uses test data only
    - For detailed diagnostics, use {{"detailed": true}}

VALIDATION CHECKS
    1. Environment variable OAUTH_ENCRYPTION_KEY is set
    2. Key is exactly 64 characters long
    3. Key contains only valid hexadecimal characters (0-9, a-f, A-F)
    4. Key can be decoded to 32 bytes
    5. Round-trip encryption/decryption works correctly

SECURITY
    - Does not expose the encryption key value in output
    - Only confirms the key is properly configured
    - Uses test data for round-trip verification
    - Detailed mode shows key length but not the key itself
"#
    );
}

fn print_schema() {
    use meal_planner::schema::SchemaBuilder;

    let schema = SchemaBuilder::new("validate_encryption", env!("CARGO_PKG_VERSION"))
        .description("Validate OAuth encryption configuration at startup")
        .input_schema(serde_json::json!({
            "type": "object",
            "properties": {
                "detailed": {
                    "type": "boolean",
                    "description": "Return detailed validation information",
                    "default": false
                }
            },
            "additionalProperties": false
        }))
        .output_success_schema(serde_json::json!({
            "type": "object",
            "properties": {
                "success": {
                    "type": "boolean",
                    "const": true
                },
                "message": {
                    "type": "string",
                    "description": "Validation result message"
                },
                "details": {
                    "type": "object",
                    "properties": {
                        "key_is_set": {"type": "boolean"},
                        "key_length": {"type": "integer"},
                        "key_is_valid_hex": {"type": "boolean"},
                        "key_correct_length": {"type": "boolean"}
                    },
                    "required": ["key_is_set", "key_length", "key_is_valid_hex", "key_correct_length"]
                }
            },
            "required": ["success", "message"],
            "additionalProperties": false
        }))
        .output_error_schema(serde_json::json!({
            "type": "object",
            "properties": {
                "success": {
                    "type": "boolean",
                    "const": false
                },
                "error": {
                    "type": "string",
                    "description": "Error message"
                },
                "details": {
                    "type": "object",
                    "properties": {
                        "key_is_set": {"type": "boolean"},
                        "key_length": {"type": "integer"},
                        "key_is_valid_hex": {"type": "boolean"},
                        "key_correct_length": {"type": "boolean"}
                    },
                    "required": ["key_is_set", "key_length", "key_is_valid_hex", "key_correct_length"]
                }
            },
            "required": ["success", "error"],
            "additionalProperties": false
        }))
        .example(
            "Simple validation",
            serde_json::json!({}),
            serde_json::json!({
                "success": true,
                "message": "Encryption configuration is valid and functional"
            })
        )
        .example(
            "Detailed validation",
            serde_json::json!({"detailed": true}),
            serde_json::json!({
                "success": true,
                "message": "Encryption configuration is valid and functional",
                "details": {
                    "key_is_set": true,
                    "key_length": 64,
                    "key_is_valid_hex": true,
                    "key_correct_length": true
                }
            })
        )
        .build();

    println!(
        "{}",
        serde_json::to_string_pretty(&schema).expect("Failed to serialize schema")
    );
}
