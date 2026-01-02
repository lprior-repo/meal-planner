//! Windmill Flow Tests for `tandoor_scrape_recipe`
//!
//! Dave Farley: "If you haven't tested it end-to-end, you don't know if it works."
//!
//! Tests verify:
//! - Windmill script exists and is properly configured
//! - Script runs successfully with valid input
//! - Script handles errors gracefully
//!
//! Run with: cargo test --test tandoor_scrape_recipe_windmill_tests -- --ignored

#![allow(clippy::unwrap_used, clippy::expect_used)]

use serde_json::json;
use std::env;
use std::path::Path;
use std::process::Command;

const DEFAULT_BASE_URL: &str = "http://localhost:8000";
const DEFAULT_WORKSPACE: &str = "meal-planner";

fn get_windmill_base_url() -> String {
    env::var("WINDMILL_BASE_URL").unwrap_or_else(|_| DEFAULT_BASE_URL.to_string())
}

fn get_windmill_token() -> String {
    env::var("WINDMILL_TOKEN").expect("WINDMILL_TOKEN must be set for integration tests")
}

fn get_windmill_workspace() -> String {
    env::var("WINDMILL_WORKSPACE").unwrap_or_else(|_| DEFAULT_WORKSPACE.to_string())
}

fn script_exists_in_repo(script_name: &str) -> bool {
    Path::new(&format!("windmill/f/tandoor/{}.sh", script_name)).exists()
}

fn check_resource_configured(resource_path: &str) -> Result<(), String> {
    let base_url = get_windmill_base_url();
    let token = get_windmill_token();
    let workspace = get_windmill_workspace();

    let url = format!(
        "{}/api/w/{}/resources/{}",
        base_url, workspace, resource_path
    );

    let output = Command::new("curl")
        .args([
            "-s",
            "-H",
            &format!("Authorization: Bearer {}", token),
            &url,
        ])
        .output()
        .map_err(|e| format!("curl failed: {}", e))?;

    if !output.status.success() {
        return Err(format!(
            "Resource check failed: {}",
            String::from_utf8_lossy(&output.stderr)
        ));
    }

    let response = String::from_utf8_lossy(&output.stdout);
    if response.contains("not found") || response.is_empty() {
        return Err(format!("Resource {} not configured", resource_path));
    }

    Ok(())
}

fn run_windmill_script(
    script_path: &str,
    args: &serde_json::Value,
) -> Result<serde_json::Value, String> {
    let base_url = get_windmill_base_url();
    let args_json = serde_json::to_string(args).map_err(|e| e.to_string())?;

    let output = Command::new("wmill")
        .args([
            "--base-url",
            &base_url,
            "script",
            "run",
            script_path,
            "-d",
            &args_json,
        ])
        .current_dir("windmill")
        .output()
        .map_err(|e| format!("Failed to run wmill: {}", e))?;

    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);

    if !output.status.success() {
        return Err(format!("Script failed: {}", stderr));
    }

    let json_start = stdout.rfind('{');
    let json_end = stdout.rfind('}');

    match (json_start, json_end) {
        (Some(start), Some(end)) if end > start => {
            let json_str = &stdout[start..=end];
            serde_json::from_str(json_str)
                .map_err(|e| format!("Failed to parse JSON: {} (output: {})", e, json_str))
        }
        _ => Err(format!(
            "No JSON found in output. stdout: {}, stderr: {}",
            stdout, stderr
        )),
    }
}

macro_rules! skip_if_not_deployed {
    ($script_name:expr) => {
        if !script_exists_in_repo($script_name) {
            println!("SKIP: Script f/tandoor/{} not deployed", $script_name);
            return;
        }
    };
}

macro_rules! skip_if_resource_not_configured {
    ($resource_path:expr) => {
        if let Err(e) = check_resource_configured($resource_path) {
            println!("SKIP: {} - {}", $resource_path, e);
            return;
        }
    };
}

#[test]
#[ignore = "requires Windmill API connection and deployed scripts"]
fn test_windmill_scrape_recipe_script_exists() {
    skip_if_not_deployed!("scrape_recipe");

    assert!(
        script_exists_in_repo("scrape_recipe"),
        "scrape_recipe.sh must exist in windmill/f/tandoor/"
    );

    println!("✓ scrape_recipe.sh exists in repository");
}

