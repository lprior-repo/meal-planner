//! Test Tandoor API connection
//!
//! JSON stdin (Windmill format):
//!   `{"tandoor": {"base_url": "...", "api_token": "..."}}`
//!
//! JSON stdin (standalone format):
//!   `{"base_url": "...", "api_token": "..."}`
//!
//! JSON stdout: `{"success": true, "message": "...", "recipe_count": N}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{TandoorClient, TandoorConfig};
use serde::Deserialize;
use std::io::{self, Read};

/// Input wrapper supporting both Windmill and standalone formats
#[derive(Deserialize)]
struct Input {
    /// Windmill resource format (optional)
    tandoor: Option<TandoorConfig>,
    /// Standalone format fields (optional)
    base_url: Option<String>,
    api_token: Option<String>,
}

fn main() {
    match run() {
        Ok(output) => println!("{}", serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON")),
        Err(e) => {
            println!("{{\"success\":false,\"error\":\"{e}\"}}");
            std::process::exit(1);
        }
    }
}

fn run() -> anyhow::Result<serde_json::Value> {
    let mut input = String::new();
    io::stdin().read_to_string(&mut input)?;

    let parsed: Input = serde_json::from_str(&input)?;

    // Support both Windmill format (nested) and standalone format (flat)
    let config = match parsed.tandoor {
        Some(c) => c,
        None => TandoorConfig {
            base_url: parsed
                .base_url
                .ok_or_else(|| anyhow::anyhow!("base_url required"))?,
            api_token: parsed
                .api_token
                .ok_or_else(|| anyhow::anyhow!("api_token required"))?,
        },
    };

    let client = TandoorClient::new(&config)?;
    let result = client.test_connection()?;

    Ok(serde_json::to_value(result)?)
}
