#[test]
fn tandoor_step_list_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();
    let _ = run_binary("tandoor_step_list", &input);
}

#[test]
fn tandoor_meal_type_response_format() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();

    let result = expect_success("tandoor_meal_type_list", &input);
    assert!(result.get("success").is_some());
    assert!(result.get("count").is_some());
    assert!(result.get("meal_types").is_some());
}

#[test]
fn tandoor_unit_response_format() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();

    let result = expect_success("tandoor_unit_list", &input);
    assert!(result.get("success").is_some());
    assert!(result.get("count").is_some());
    assert!(result.get("units").is_some());
}

#[test]
fn tandoor_recipe_list_invalid_auth() {
    let input = json!({
        "tandoor": {"base_url": "http://localhost:8090", "api_token": "invalid_token"}
    })
    .to_string();
    let result = run_binary("tandoor_recipe_list", &input);
    assert!(result.is_ok());
}

#[test]
fn tandoor_recipe_list_zero_page() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "page": 0
    })
    .to_string();
    let _ = run_binary("tandoor_recipe_list", &input);
}

#[test]
fn tandoor_recipe_list_large_page_size() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "page": 1,
        "page_size": 100
    })
    .to_string();
    let result = run_binary("tandoor_recipe_list", &input).unwrap();
    assert!(result["recipes"].is_array());
}
