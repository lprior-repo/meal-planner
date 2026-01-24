//! Get a single space from Tandoor
//!
//! Retrieves a specific user workspace/space by ID from the Tandoor API.
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "id": 123}`
//!
//! JSON stdout: `{"success": true, "space": {...}}`
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
    id: i64,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    space: Option<Space>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

/// Functional wrapper for space get that follows Railway-Oriented Programming patterns
fn get_space_with_validation(input: Input) -> Result<Output, Box<dyn std::error::Error>> {
    // Step 1: Validate input
    let validated_input = validate_get_input(input)?;

    // Step 2: Create client
    let client = TandoorClient::new(&validated_input.tandoor)?;

    // Step 3: Call API with proper error handling
    let space = client.get_space(validated_input.id)?;

    Ok(Output {
        success: true,
        space: Some(space),
        error: None,
    })
}

fn validate_get_input(input: Input) -> Result<Input, Box<dyn std::error::Error>> {
    if input.id <= 0 {
        return Err("Space ID must be positive".into());
    }

    Ok(input)
}

fn main() {
    let output = match run() {
        Ok(o) => o,
        Err(e) => Output {
            success: false,
            space: None,
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

    get_space_with_validation(input)
}
