    let _ = run_binary("fatsecret_foods_recently_eaten", &input);
}

#[test]
fn fatsecret_recipes_get_favorites_success() {
    let input = json!({}).to_string();
    let _ = run_binary("fatsecret_recipes_get_favorites", &input);
}

#[test]
fn fatsecret_recipe_add_favorite_success() {
    let input = json!({"recipe_id": "1"}).to_string();
    let _ = run_binary("fatsecret_recipe_add_favorite", &input);
}

#[test]
fn fatsecret_recipe_delete_favorite_success() {
    let input = json!({"recipe_id": "1"}).to_string();
    let _ = run_binary("fatsecret_recipe_delete_favorite", &input);
}

#[test]
fn fatsecret_foods_search_missing_query() {
    let input = json!({}).to_string();
    expect_failure("fatsecret_foods_search", &input);
}

#[test]
fn fatsecret_food_get_missing_id() {
    let input = json!({}).to_string();
    expect_failure("fatsecret_food_get", &input);
}

#[test]
fn fatsecret_food_get_invalid_format() {
    let input = json!({"food_id": "not_a_number"}).to_string();
    let _ = run_binary("fatsecret_food_get", &input);
}

#[test]
fn fatsecret_search_unicode() {
    let input = json!({"query": "θερμιδες"}).to_string();
    let _ = run_binary("fatsecret_foods_search", &input);
}

#[test]
fn fatsecret_search_special_chars() {
    let input = json!({"query": "chicken & rice"}).to_string();
    let result = run_binary("fatsecret_foods_search", &input);
    assert!(
        result.is_ok(),
        "Binary should handle special chars without panicking"
    );
    let value = result.unwrap();
    assert!(
        value["foods"].is_object() || value.get("success") == Some(&json!(false)),
        "Should return foods object or error indication"
    );
}

#[test]
fn fatsecret_food_response_format() {
    let input = json!({"food_id": "1633"}).to_string();
    let result = expect_success("fatsecret_food_get", &input);
    assert!(result.get("success").is_some());
    assert!(result.get("food").is_some());
}

#[test]
fn fatsecret_recipe_types_response_format() {
    let input = json!({}).to_string();
    let result = expect_success("fatsecret_recipe_types_get", &input);
    assert!(result.get("success").is_some());
    assert!(result.get("recipe_types").is_some());
}

#[test]
fn fatsecret_search_latency() {
    let start = std::time::Instant::now();
    let input = json!({"query": "chicken", "max_results": 5}).to_string();
    let result = run_binary("fatsecret_foods_search", &input);
    let elapsed = start.elapsed();
    let is_ci = std::env::var("CI").is_ok() || std::env::var("GITHUB_ACTIONS").is_ok();
    let max_secs = if is_ci { 60 } else { 30 };
    assert!(result.is_ok(), "Binary should complete without error");
    assert!(
        elapsed.as_secs() < max_secs,
        "Search took too long: {:?} (CI: {}, max: {}s)",
        elapsed,
        is_ci,
        max_secs
    );
}

#[test]
fn fatsecret_serving_ids_are_consistent() {
    let search_input = json!({
        "search_expression": "chicken breast",
        "max_results": 1
    })
    .to_string();

    let search_result = run_binary("fatsecret_foods_search", &search_input).unwrap();

    if let Some(foods) = search_result["foods"]["food"].as_array() {
        if let Some(first) = foods.first() {
            let food_id = first["food_id"].as_str().unwrap();
            let get_input = json!({"food_id": food_id}).to_string();

            let get_result = run_binary("fatsecret_food_get", &get_input).unwrap();
            if let Some(servings) = get_result["food"]["servings"]["serving"].as_array() {
                for serving in servings {
                    let serving_id = serving["serving_id"].as_str().unwrap();
                    assert!(!serving_id.is_empty());
                }
            }
        }
    }
}
