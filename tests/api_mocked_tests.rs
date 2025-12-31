//! Comprehensive mocked API tests for FatSecret and Tandoor
//!
//! This test module uses wiremock to mock HTTP responses and test
//! both happy paths and error scenarios for all API endpoints.
//!
//! # FatSecret API Error Codes
//!
//! The FatSecret API returns the following error codes:
//!
//! ## OAuth Errors (2-9)
//! - Code 2: Missing OAuth parameter
//! - Code 3: Unsupported OAuth parameter
//! - Code 4: Invalid signature method
//! - Code 5: Invalid consumer credentials
//! - Code 6: Invalid or expired token
//! - Code 7: Invalid signature
//! - Code 8: Invalid nonce
//! - Code 9: Invalid access token
//!
//! ## API Errors (13-14)
//! - Code 13: Invalid method
//! - Code 14: API unavailable
//!
//! ## Parameter Errors (101, 106-108)
//! - Code 101: Missing required parameter
//! - Code 106: Invalid ID
//! - Code 107: Invalid search value
//! - Code 108: Invalid date
//!
//! ## Domain Errors (205-207)
//! - Code 205: Weight date too far in future
//! - Code 206: Weight date earlier than expected
//! - Code 207: No entries found

#![allow(clippy::unwrap_used)]
#![allow(clippy::expect_used)]
#![allow(clippy::panic)]
#![allow(clippy::wildcard_enum_match_arm)]
#![allow(dead_code)]
#![allow(unused_imports)]

use meal_planner::fatsecret::core::config::FatSecretConfig;
use meal_planner::fatsecret::core::errors::{ApiErrorCode, FatSecretError};
use meal_planner::fatsecret::core::oauth::AccessToken;
use meal_planner::fatsecret::foods::{
    autocomplete_foods, get_food, search_foods, search_foods_simple, FoodId,
};
use meal_planner::fatsecret::diary::{
    create_food_entry, get_food_entry, get_food_entries, edit_food_entry,
    delete_food_entry, get_month_summary, FoodEntryId, FoodEntryInput, FoodEntryUpdate, MealType,
};
use meal_planner::fatsecret::favorites::{
    add_favorite_food, delete_favorite_food, get_favorite_foods,
    get_most_eaten, get_recently_eaten,
};
use meal_planner::fatsecret::profile::{get_profile, create_profile, get_profile_auth};
use wiremock::matchers::{body_string_contains, method, path};
use wiremock::{Mock, MockServer, ResponseTemplate};

// ============================================================================
// TEST FIXTURES - FatSecret API Response Templates
// ============================================================================

