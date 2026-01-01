//! Parse ingredient text from Tandoor
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "text": "2 cups flour"}`
//!
//! JSON stdout: `{"success": true, "ingredient": {...}}`
//!   or on error: `{"success": false, "error": "..."}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{
    IngredientFromStringRequest, ParsedIngredient, TandoorClient, TandoorConfig,
};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    /// Tandoor configuration
    tandoor: TandoorConfig,
    /// Ingredient text to parse
    text: String,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    ingredient: Option<ParsedIngredient>,
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
                ingredient: None,
                error: Some(e.to_string()),
            };
            println!("{}", serde_json::to_string(serde_json::to_string(&error).expect("Unexpected None value")error).expect("Failed to serialize error JSON"));
            std::process::exit(1);
        }
    }
}

fn run() -> anyhow::Result<Output> {
    // Read input: prefer CLI arg, fall back to stdin
    let input: Input = if let Some(arg) = std::env::args().nth(1) {
        serde_json::from_str(&arg)?
    } else {
        let mut input_str = String::new();
        io::stdin().read_to_string(&mut input_str)?;
        serde_json::from_str(&input_str)?
    };

    let client = TandoorClient::new(&input.tandoor)?;

    let request = IngredientFromStringRequest { text: input.text };

    let result = client.ingredient_from_string(&request)?;

    Ok(Output {
        success: true,
        ingredient: Some(result),
        error: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_output_serialization() {
        let output = Output {
            success: true,
            ingredient: None,
            error: None,
        };
        let json = serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":true"));
    }

    #[test]
    fn test_error_output_serialization() {
        let output = Output {
            success: false,
            ingredient: None,
            error: Some("invalid text".to_string()),
        };
        let json = serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("invalid text"));
    }
}
