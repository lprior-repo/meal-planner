//! Update a property type in Tandoor
//!
//! JSON input: `{"tandoor": {...}, "property_type_id": 123, "name": "...", "unit": "..."}`
//! JSON stdout: `{"success": true, "property_type": {...}}`

#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{TandoorClient, TandoorConfig, UpdatePropertyTypeRequest};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    tandoor: TandoorConfig,
    property_type_id: i64,
    #[serde(default)]
    name: Option<String>,
    #[serde(default)]
    unit: Option<String>,
    #[serde(default)]
    description: Option<String>,
    #[serde(default)]
    order: Option<i32>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    property_type: Option<serde_json::Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    let output = match run() {
        Ok(o) => o,
        Err(e) => Output {
            success: false,
            property_type: None,
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

    let request = UpdatePropertyTypeRequest {
        name: input.name,
        unit: input.unit,
        description: input.description,
        order: input.order,
        category: None,
    };

    let client = TandoorClient::new(&input.tandoor)?;
    let result = client.update_property_type(input.property_type_id, &request)?;

    Ok(Output {
        success: true,
        property_type: Some(serde_json::to_value(result)?),
        error: None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_input_parsing() {
        let json = r#"{"tandoor": {"base_url": "http://localhost", "api_token": "test"}, "property_type_id": 1, "name": "Updated"}"#;
        let input: Input = serde_json::from_str(json).unwrap();
        assert_eq!(input.property_type_id, 1);
        assert_eq!(input.name, Some("Updated".to_string()));
    }
}