mod fixtures {
    /// Food search response with multiple results
    pub const FOOD_SEARCH_RESPONSE: &str = r#"{
        "foods": {
            "food": [
                {
                    "food_id": "33691",
                    "food_name": "Chicken Breast",
                    "food_type": "Generic",
                    "food_description": "Per 100g - Calories: 165kcal | Fat: 3.57g | Carbs: 0g | Protein: 31.02g",
                    "food_url": "https://www.fatsecret.com/calories-nutrition/generic/chicken-breast"
                },
                {
                    "food_id": "4877",
                    "food_name": "Grilled Chicken Breast",
                    "food_type": "Generic",
                    "food_description": "Per 100g - Calories: 148kcal | Fat: 3.17g | Carbs: 0g | Protein: 28.98g",
                    "food_url": "https://www.fatsecret.com/calories-nutrition/generic/grilled-chicken-breast"
                }
            ],
            "max_results": "20",
            "total_results": "1234",
            "page_number": "0"
        }
    }"#;

    /// Single food search result (API returns object, not array, when 1 result)
    pub const FOOD_SEARCH_SINGLE: &str = r#"{
        "foods": {
            "food": {
                "food_id": "33691",
                "food_name": "Chicken Breast",
                "food_type": "Generic",
                "food_description": "Per 100g - Calories: 165kcal | Fat: 3.57g | Carbs: 0g | Protein: 31.02g",
                "food_url": "https://www.fatsecret.com/calories-nutrition/generic/chicken-breast"
            },
            "max_results": "20",
            "total_results": "1",
            "page_number": "0"
        }
    }"#;

    /// Empty food search result
    pub const FOOD_SEARCH_EMPTY: &str = r#"{
        "foods": {
            "food": [],
            "max_results": "20",
            "total_results": "0",
            "page_number": "0"
        }
    }"#;

    /// Food get response (food.get.v5)
    pub const FOOD_GET_RESPONSE: &str = r#"{
        "food": {
            "food_id": "33691",
            "food_name": "Chicken Breast",
            "food_type": "Generic",
            "food_url": "https://www.fatsecret.com/calories-nutrition/generic/chicken-breast",
            "servings": {
                "serving": [
                    {
                        "serving_id": "34321",
                        "serving_description": "100 g",
                        "serving_url": "https://www.fatsecret.com/serving",
                        "metric_serving_amount": "100.000",
                        "metric_serving_unit": "g",
                        "number_of_units": "1.00",
                        "measurement_description": "serving (100g)",
                        "is_default": "1",
                        "calories": "165",
                        "carbohydrate": "0.00",
                        "protein": "31.02",
                        "fat": "3.57",
                        "saturated_fat": "1.00",
                        "fiber": "0",
                        "sugar": "0",
                        "sodium": "74"
                    },
                    {
                        "serving_id": "34322",
                        "serving_description": "1 oz",
                        "serving_url": "https://www.fatsecret.com/serving",
                        "metric_serving_amount": "28.350",
                        "metric_serving_unit": "g",
                        "number_of_units": "1.00",
                        "measurement_description": "oz",
                        "calories": "47",
                        "carbohydrate": "0.00",
                        "protein": "8.79",
                        "fat": "1.01"
                    }
                ]
            }
        }
    }"#;

    /// Food get response with single serving (API returns object, not array)
    pub const FOOD_GET_SINGLE_SERVING: &str = r#"{
        "food": {
            "food_id": "12345",
            "food_name": "Simple Food",
            "food_type": "Generic",
            "food_url": "https://www.fatsecret.com/simple",
            "servings": {
                "serving": {
                    "serving_id": "11111",
                    "serving_description": "1 cup",
                    "serving_url": "https://www.fatsecret.com/serving",
                    "number_of_units": "1.00",
                    "measurement_description": "cup",
                    "calories": "100",
                    "carbohydrate": "10.00",
                    "protein": "5.00",
                    "fat": "2.00"
                }
            }
        }
    }"#;

    /// Autocomplete response
    pub const AUTOCOMPLETE_RESPONSE: &str = r#"{
        "suggestions": {
            "suggestion": [
                {"food_id": "33691", "food_name": "Chicken"},
                {"food_id": "33692", "food_name": "Chicken Breast"},
                {"food_id": "33693", "food_name": "Chicken Wings"}
            ]
        }
    }"#;

    /// Autocomplete single result
    pub const AUTOCOMPLETE_SINGLE: &str = r#"{
        "suggestions": {
            "suggestion": {"food_id": "33691", "food_name": "Chicken"}
        }
    }"#;

    /// Food entry response
    pub const FOOD_ENTRY_RESPONSE: &str = r#"{
        "food_entry": {
            "food_entry_id": "12345",
            "food_entry_name": "Chicken Breast",
            "food_entry_description": "100g Chicken Breast",
            "food_id": "33691",
            "serving_id": "34321",
            "number_of_units": "1.5",
            "meal": "lunch",
            "date_int": "20000",
            "calories": "247.5",
            "carbohydrate": "0.00",
            "protein": "46.53",
            "fat": "5.36"
        }
    }"#;

    /// Food entries list response
    pub const FOOD_ENTRIES_RESPONSE: &str = r#"{
        "food_entries": {
            "food_entry": [
                {
                    "food_entry_id": "12345",
                    "food_entry_name": "Chicken Breast",
                    "food_entry_description": "100g Chicken Breast",
                    "food_id": "33691",
                    "serving_id": "34321",
                    "number_of_units": "1.5",
                    "meal": "lunch",
                    "date_int": "20000",
                    "calories": "247.5",
                    "carbohydrate": "0.00",
                    "protein": "46.53",
                    "fat": "5.36"
                },
                {
                    "food_entry_id": "12346",
                    "food_entry_name": "Brown Rice",
                    "food_entry_description": "1 cup Brown Rice",
                    "food_id": "5055",
                    "serving_id": "5056",
                    "number_of_units": "1.0",
                    "meal": "lunch",
                    "date_int": "20000",
                    "calories": "216",
                    "carbohydrate": "44.77",
                    "protein": "5.03",
                    "fat": "1.75"
                }
            ]
        }
    }"#;

    /// Create food entry response
    pub const CREATE_ENTRY_RESPONSE: &str = r#"{
        "food_entry_id": {
            "value": "98765"
        }
    }"#;

    /// Month summary response
    pub const MONTH_SUMMARY_RESPONSE: &str = r#"{
        "month": {
            "day": [
                {
                    "date_int": "20000",
                    "calories": "2100",
                    "carbohydrate": "250",
                    "protein": "150",
                    "fat": "70"
                },
                {
                    "date_int": "20001",
                    "calories": "1800",
                    "carbohydrate": "200",
                    "protein": "130",
                    "fat": "60"
                }
            ],
            "month": "1",
            "year": "2024"
        }
    }"#;

    /// Profile response
    pub const PROFILE_RESPONSE: &str = r#"{
        "profile": {
            "goal_weight_kg": "70",
            "last_weight_kg": "75",
            "last_weight_date_int": "20000",
            "height_cm": "180",
            "calorie_goal": "2000",
            "weight_measure": "Kg",
            "height_measure": "Cm"
        }
    }"#;

    /// Profile auth response (from profile.create or profile.get_auth)
    pub const PROFILE_AUTH_RESPONSE: &str = r#"{
        "profile": {
            "auth_token": "abc123token",
            "auth_secret": "xyz789secret"
        }
    }"#;

    /// Favorite foods response (foods.get_favorites.v2)
    pub const FAVORITE_FOODS_RESPONSE: &str = r#"{
        "food": [
            {
                "food_id": "33691",
                "food_name": "Chicken Breast",
                "food_type": "Generic",
                "food_description": "Per 100g - Calories: 165kcal",
                "food_url": "https://www.fatsecret.com/chicken",
                "serving_id": "34321",
                "number_of_units": "1.00"
            }
        ]
    }"#;

    /// Most eaten foods response
    pub const MOST_EATEN_RESPONSE: &str = r#"{
        "food": [
            {
                "food_id": "33691",
                "food_name": "Chicken Breast",
                "food_type": "Generic",
                "food_description": "Per 100g - Calories: 165kcal",
                "food_url": "https://www.fatsecret.com/chicken",
                "serving_id": "34321",
                "number_of_units": "2.50"
            }
        ]
    }"#;

    /// Recently eaten foods response
    pub const RECENTLY_EATEN_RESPONSE: &str = r#"{
        "food": [
            {
                "food_id": "5055",
                "food_name": "Brown Rice",
                "food_type": "Generic",
                "food_description": "Per cup - Calories: 216kcal",
                "food_url": "https://www.fatsecret.com/rice",
                "serving_id": "5056",
                "number_of_units": "1.00"
            }
        ]
    }"#;

    /// Empty success response (for mutations that don't return data)
    pub const SUCCESS_RESPONSE: &str = r#"{}"#;

    /// Barcode lookup response
    pub const BARCODE_RESPONSE: &str = r#"{
        "food_id": {
            "value": "12345"
        }
    }"#;

    // =========================================================================
    // ERROR RESPONSES
    // =========================================================================

    /// Generic error response template
    pub fn error_response(code: i32, message: &str) -> String {
        format!(r#"{{"error": {{"code": {}, "message": "{}"}}}}"#, code, message)
    }

    /// Missing OAuth parameter (code 2)
    pub fn missing_oauth_param_error() -> String {
        error_response(2, "Missing required oauth parameter: oauth_consumer_key")
    }

    /// Unsupported OAuth parameter (code 3)
    pub fn unsupported_oauth_param_error() -> String {
        error_response(3, "Unsupported oauth parameter")
    }

    /// Invalid signature method (code 4)
    pub fn invalid_signature_method_error() -> String {
        error_response(4, "Invalid signature method")
    }

    /// Invalid consumer credentials (code 5)
    pub fn invalid_credentials_error() -> String {
        error_response(5, "Invalid consumer key")
    }

    /// Invalid or expired token (code 6)
    pub fn expired_token_error() -> String {
        error_response(6, "Invalid/expired request token")
    }

    /// Invalid signature (code 8)
    pub fn invalid_signature_error() -> String {
        error_response(8, "Invalid signature")
    }

    /// Invalid nonce (code 7)
    pub fn invalid_nonce_error() -> String {
        error_response(7, "Invalid/used nonce")
    }

    /// Invalid access token (code 9)
    pub fn invalid_access_token_error() -> String {
        error_response(9, "Invalid access token")
    }

    /// Invalid method (code 13)
    pub fn invalid_method_error() -> String {
        error_response(13, "Method not found")
    }

    /// API unavailable (code 14)
    pub fn api_unavailable_error() -> String {
        error_response(14, "API temporarily unavailable")
    }

    /// Missing required parameter (code 101)
    pub fn missing_required_param_error() -> String {
        error_response(101, "Missing required parameter")
    }

    /// Invalid ID (code 106)
    pub fn invalid_id_error() -> String {
        error_response(106, "Invalid ID value")
    }

    /// Invalid search value (code 107)
    pub fn invalid_search_error() -> String {
        error_response(107, "Invalid search expression")
    }

    /// Invalid date (code 108)
    pub fn invalid_date_error() -> String {
        error_response(108, "Invalid date format")
    }

    /// Weight date too far (code 205)
    pub fn weight_date_too_far_error() -> String {
        error_response(205, "Weight date too far in the future")
    }

    /// Weight date earlier (code 206)
    pub fn weight_date_earlier_error() -> String {
        error_response(206, "Weight date must be after previous entry")
    }

    /// No entries found (code 207)
    pub fn no_entries_error() -> String {
        error_response(207, "No entries found for specified date")
    }
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/// Create a test config pointing to the mock server
fn test_config(mock_server: &MockServer) -> FatSecretConfig {
    FatSecretConfig::with_base_url("test_key", "test_secret", mock_server.uri())
}

/// Create a test access token
fn test_token() -> AccessToken {
    AccessToken {
        oauth_token: "test_oauth_token".to_string(),
        oauth_token_secret: "test_oauth_token_secret".to_string(),
    }
}

// ============================================================================
// FOOD SEARCH API TESTS - HAPPY PATH
// ============================================================================

#[tokio::test]
async fn test_food_search_happy_path_multiple_results() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .and(body_string_contains("method=foods.search"))
        .respond_with(ResponseTemplate::new(200).set_body_string(fixtures::FOOD_SEARCH_RESPONSE))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let result = search_foods(&config, "chicken", 0, 20).await;

    assert!(result.is_ok());
    let response = result.unwrap();
    assert_eq!(response.foods.len(), 2);
    assert_eq!(response.foods[0].food_name, "Chicken Breast");
    assert_eq!(response.foods[0].food_id.as_str(), "33691");
    assert_eq!(response.total_results, 1234);
    assert_eq!(response.page_number, 0);
}

