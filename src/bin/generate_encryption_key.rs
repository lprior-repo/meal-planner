//! Generate OAuth encryption key for secure token storage
//!
//! This utility generates a cryptographically secure 256-bit encryption key
//! for use with the OAuth token encryption system.
//!
//! The generated key is a 64-character hex string (32 bytes) suitable for
//! AES-256-GCM encryption.
//!
//! # Usage
//!
//! ```bash
//! # Generate a new key
//! cargo run --bin generate_encryption_key
//!
//! # Set it as environment variable
//! export OAUTH_ENCRYPTION_KEY="generated_key_here"
//! ```

#![allow(
    clippy::exit,
    clippy::unwrap_used,
    clippy::expect_used,
    clippy::unnecessary_wraps
)]

use meal_planner::fatsecret::crypto::generate_key;

#[derive(serde::Serialize)]
struct Output {
    success: bool,
    key: String,
    instructions: String,
}

#[derive(serde::Serialize)]
struct ErrorOutput {
    success: bool,
    error: String,
}

#[tokio::main]
async fn main() {
    // Check for help and schema flags first
    let args: Vec<String> = std::env::args().collect();
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
            let error = ErrorOutput {
                success: false,
                error: e.to_string(),
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
    let key = generate_key();

    let instructions = format!(
        r#"To use this encryption key:

1. Set the environment variable:
   export OAUTH_ENCRYPTION_KEY="{}"

2. Add to your shell profile (~/.bashrc, ~/.zshrc, etc):
   export OAUTH_ENCRYPTION_KEY="{}"

3. For Windmill, store as a secure resource

The key is 64 hex characters (32 bytes) for AES-256-GCM encryption.
Keep this key secure - you cannot recover encrypted data without it!"#,
        key, key
    );

    Ok(Output {
        success: true,
        key,
        instructions,
    })
}

fn print_help() {
    println!(
        r#"generate_encryption_key - Generate OAuth encryption key for secure token storage

USAGE
    generate_encryption_key
    generate_encryption_key --help
    generate_encryption_key -h
    generate_encryption_key help

    This utility generates a cryptographically secure 256-bit encryption key
    for use with the OAuth token encryption system.

INPUT SCHEMA
    No input required. The binary generates a random encryption key.

    Command-line arguments:
    - --help, -h, help: Display this help message

    Standard input: Not used (no JSON input expected)

OUTPUT SCHEMA
    Success response (JSON on stdout):
    {{
        "success": true,
        "key": "64-character hex string (32 bytes)",
        "instructions": "Step-by-step setup instructions"
    }}

    The key field contains a 64-character hexadecimal string representing
    a 32-byte (256-bit) encryption key suitable for AES-256-GCM encryption.

    Error response (JSON on stderr):
    {{
        "success": false,
        "error": "Error description"
    }}

EXAMPLES
    1. Generate a new encryption key:
       $ generate_encryption_key
       {{"success":true,"key":"a1b2c3...","instructions":"..."}}

    2. Export the key to environment:
       $ export OAUTH_ENCRYPTION_KEY=$(generate_encryption_key | jq -r '.key')

    3. Display help:
       $ generate_encryption_key --help

EXIT CODES
    0 - Success (key generated and printed)
    1 - Error (failed to generate or serialize key)

NOTES
    - The generated key is cryptographically random using a secure RNG
    - Key format: 64 hexadecimal characters (32 bytes / 256 bits)
    - Suitable for AES-256-GCM encryption used by the OAuth token storage
    - Store the key securely - encrypted data cannot be recovered without it
    - For production use, store in environment variables or secure vaults
    - For Windmill deployments, add as a secure resource
    - Never commit encryption keys to version control

SECURITY
    - Uses the `ring` cryptography library's secure random number generator
    - Each invocation generates a unique, unpredictable key
    - The key should be treated as a secret with the same sensitivity as passwords
"#
    );
}

fn print_schema() {
    use meal_planner::schema::SchemaBuilder;

    let schema = SchemaBuilder::new("generate_encryption_key", env!("CARGO_PKG_VERSION"))
        .description("Generate a cryptographically secure 256-bit encryption key for OAuth token storage")
        .input_schema(serde_json::json!({
            "type": "null",
            "description": "No input required - generates a new key on each invocation"
        }))
        .output_success_schema(serde_json::json!({
            "type": "object",
            "properties": {
                "success": {
                    "type": "boolean",
                    "const": true
                },
                "key": {
                    "type": "string",
                    "pattern": "^[0-9a-f]{64}$",
                    "description": "64-character hex string (32 bytes) for AES-256-GCM encryption"
                },
                "instructions": {
                    "type": "string",
                    "description": "Human-readable setup instructions"
                }
            },
            "required": ["success", "key", "instructions"],
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
                }
            },
            "required": ["success", "error"],
            "additionalProperties": false
        }))
        .example(
            "Generate a new encryption key",
            serde_json::json!(null),
            serde_json::json!({
                "success": true,
                "key": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
                "instructions": "To use this encryption key:\n\n1. Set the environment variable:\n   export OAUTH_ENCRYPTION_KEY=\"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef\"\n\n2. Add to your shell profile (~/.bashrc, ~/.zshrc, etc):\n   export OAUTH_ENCRYPTION_KEY=\"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef\"\n\n3. For Windmill, store as a secure resource\n\nThe key is 64 hex characters (32 bytes) for AES-256-GCM encryption.\nKeep this key secure - you cannot recover encrypted data without it!"
            })
        )
        .example(
            "Use in shell script",
            serde_json::json!(null),
            serde_json::json!({
                "success": true,
                "key": "fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210",
                "instructions": "To use this encryption key:\n\n1. Set the environment variable:\n   export OAUTH_ENCRYPTION_KEY=\"fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210\"\n\n2. Add to your shell profile (~/.bashrc, ~/.zshrc, etc):\n   export OAUTH_ENCRYPTION_KEY=\"fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210\"\n\n3. For Windmill, store as a secure resource\n\nThe key is 64 hex characters (32 bytes) for AES-256-GCM encryption.\nKeep this key secure - you cannot recover encrypted data without it!"
            })
        )
        .build();

    println!(
        "{}",
        serde_json::to_string_pretty(&schema).expect("Failed to serialize schema")
    );
}
