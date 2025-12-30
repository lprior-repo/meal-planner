//! Tandoor API client

use crate::tandoor::types::*;
use reqwest::blocking::Client;
use reqwest::header::{HeaderMap, HeaderValue, AUTHORIZATION, CONTENT_TYPE};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum TandoorError {
    #[error("HTTP request failed: {0}")]
    HttpError(#[from] reqwest::Error),

    #[error("Authentication failed: {0}")]
    AuthError(String),

    #[error("API error ({status}): {message}")]
    ApiError { status: u16, message: String },

    #[error("Failed to parse response: {0}")]
    ParseError(String),
}

/// Tandoor API client
pub struct TandoorClient {
    client: Client,
    base_url: String,
    headers: HeaderMap,
}

impl TandoorClient {
    /// Create a new Tandoor client
    pub fn new(config: &TandoorConfig) -> Result<Self, TandoorError> {
        let mut headers = HeaderMap::new();
        headers.insert(
            AUTHORIZATION,
            HeaderValue::from_str(&format!("Bearer {}", config.api_token))
                .map_err(|e| TandoorError::AuthError(e.to_string()))?,
        );
        headers.insert(CONTENT_TYPE, HeaderValue::from_static("application/json"));
        // Required for Docker networking where host header validation may occur
        headers.insert("Host", HeaderValue::from_static("localhost"));

        let client = Client::builder()
            .timeout(std::time::Duration::from_secs(30))
            .default_headers(headers.clone())
            .build()?;

        Ok(Self {
            client,
            base_url: config.base_url.trim_end_matches('/').to_string(),
            headers,
        })
    }

    /// Test connection by fetching recipes
    pub fn test_connection(&self) -> Result<ConnectionTestResult, TandoorError> {
        let url = format!("{}/api/recipe/", self.base_url);

        let response = self.client.get(&url).send()?;
        let status = response.status();

        if status.as_u16() == 401 || status.as_u16() == 403 {
            let body = response.text().unwrap_or_default();
            return Err(TandoorError::AuthError(body));
        }

        if !status.is_success() {
            let body = response.text().unwrap_or_default();
            return Err(TandoorError::ApiError {
                status: status.as_u16(),
                message: body,
            });
        }

        let paginated: PaginatedResponse<RecipeSummary> = response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))?;

        Ok(ConnectionTestResult {
            success: true,
            message: format!(
                "Successfully connected to Tandoor. Found {} recipes.",
                paginated.count
            ),
            recipe_count: paginated.count,
        })
    }

    /// List recipes with pagination
    pub fn list_recipes(
        &self,
        page: Option<u32>,
        page_size: Option<u32>,
    ) -> Result<PaginatedResponse<RecipeSummary>, TandoorError> {
        let mut url = format!("{}/api/recipe/", self.base_url);

        let mut params = Vec::new();
        if let Some(p) = page {
            params.push(format!("page={}", p));
        }
        if let Some(ps) = page_size {
            params.push(format!("page_size={}", ps));
        }
        if !params.is_empty() {
            url = format!("{}?{}", url, params.join("&"));
        }

        let response = self.client.get(&url).send()?;
        let status = response.status();

        if !status.is_success() {
            let body = response.text().unwrap_or_default();
            return Err(TandoorError::ApiError {
                status: status.as_u16(),
                message: body,
            });
        }

        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_client_creation() {
        let config = TandoorConfig {
            base_url: "http://localhost:8090".to_string(),
            api_token: "test_token".to_string(),
        };
        let client = TandoorClient::new(&config);
        assert!(client.is_ok());
    }
}