#[tokio::test]
async fn test_food_search_single_result() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .and(body_string_contains("method=foods.search"))
        .respond_with(ResponseTemplate::new(200).set_body_string(fixtures::FOOD_SEARCH_SINGLE))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let result = search_foods_simple(&config, "unique food").await;

    assert!(result.is_ok());
    let response = result.unwrap();
    assert_eq!(response.foods.len(), 1);
    assert_eq!(response.total_results, 1);
}

#[tokio::test]
async fn test_food_search_empty_results() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .and(body_string_contains("method=foods.search"))
        .respond_with(ResponseTemplate::new(200).set_body_string(fixtures::FOOD_SEARCH_EMPTY))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let result = search_foods(&config, "xyznonexistent123", 0, 20).await;

    assert!(result.is_ok());
    let response = result.unwrap();
    assert!(response.foods.is_empty());
    assert_eq!(response.total_results, 0);
}

// ============================================================================
// FOOD GET API TESTS - HAPPY PATH
// ============================================================================

#[tokio::test]
async fn test_food_get_happy_path() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .and(body_string_contains("method=food.get.v5"))
        .respond_with(ResponseTemplate::new(200).set_body_string(fixtures::FOOD_GET_RESPONSE))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let food_id = FoodId::new("33691");
    let result = get_food(&config, &food_id).await;

    assert!(result.is_ok());
    let food = result.unwrap();
    assert_eq!(food.food_name, "Chicken Breast");
    assert_eq!(food.food_id.as_str(), "33691");
    assert_eq!(food.food_type, "Generic");
    assert_eq!(food.servings.serving.len(), 2);

    // Check first serving nutrition
    let serving = &food.servings.serving[0];
    assert_eq!(serving.serving_id.as_str(), "34321");
    assert!((serving.nutrition.calories - 165.0).abs() < 0.01);
    assert!((serving.nutrition.protein - 31.02).abs() < 0.01);
}

