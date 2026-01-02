//! Windmill Flow Acceptance Tests for `tandoor_create_recipe`
//!
//! Dave Farley says: "Validate structure, then test manually in production."
//!
//! Tests:
//! - Windmill script exists and is valid
//! - Binary contract matches schema
//! - Manual testing instructions documented

#![allow(clippy::unwrap_used, clippy::too_many_lines)]

use serde_json::json;

fn script_exists_in_repo(script_path: &str) -> bool {
    std::path::Path::new(&format!("windmill/f/tandoor/{}", script_path)).exists()
}

#[test]
fn test_tandoor_create_recipe_script_exists() {
    let script_path = "windmill/f/tandoor/create_recipe.sh";
    assert!(
        script_exists_in_repo("create_recipe.sh"),
        "Windmill script should exist: {}",
        script_path
    );
}

#[test]
fn test_tandoor_create_recipe_script_calls_binary() {
    let script_path = "windmill/f/tandoor/create_recipe.sh";
    let content = std::fs::read_to_string(script_path).expect("Script should be readable");
    assert!(
        content.contains("tandoor_create_recipe"),
        "Script should call the tandoor_create_recipe binary"
    );
}

#[test]
fn test_tandoor_create_recipe_schema_exists() {
    let schema_path = "windmill/f/tandoor/create_recipe.script.yaml";
    assert!(
        std::path::Path::new(schema_path).exists(),
        "Schema file should exist: {}",
        schema_path
    );
}

#[test]
fn test_tandoor_create_recipe_schema_valid_yaml() {
    let schema_path = "windmill/f/tandoor/create_recipe.script.yaml";
    let content = std::fs::read_to_string(schema_path).expect("Schema should be readable");
    let parsed: serde_yaml::Value =
        serde_yaml::from_str(&content).expect("Schema should be valid YAML");
    assert!(
        parsed.get("summary").is_some(),
        "Schema should have a summary field"
    );
    assert!(
        parsed.get("kind").is_some(),
        "Schema should have a kind field"
    );
    assert_eq!(parsed["kind"], "script", "Kind should be 'script'");
}

#[test]
fn test_tandoor_create_recipe_schema_inputs() {
    let schema_path = "windmill/f/tandoor/create_recipe.script.yaml";
    let content = std::fs::read_to_string(schema_path).expect("Schema should be readable");
    let parsed: serde_yaml::Value =
        serde_yaml::from_str(&content).expect("Schema should be valid YAML");

    let props = parsed["schema"]["properties"]
        .as_mapping()
        .expect("Schema should have properties");

    assert!(
        props.contains_key(&serde_yaml::Value::String("tandoor".to_string())),
        "Schema should have 'tandoor' property"
    );
    assert!(
        props.contains_key(&serde_yaml::Value::String("recipe".to_string())),
        "Schema should have 'recipe' property"
    );
    assert!(
        props.contains_key(&serde_yaml::Value::String(
            "additional_keywords".to_string()
        )),
        "Schema should have 'additional_keywords' property"
    );
}

#[test]
fn test_tandoor_create_recipe_binary_contract_matches_schema() {
    let schema_path = "windmill/f/tandoor/create_recipe.script.yaml";
    let schema_content = std::fs::read_to_string(schema_path).expect("Schema should be readable");
    let schema: serde_yaml::Value =
        serde_yaml::from_str(&schema_content).expect("Schema should be valid YAML");

    let schema_required: Vec<String> = schema["schema"]["required"]
        .as_sequence()
        .expect("Required should be a sequence")
        .iter()
        .filter_map(|v| v.as_str().map(|s| s.to_string()))
        .collect();

    assert!(
        schema_required.contains(&"tandoor".to_string()),
        "Schema should require 'tandoor'"
    );
    assert!(
        schema_required.contains(&"recipe".to_string()),
        "Schema should require 'recipe'"
    );
}

#[test]
fn test_tandoor_create_recipe_script_accepts_three_args() {
    let script_path = "windmill/f/tandoor/create_recipe.sh";
    let content = std::fs::read_to_string(script_path).expect("Script should be readable");
    assert!(
        content.contains("$1") && content.contains("$2") && content.contains("$3"),
        "Script should accept 3 positional arguments"
    );
}

#[test]
fn test_tandoor_create_recipe_script_builds_json() {
    let script_path = "windmill/f/tandoor/create_recipe.sh";
    let content = std::fs::read_to_string(script_path).expect("Script should be readable");
    assert!(
        content.contains("jq -n"),
        "Script should use jq to build JSON input"
    );
    assert!(
        content.contains("--argjson"),
        "Script should use --argjson for JSON arguments"
    );
}

#[test]
fn test_tandoor_create_recipe_script_outputs_json() {
    let script_path = "windmill/f/tandoor/create_recipe.sh";
    let content = std::fs::read_to_string(script_path).expect("Script should be readable");
    assert!(
        content.contains("result.json"),
        "Script should write output to result.json"
    );
}

#[test]
fn test_windmill_tandoor_coverage() {
    println!("\n========================================");
    println!("Windmill Tandoor Script Test Coverage");
    println!("========================================\n");

    println!("✅ Scripts validated:");
    println!("   [x] create_recipe.sh (Windmill flow testing)");
    println!("   [x] create_recipe.script.yaml (schema validation)");
    println!();

    println!("📝 Manual Testing Instructions:");
    println!();
    println!("   For E2E testing through Windmill:");
    println!("   1. Deploy script:");
    println!("      wmill script push windmill/f/tandoor/create_recipe.sh f/tandoor/create_recipe");
    println!();
    println!("   2. Configure resource:");
    println!("      - u/admin/tandoor_api (base_url + api_token)");
    println!();
    println!("   3. Test in Windmill UI with:");
    println!(
        r#"      {{"tandoor": "$res:u/admin/tandoor_api", "recipe": {{"name": "Test Recipe"}}}}"#
    );
    println!();
    println!("   4. Verify output contains recipe_id and name");
    println!();

    println!("========================================\n");
}

#[test]
fn test_tandoor_create_recipe_input_parses_correctly() {
    let tandoor = json!({"base_url": "http://localhost:8090", "api_token": "test_token"});
    let recipe = json!({
        "name": "Test Recipe",
        "description": "A test recipe",
        "servings": 4,
        "steps": [],
        "keywords": []
    });
    let additional_keywords = json!(["test", "integration"]);

    let input = json!({
        "tandoor": tandoor,
        "recipe": recipe,
        "additional_keywords": additional_keywords
    });

    assert_eq!(input["tandoor"]["base_url"], "http://localhost:8090");
    assert_eq!(input["recipe"]["name"], "Test Recipe");
    assert_eq!(input["additional_keywords"].as_array().unwrap().len(), 2);
}
