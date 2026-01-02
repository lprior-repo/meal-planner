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