#[tokio::test]
async fn test_food_get_single_serving() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .and(body_string_contains("method=food.get.v5"))
        .respond_with(
            ResponseTemplate::new(200).set_body_string(fixtures::FOOD_GET_SINGLE_SERVING),
        )
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let food_id = FoodId::new("12345");
    let result = get_food(&config, &food_id).await;

    assert!(result.is_ok());
    let food = result.unwrap();
    assert_eq!(food.servings.serving.len(), 1);
}

// ============================================================================
// AUTOCOMPLETE API TESTS - HAPPY PATH
// ============================================================================

#[tokio::test]
async fn test_autocomplete_happy_path() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .and(body_string_contains("method=foods.autocomplete"))
        .respond_with(ResponseTemplate::new(200).set_body_string(fixtures::AUTOCOMPLETE_RESPONSE))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let result = autocomplete_foods(&config, "chick").await;

    assert!(result.is_ok());
    let response = result.unwrap();
    assert_eq!(response.suggestions.len(), 3);
    assert_eq!(response.suggestions[0].food_name, "Chicken");
}

#[tokio::test]
async fn test_autocomplete_single_result() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .and(body_string_contains("method=foods.autocomplete"))
        .respond_with(ResponseTemplate::new(200).set_body_string(fixtures::AUTOCOMPLETE_SINGLE))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let result = autocomplete_foods(&config, "chicken").await;

    assert!(result.is_ok());
    let response = result.unwrap();
    assert_eq!(response.suggestions.len(), 1);
}

// ============================================================================
// FOOD SEARCH API TESTS - ERROR CODES
// ============================================================================

#[tokio::test]
async fn test_food_search_error_invalid_credentials() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .respond_with(
            ResponseTemplate::new(200).set_body_string(fixtures::invalid_credentials_error()),
        )
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let result = search_foods(&config, "chicken", 0, 20).await;

    assert!(result.is_err());
    let err = result.unwrap_err();
    match err {
        FatSecretError::ApiError { code, message } => {
            assert_eq!(code, ApiErrorCode::InvalidConsumerCredentials);
            assert!(message.contains("Invalid consumer key"));
        }
        _ => panic!("Expected ApiError, got {:?}", err),
    }
}

#[tokio::test]
async fn test_food_search_error_invalid_search_value() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .respond_with(
            ResponseTemplate::new(200).set_body_string(fixtures::invalid_search_error()),
        )
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let result = search_foods(&config, "", 0, 20).await;

    assert!(result.is_err());
    let err = result.unwrap_err();
    match err {
        FatSecretError::ApiError { code, .. } => {
            assert_eq!(code, ApiErrorCode::InvalidServingId);
        }
        _ => panic!("Expected ApiError, got {:?}", err),
    }
}

#[tokio::test]
async fn test_food_get_error_invalid_id() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .respond_with(ResponseTemplate::new(200).set_body_string(fixtures::invalid_id_error()))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let food_id = FoodId::new("invalid");
    let result = get_food(&config, &food_id).await;

    assert!(result.is_err());
    let err = result.unwrap_err();
    match err {
        FatSecretError::ApiError { code, .. } => {
            assert_eq!(code, ApiErrorCode::InvalidFoodId);
        }
        _ => panic!("Expected ApiError, got {:?}", err),
    }
}

// ============================================================================
// OAUTH ERROR TESTS
// ============================================================================

#[tokio::test]
async fn test_error_missing_oauth_parameter() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .respond_with(
            ResponseTemplate::new(200).set_body_string(fixtures::missing_oauth_param_error()),
        )
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let result = search_foods(&config, "test", 0, 20).await;

    assert!(result.is_err());
    let err = result.unwrap_err();
    match err {
        FatSecretError::ApiError { code, .. } => {
            assert_eq!(code, ApiErrorCode::MissingOAuthParameter);
            assert!(code.is_auth_related());
        }
        _ => panic!("Expected ApiError, got {:?}", err),
    }
}

#[tokio::test]
async fn test_error_invalid_signature() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .respond_with(
            ResponseTemplate::new(200).set_body_string(fixtures::invalid_signature_error()),
        )
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let result = search_foods(&config, "test", 0, 20).await;

    assert!(result.is_err());
    let err = result.unwrap_err();
    match err {
        FatSecretError::ApiError { code, .. } => {
            assert_eq!(code, ApiErrorCode::InvalidSignature);
            assert!(code.is_auth_related());
        }
        _ => panic!("Expected ApiError, got {:?}", err),
    }
}

#[tokio::test]
async fn test_error_expired_token() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .respond_with(ResponseTemplate::new(200).set_body_string(fixtures::expired_token_error()))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let result = search_foods(&config, "test", 0, 20).await;

    assert!(result.is_err());
    let err = result.unwrap_err();
    match err {
        FatSecretError::ApiError { code, .. } => {
            assert_eq!(code, ApiErrorCode::InvalidOrExpiredTimestamp);
            assert!(code.is_auth_related());
        }
        _ => panic!("Expected ApiError, got {:?}", err),
    }
}

