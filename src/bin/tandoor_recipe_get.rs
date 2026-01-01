//! Get recipe details from Tandoor by ID
//!
//! Retrieves full recipe information including all ingredients and steps
//! from the Tandoor API.
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "recipe_id": 123}`
//!
//! JSON stdout: `{"success": true, "recipe": {...}}`
//!   or `{"success": false, "error": "..."}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    /// Tandoor configuration (URL and token)
    tandoor: TandoorConfig,
    /// Recipe ID to retrieve
    recipe_id: i64,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    recipe: Option<Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    match run() {
        Ok(output) => {
            println!("{}", serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON"));
        }
        Err(e) => {
            let error = Output {
                success: false,
                recipe: None,
                error: Some(e.to_string()),
            };
            println!("{}", serde_json::to_string(serde_json::to_string(&error).expect("Unexpected None value")error).expect("Failed to serialize error JSON"));
            std::process::exit(1);
        }
    }
}

fn run() -> Result<Output, Box<dyn std::error::Error>> {
    // Read input: prefer CLI arg, fall back to stdin
    let input: Input = if let Some(arg) = std::env::args().nth(1) {
        serde_json::from_str(&arg)?
    } else {
        let mut input_str = String::new();
        io::stdin().read_to_string(&mut input_str)?;
        serde_json::from_str(&input_str)?
    };

    let client = TandoorClient::new(&input.tandoor)?;
    let recipe = client.get_recipe(input.recipe_id)?;

    Ok(Output {
        success: true,
        recipe: Some(recipe),
        error: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_output_serialize() {
        let output = Output {
            success: true,
            recipe: None,
            error: None,
        };
        let json = serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":true"));
        assert!(!json.contains("\"recipe\""));
    }

    #[test]
    fn test_error_output_serialize() {
        let output = Output {
            success: false,
            recipe: None,
            error: Some("Recipe not found".to_string()),
        };
        let json = serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("\"error\""));
        assert!(!json.contains("\"recipe\""));
    }
}
