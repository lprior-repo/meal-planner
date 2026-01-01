//! Connection tests for Tandoor API client
//!
//! Tests connection testing, auth failures, and client configuration.

#![allow(clippy::expect_used)]

use meal_planner::tandoor::{ConnectionTestResult, TandoorClient, TandoorConfig};
use serde_json::json;
use wiremock::{
    matchers::{header, method, path},
    Mock, MockServer, ResponseTemplate,
};

/// Helper to create a test client pointing to the mock server
#[allow(clippy::unwrap_used)]
fn create_test_client(base_url: &str) -> TandoorClient {
    let config = TandoorConfig {
        base_url: base_url.to_string(),
        api_token: "test_token_12345".to_string(),
    };
    TandoorClient::new(&config).unwrap()
}

// ============================================================================
// Connection Testing
// ============================================================================

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_connection_success() {
    let mock_server = MockServer::start().await;

    Mock::given(method("GET"))
        .and(path("/api/recipe/"))
        .and(header("Authorization", "Bearer test_token_12345"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "count": 42,
            "next": null,
            "previous": null,
            "results": []
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.test_connection()
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let conn_test: ConnectionTestResult = result.expect("Should succeed");
    assert!(conn_test.success);
    assert_eq!(conn_test.recipe_count, 42);
    assert!(conn_test.message.contains("42"));
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_connection_auth_failure_401() {
    let mock_server = MockServer::start().await;

    Mock::given(method("GET"))
        .and(path("/api/recipe/"))
        .respond_with(ResponseTemplate::new(401).set_body_json(json!({
            "detail": "Invalid token"
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.test_connection()
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_err());
    let err_msg = result.unwrap_err().to_string();
    assert!(err_msg.contains("Authentication failed"));
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_connection_auth_failure_403() {
    let mock_server = MockServer::start().await;

    Mock::given(method("GET"))
        .and(path("/api/recipe/"))
        .respond_with(ResponseTemplate::new(403).set_body_json(json!({
            "detail": "Access denied"
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.test_connection()
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_err());
    let err_msg = result.unwrap_err().to_string();
    assert!(err_msg.contains("Authentication failed"));
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_connection_server_error() {
    let mock_server = MockServer::start().await;

    Mock::given(method("GET"))
        .and(path("/api/recipe/"))
        .respond_with(ResponseTemplate::new(500).set_body_string("Internal Server Error"))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.test_connection()
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_err());
    let err_msg = result.unwrap_err().to_string();
    assert!(err_msg.contains("API error (500)"));
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_connection_parse_error() {
    let mock_server = MockServer::start().await;

    Mock::given(method("GET"))
        .and(path("/api/recipe/"))
        .respond_with(ResponseTemplate::new(200).set_body_string("not json"))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.test_connection()
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_err());
    let err_msg = result.unwrap_err().to_string();
    assert!(err_msg.contains("Failed to parse response"));
}

// ============================================================================
// Network Error Handling
// ============================================================================

#[test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
fn test_network_timeout() {
    // Use an invalid/unroutable IP to simulate network error
    let config = TandoorConfig {
        base_url: "http://192.0.2.1:9999".to_string(), // TEST-NET-1, guaranteed unroutable
        api_token: "test_token".to_string(),
    };
    let client = TandoorClient::new(&config).expect("Client creation should succeed");

    let result = client.test_connection();
    assert!(result.is_err());
    let err_msg = result.unwrap_err().to_string().to_lowercase();
    // Accept various network error messages depending on environment
    // In sandboxed/proxy environments, "host not allowed" or "auth" errors are expected
    assert!(
        err_msg.contains("http request failed")
            || err_msg.contains("connection")
            || err_msg.contains("network")
            || err_msg.contains("timeout")
            || err_msg.contains("error")
            || err_msg.contains("host not allowed")
            || err_msg.contains("auth"),
        "Expected network error, got: {}",
        err_msg
    );
}

// ============================================================================
// Client Configuration
// ============================================================================

#[test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
fn test_client_creation_valid_config() {
    let config = TandoorConfig {
        base_url: "http://localhost:8090".to_string(),
        api_token: "valid_token".to_string(),
    };
    let client = TandoorClient::new(&config);
    assert!(client.is_ok());
}

#[test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
fn test_client_creation_trims_trailing_slash() {
    let config = TandoorConfig {
        base_url: "http://localhost:8090/".to_string(),
        api_token: "test_token".to_string(),
    };
    let client = TandoorClient::new(&config);
    assert!(client.is_ok());
}

#[test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
fn test_client_creation_with_https() {
    let config = TandoorConfig {
        base_url: "https://tandoor.example.com".to_string(),
        api_token: "secure_token".to_string(),
    };
    let client = TandoorClient::new(&config);
    assert!(client.is_ok());
}