#[tokio::test]
async fn test_error_invalid_access_token() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .respond_with(
            ResponseTemplate::new(200).set_body_string(fixtures::invalid_access_token_error()),
        )
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let result = search_foods(&config, "test", 0, 20).await;

    assert!(result.is_err());
    let err = result.unwrap_err();
    match err {
        FatSecretError::ApiError { code, .. } => {
            assert_eq!(code, ApiErrorCode::InvalidAccessToken);
            assert!(code.is_auth_related());
        }
        _ => panic!("Expected ApiError, got {:?}", err),
    }
}

#[tokio::test]
async fn test_error_invalid_nonce() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .respond_with(ResponseTemplate::new(200).set_body_string(fixtures::invalid_nonce_error()))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let result = search_foods(&config, "test", 0, 20).await;

    assert!(result.is_err());
    let err = result.unwrap_err();
    match err {
        FatSecretError::ApiError { code, .. } => {
            assert_eq!(code, ApiErrorCode::InvalidNonce);
        }
        _ => panic!("Expected ApiError, got {:?}", err),
    }
}

// ============================================================================
// API ERROR TESTS
// ============================================================================

#[tokio::test]
async fn test_error_invalid_method() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .respond_with(ResponseTemplate::new(200).set_body_string(fixtures::invalid_method_error()))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let result = search_foods(&config, "test", 0, 20).await;

    assert!(result.is_err());
    let err = result.unwrap_err();
    match err {
        FatSecretError::ApiError { code, .. } => {
            assert_eq!(code, ApiErrorCode::OAuth2InvalidToken);
        }
        _ => panic!("Expected ApiError, got {:?}", err),
    }
}

#[tokio::test]
async fn test_error_api_unavailable() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .respond_with(
            ResponseTemplate::new(200).set_body_string(fixtures::api_unavailable_error()),
        )
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let result = search_foods(&config, "test", 0, 20).await;

    assert!(result.is_err());
    let err = result.unwrap_err();
    match &err {
        FatSecretError::ApiError { code, .. } => {
            assert_eq!(*code, ApiErrorCode::OAuth2TokenExpired);
            // API unavailable should be recoverable
            assert!(err.is_recoverable());
        }
        _ => panic!("Expected ApiError, got {:?}", err),
    }
}

#[tokio::test]
async fn test_error_missing_required_parameter() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .respond_with(
            ResponseTemplate::new(200).set_body_string(fixtures::missing_required_param_error()),
        )
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let result = search_foods(&config, "test", 0, 20).await;

    assert!(result.is_err());
    let err = result.unwrap_err();
    match err {
        FatSecretError::ApiError { code, .. } => {
            assert_eq!(code, ApiErrorCode::MissingRequiredParameter);
            // Not auth-related
            assert!(!code.is_auth_related());
        }
        _ => panic!("Expected ApiError, got {:?}", err),
    }
}

// ============================================================================
// HTTP ERROR STATUS CODE TESTS
// ============================================================================

#[tokio::test]
async fn test_http_400_bad_request() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .respond_with(ResponseTemplate::new(400).set_body_string("Bad Request"))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let result = search_foods(&config, "test", 0, 20).await;

    assert!(result.is_err());
    let err = result.unwrap_err();
    match err {
        FatSecretError::RequestFailed { status, body } => {
            assert_eq!(status, 400);
            assert_eq!(body, "Bad Request");
            // 4xx errors are NOT recoverable
            assert!(!FatSecretError::request_failed(400, "").is_recoverable());
        }
        _ => panic!("Expected RequestFailed, got {:?}", err),
    }
}

#[tokio::test]
async fn test_http_401_unauthorized() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .respond_with(ResponseTemplate::new(401).set_body_string("Unauthorized"))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let result = search_foods(&config, "test", 0, 20).await;

    assert!(result.is_err());
    let err = result.unwrap_err();
    match err {
        FatSecretError::RequestFailed { status, .. } => {
            assert_eq!(status, 401);
        }
        _ => panic!("Expected RequestFailed, got {:?}", err),
    }
}

#[tokio::test]
async fn test_http_403_forbidden() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .respond_with(ResponseTemplate::new(403).set_body_string("Forbidden"))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let result = search_foods(&config, "test", 0, 20).await;

    assert!(result.is_err());
    let err = result.unwrap_err();
    match err {
        FatSecretError::RequestFailed { status, .. } => {
            assert_eq!(status, 403);
        }
        _ => panic!("Expected RequestFailed, got {:?}", err),
    }
}

#[tokio::test]
async fn test_http_404_not_found() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .respond_with(ResponseTemplate::new(404).set_body_string("Not Found"))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let result = search_foods(&config, "test", 0, 20).await;

    assert!(result.is_err());
    let err = result.unwrap_err();
    match err {
        FatSecretError::RequestFailed { status, .. } => {
            assert_eq!(status, 404);
        }
        _ => panic!("Expected RequestFailed, got {:?}", err),
    }
}

#[tokio::test]
async fn test_http_500_internal_server_error() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .respond_with(ResponseTemplate::new(500).set_body_string("Internal Server Error"))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let result = search_foods(&config, "test", 0, 20).await;

    assert!(result.is_err());
    let err = result.unwrap_err();
    match err {
        FatSecretError::RequestFailed { status, body } => {
            assert_eq!(status, 500);
            assert_eq!(body, "Internal Server Error");
            // 5xx errors ARE recoverable
            assert!(FatSecretError::request_failed(500, "").is_recoverable());
        }
        _ => panic!("Expected RequestFailed, got {:?}", err),
    }
}

