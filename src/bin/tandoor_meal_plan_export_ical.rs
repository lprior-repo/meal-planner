//! Export meal plan as iCalendar format
//!
//! Exports a meal plan with all its meals as an iCalendar (.ics) file format string.
//!
//! JSON input (CLI arg or stdin):
//!   `{"tandoor": {...}, "id": 123}`
//!
//! JSON stdout:
//!   `{"success": true, "ical": "BEGIN:VCALENDAR\n..."}`
//!   `{"success": false, "error": "..."}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    /// Tandoor configuration
    tandoor: TandoorConfig,
    /// Meal plan ID to export
    id: i64,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    ical: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    let output = match run() {
        Ok(ical) => Output {
            success: true,
            ical: Some(ical),
            error: None,
        },
        Err(e) => Output {
            success: false,
            ical: None,
            error: Some(e.to_string()),
        },
    };
    println!("{}", serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON"));
    if !output.success {
        std::process::exit(1);
    }
}

fn run() -> Result<String, Box<dyn std::error::Error>> {
    // Read input: prefer CLI arg, fall back to stdin
    let input: Input = if let Some(arg) = std::env::args().nth(1) {
        serde_json::from_str(&arg)?
    } else {
        let mut input_str = String::new();
        io::stdin().read_to_string(&mut input_str)?;
        serde_json::from_str(&input_str)?
    };

    let client = TandoorClient::new(&input.tandoor)?;
    let ical = client.export_meal_plan_ical(input.id)?;

    Ok(ical)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_deserialization() {
        let json =
            r#"{"tandoor": {"base_url": "http://localhost:8090", "api_token": "test"}, "id": 42}"#;
        let input: Input = serde_json::from_str(json).expect("Failed to parse test JSON");
        assert_eq!(input.id, 42);
    }

    #[test]
    fn test_output_serialization_success() {
        let ical = "BEGIN:VCALENDAR\nVERSION:2.0\nPRODID:-//Tandoor//EN\nEND:VCALENDAR".to_string();
        let output = Output {
            success: true,
            ical: Some(ical),
            error: None,
        };
        let json = serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("BEGIN:VCALENDAR"));
    }

    #[test]
    fn test_output_serialization_error() {
        let output = Output {
            success: false,
            ical: None,
            error: Some("Meal plan not found".to_string()),
        };
        let json = serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON");
        assert!(json.contains("\"success\":false"));
        assert!(json.contains("Meal plan not found"));
    }
}
