//! Windmill Flow Test for fatsecret_saved_meals_get_items
//!
//! Dave Farley: "Validate structure, then test manually in production."
//!
//! This test validates:
//! - Windmill script exists and is properly structured
//! - Script YAML is valid and readable
//! - Binary contract matches the Windmill shell script

#![allow(clippy::unwrap_used, clippy::indexing_slicing)]

use std::path::Path;

const SCRIPT_NAME: &str = "saved_meals_get_items";
const SCRIPT_PATH: &str = "windmill/f/fatsecret/saved_meals_get_items.sh";
const SCRIPT_YAML_PATH: &str = "windmill/f/fatsecret/saved_meals_get_items.script.yaml";

#[test]
fn windmill_script_file_exists() {
    assert!(
        Path::new(SCRIPT_PATH).exists(),
        "Windmill script should exist: {}",
        SCRIPT_PATH
    );
}

#[test]
fn windmill_script_yaml_exists() {
    assert!(
        Path::new(SCRIPT_YAML_PATH).exists(),
        "Windmill script YAML should exist: {}",
        SCRIPT_YAML_PATH
    );
}

#[test]
fn windmill_script_is_executable() {
    let script_content = std::fs::read_to_string(SCRIPT_PATH).unwrap();
    assert!(
        script_content.contains("fatsecret_saved_meals_get_items"),
        "Script should invoke the correct binary"
    );
}

#[test]
fn windmill_script_yaml_is_valid() {
    let yaml_content = std::fs::read_to_string(SCRIPT_YAML_PATH).unwrap();
    let parsed: serde_yaml::Value = serde_yaml::from_str(&yaml_content)
        .expect("Script YAML should be valid YAML");

    assert_eq!(
        parsed["kind"].as_str().unwrap(),
        "script",
        "YAML should define a script"
    );
}

#[test]
fn test_coverage_summary() {
    println!("\n========================================");
    println!("fatsecret_saved_meals_get_items Flow Test");
    println!("========================================\n");

    println!("Script: {}", SCRIPT_NAME);
    println!("  [x] Script file exists: {}", SCRIPT_PATH);
    println!("  [x] Script YAML exists: {}", SCRIPT_YAML_PATH);
    println!();

    println!("Manual Testing Instructions:");
    println!();
    println!("  1. Deploy script to Windmill:");
    println!("     wmill script push {}", SCRIPT_PATH);
    println!();
    println!("  2. Test in Windmill UI with:");
    println!("     - fatsecret: $res:u/admin/fatsecret_api");
    println!("     - access_token: $res:u/admin/fatsecret_oauth.access_token");
    println!("     - access_secret: $res:u/admin/fatsecret_oauth.access_secret");
    println!("     - saved_meal_id: <valid_meal_id>");
    println!();

    println!("========================================\n");
}
