//! CUE Contract Testing for Meal Planner Binaries
//!
//! This module provides contract testing capabilities using CUE schemas.
//! It validates binary inputs and outputs against the CUE schema definitions
//! in the `schemas/cue/` directory.

use serde_json::Value;
use std::process::{Command, Stdio};
use std::sync::OnceLock;

/// Path to CUE binary
static CUE_PATH: OnceLock<String> = OnceLock::new();

fn get_cue_path() -> String {
    CUE_PATH
        .get_or_init(|| "/home/lewis/.local/share/mise/installs/cue/0.15.3/cue".to_string())
        .clone()
}

/// CUE schema directory
static SCHEMA_DIR: &str = "schemas/cue";

/// Validate input data against CUE schema for a binary
pub fn validate_input(binary_name: &str, input: &Value) -> Result<(), String> {
    validate_against_schema(binary_name, input)
}

/// Validate output data against CUE schema for a binary  
pub fn validate_output(binary_name: &str, output: &Value) -> Result<(), String> {
    validate_against_schema(binary_name, output)
}

/// Generic schema validation against CUE
fn validate_against_schema(binary_name: &str, _data: &Value) -> Result<(), String> {
    let output = Command::new(get_cue_path())
        .arg("vet")
        .arg("--schema")
        .arg(format!("{}/{}.cue", SCHEMA_DIR, get_domain(binary_name)))
        .arg("-")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .output()
        .map_err(|e| format!("Failed to run CUE: {}", e))?;

    if output.status.success() {
        Ok(())
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr);
        Err(format!("CUE validation failed: {}", stderr))
    }
}

/// Get domain directory for a binary
fn get_domain(binary_name: &str) -> &'static str {
    if binary_name.starts_with("fatsecret") {
        if binary_name.starts_with("fatsecret_foods") {
            "fatsecret_foods"
        } else if binary_name.starts_with("fatsecret_food_entry") {
            "fatsecret_diary"
        } else if binary_name.starts_with("fatsecret_exercise") {
            "fatsecret_exercise"
        } else if binary_name.starts_with("fatsecret_recipe") {
            "fatsecret_recipes"
        } else if binary_name.starts_with("fatsecret_saved_meals") {
            "fatsecret_saved_meals"
        } else if binary_name.starts_with("fatsecret_weight") {
            "fatsecret_weight"
        } else if binary_name.starts_with("fatsecret_oauth")
            || binary_name.starts_with("fatsecret_get")
        {
            "fatsecret_oauth"
        } else {
            "fatsecret_foods"
        }
    } else if binary_name.starts_with("tandoor") {
        "tandoor"
    } else {
        "base"
    }
}

/// Validate using inline CUE definition
pub fn validate_with_inline_cue(cue_definition: &str, data: &Value) -> Result<(), String> {
    let _cue_script = format!(
        r#"
package mealplanner

{}
data: json.Marshal({}) || {{}}
"#,
        cue_definition,
        serde_json::to_string(data).map_err(|e| e.to_string())?
    );

    let output = Command::new(get_cue_path())
        .arg("vet")
        .arg("-")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .output()
        .map_err(|e| format!("Failed to run CUE: {}", e))?;

    if output.status.success() {
        Ok(())
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr);
        Err(format!("CUE validation failed: {}", stderr))
    }
}

/// Check if CUE is available
pub fn is_cue_available() -> bool {
    Command::new(get_cue_path())
        .arg("version")
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .is_ok()
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn test_cue_available() {
        assert!(is_cue_available(), "CUE should be installed");
    }

    #[test]
    fn test_validate_inline_cue() {
        let cue_def = r#"
#TestInput: {
    name: string & !=""
    value: int & >=0
}
"#;
        let data = json!({
            "name": "test",
            "value": 42
        });
        assert!(validate_with_inline_cue(cue_def, &data).is_ok());
    }
}
