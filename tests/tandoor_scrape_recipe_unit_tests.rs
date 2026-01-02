//! Unit Tests for `tandoor_scrape_recipe` Flow Logic
//!
//! Tests the pure core functions that validate and transform flow data.
//! All functions ≤25 lines - Functional Core / Imperative Shell pattern.

#![allow(clippy::unwrap_used, clippy::expect_used)]

use serde_json::json;

#[derive(Debug, Clone)]
struct ScrapeRecipeInput {
    tandoor: String,
    url: String,
}

#[derive(Debug, PartialEq)]
struct ScrapeRecipeOutput {
    success: bool,
    recipe_json: Option<serde_json::Value>,
    images: Option<Vec<String>>,
    error: Option<String>,
}

fn validate_url(url: &str) -> Result<(), String> {
    if url.is_empty() {
        return Err("URL cannot be empty".to_string());
    }
    if !url.starts_with("http://") && !url.starts_with("https://") {
        return Err("URL must start with http:// or https://".to_string());
    }
    Ok(())
}

fn parse_input(raw: &serde_json::Value) -> Result<ScrapeRecipeInput, String> {
    let tandoor = raw["tandoor"]
        .as_str()
        .ok_or("Missing tandoor")?
        .to_string();
    let url = raw["url"].as_str().ok_or("Missing url")?.to_string();
    validate_url(&url)?;
    Ok(ScrapeRecipeInput { tandoor, url })
}

fn build_success_output(recipe: serde_json::Value, images: Vec<String>) -> ScrapeRecipeOutput {
    ScrapeRecipeOutput {
        success: true,
        recipe_json: Some(recipe),
        images: Some(images),
        error: None,
    }
}

fn build_error_output(msg: String) -> ScrapeRecipeOutput {
    ScrapeRecipeOutput {
        success: false,
        recipe_json: None,
        images: None,
        error: Some(msg),
    }
}

fn extract_recipe_name(recipe: &serde_json::Value) -> Option<String> {
    recipe["name"].as_str().map(|s| s.to_string())
}

fn count_recipe_steps(recipe: &serde_json::Value) -> usize {
    recipe["steps"].as_array().map(|s| s.len()).unwrap_or(0)
}

fn has_keywords(recipe: &serde_json::Value) -> bool {
    recipe["keywords"]
        .as_array()
        .map(|k| !k.is_empty())
        .unwrap_or(false)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_validate_url_valid_https() {
        assert!(validate_url("https://example.com/recipe").is_ok());
    }

    #[test]
    fn test_validate_url_valid_http() {
        assert!(validate_url("http://example.com/recipe").is_ok());
    }

    #[test]
    fn test_validate_url_empty() {
        assert!(validate_url("").is_err());
    }

    #[test]
    fn test_validate_url_no_protocol() {
        assert!(validate_url("example.com/recipe").is_err());
    }

    #[test]
    fn test_parse_input_valid() {
        let input = json!({
            "tandoor": "$res:u/admin/tandoor",
            "url": "https://example.com/recipe"
        });
        let result = parse_input(&input);
        assert!(result.is_ok());
        let parsed = result.unwrap();
        assert_eq!(parsed.tandoor, "$res:u/admin/tandoor");
        assert_eq!(parsed.url, "https://example.com/recipe");
    }

    #[test]
    fn test_parse_input_missing_tandoor() {
        let input = json!({"url": "https://example.com"});
        assert!(parse_input(&input).is_err());
    }

    #[test]
    fn test_parse_input_missing_url() {
        let input = json!({"tandoor": "test"});
        assert!(parse_input(&input).is_err());
    }

    #[test]
    fn test_parse_input_invalid_url() {
        let input = json!({
            "tandoor": "test",
            "url": "invalid-url"
        });
        assert!(parse_input(&input).is_err());
    }

    #[test]
    fn test_build_success_output() {
        let recipe = json!({"name": "Test Recipe"});
        let images = vec!["img1.jpg".to_string(), "img2.jpg".to_string()];
        let output = build_success_output(recipe.clone(), images.clone());
        assert!(output.success);
        assert_eq!(output.recipe_json, Some(recipe));
        assert_eq!(output.images, Some(images));
        assert!(output.error.is_none());
    }

    #[test]
    fn test_build_error_output() {
        let output = build_error_output("Test error".to_string());
        assert!(!output.success);
        assert!(output.recipe_json.is_none());
        assert!(output.images.is_none());
        assert_eq!(output.error, Some("Test error".to_string()));
    }

    #[test]
    fn test_extract_recipe_name() {
        let recipe = json!({"name": "BBQ Ribs"});
        assert_eq!(extract_recipe_name(&recipe), Some("BBQ Ribs".to_string()));
    }

    #[test]
    fn test_extract_recipe_name_missing() {
        let recipe = json!({});
        assert_eq!(extract_recipe_name(&recipe), None);
    }

    #[test]
    fn test_count_recipe_steps() {
        let recipe = json!({
            "steps": [
                {"instruction": "Step 1"},
                {"instruction": "Step 2"},
                {"instruction": "Step 3"}
            ]
        });
        assert_eq!(count_recipe_steps(&recipe), 3);
    }

    #[test]
    fn test_count_recipe_steps_empty() {
        let recipe = json!({"steps": []});
        assert_eq!(count_recipe_steps(&recipe), 0);
    }

    #[test]
    fn test_count_recipe_steps_missing() {
        let recipe = json!({});
        assert_eq!(count_recipe_steps(&recipe), 0);
    }

    #[test]
    fn test_has_keywords_true() {
        let recipe = json!({"keywords": [{"name": "dinner"}, {"name": "spicy"}]});
        assert!(has_keywords(&recipe));
    }

    #[test]
    fn test_has_keywords_false() {
        let recipe = json!({"keywords": []});
        assert!(!has_keywords(&recipe));
    }

    #[test]
    fn test_has_keywords_missing() {
        let recipe = json!({});
        assert!(!has_keywords(&recipe));
    }

    #[test]
    fn test_full_scrape_recipe_validation() {
        let input = json!({
            "tandoor": "$res:u/admin/tandoor",
            "url": "https://allrecipes.com/recipe/24470"
        });

        let parsed = parse_input(&input).expect("Should parse valid input");

        assert!(validate_url(&parsed.url).is_ok());
        assert!(!parsed.tandoor.is_empty());
    }

    #[test]
    fn test_error_output_with_scraping_error() {
        let error_msg = "Failed to parse recipe: unsupported format";
        let output = build_error_output(error_msg.to_string());
        assert!(!output.success);
        assert!(output.error.unwrap().contains("Failed to parse"));
    }
}
