//! Tandoor API HTTP Client
//!
//! Provides [`TandoorClient`] for making blocking HTTP requests to the Tandoor Recipes API.
//! All methods return [`Result<T, TandoorError>`](TandoorError) for error handling.
//!
//! # Key Types
//!
//! - [`TandoorClient`] - Main HTTP client (blocking, thread-safe)
//! - [`TandoorError`] - Typed error enum for API failures
//!
//! # Client Creation
//!
//! The client is created from [`TandoorConfig`](crate::tandoor::TandoorConfig) and sets up:
//! - Bearer token authentication
//! - 30-second request timeout
//! - Required headers (`Authorization`, `Content-Type`, `Host`)
//!
//! # API Methods
//!
//! ## Connection Testing
//! - [`test_connection`](TandoorClient::test_connection) - Verify API access
//!
//! ## Recipe Operations
//! - [`list_recipes`](TandoorClient::list_recipes) - Paginated recipe listing
//! - [`scrape_recipe_from_url`](TandoorClient::scrape_recipe_from_url) - Scrape recipe data
//! - [`create_recipe`](TandoorClient::create_recipe) - Create from scraped data
//! - [`import_recipe_from_url`](TandoorClient::import_recipe_from_url) - Scrape + create (convenience)
//!
//! # Usage Example
//!
//! ```rust,no_run
//! use meal_planner::tandoor::{TandoorClient, TandoorConfig};
//!
//! # fn main() -> Result<(), Box<dyn std::error::Error>> {
//! let config = TandoorConfig {
//!     base_url: "http://localhost:8090".to_string(),
//!     api_token: "your-token".to_string(),
//! };
//!
//! let client = TandoorClient::new(&config)?;
//!
//! // Test connectivity
//! match client.test_connection() {
//!     Ok(result) => println!("{}", result.message),
//!     Err(e) => eprintln!("Connection failed: {}", e),
//! }
//!
//! // Import a recipe
//! let result = client.import_recipe_from_url(
//!     "https://example.com/recipe",
//!     Some(vec!["dinner".to_string()])
//! )?;
//!
//! if result.success {
//!     println!("Created recipe ID: {}", result.`recipe_id`.unwrap());
//! } else {
//!     eprintln!("Import failed: {}", result.message);
//! }
//! # Ok(())
//! # }
//! ```
//!
//! # Error Handling
//!
//! All methods return [`TandoorError`] which covers:
//! - HTTP transport errors ([`HttpError`](TandoorError::HttpError))
//! - Authentication failures ([`AuthError`](TandoorError::AuthError))
//! - API errors with status codes ([`ApiError`](TandoorError::ApiError))
//! - JSON parsing failures ([`ParseError`](TandoorError::ParseError))
//!
//! # Thread Safety
//!
//! [`TandoorClient`] is `Send + Sync` and can be shared across threads or used in async contexts
//! via `tokio::task::spawn_blocking`.

use crate::tandoor::types::*;
use reqwest::blocking::Client;
use reqwest::header::{HeaderMap, HeaderValue, AUTHORIZATION, CONTENT_TYPE};
use thiserror::Error;

