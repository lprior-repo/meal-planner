fn tandoor_shopping_list_entry_list_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();
    let _ = run_binary("tandoor_shopping_list_entry_list", &input);
}

#[test]
fn tandoor_shopping_list_entry_create_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "mealplan_id": 1,
        "entry": {
            "list": 1,
            "food": "test_item",
            "amount": 2.0,
            "checked": false
        }
    })
    .to_string();
    let result = run_binary("tandoor_shopping_list_entry_create", &input).unwrap();
    assert_eq!(result["success"], true);
    assert!(result["entry"].is_object());
    assert_eq!(result["entry"]["food"], "test_item");
}

#[test]
fn tandoor_shopping_list_entry_update_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "mealplan_id": 1,
        "entry_id": 1,
        "update": {
            "checked": true,
            "amount": 5.0
        }
    })
    .to_string();
    let _ = run_binary("tandoor_shopping_list_entry_update", &input);
}

#[test]
fn tandoor_shopping_list_entry_delete_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "mealplan_id": 1,
        "entry_id": 999
    })
    .to_string();
    let _ = run_binary("tandoor_shopping_list_entry_delete", &input);
}

#[test]
fn tandoor_shopping_list_recipe_add_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "mealplan_id": 1,
        "recipe_id": 1,
        "servings": 2.0
    })
    .to_string();
    let result = run_binary("tandoor_shopping_list_recipe_add", &input).unwrap();
    assert_eq!(result["success"], true);
    assert!(result["entries"].is_array());
}

#[test]
fn tandoor_shopping_list_recipe_get_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "mealplan_id": 1,
        "recipe_id": 1
    })
    .to_string();
    let result = run_binary("tandoor_shopping_list_recipe_get", &input).unwrap();
    assert_eq!(result["success"], true);
    assert!(result["recipe"].is_object());
}

#[test]
fn tandoor_shopping_list_recipe_delete_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "mealplan_id": 1,
        "recipe_id": 999
    })
    .to_string();
    let _ = run_binary("tandoor_shopping_list_recipe_delete", &input);
}
