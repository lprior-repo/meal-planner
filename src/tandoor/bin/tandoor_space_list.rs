//! List all spaces in Tandoor
//!
//! Retrieves all user workspaces/spaces from the Tandoor API.
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}}`
//!
//! JSON stdout: `{"success": true, "spaces": [...]}`
//!   or `{"success": false, "error": "..."}`
//!
//! This binary uses the TandoorClient to make real API calls.

// CLI binaries: exit and unwrap/expect are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::tandoor::{Space, TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    tandoor: TandoorConfig,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    spaces: Option<Vec<Space>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

/// Functional wrapper for space listing that follows Railway-Oriented Programming patterns
fn list_spaces_with_validation(input: Input) -> Result<Output, Box<dyn std::error::Error>> {
    // Step 1: Validate input (no validation needed for this operation)
    let _validated_input = validate_list_input(input)?;

    // Step 2: Create client
    let client = TandoorClient::new(&_validated_input.tandoor)?;

    // Step 3: Call API with proper error handling
    let spaces = client.list_spaces()?;

    Ok(Output {
        success: true,
        spaces: Some(spaces),
        error: None,
    })
}

fn validate_list_input(input: Input) -> Result<Input, Box<dyn std::error::Error>> {
    // No validation needed for list operation - just return the input
    Ok(input)
}

fn main() {
    let output = match run() {
        Ok(o) => o,
        Err(e) => Output {
            success: false,
            spaces: None,
            error: Some(e.to_string()),
        },
    };
    println!(
        "{}",
        serde_json::to_string(&output).expect("Failed to serialize output JSON")
    );
    if !output.success {
        std::process::exit(1);
    }
}

fn run() -> Result<Output, Box<dyn std::error::Error>> {
    let input: Input = if let Some(arg) = std::env::args().nth(1) {
        serde_json::from_str(&arg)?
    } else {
        let mut input_str = String::new();
        io::stdin().read_to_string(&mut input_str)?;
        serde_json::from_str(&input_str)?
    };

    list_spaces_with_validation(input)
}
