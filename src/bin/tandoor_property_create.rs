//! Create a property in Tandoor
//!
//! JSON input: `{"tandoor": {...}, "property_amount": 100.0, "property_type": 1}`
//! JSON stdout: `{"success": true, "property": {...}}`

#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{CreatePropertyRequest, TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    tandoor: TandoorConfig,
    property_amount: f64,
    property_type: i64,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    property: Option<serde_json::Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    let output = match run() {
        Ok(o) => o,
        Err(e) => Output {
            success: false,
            property: None,
            error: Some(e.to_string()),
        },
    };
    println!("{}", serde_json::to_string(&output).unwrap());
    if !output.success {
        std::process::exit(1);
    }
}

fn run() -> anyhow::Result<Output> {
    let input: Input = if let Some(arg) = std::env::args().nth(1) {
        serde_json::from_str(&arg)?
    } else {
        let mut input_str = String::new();
        io::stdin().read_to_string(&mut input_str)?;
        serde_json::from_str(&input_str)?
    };

    let request = CreatePropertyRequest {
        property_amount: input.property_amount,
        property_type: input.property_type,
    };

    let client = TandoorClient::new(&input.tandoor)?;
    let result = client.create_property(&request)?;

    Ok(Output {
        success: true,
        property: Some(serde_json::to_value(result)?),
        error: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_parsing() {
        let json = r#"{"tandoor": {"base_url": "http://localhost", "api_token": "test"}, "property_amount": 250.5, "property_type": 1}"#;
        let input: Input = serde_json::from_str(json).unwrap();
        assert!((input.property_amount - 250.5).abs() < f64::EPSILON);
        assert_eq!(input.property_type, 1);
    }
}
