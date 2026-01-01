//! List properties from Tandoor
//!
//! Retrieves all property values (nutrition values attached to foods/recipes)
//!
//! JSON input: `{"tandoor": {...}, "page": 1, "page_size": 50}`
//! JSON stdout: `{"success": true, "count": N, "properties": [...]}`

#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::tandoor::{TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    tandoor: TandoorConfig,
    #[serde(default)]
    page: Option<u32>,
    #[serde(default)]
    page_size: Option<u32>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    count: Option<i64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    properties: Option<Vec<serde_json::Value>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    let output = match run() {
        Ok(o) => o,
        Err(e) => Output {
            success: false,
            count: None,
            properties: None,
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

    let client = TandoorClient::new(&input.tandoor)?;
    let result = client.list_properties(input.page, input.page_size)?;

    Ok(Output {
        success: true,
        count: Some(result.count),
        properties: Some(
            result
                .results
                .into_iter()
                .map(|p| serde_json::to_value(p).unwrap())
                .collect(),
        ),
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
            count: Some(10),
            properties: Some(vec![]),
            error: None,
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(json.contains("\"success\":true"));
    }
}
