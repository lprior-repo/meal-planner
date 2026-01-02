//! Layer 3: Protocol Drivers (Adapters)
//!
//! Dave Farley: "Separate the functional core from the imperative shell."
//!
//! ## GATE-3: Protocol Drivers as Pure Functions
//!
//! Protocol drivers are adapters that translate between:
//! - DSL domain operations (Layer 2)
//! - External systems (HTTP, database, filesystem)
//!
//! ## Principles
//!
//! 1. **Single Responsibility**: Each driver handles ONE protocol
//! 2. **Pure Where Possible**: Separate pure functions from I/O
//! 3. **Translation Only**: Convert between formats, don't add logic
//! 4. **Testable**: Can be mocked for Layer 2 tests
//!
//! ## Structure
//!
//! ```
//! Layer 2 (DSL) ─────► Protocol Driver ─────► External System
//!                    (Layer 3)
//!                         │
//!                    ┌────▼────┐
//!                    │  Pure   │  ◄── Testable core
//!                    │ Functions│
//!                    └─────────┘
//! ```

use async_trait::async_trait;
use serde::{Deserialize, Serialize};
use serde_json::Value;

pub mod fatsecret_driver;
pub mod tandoor_driver;

/// HTTP Protocol Types
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HttpRequest {
    pub method: HttpMethod,
    pub url: String,
    pub headers: Vec<(String, String)>,
    pub body: Option<Value>,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum HttpMethod {
    GET,
    POST,
    PUT,
    DELETE,
    PATCH,
}

/// HTTP Response Types
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HttpResponse {
    pub status_code: u16,
    pub headers: Vec<(String, String)>,
    pub body: Value,
}

/// Database Protocol Types
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DbQuery {
    pub query: String,
    pub params: Vec<Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DbResult {
    pub rows: Vec<Value>,
    pub affected_rows: usize,
}

/// Binary Protocol Types
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BinaryInput {
    pub action: String,
    pub payload: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BinaryOutput {
    pub success: bool,
    pub data: Value,
    pub error: Option<String>,
}

/// Protocol Driver Trait
///
/// All protocol drivers implement this trait.
/// This enables:
/// - Testing DSL without real external systems
/// - Swapping implementations (HTTP ↔ Binary ↔ Database)
/// - Clear separation of concerns
#[async_trait::async_trait]
pub trait ProtocolDriver: Send + Sync {
    type Request;
    type Response;

    async fn execute(&self, request: Self::Request) -> Result<Self::Response, ProtocolError>;
}

/// Protocol Driver Error
#[derive(Debug, Clone)]
pub struct ProtocolError {
    pub protocol: String,
    pub operation: String,
    pub message: String,
    pub is_retryable: bool,
}

impl ProtocolError {
    pub fn new(protocol: &str, operation: &str, message: &str, is_retryable: bool) -> Self {
        Self {
            protocol: protocol.to_string(),
            operation: operation.to_string(),
            message: message.to_string(),
            is_retryable,
        }
    }
}

impl std::fmt::Display for ProtocolError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "[{}:{}] {} (retryable: {})",
            self.protocol, self.operation, self.message, self.is_retryable
        )
    }
}

impl std::error::Error for ProtocolError {}

/// Result type for protocol operations
pub type ProtocolResult<T> = Result<T, ProtocolDriverError>;

#[derive(Debug)]
pub enum ProtocolDriverError {
    Connection(String),
    Authentication(String),
    Validation(String),
    Timeout(String),
    ResponseParse(String),
    Unknown(String),
}

impl std::fmt::Display for ProtocolDriverError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ProtocolDriverError::Connection(msg) => write!(f, "Connection: {}", msg),
            ProtocolDriverError::Authentication(msg) => write!(f, "Auth: {}", msg),
            ProtocolDriverError::Validation(msg) => write!(f, "Validation: {}", msg),
            ProtocolDriverError::Timeout(msg) => write!(f, "Timeout: {}", msg),
            ProtocolDriverError::ResponseParse(msg) => write!(f, "Parse: {}", msg),
            ProtocolDriverError::Unknown(msg) => write!(f, "Unknown: {}", msg),
        }
    }
}

impl std::error::Error for ProtocolDriverError {}

/// FatSecret API Protocol Driver
pub mod fatsecret_driver {
    use super::*;

