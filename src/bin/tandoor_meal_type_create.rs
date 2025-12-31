//! Create a new meal type in Tandoor
//!
//! Creates a new meal type with the provided details.
//!
//! JSON stdin:
//!   {"tandoor": {...}, "name": "Breakfast", "order": 0, "time": "08:00", "color": null, "default": false}
//!
//! JSON stdout:
//!   {"success": true, "meal_type": {...}}
//!   {"success": false, "error": "..."}

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{CreateMealTypeRequest, MealType, TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    tandoor: TandoorConfig,
    name: String,
    #[serde(default)]
    order: Option<i32>,
    #[serde(default)]
    time: Option<String>,
    #[serde(default)]
    color: Option<String>,
    #[serde(default)]
    default: Option<bool>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    meal_type: Option<MealType>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    match run() {
        Ok(output) => println!("{}", serde_json::to_string(&output).unwrap()),
        Err(e) => {
            let error = Output {
                success: false,
                meal_type: None,
                error: Some(e.to_string()),
            };
            println!("{}", serde_json::to_string(&error).unwrap());
            std::process::exit(1);
        }
    }
}

fn run() -> anyhow::Result<Output> {
    let mut input = String::new();
    io::stdin().read_to_string(&mut input)?;

    let parsed: Input = serde_json::from_str(&input)?;
    let client = TandoorClient::new(&parsed.tandoor)?;

    let request = CreateMealTypeRequest {
        name: parsed.name,
        order: parsed.order,
        time: parsed.time,
        color: parsed.color,
        default: parsed.default,
    };

    let meal_type = client.create_meal_type(&request)?;

    Ok(Output {
        success: true,
        meal_type: Some(meal_type),
        error: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_parsing_minimal() {
        let json = "{\"tandoor\": {\"base_url\": \"http://localhost:8090\", \"api_token\": \"test\"}, \"name\": \"Breakfast\"}";
        let parsed: Input = serde_json::from_str(json).unwrap();
        assert_eq!(parsed.name, "Breakfast");
        assert_eq!(parsed.order, None);
    }

    #[test]
    fn test_input_parsing_full() {
        let json = "{\"tandoor\": {\"base_url\": \"http://localhost:8090\", \"api_token\": \"test\"}, \"name\": \"Breakfast\", \"order\": 1, \"time\": \"08:00\", \"color\": \"#FF0000\", \"default\": true}";
        let parsed: Input = serde_json::from_str(json).unwrap();
        assert_eq!(parsed.name, "Breakfast");
        assert_eq!(parsed.order, Some(1));
        assert_eq!(parsed.time, Some("08:00".to_string()));
        assert_eq!(parsed.default, Some(true));
    }

    #[test]
    fn test_output_serialization() {
        let output = Output {
            success: true,
            meal_type: None,
            error: None,
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":true"));
    }
}