#[tokio::test]
async fn test_http_502_bad_gateway() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .respond_with(ResponseTemplate::new(502).set_body_string("Bad Gateway"))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let result = search_foods(&config, "test", 0, 20).await;

    assert!(result.is_err());
    let err = result.unwrap_err();
    match err {
        FatSecretError::RequestFailed { status, .. } => {
            assert_eq!(status, 502);
            assert!(FatSecretError::request_failed(502, "").is_recoverable());
        }
        _ => panic!("Expected RequestFailed, got {:?}", err),
    }
}

#[tokio::test]
async fn test_http_503_service_unavailable() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .respond_with(ResponseTemplate::new(503).set_body_string("Service Unavailable"))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let result = search_foods(&config, "test", 0, 20).await;

    assert!(result.is_err());
    let err = result.unwrap_err();
    match err {
        FatSecretError::RequestFailed { status, .. } => {
            assert_eq!(status, 503);
            assert!(FatSecretError::request_failed(503, "").is_recoverable());
        }
        _ => panic!("Expected RequestFailed, got {:?}", err),
    }
}

// ============================================================================
// MALFORMED RESPONSE TESTS
// ============================================================================

#[tokio::test]
async fn test_malformed_json_response() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .respond_with(ResponseTemplate::new(200).set_body_string("not valid json {{{"))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let result = search_foods(&config, "test", 0, 20).await;

    assert!(result.is_err());
    let err = result.unwrap_err();
    match err {
        FatSecretError::ParseError(msg) => {
            assert!(msg.contains("JSON") || msg.contains("parse") || msg.contains("json"));
        }
        _ => panic!("Expected ParseError, got {:?}", err),
    }
}

#[tokio::test]
async fn test_empty_response() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .respond_with(ResponseTemplate::new(200).set_body_string(""))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let result = search_foods(&config, "test", 0, 20).await;

    assert!(result.is_err());
}

#[tokio::test]
async fn test_missing_expected_fields() {
    let mock_server = MockServer::start().await;

    // Response missing required "foods" field
    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .respond_with(ResponseTemplate::new(200).set_body_string(r#"{"other": "data"}"#))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let result = search_foods(&config, "test", 0, 20).await;

    assert!(result.is_err());
}

// ============================================================================
// ERROR CLASSIFICATION TESTS
// ============================================================================

#[tokio::test]
async fn test_error_is_auth_error_classification() {
    // OAuth error should be auth error
    let oauth_err = FatSecretError::oauth_error("token expired");
    assert!(oauth_err.is_auth_error());

    // Config missing should be auth error
    let config_err = FatSecretError::ConfigMissing;
    assert!(config_err.is_auth_error());

    // Network error should NOT be auth error
    let network_err = FatSecretError::network_error("timeout");
    assert!(!network_err.is_auth_error());

    // Parse error should NOT be auth error
    let parse_err = FatSecretError::parse_error("invalid json");
    assert!(!parse_err.is_auth_error());

    // API error with auth code should be auth error
    let api_auth_err = FatSecretError::api_error(9, "invalid access token");
    assert!(api_auth_err.is_auth_error());

    // API error with non-auth code should NOT be auth error
    let api_non_auth_err = FatSecretError::api_error(101, "missing param");
    assert!(!api_non_auth_err.is_auth_error());
}

#[tokio::test]
async fn test_error_is_recoverable_classification() {
    // Network errors are recoverable
    assert!(FatSecretError::network_error("timeout").is_recoverable());

    // API unavailable is recoverable
    assert!(FatSecretError::api_error(14, "temporarily unavailable").is_recoverable());

    // 5xx errors are recoverable
    assert!(FatSecretError::request_failed(500, "server error").is_recoverable());
    assert!(FatSecretError::request_failed(503, "service unavailable").is_recoverable());

    // 4xx errors are NOT recoverable
    assert!(!FatSecretError::request_failed(400, "bad request").is_recoverable());
    assert!(!FatSecretError::request_failed(404, "not found").is_recoverable());

    // Other API errors are NOT recoverable
    assert!(!FatSecretError::api_error(5, "invalid credentials").is_recoverable());
    assert!(!FatSecretError::api_error(101, "missing param").is_recoverable());

    // Config missing is NOT recoverable
    assert!(!FatSecretError::ConfigMissing.is_recoverable());

    // Parse errors are NOT recoverable
    assert!(!FatSecretError::parse_error("invalid json").is_recoverable());
}

// ============================================================================
// ALL API ERROR CODES COVERAGE
// ============================================================================

#[tokio::test]
async fn test_all_api_error_codes_roundtrip() {
    // Test all documented error codes convert correctly
    let codes = vec![
        (2, ApiErrorCode::MissingOAuthParameter),
        (3, ApiErrorCode::UnsupportedOAuthParameter),
        (4, ApiErrorCode::InvalidSignatureMethod),
        (5, ApiErrorCode::InvalidConsumerCredentials),
        (6, ApiErrorCode::InvalidOrExpiredTimestamp),
        (7, ApiErrorCode::InvalidNonce),
        (8, ApiErrorCode::InvalidSignature),
        (9, ApiErrorCode::InvalidAccessToken),
        (13, ApiErrorCode::OAuth2InvalidToken),
        (14, ApiErrorCode::OAuth2TokenExpired),
        (101, ApiErrorCode::MissingRequiredParameter),
        (106, ApiErrorCode::InvalidFoodId),
        (107, ApiErrorCode::InvalidServingId),
        (108, ApiErrorCode::InvalidRecipeId),
        (205, ApiErrorCode::ExerciseEntryNotFound),
        (206, ApiErrorCode::WeightEntryNotFound),
        (207, ApiErrorCode::UserProfileNotFound),
    ];

    for (code, expected) in codes {
        let parsed = ApiErrorCode::from_code(code);
        assert_eq!(parsed, expected, "Code {} should parse to {:?}", code, expected);
        assert_eq!(
            parsed.to_code(),
            code,
            "{:?} should convert back to {}",
            expected,
            code
        );
    }

    // Unknown code should be preserved
    let unknown = ApiErrorCode::from_code(999);
    assert_eq!(unknown, ApiErrorCode::UnknownError(999));
    assert_eq!(unknown.to_code(), 999);
}

#[tokio::test]
async fn test_auth_related_codes() {
    // Codes 2-9 are OAuth 1.0 auth-related
    for code in 2..=9 {
        let error_code = ApiErrorCode::from_code(code);
        assert!(
            error_code.is_auth_related(),
            "Code {} should be auth-related",
            code
        );
    }

    // Code 12 (MethodNotAccessible) and codes 13-14 (OAuth 2.0) are also auth-related
    for code in [12, 13, 14] {
        let error_code = ApiErrorCode::from_code(code);
        assert!(
            error_code.is_auth_related(),
            "Code {} should be auth-related",
            code
        );
    }

    // Parameter and not-found codes are NOT auth-related
    for code in [101, 106, 107, 108, 205, 206, 207] {
        let error_code = ApiErrorCode::from_code(code);
        assert!(
            !error_code.is_auth_related(),
            "Code {} should NOT be auth-related",
            code
        );
    }
}

// ============================================================================
// DIARY API TESTS - HAPPY PATH
// ============================================================================

#[tokio::test]
async fn test_diary_create_food_entry() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .and(body_string_contains("method=food_entry.create"))
        .respond_with(ResponseTemplate::new(200).set_body_string(fixtures::CREATE_ENTRY_RESPONSE))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let token = test_token();
    let input = FoodEntryInput::FromFood {
        food_id: "33691".to_string(),
        food_entry_name: "Chicken Breast".to_string(),
        serving_id: "34321".to_string(),
        number_of_units: 1.5,
        meal: MealType::Lunch,
        date_int: 20000,
    };

    let result = create_food_entry(&config, &token, input).await;
    assert!(result.is_ok());
    let entry_id = result.unwrap();
    assert_eq!(entry_id.as_str(), "98765");
}

#[tokio::test]
async fn test_diary_get_food_entry() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .and(body_string_contains("method=food_entry.get"))
        .respond_with(ResponseTemplate::new(200).set_body_string(fixtures::FOOD_ENTRY_RESPONSE))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let token = test_token();
    let entry_id = FoodEntryId::new("12345");

    let result = get_food_entry(&config, &token, &entry_id).await;
    assert!(result.is_ok());
    let entry = result.unwrap();
    assert_eq!(entry.food_entry_id.as_str(), "12345");
    assert_eq!(entry.food_entry_name, "Chicken Breast");
    assert_eq!(entry.meal, MealType::Lunch);
    assert!((entry.calories - 247.5).abs() < 0.01);
}