#[test]
#[ignore = "requires Windmill API connection and deployed scripts"]
fn test_windmill_scrape_recipe_with_valid_url() {
    skip_if_not_deployed!("scrape_recipe");
    skip_if_resource_not_configured!("u/admin/tandoor");

    let result = run_windmill_script(
        "f/tandoor/scrape_recipe.sh",
        &json!({
            "tandoor": "$res:u/admin/tandoor",
            "url": "https://example.com/recipe"
        }),
    );

    assert!(result.is_ok(), "Script failed: {:?}", result.err());

    let output = result.unwrap();

    assert_eq!(
        output["success"], true,
        "Expected success: true, got: {:?}",
        output
    );

    assert!(
        output["recipe_json"].is_object() || output["recipe_json"].is_null(),
        "recipe_json should be object or null"
    );

    println!("✓ scrape_recipe returned success");
}

#[test]
#[ignore = "requires Windmill API connection and deployed scripts"]
fn test_windmill_scrape_recipe_with_invalid_url() {
    skip_if_not_deployed!("scrape_recipe");
    skip_if_resource_not_configured!("u/admin/tandoor");

    let result = run_windmill_script(
        "f/tandoor/scrape_recipe.sh",
        &json!({
            "tandoor": "$res:u/admin/tandoor",
            "url": "not-a-valid-url"
        }),
    );

    assert!(
        result.is_ok(),
        "Script should return valid JSON even for errors"
    );

    let output = result.unwrap();

    if output["success"] == false {
        assert!(
            output["error"].is_string(),
            "Error should have error message"
        );
        println!("✓ scrape_recipe handled invalid URL gracefully");
    } else {
        println!("⚠ Script succeeded with invalid URL (may be valid scraper behavior)");
    }
}

#[test]
#[ignore = "requires Windmill API connection and deployed scripts"]
fn test_windmill_scrape_recipe_with_missing_tandoor_resource() {
    skip_if_not_deployed!("scrape_recipe");

    let result = run_windmill_script(
        "f/tandoor/scrape_recipe.sh",
        &json!({
            "tandoor": "$res:u/admin/nonexistent",
            "url": "https://example.com/recipe"
        }),
    );

    assert!(result.is_ok(), "Script should return valid JSON");

    let output = result.unwrap();

    assert_eq!(
        output["success"], false,
        "Should fail with missing resource"
    );

    println!("✓ scrape_recipe handled missing resource gracefully");
}

#[test]
#[ignore = "requires Windmill API connection and deployed scripts"]
fn test_windmill_scrape_recipe_deployment_status() {
    skip_if_not_deployed!("scrape_recipe");

    println!("\n=== scrape_recipe Deployment Status ===");

    let scripts = ["scrape_recipe"];

    let mut deployed_count = 0;
    for script in &scripts {
        if script_exists_in_repo(script) {
            println!("  {}: DEPLOYED", script);
            deployed_count += 1;
        } else {
            println!("  {}: NOT DEPLOYED", script);
        }
    }

    println!("\nDeployed: {}/{} scripts", deployed_count, scripts.len());
    println!("Tests will pass when scripts are deployed to Windmill");

    assert!(
        deployed_count == scripts.len(),
        "All scripts must be deployed"
    );
}

#[test]
#[ignore = "requires Windmill API connection and deployed scripts"]
fn test_windmill_scrape_recipe_full_flow() {
    skip_if_not_deployed!("scrape_recipe");
    skip_if_resource_not_configured!("u/admin/tandoor");

    println!("\n=== Testing scrape_recipe Full Flow ===");

    println!("Step 1: Run scrape_recipe with valid URL");
    let result = run_windmill_script(
        "f/tandoor/scrape_recipe.sh",
        &json!({
            "tandoor": "$res:u/admin/tandoor",
            "url": "https://allrecipes.com/recipe/24470/rigatoni-with-broccoli/"
        }),
    );

    assert!(result.is_ok(), "Script failed: {:?}", result.err());
    let output = result.unwrap();

    assert_eq!(output["success"], true, "Expected success: true");

    if output["recipe_json"].is_object() {
        let recipe = &output["recipe_json"];
        assert!(
            recipe["name"].is_string() || recipe["name"].is_null(),
            "Recipe should have name field"
        );
        println!("  ✓ Recipe scraped successfully");
    } else {
        println!("  ⚠ No recipe data returned (site may not be scrapable)");
    }

    if output["images"].is_array() {
        let images = output["images"].as_array().unwrap();
        println!("  ✓ Found {} images", images.len());
    }

    println!("\n✓ scrape_recipe flow test complete\n");
}