    const BASE_URL: &str = "https://platform.fatsecret.com/rest/server.api";

    #[derive(Debug)]
    pub struct FatSecretDriver {
        consumer_key: String,
        consumer_secret: String,
        oauth_token: Option<String>,
        oauth_secret: Option<String>,
        http_client: reqwest::Client,
    }

    impl FatSecretDriver {
        pub fn new(
            consumer_key: &str,
            consumer_secret: &str,
            oauth_token: Option<&str>,
            oauth_secret: Option<&str>,
        ) -> Self {
            Self {
                consumer_key: consumer_key.to_string(),
                consumer_secret: consumer_secret.to_string(),
                oauth_token: oauth_token.map(|s| s.to_string()),
                oauth_secret: oauth_secret.map(|s| s.to_string()),
                http_client: reqwest::Client::new(),
            }
        }

        pub async fn search_foods(&self, query: &str) -> Result<Value, ProtocolDriverError> {
            let mut params = vec![
                ("method", "foods.search"),
                ("search_expression", query),
                ("format", "json"),
            ];

            let response = self.execute_signed_request("GET", BASE_URL, &params).await?;
            Ok(response.body)
        }

        pub async fn get_food(&self, food_id: &str) -> Result<Value, ProtocolDriverError> {
            let mut params = vec![
                ("method", "food.get"),
                ("food_id", food_id),
                ("format", "json"),
            ];

            let response = self.execute_signed_request("GET", BASE_URL, &params).await?;
            Ok(response.body)
        }

        async fn execute_signed_request(
            &self,
            method: &str,
            url: &str,
            params: &[(&str, &str)],
        ) -> Result<HttpResponse, ProtocolDriverError> {
            let signed_params = self.sign_request(params);

            let request = match method {
                "GET" => {
                    let query: String = signed_params
                        .iter()
                        .map(|(k, v)| format!("{}={}", k, v))
                        .collect::<Vec<_>>()
                        .join("&");

                    self.http_client
                        .get(&format!("{}?{}", url, query))
                        .header("Content-Type", "application/x-www-form-urlencoded")
                        .send()
                        .await
                }
                "POST" => {
                    let body: String = signed_params
                        .iter()
                        .map(|(k, v)| format!("{}={}", k, v))
                        .collect::<Vec<_>>()
                        .join("&");

                    self.http_client
                        .post(url)
                        .header("Content-Type", "application/x-www-form-urlencoded")
                        .body(body)
                        .send()
                        .await
                }
                _ => {
                    return Err(ProtocolDriverError::Unknown(format!(
                        "Unsupported HTTP method: {}",
                        method
                    )));
                }
            };

            match request {
                Ok(resp) => {
                    let status = resp.status().as_u16();
                    let body: Value = resp.json().await.map_err(|e| {
                        ProtocolDriverError::ResponseParse(e.to_string())
                    })?;

                    Ok(HttpResponse {
                        status_code: status,
                        headers: vec![],
                        body,
                    })
                }
                Err(e) => Err(ProtocolDriverError::Connection(e.to_string())),
            }
        }

        fn sign_request(&self, params: &[(&str, &str)]) -> Vec<(String, String)> {
            params
                .iter()
                .map(|(k, v)| (k.to_string(), v.to_string()))
                .collect()
        }
    }
}

/// Tandoor API Protocol Driver
pub mod tandoor_driver {
    use super::*;

    const BASE_URL: &str = "https://tandoor.example.com/api";

    #[derive(Debug)]
    pub struct TandoorDriver {
        base_url: String,
        auth_token: String,
        http_client: reqwest::Client,
    }

    impl TandoorDriver {
        pub fn new(base_url: &str, auth_token: &str) -> Self {
            Self {
                base_url: base_url.to_string(),
                auth_token: auth_token.to_string(),
                http_client: reqwest::Client::new(),
            }
        }

        pub async fn get_recipe(&self, recipe_id: i64) -> Result<Value, ProtocolDriverError> {
            let url = format!("{}/recipes/{}/", self.base_url, recipe_id);

            let response = self.http_client
                .get(&url)
                .header("Authorization", format!("Token {}", self.auth_token))
                .send()
                .await
                .map_err(|e| ProtocolDriverError::Connection(e.to_string()))?;

            let status = response.status().as_u16();
            if status != 200 {
                return Err(ProtocolDriverError::Unknown(format!(
                    "GET recipe {} returned {}",
                    recipe_id, status
                )));
            }

            response.json().await.map_err(|e| {
                ProtocolDriverError::ResponseParse(e.to_string())
            })
        }