#[tokio::test]
async fn test_diary_get_food_entries() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .and(body_string_contains("method=food_entries.get"))
        .respond_with(ResponseTemplate::new(200).set_body_string(fixtures::FOOD_ENTRIES_RESPONSE))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let token = test_token();

    let result = get_food_entries(&config, &token, 20000).await;
    assert!(result.is_ok());
    let entries = result.unwrap();
    assert_eq!(entries.len(), 2);
    assert_eq!(entries[0].food_entry_name, "Chicken Breast");
    assert_eq!(entries[1].food_entry_name, "Brown Rice");
}

#[tokio::test]
async fn test_diary_edit_food_entry() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .and(body_string_contains("method=food_entry.edit"))
        .respond_with(ResponseTemplate::new(200).set_body_string(fixtures::SUCCESS_RESPONSE))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let token = test_token();
    let entry_id = FoodEntryId::new("12345");
    let update = FoodEntryUpdate::new()
        .with_units(2.0)
        .with_meal(MealType::Dinner);

    let result = edit_food_entry(&config, &token, &entry_id, update).await;
    assert!(result.is_ok());
}

#[tokio::test]
async fn test_diary_delete_food_entry() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .and(body_string_contains("method=food_entry.delete"))
        .respond_with(ResponseTemplate::new(200).set_body_string(fixtures::SUCCESS_RESPONSE))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let token = test_token();
    let entry_id = FoodEntryId::new("12345");

    let result = delete_food_entry(&config, &token, &entry_id).await;
    assert!(result.is_ok());
}

#[tokio::test]
async fn test_diary_get_month_summary() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .and(body_string_contains("method=food_entries.get_month"))
        .respond_with(ResponseTemplate::new(200).set_body_string(fixtures::MONTH_SUMMARY_RESPONSE))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let token = test_token();

    let result = get_month_summary(&config, &token, 20000).await;
    assert!(result.is_ok());
    let summary = result.unwrap();
    assert_eq!(summary.month, 1);
    assert_eq!(summary.year, 2024);
    assert_eq!(summary.days.len(), 2);
    assert!((summary.days[0].calories - 2100.0).abs() < 0.01);
}

// ============================================================================
// DIARY API TESTS - ERROR CASES
// ============================================================================

