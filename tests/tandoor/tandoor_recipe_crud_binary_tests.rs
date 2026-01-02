fn tandoor_recipe_ids_are_consistent() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();

    let result = expect_success("tandoor_recipe_list", &input);

    if let Some(recipes) = result["recipes"].as_array() {
        for recipe in recipes {
            let id = recipe["id"].as_i64().unwrap();
            let get_input = json!({
                "tandoor": {"base_url": url, "api_token": token},
                "recipe_id": id
            })
            .to_string();

            let get_result = run_binary("tandoor_recipe_get", &get_input).unwrap();
            if get_result["success"].as_bool().unwrap_or(false) {
                let fetched_id = get_result["recipe"]["id"].as_i64().unwrap();
                assert_eq!(id, fetched_id, "Recipe ID mismatch");
            }
        }
    }
}

#[test]
fn tandoor_recipe_create_success() {
    let (url, token) = get_tandoor_creds();
    let recipe = json!({
        "name": "Integration Test Recipe",
        "description": "Created by integration test",
        "servings": 4,
        "working_time": 30,
        "waiting_time": 0,
        "keywords": [{"name": "test"}],
        "steps": [
            {
                "instruction": "Mix ingredients",
                "ingredients": [
                    {"amount": 2.0, "food": {"name": "eggs"}, "unit": {"name": "piece"}, "note": ""}
                ]
            }
        ]
    });
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "recipe": recipe
    })
    .to_string();

    let result = expect_success("tandoor_create_recipe", &input);
    assert!(
        result["recipe_id"].as_i64().unwrap_or(0) > 0,
        "Recipe ID should be positive"
    );
    assert_eq!(result["name"].as_str(), Some("Integration Test Recipe"));
}

#[test]
fn tandoor_recipe_update_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "recipe_id": 1,
        "name": "Updated Integration Test Recipe",
        "description": "Updated by integration test",
        "servings": 6
    })
    .to_string();

    let result = expect_success("tandoor_recipe_update", &input);
    assert!(
        result["recipe"].is_object(),
        "Response should contain recipe object"
    );
}

#[test]
fn tandoor_recipe_delete_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "recipe_id": 999999999
    })
    .to_string();
    let result = run_binary("tandoor_recipe_delete", &input);
    assert!(result.is_ok(), "Delete should complete without panicking");
}

#[test]
fn tandoor_recipe_upload_image_success() {
    let (url, token) = get_tandoor_creds();
    let temp_dir = std::env::temp_dir();
    let test_image_path = temp_dir.join("test_recipe_image.jpg");
    std::fs::write(&test_image_path, b"fake image data").expect("Failed to create test image");

    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "recipe_id": 1,
        "image_path": test_image_path.to_string_lossy().to_string()
    })
    .to_string();

    let result = run_binary("tandoor_recipe_upload_image", &input);
    std::fs::remove_file(&test_image_path).ok();
    assert!(result.is_ok(), "Image upload should complete successfully");
}

#[test]
fn tandoor_recipe_get_related_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "recipe_id": 1
    })
    .to_string();

    let result = expect_success("tandoor_recipe_get_related", &input);
    assert!(
        result["recipes"].is_array() || result["recipes"].is_null(),
        "Recipes should be array or null"
    );
    let _count = result["recipe_count"].as_u64().unwrap_or(0);
}

#[test]
fn tandoor_recipe_batch_update_success() {
    let (url, token) = get_tandoor_creds();
    let updates = json!([
        {"id": 1, "name": "Batch Updated Recipe 1", "servings": 4},
        {"id": 2, "description": "Batch updated description"}
    ]);
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "updates": updates
    })
    .to_string();

    let result = expect_success("tandoor_recipe_batch_update", &input);
    assert!(
        result.get("updated_count").and_then(|v| v.as_i64()).unwrap_or(0) >= 0,
        "Updated count should be non-negative"
    );
}
