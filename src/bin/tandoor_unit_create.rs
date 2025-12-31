//! Create a new unit in Tandoor
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "name": "kg", "plural_name": "kilograms"}`
//!
//! JSON stdout: `{"success": true, "id": 123, "name": "kg"}`
//!   or on error: `{"success": false, "error": "..."}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{CreateUnitRequestData, TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    /// Tandoor configuration
    tandoor: TandoorConfig,
    /// Unit name
    name: String,
    /// Plural name (optional)
    #[serde(default)]
    plural_name: Option<String>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    id: Option<i64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    match run() {
        Ok(output) => {
            println!("{}", serde_json::to_string(&output).unwrap());
        }
        Err(e) => {
            let error = Output {
                success: false,
                id: None,
                name: None,
                error: Some(e.to_string()),
            };
            println!("{}", serde_json::to_string(&error).unwrap());
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

    let request = CreateUnitRequestData {
        name: input.name.clone(),
        plural_name: input.plural_name.clone(),
    };

    let created = client.create_unit(&request)?;

    Ok(Output {
        success: true,
        id: Some(created.id),
        name: Some(created.name),
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
            id: Some(42),
            name: Some("kg".to_string()),
            error: None,
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"id\":42"));
        assert!(json.contains("kg"));
    }

    #[test]
    fn test_error_output_serialization() {
        let output = Output {
            success: false,
            id: None,
            name: None,
            error: Some("unit already exists".to_string()),
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("unit already exists"));
    }
}