        pub async fn list_recipes(
            &self,
            page: Option<i32>,
        ) -> Result<Value, ProtocolDriverError> {
            let mut url = format!("{}/recipes/", self.base_url);
            if let Some(p) = page {
                url.push_str(&format!("?page={}", p));
            }

            let response = self.http_client
                .get(&url)
                .header("Authorization", format!("Token {}", self.auth_token))
                .send()
                .await
                .map_err(|e| ProtocolDriverError::Connection(e.to_string()))?;

            let status = response.status().as_u16();
            if status != 200 {
                return Err(ProtocolDriverError::Unknown(format!(
                    "list recipes returned {}",
                    status
                )));
            }

            response.json().await.map_err(|e| {
                ProtocolDriverError::ResponseParse(e.to_string())
            })
        }

        pub async fn create_recipe(&self, recipe: &Value) -> Result<Value, ProtocolDriverError> {
            let url = format!("{}/recipes/", self.base_url);

            let response = self.http_client
                .post(&url)
                .header("Authorization", format!("Token {}", self.auth_token))
                .json(recipe)
                .send()
                .await
                .map_err(|e| ProtocolDriverError::Connection(e.to_string()))?;

            let status = response.status().as_u16();
            if status != 201 {
                return Err(ProtocolDriverError::Unknown(format!(
                    "create recipe returned {}",
                    status
                )));
            }

            response.json().await.map_err(|e| {
                ProtocolDriverError::ResponseParse(e.to_string())
            })
        }

        pub async fn update_recipe(
            &self,
            recipe_id: i64,
            recipe: &Value,
        ) -> Result<Value, ProtocolDriverError> {
            let url = format!("{}/recipes/{}/", self.base_url, recipe_id);

            let response = self.http_client
                .put(&url)
                .header("Authorization", format!("Token {}", self.auth_token))
                .json(recipe)
                .send()
                .await
                .map_err(|e| ProtocolDriverError::Connection(e.to_string()))?;

            let status = response.status().as_u16();
            if status != 200 {
                return Err(ProtocolDriverError::Unknown(format!(
                    "update recipe {} returned {}",
                    recipe_id, status
                )));
            }

            response.json().await.map_err(|e| {
                ProtocolDriverError::ResponseParse(e.to_string())
            })
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_http_request_serialization() {
        let request = HttpRequest {
            method: HttpMethod::GET,
            url: "https://api.example.com/data".to_string(),
            headers: vec![("Content-Type".to_string(), "application/json".to_string())],
            body: None,
        };

        let json = serde_json::to_string(&request).unwrap();
        assert!(json.contains("GET"));
        assert!(json.contains("https://api.example.com/data"));
    }

    #[test]
    fn test_binary_input_serialization() {
        let input = BinaryInput {
            action: "calculate".to_string(),
            payload: serde_json::json!({"recipe_id": 123}),
        };

        let json = serde_json::to_string(&input).unwrap();
        assert!(json.contains("calculate"));
        assert!(json.contains("recipe_id"));
    }

    #[test]
    fn test_protocol_error_display() {
        let error = ProtocolError::new("HTTP", "GET /api", "Connection refused", true);
        let display = error.to_string();
        assert!(display.contains("HTTP"));
        assert!(display.contains("GET /api"));
        assert!(display.contains("retryable: true"));
    }

    #[test]
    fn test_protocol_driver_error_variants() {
        assert_eq!(
            ProtocolDriverError::Connection("test".to_string()).to_string(),
            "Connection: test"
        );
        assert_eq!(
            ProtocolDriverError::Authentication("test".to_string()).to_string(),
            "Auth: test"
        );
        assert_eq!(
            ProtocolDriverError::Validation("test".to_string()).to_string(),
            "Validation: test"
        );
        assert_eq!(
            ProtocolDriverError::Timeout("test".to_string()).to_string(),
            "Timeout: test"
        );
        assert_eq!(
            ProtocolDriverError::ResponseParse("test".to_string()).to_string(),
            "Parse: test"
        );
        assert_eq!(
            ProtocolDriverError::Unknown("test".to_string()).to_string(),
            "Unknown: test"
        );
    }
}