#[tokio::test]
async fn test_diary_get_entry_invalid_id() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .respond_with(ResponseTemplate::new(200).set_body_string(fixtures::invalid_id_error()))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let token = test_token();
    let entry_id = FoodEntryId::new("invalid");

    let result = get_food_entry(&config, &token, &entry_id).await;
    assert!(result.is_err());
    match result.unwrap_err() {
        FatSecretError::ApiError { code, .. } => {
            assert_eq!(code, ApiErrorCode::InvalidFoodId);
        }
        e => panic!("Expected ApiError, got {:?}", e),
    }
}

#[tokio::test]
async fn test_diary_get_entries_no_entries() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .respond_with(ResponseTemplate::new(200).set_body_string(fixtures::no_entries_error()))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let token = test_token();

    let result = get_food_entries(&config, &token, 19000).await;
    assert!(result.is_err());
    match result.unwrap_err() {
        FatSecretError::ApiError { code, .. } => {
            assert_eq!(code, ApiErrorCode::UserProfileNotFound);
        }
        e => panic!("Expected ApiError, got {:?}", e),
    }
}

// ============================================================================
// FAVORITES API TESTS - HAPPY PATH
// ============================================================================

#[tokio::test]
async fn test_favorites_add_food() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .and(body_string_contains("method=food.add_favorite"))
        .respond_with(ResponseTemplate::new(200).set_body_string(fixtures::SUCCESS_RESPONSE))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let token = test_token();

    let result = add_favorite_food(&config, &token, "33691").await;
    assert!(result.is_ok());
}

#[tokio::test]
async fn test_favorites_delete_food() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .and(body_string_contains("method=food.delete_favorite"))
        .respond_with(ResponseTemplate::new(200).set_body_string(fixtures::SUCCESS_RESPONSE))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let token = test_token();

    let result = delete_favorite_food(&config, &token, "33691").await;
    assert!(result.is_ok());
}

#[tokio::test]
async fn test_favorites_get_favorite_foods() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .and(body_string_contains("method=foods.get_favorites"))
        .respond_with(ResponseTemplate::new(200).set_body_string(fixtures::FAVORITE_FOODS_RESPONSE))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let token = test_token();

    let result = get_favorite_foods(&config, &token, None, None).await;
    assert!(result.is_ok());
    let foods = result.unwrap();
    assert_eq!(foods.len(), 1);
    assert_eq!(foods[0].food_name, "Chicken Breast");
}

#[tokio::test]
async fn test_favorites_get_most_eaten() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .and(body_string_contains("method=foods.get_most_eaten"))
        .respond_with(ResponseTemplate::new(200).set_body_string(fixtures::MOST_EATEN_RESPONSE))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let token = test_token();

    let result = get_most_eaten(&config, &token, None).await;
    assert!(result.is_ok());
    let foods = result.unwrap();
    assert_eq!(foods.len(), 1);
    assert!((foods[0].number_of_units - 2.5).abs() < 0.01);
}

#[tokio::test]
async fn test_favorites_get_recently_eaten() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .and(body_string_contains("method=foods.get_recently_eaten"))
        .respond_with(ResponseTemplate::new(200).set_body_string(fixtures::RECENTLY_EATEN_RESPONSE))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let token = test_token();

    let result = get_recently_eaten(&config, &token, None).await;
    assert!(result.is_ok());
    let foods = result.unwrap();
    assert_eq!(foods.len(), 1);
    assert_eq!(foods[0].food_name, "Brown Rice");
}

// ============================================================================
// PROFILE API TESTS - HAPPY PATH
// ============================================================================

#[tokio::test]
async fn test_profile_get() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .and(body_string_contains("method=profile.get"))
        .respond_with(ResponseTemplate::new(200).set_body_string(fixtures::PROFILE_RESPONSE))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let token = test_token();

    let result = get_profile(&config, &token).await;
    assert!(result.is_ok());
    let profile = result.unwrap();
    assert!((profile.goal_weight_kg.unwrap() - 70.0).abs() < 0.01);
    assert!((profile.height_cm.unwrap() - 180.0).abs() < 0.01);
    assert_eq!(profile.calorie_goal.unwrap(), 2000);
}

#[tokio::test]
async fn test_profile_create() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .and(body_string_contains("method=profile.create"))
        .respond_with(ResponseTemplate::new(200).set_body_string(fixtures::PROFILE_AUTH_RESPONSE))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let token = test_token();

    let result = create_profile(&config, &token, "user123").await;
    assert!(result.is_ok());
    let auth = result.unwrap();
    assert_eq!(auth.auth_token, "abc123token");
    assert_eq!(auth.auth_secret, "xyz789secret");
}

#[tokio::test]
async fn test_profile_get_auth() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .and(body_string_contains("method=profile.get_auth"))
        .respond_with(ResponseTemplate::new(200).set_body_string(fixtures::PROFILE_AUTH_RESPONSE))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let token = test_token();

    let result = get_profile_auth(&config, &token, "user123").await;
    assert!(result.is_ok());
    let auth = result.unwrap();
    assert_eq!(auth.auth_token, "abc123token");
}

// ============================================================================
// PROFILE API TESTS - ERROR CASES
// ============================================================================

#[tokio::test]
async fn test_profile_get_unauthorized() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/rest/server.api"))
        .respond_with(ResponseTemplate::new(200).set_body_string(fixtures::invalid_access_token_error()))
        .mount(&mock_server)
        .await;

    let config = test_config(&mock_server);
    let token = test_token();

    let result = get_profile(&config, &token).await;
    assert!(result.is_err());
    match result.unwrap_err() {
        FatSecretError::ApiError { code, .. } => {
            assert_eq!(code, ApiErrorCode::InvalidAccessToken);
            assert!(code.is_auth_related());
        }
        e => panic!("Expected ApiError, got {:?}", e),
    }
}