#[derive(Error, Debug)]
#[allow(clippy::enum_variant_names)]
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
    #[allow(dead_code)]
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

    /// Import a recipe from a URL using Tandoor's scraper
    ///
    /// This calls the /api/recipe-from-source/ endpoint which scrapes
    /// recipe data from the provided URL.
    pub fn scrape_recipe_from_url(
        &self,
        url: &str,
    ) -> Result<RecipeFromSourceResponse, TandoorError> {
        let api_url = format!("{}/api/recipe-from-source/", self.base_url);

        let request = RecipeFromSourceRequest {
            url: Some(url.to_string()),
            data: None,
            bookmarklet: None,
        };

        let response = self.client.post(&api_url).json(&request).send()?;
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

        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Create a recipe from scraped/imported data
    pub fn create_recipe(
        &self,
        recipe: &CreateRecipeRequest,
    ) -> Result<CreatedRecipe, TandoorError> {
        let api_url = format!("{}/api/recipe/", self.base_url);

        let response = self.client.post(&api_url).json(recipe).send()?;
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

        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Import a recipe from URL: scrape then create
    ///
    /// This is a convenience method that combines scraping and creation.
    /// It scrapes the recipe from the URL, then creates it in Tandoor.
    #[allow(clippy::too_many_lines)] // Complex import logic - hard to split meaningfully
    pub fn import_recipe_from_url(
        &self,
        url: &str,
        additional_keywords: Option<Vec<String>>,
    ) -> Result<RecipeImportResult, TandoorError> {
        // First, scrape the recipe
        let scraped = self.scrape_recipe_from_url(url)?;

        if scraped.error {
            return Ok(RecipeImportResult {
                success: false,
                recipe_id: None,
                recipe_name: None,
                source_url: url.to_string(),
                message: scraped.msg,
            });
        }

        // Extract the recipe data
        let recipe_json = match scraped.recipe {
            Some(r) => r,
            None => {
                return Ok(RecipeImportResult {
                    success: false,
                    recipe_id: None,
                    recipe_name: None,
                    source_url: url.to_string(),
                    message: "No recipe data found in response".to_string(),
                });
            }
        };

        // Build keywords from scraped data plus any additional ones
        let mut keywords: Vec<CreateKeywordRequest> = recipe_json
            .keywords
            .iter()
            .map(|k| CreateKeywordRequest {
                name: k.name.clone(),
            })
            .collect();

        if let Some(additional) = additional_keywords {
            for kw in additional {
                keywords.push(CreateKeywordRequest { name: kw });
            }
        }

        // Build steps with ingredients
        let steps: Vec<CreateStepRequest> = recipe_json
            .steps
            .iter()
            .map(|s| {
                let ingredients: Vec<CreateIngredientRequest> = s
                    .ingredients
                    .iter()
                    .filter_map(|i| {
                        // Skip ingredients without a food name
                        let food = i.food.as_ref()?;
                        Some(CreateIngredientRequest {
                            amount: i.amount,
                            food: CreateFoodRequest {
                                name: food.name.clone(),
                            },
                            unit: i.unit.as_ref().map(|u| CreateUnitRequest {
                                name: u.name.clone(),
                            }),
                            note: if i.note.is_empty() {
                                None
                            } else {
                                Some(i.note.clone())
                            },
                        })
                    })
                    .collect();

                CreateStepRequest {
                    instruction: s.instruction.clone(),
                    ingredients: if ingredients.is_empty() {
                        None
                    } else {
                        Some(ingredients)
                    },
                }
            })
            .collect();

        // Create the recipe request
        let create_request = CreateRecipeRequest {
            name: recipe_json.name.clone(),
            description: if recipe_json.description.is_empty() {
                None
            } else {
                Some(recipe_json.description.clone())
            },
            source_url: Some(url.to_string()),
            servings: Some(recipe_json.servings),
            working_time: if recipe_json.working_time > 0 {
                Some(recipe_json.working_time)
            } else {
                None
            },
            waiting_time: if recipe_json.waiting_time > 0 {
                Some(recipe_json.waiting_time)
            } else {
                None
            },
            keywords: if keywords.is_empty() {
                None
            } else {
                Some(keywords)
            },
            steps: if steps.is_empty() { None } else { Some(steps) },
        };

        // Create the recipe
        let created = self.create_recipe(&create_request)?;

        Ok(RecipeImportResult {
            success: true,
            recipe_id: Some(created.id),
            recipe_name: Some(created.name),
            source_url: url.to_string(),
            message: "Recipe imported successfully".to_string(),
        })
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

    #[test]
    fn test_client_creation_with_trailing_slash() {
        let config = TandoorConfig {
            base_url: "http://localhost:8090/".to_string(),
            api_token: "test_token".to_string(),
        };
        let client = TandoorClient::new(&config).unwrap();
        // base_url should have trailing slash stripped
        assert!(!client.base_url.ends_with('/'));
        assert_eq!(client.base_url, "http://localhost:8090");
    }

    #[test]
    fn test_tandoor_error_display_http() {
        // We can't easily create a reqwest::Error, but we can test other variants
        let err = TandoorError::AuthError("Invalid token".to_string());
        assert!(err.to_string().contains("Authentication"));
        assert!(err.to_string().contains("Invalid token"));
    }

    #[test]
    fn test_tandoor_error_display_api_error() {
        let err = TandoorError::ApiError {
            status: 404,
            message: "Not found".to_string(),
        };
        let display = err.to_string();
        assert!(display.contains("404"));
        assert!(display.contains("Not found"));
        assert!(display.contains("API error"));
    }

    #[test]
    fn test_tandoor_error_display_parse_error() {
        let err = TandoorError::ParseError("unexpected token".to_string());
        let display = err.to_string();
        assert!(display.contains("parse"));
        assert!(display.contains("unexpected token"));
    }

    #[test]
    fn test_tandoor_error_auth_error_debug() {
        let err = TandoorError::AuthError("token expired".to_string());
        let debug = format!("{:?}", err);
        assert!(debug.contains("AuthError"));
        assert!(debug.contains("token expired"));
    }

    #[test]
    fn test_tandoor_error_api_error_debug() {
        let err = TandoorError::ApiError {
            status: 500,
            message: "Server error".to_string(),
        };
        let debug = format!("{:?}", err);
        assert!(debug.contains("ApiError"));
        assert!(debug.contains("500"));
        assert!(debug.contains("Server error"));
    }

    #[test]
    fn test_tandoor_error_parse_error_debug() {
        let err = TandoorError::ParseError("invalid json".to_string());
        let debug = format!("{:?}", err);
        assert!(debug.contains("ParseError"));
        assert!(debug.contains("invalid json"));
    }

    #[test]
    fn test_client_stores_headers() {
        let config = TandoorConfig {
            base_url: "http://localhost:8090".to_string(),
            api_token: "my_secret_token".to_string(),
        };
        let client = TandoorClient::new(&config).unwrap();

        // Verify headers were set (we can check the stored headers)
        assert!(client.headers.contains_key(AUTHORIZATION));
        assert!(client.headers.contains_key(CONTENT_TYPE));
    }

    #[test]
    fn test_client_with_different_ports() {
        // Test various port configurations
        for port in [80, 443, 8080, 9000, 3000] {
            let config = TandoorConfig {
                base_url: format!("http://localhost:{}", port),
                api_token: "token".to_string(),
            };
            let client = TandoorClient::new(&config);
            assert!(client.is_ok(), "Failed to create client for port {}", port);
        }
    }

    #[test]
    fn test_client_with_https_url() {
        let config = TandoorConfig {
            base_url: "https://tandoor.example.com".to_string(),
            api_token: "secure_token".to_string(),
        };
        let client = TandoorClient::new(&config);
        assert!(client.is_ok());
    }

    #[test]
    fn test_client_with_path_in_url() {
        let config = TandoorConfig {
            base_url: "http://localhost:8090/tandoor".to_string(),
            api_token: "token".to_string(),
        };
        let client = TandoorClient::new(&config).unwrap();
        assert_eq!(client.base_url, "http://localhost:8090/tandoor");
    }
}
