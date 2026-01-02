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
//!     println!("Created recipe ID: {}", result.recipe_id.unwrap());
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

    #[error("Request too large: {size} bytes exceeds limit of {limit} bytes")]
    RequestTooLarge { size: u64, limit: u64 },
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
            // DOS prevention: Limit connection pool to prevent resource exhaustion
            .pool_max_idle_per_host(5)
            .pool_idle_timeout(std::time::Duration::from_secs(60))
            .build()?;

        Ok(Self {
            client,
            base_url: config.base_url.trim_end_matches('/').to_string(),
            headers,
        })
    }

    /// Validate request body size against DOS limits
    #[allow(clippy::unused_self)]
    fn validate_request_size(&self, body: &[u8]) -> Result<(), TandoorError> {
        const MAX_REQUEST_SIZE: u64 = 10 * 1024 * 1024; // 10MB
        let size = u64::try_from(body.len()).unwrap_or(u64::MAX);

        if size > MAX_REQUEST_SIZE {
            return Err(TandoorError::RequestTooLarge {
                size,
                limit: MAX_REQUEST_SIZE,
            });
        }
        Ok(())
    }

    /// Serialize and send a validated POST request (DOS prevention)
    fn post_request<T: serde::Serialize>(
        &self,
        url: &str,
        request: &T,
    ) -> Result<reqwest::blocking::Response, TandoorError> {
        let json =
            serde_json::to_vec(request).map_err(|e| TandoorError::ParseError(e.to_string()))?;
        self.validate_request_size(&json)?;
        Ok(self.client.post(url).json(request).send()?)
    }

    /// Serialize and send a validated PATCH request (DOS prevention)
    fn patch_request<T: serde::Serialize>(
        &self,
        url: &str,
        request: &T,
    ) -> Result<reqwest::blocking::Response, TandoorError> {
        let json =
            serde_json::to_vec(request).map_err(|e| TandoorError::ParseError(e.to_string()))?;
        self.validate_request_size(&json)?;
        Ok(self.client.patch(url).json(request).send()?)
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

        let response = self.post_request(&api_url, &request)?;
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

        let response = self.post_request(&api_url, recipe)?;
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

    // ============================================================================
    // Unit Methods (/api/unit/)
    // ============================================================================

    /// List all units with optional pagination
    pub fn list_units(
        &self,
        page: Option<u32>,
        page_size: Option<u32>,
    ) -> Result<PaginatedResponse<Unit>, TandoorError> {
        let mut url = format!("{}/api/unit/", self.base_url);
        let mut params = Vec::new();
        if let Some(p) = page {
            params.push(format!("page={}", p));
        }
        if let Some(ps) = page_size {
            params.push(format!("page_size={}", ps));
        }
        if !params.is_empty() {
            url.push('?');
            url.push_str(&params.join("&"));
        }

        let response = self.client.get(&url).send()?;

        if response.status().as_u16() == 401 || response.status().as_u16() == 403 {
            return Err(TandoorError::AuthError(response.text().unwrap_or_default()));
        }
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }

        response
            .json::<PaginatedResponse<Unit>>()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Get a specific unit by ID
    pub fn get_unit(&self, id: i64) -> Result<Unit, TandoorError> {
        let url = format!("{}/api/unit/{}/", self.base_url, id);
        let response = self.client.get(&url).send()?;

        if response.status().as_u16() == 401 || response.status().as_u16() == 403 {
            return Err(TandoorError::AuthError(response.text().unwrap_or_default()));
        }
        if response.status().as_u16() == 404 {
            return Err(TandoorError::ApiError {
                status: 404,
                message: "Unit not found".to_string(),
            });
        }
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }

        response
            .json::<Unit>()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Create a new unit
    pub fn create_unit(&self, request: &CreateUnitRequestData) -> Result<Unit, TandoorError> {
        let url = format!("{}/api/unit/", self.base_url);
        let response = self.client.post(&url).json(request).send()?;

        if response.status().as_u16() == 401 || response.status().as_u16() == 403 {
            return Err(TandoorError::AuthError(response.text().unwrap_or_default()));
        }
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }

        response
            .json::<Unit>()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Update an existing unit
    pub fn update_unit(&self, id: i64, request: &UpdateUnitRequest) -> Result<Unit, TandoorError> {
        let url = format!("{}/api/unit/{}/", self.base_url, id);
        let response = self.client.patch(&url).json(request).send()?;

        if response.status().as_u16() == 401 || response.status().as_u16() == 403 {
            return Err(TandoorError::AuthError(response.text().unwrap_or_default()));
        }
        if response.status().as_u16() == 404 {
            return Err(TandoorError::ApiError {
                status: 404,
                message: "Unit not found".to_string(),
            });
        }
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }

        response
            .json::<Unit>()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Delete a unit by ID
    pub fn delete_unit(&self, id: i64) -> Result<(), TandoorError> {
        let url = format!("{}/api/unit/{}/", self.base_url, id);
        let response = self.client.delete(&url).send()?;

        if response.status().as_u16() == 401 || response.status().as_u16() == 403 {
            return Err(TandoorError::AuthError(response.text().unwrap_or_default()));
        }
        if response.status().as_u16() == 404 {
            return Err(TandoorError::ApiError {
                status: 404,
                message: "Unit not found".to_string(),
            });
        }
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        Ok(())
    }

    /// List all unit conversions with optional pagination
    pub fn list_unit_conversions(
        &self,
        page: Option<u32>,
        page_size: Option<u32>,
    ) -> Result<PaginatedResponse<UnitConversion>, TandoorError> {
        let mut url = format!("{}/api/unit-conversion/", self.base_url);
        let mut params = Vec::new();
        if let Some(p) = page {
            params.push(format!("page={}", p));
        }
        if let Some(ps) = page_size {
            params.push(format!("page_size={}", ps));
        }
        if !params.is_empty() {
            url.push('?');
            url.push_str(&params.join("&"));
        }

        let response = self.client.get(&url).send()?;

        if response.status().as_u16() == 401 || response.status().as_u16() == 403 {
            return Err(TandoorError::AuthError(response.text().unwrap_or_default()));
        }
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }

        response
            .json::<PaginatedResponse<UnitConversion>>()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    // ============================================================================
    // Ingredient Methods (/api/ingredient/)
    // ============================================================================

    /// List all ingredients with optional pagination
    pub fn list_ingredients(
        &self,
        page: Option<u32>,
        page_size: Option<u32>,
    ) -> Result<PaginatedResponse<Ingredient>, TandoorError> {
        let mut url = format!("{}/api/ingredient/", self.base_url);
        let mut params = Vec::new();
        if let Some(p) = page {
            params.push(format!("page={}", p));
        }
        if let Some(ps) = page_size {
            params.push(format!("page_size={}", ps));
        }
        if !params.is_empty() {
            url.push('?');
            url.push_str(&params.join("&"));
        }

        let response = self.client.get(&url).send()?;

        if response.status().as_u16() == 401 || response.status().as_u16() == 403 {
            return Err(TandoorError::AuthError(response.text().unwrap_or_default()));
        }
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }

        response
            .json::<PaginatedResponse<Ingredient>>()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Get a specific ingredient by ID
    pub fn get_ingredient(&self, id: i64) -> Result<Ingredient, TandoorError> {
        let url = format!("{}/api/ingredient/{}/", self.base_url, id);
        let response = self.client.get(&url).send()?;

        if response.status().as_u16() == 401 || response.status().as_u16() == 403 {
            return Err(TandoorError::AuthError(response.text().unwrap_or_default()));
        }
        if response.status().as_u16() == 404 {
            return Err(TandoorError::ApiError {
                status: 404,
                message: "Ingredient not found".to_string(),
            });
        }
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }

        response
            .json::<Ingredient>()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Create a new ingredient
    pub fn create_ingredient(
        &self,
        request: &CreateIngredientRequestData,
    ) -> Result<Ingredient, TandoorError> {
        let url = format!("{}/api/ingredient/", self.base_url);
        let response = self.client.post(&url).json(request).send()?;

        if response.status().as_u16() == 401 || response.status().as_u16() == 403 {
            return Err(TandoorError::AuthError(response.text().unwrap_or_default()));
        }
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }

        response
            .json::<Ingredient>()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Update an existing ingredient
    pub fn update_ingredient(
        &self,
        id: i64,
        request: &UpdateIngredientRequest,
    ) -> Result<Ingredient, TandoorError> {
        let url = format!("{}/api/ingredient/{}/", self.base_url, id);
        let response = self.client.patch(&url).json(request).send()?;

        if response.status().as_u16() == 401 || response.status().as_u16() == 403 {
            return Err(TandoorError::AuthError(response.text().unwrap_or_default()));
        }
        if response.status().as_u16() == 404 {
            return Err(TandoorError::ApiError {
                status: 404,
                message: "Ingredient not found".to_string(),
            });
        }
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }

        response
            .json::<Ingredient>()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Delete an ingredient by ID
    pub fn delete_ingredient(&self, id: i64) -> Result<(), TandoorError> {
        let url = format!("{}/api/ingredient/{}/", self.base_url, id);
        let response = self.client.delete(&url).send()?;

        if response.status().as_u16() == 401 || response.status().as_u16() == 403 {
            return Err(TandoorError::AuthError(response.text().unwrap_or_default()));
        }
        if response.status().as_u16() == 404 {
            return Err(TandoorError::ApiError {
                status: 404,
                message: "Ingredient not found".to_string(),
            });
        }
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        Ok(())
    }

    /// Parse ingredient text and return parsed ingredient
    pub fn ingredient_from_string(
        &self,
        request: &IngredientFromStringRequest,
    ) -> Result<ParsedIngredient, TandoorError> {
        let url = format!("{}/api/ingredient-from-string/", self.base_url);
        let response = self.client.post(&url).json(request).send()?;

        if response.status().as_u16() == 401 || response.status().as_u16() == 403 {
            return Err(TandoorError::AuthError(response.text().unwrap_or_default()));
        }
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }

        response
            .json::<ParsedIngredient>()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    // ============= RECIPE OPERATIONS =============

    /// Get a single recipe by ID
    pub fn get_recipe(&self, id: i64) -> Result<serde_json::Value, TandoorError> {
        let url = format!("{}/api/recipe/{}/", self.base_url, id);
        let response = self.client.get(&url).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Delete a recipe by ID
    pub fn delete_recipe(&self, id: i64) -> Result<(), TandoorError> {
        let url = format!("{}/api/recipe/{}/", self.base_url, id);
        let response = self.client.delete(&url).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        Ok(())
    }

    /// Get recipes related to a given recipe
    pub fn get_related_recipes(&self, id: i64) -> Result<Vec<RecipeSummary>, TandoorError> {
        let url = format!("{}/api/recipe/{}/related/", self.base_url, id);
        let response = self.client.get(&url).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Batch update multiple recipes
    pub fn batch_update_recipes(&self, updates: &[serde_json::Value]) -> Result<i32, TandoorError> {
        let url = format!("{}/api/recipe/batch_update/", self.base_url);
        let response = self.client.patch(&url).json(updates).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        // Return count of updated recipes
        Ok(i32::try_from(updates.len()).unwrap_or(i32::MAX))
    }

    // ============= FOOD OPERATIONS =============

    /// List foods with pagination
    pub fn list_foods(
        &self,
        page: Option<u32>,
        page_size: Option<u32>,
    ) -> Result<PaginatedResponse<Food>, TandoorError> {
        let mut url = format!("{}/api/food/", self.base_url);
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
        if response.status().as_u16() == 401 || response.status().as_u16() == 403 {
            return Err(TandoorError::AuthError(response.text().unwrap_or_default()));
        }
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Get a single food by ID
    pub fn get_food(&self, id: i64) -> Result<Food, TandoorError> {
        let url = format!("{}/api/food/{}/", self.base_url, id);
        let response = self.client.get(&url).send()?;
        if response.status().as_u16() == 401 || response.status().as_u16() == 403 {
            return Err(TandoorError::AuthError(response.text().unwrap_or_default()));
        }
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Delete a food by ID
    pub fn delete_food(&self, id: i64) -> Result<(), TandoorError> {
        let url = format!("{}/api/food/{}/", self.base_url, id);
        let response = self.client.delete(&url).send()?;
        if response.status().as_u16() == 401 || response.status().as_u16() == 403 {
            return Err(TandoorError::AuthError(response.text().unwrap_or_default()));
        }
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        Ok(())
    }

    /// Batch update multiple foods
    pub fn batch_update_foods(&self, updates: &[serde_json::Value]) -> Result<i32, TandoorError> {
        let url = format!("{}/api/food/batch_update/", self.base_url);
        let response = self.client.patch(&url).json(updates).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        Ok(i32::try_from(updates.len()).unwrap_or(i32::MAX))
    }

    // ============= MEAL PLAN OPERATIONS =============

    /// List meal plans with pagination
    pub fn list_meal_plans(
        &self,
        page: Option<u32>,
        page_size: Option<u32>,
    ) -> Result<PaginatedMealPlanResponse, TandoorError> {
        let mut url = format!("{}/api/meal-plan/", self.base_url);
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
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Get a single meal plan by ID
    pub fn get_meal_plan(&self, id: i64) -> Result<MealPlan, TandoorError> {
        let url = format!("{}/api/meal-plan/{}/", self.base_url, id);
        let response = self.client.get(&url).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Create a new meal plan
    pub fn create_meal_plan(
        &self,
        request: &CreateMealPlanRequest,
    ) -> Result<MealPlan, TandoorError> {
        let url = format!("{}/api/meal-plan/", self.base_url);
        let response = self.client.post(&url).json(request).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Update a meal plan
    pub fn update_meal_plan(
        &self,
        id: i64,
        request: &UpdateMealPlanRequest,
    ) -> Result<MealPlan, TandoorError> {
        let url = format!("{}/api/meal-plan/{}/", self.base_url, id);
        let response = self.client.patch(&url).json(request).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Export meal plan as iCalendar format
    pub fn export_meal_plan_ical(&self, id: i64) -> Result<String, TandoorError> {
        let url = format!("{}/api/meal-plan/{}/ical/", self.base_url, id);
        let response = self.client.get(&url).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .text()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Delete a meal plan by ID
    pub fn delete_meal_plan(&self, id: i64) -> Result<(), TandoorError> {
        let url = format!("{}/api/meal-plan/{}/", self.base_url, id);
        let response = self.client.delete(&url).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        Ok(())
    }

    // ============= MEAL TYPE OPERATIONS =============

    /// List meal types with pagination
    pub fn list_meal_types(
        &self,
        page: Option<u32>,
        page_size: Option<u32>,
    ) -> Result<PaginatedResponse<MealType>, TandoorError> {
        let mut url = format!("{}/api/meal-type/", self.base_url);
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
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Create a new meal type
    pub fn create_meal_type(
        &self,
        request: &CreateMealTypeRequest,
    ) -> Result<MealType, TandoorError> {
        let url = format!("{}/api/meal-type/", self.base_url);
        let response = self.client.post(&url).json(request).send()?;
        if response.status().as_u16() == 401 || response.status().as_u16() == 403 {
            return Err(TandoorError::AuthError(response.text().unwrap_or_default()));
        }
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Update a meal type
    pub fn update_meal_type(
        &self,
        id: i64,
        request: &UpdateMealTypeRequest,
    ) -> Result<MealType, TandoorError> {
        let url = format!("{}/api/meal-type/{}/", self.base_url, id);
        let response = self.client.patch(&url).json(request).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Delete a meal type
    pub fn delete_meal_type(&self, id: i64) -> Result<(), TandoorError> {
        let url = format!("{}/api/meal-type/{}/", self.base_url, id);
        let response = self.client.delete(&url).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        Ok(())
    }

    // ============= SHOPPING LIST OPERATIONS =============

    /// List shopping list entries for a meal plan
    pub fn list_shopping_list_entries(
        &self,
        mealplan_id: i64,
    ) -> Result<Vec<ShoppingListEntry>, TandoorError> {
        let url = format!("{}/api/meal-plan/{}/shopping/", self.base_url, mealplan_id);
        let response = self.client.get(&url).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        // The API returns a paginated response, extract the results
        let paginated: PaginatedResponse<ShoppingListEntry> = response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))?;
        Ok(paginated.results)
    }

    /// Delete a recipe from shopping list
    pub fn delete_recipe_from_shopping_list(
        &self,
        mealplan_id: i64,
        recipe_id: i64,
    ) -> Result<(), TandoorError> {
        let url = format!(
            "{}/api/meal-plan/{}/shopping/recipes/{}/",
            self.base_url, mealplan_id, recipe_id
        );
        let response = self.client.delete(&url).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        Ok(())
    }

    /// Bulk create shopping list entries
    pub fn bulk_create_shopping_list_entries(
        &self,
        mealplan_id: i64,
        entries: &[serde_json::Value],
    ) -> Result<i32, TandoorError> {
        let url = format!(
            "{}/api/meal-plan/{}/shopping/bulk/",
            self.base_url, mealplan_id
        );
        let response = self.client.post(&url).json(entries).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        Ok(i32::try_from(entries.len()).unwrap_or(i32::MAX))
    }

    // ============= RECIPE BOOK OPERATIONS =============

    /// Create a recipe book
    pub fn create_recipe_book(
        &self,
        request: &serde_json::Value,
    ) -> Result<serde_json::Value, TandoorError> {
        let url = format!("{}/api/recipe-book/", self.base_url);
        let response = self.client.post(&url).json(request).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Get a recipe book by ID
    pub fn get_recipe_book(&self, id: i64) -> Result<serde_json::Value, TandoorError> {
        let url = format!("{}/api/recipe-book/{}/", self.base_url, id);
        let response = self.client.get(&url).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Update a recipe book
    pub fn update_recipe_book(
        &self,
        id: i64,
        request: &serde_json::Value,
    ) -> Result<serde_json::Value, TandoorError> {
        let url = format!("{}/api/recipe-book/{}/", self.base_url, id);
        let response = self.client.patch(&url).json(request).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Get a recipe book entry by ID
    pub fn get_recipe_book_entry(&self, id: i64) -> Result<serde_json::Value, TandoorError> {
        let url = format!("{}/api/recipe-book-entry/{}/", self.base_url, id);
        let response = self.client.get(&url).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Delete a recipe book entry
    pub fn delete_recipe_book_entry(&self, id: i64) -> Result<(), TandoorError> {
        let url = format!("{}/api/recipe-book-entry/{}/", self.base_url, id);
        let response = self.client.delete(&url).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        Ok(())
    }

    // ============= SUPERMARKET OPERATIONS =============

    /// List supermarkets with pagination
    pub fn list_supermarkets(
        &self,
        page: Option<u32>,
        page_size: Option<u32>,
    ) -> Result<PaginatedResponse<serde_json::Value>, TandoorError> {
        let mut url = format!("{}/api/supermarket/", self.base_url);
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
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Get a supermarket by ID
    pub fn get_supermarket(&self, id: i64) -> Result<serde_json::Value, TandoorError> {
        let url = format!("{}/api/supermarket/{}/", self.base_url, id);
        let response = self.client.get(&url).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Create a supermarket
    pub fn create_supermarket(
        &self,
        request: &serde_json::Value,
    ) -> Result<serde_json::Value, TandoorError> {
        let url = format!("{}/api/supermarket/", self.base_url);
        let response = self.client.post(&url).json(request).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Update a supermarket
    pub fn update_supermarket(
        &self,
        id: i64,
        request: &serde_json::Value,
    ) -> Result<serde_json::Value, TandoorError> {
        let url = format!("{}/api/supermarket/{}/", self.base_url, id);
        let response = self.client.patch(&url).json(request).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Delete a supermarket
    pub fn delete_supermarket(&self, id: i64) -> Result<(), TandoorError> {
        let url = format!("{}/api/supermarket/{}/", self.base_url, id);
        let response = self.client.delete(&url).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        Ok(())
    }

    // ============= STEP OPERATIONS =============

    /// Create a food
    pub fn create_food(&self, request: &CreateFoodRequestData) -> Result<Food, TandoorError> {
        let url = format!("{}/api/food/", self.base_url);
        let response = self.client.post(&url).json(request).send()?;
        if response.status().as_u16() == 401 || response.status().as_u16() == 403 {
            return Err(TandoorError::AuthError(response.text().unwrap_or_default()));
        }
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Update a food
    pub fn update_food(&self, id: i64, request: &UpdateFoodRequest) -> Result<Food, TandoorError> {
        let url = format!("{}/api/food/{}/", self.base_url, id);
        let response = self.client.patch(&url).json(request).send()?;
        if response.status().as_u16() == 401 || response.status().as_u16() == 403 {
            return Err(TandoorError::AuthError(response.text().unwrap_or_default()));
        }
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Create a keyword
    pub fn create_keyword(&self, request: &CreateKeywordRequest) -> Result<Keyword, TandoorError> {
        let url = format!("{}/api/keyword/", self.base_url);
        let response = self.client.post(&url).json(request).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Update a recipe (using `serde_json::Value`)
    pub fn update_recipe(
        &self,
        id: i64,
        request: &serde_json::Value,
    ) -> Result<serde_json::Value, TandoorError> {
        let url = format!("{}/api/recipe/{}/", self.base_url, id);
        let response = self.patch_request(&url, request)?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Delete a keyword
    pub fn delete_keyword(&self, id: i64) -> Result<(), TandoorError> {
        let url = format!("{}/api/keyword/{}/", self.base_url, id);
        let response = self.client.delete(&url).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        Ok(())
    }

    /// Get a meal type by ID
    pub fn get_meal_type(&self, id: i64) -> Result<MealType, TandoorError> {
        let url = format!("{}/api/meal-type/{}/", self.base_url, id);
        let response = self.client.get(&url).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Get a space by ID
    pub fn get_space(&self, id: i64) -> Result<serde_json::Value, TandoorError> {
        let url = format!("{}/api/space/{}/", self.base_url, id);
        let response = self.client.get(&url).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// List spaces
    pub fn list_spaces(&self) -> Result<Vec<serde_json::Value>, TandoorError> {
        let url = format!("{}/api/space/", self.base_url);
        let response = self.client.get(&url).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Get a step by ID
    pub fn get_step(&self, id: i64) -> Result<serde_json::Value, TandoorError> {
        let url = format!("{}/api/step/{}/", self.base_url, id);
        let response = self.client.get(&url).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Delete a step
    pub fn delete_step(&self, id: i64) -> Result<(), TandoorError> {
        let url = format!("{}/api/step/{}/", self.base_url, id);
        let response = self.client.delete(&url).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        Ok(())
    }

    /// Update a step
    pub fn update_step(
        &self,
        id: i64,
        request: &serde_json::Value,
    ) -> Result<serde_json::Value, TandoorError> {
        let url = format!("{}/api/step/{}/", self.base_url, id);
        let response = self.client.patch(&url).json(request).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Create a step
    pub fn create_step(
        &self,
        request: &serde_json::Value,
    ) -> Result<serde_json::Value, TandoorError> {
        let url = format!("{}/api/step/", self.base_url);
        let response = self.client.post(&url).json(request).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// List steps with pagination
    pub fn list_steps(
        &self,
        page: Option<u32>,
        page_size: Option<u32>,
    ) -> Result<PaginatedResponse<serde_json::Value>, TandoorError> {
        let mut url = format!("{}/api/step/", self.base_url);
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
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Get a recipe from shopping list
    pub fn get_recipe_from_shopping_list(
        &self,
        mealplan_id: i64,
        recipe_id: i64,
    ) -> Result<serde_json::Value, TandoorError> {
        let url = format!(
            "{}/api/meal-plan/{}/shopping/recipes/{}/",
            self.base_url, mealplan_id, recipe_id
        );
        let response = self.client.get(&url).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Delete a recipe book
    pub fn delete_recipe_book(&self, id: i64) -> Result<(), TandoorError> {
        let url = format!("{}/api/recipe-book/{}/", self.base_url, id);
        let response = self.client.delete(&url).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        Ok(())
    }

    /// Create a recipe book entry
    pub fn create_recipe_book_entry(
        &self,
        request: &serde_json::Value,
    ) -> Result<serde_json::Value, TandoorError> {
        let url = format!("{}/api/recipe-book-entry/", self.base_url);
        let response = self.client.post(&url).json(request).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// List keywords with pagination
    pub fn list_keywords(
        &self,
        page: Option<u32>,
        page_size: Option<u32>,
    ) -> Result<PaginatedResponse<Keyword>, TandoorError> {
        let mut url = format!("{}/api/keyword/", self.base_url);
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
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Get a keyword by ID
    pub fn get_keyword(&self, id: i64) -> Result<Keyword, TandoorError> {
        let url = format!("{}/api/keyword/{}/", self.base_url, id);
        let response = self.client.get(&url).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Update a keyword
    pub fn update_keyword(
        &self,
        id: i64,
        request: &UpdateKeywordRequest,
    ) -> Result<Keyword, TandoorError> {
        let url = format!("{}/api/keyword/{}/", self.base_url, id);
        let response = self.client.patch(&url).json(request).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// List recipe books with pagination
    pub fn list_recipe_books(
        &self,
        page: Option<u32>,
        page_size: Option<u32>,
    ) -> Result<PaginatedResponse<RecipeBook>, TandoorError> {
        let mut url = format!("{}/api/recipe-book/", self.base_url);
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
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// List recipe book entries with pagination
    pub fn list_recipe_book_entries(
        &self,
        page: Option<u32>,
        page_size: Option<u32>,
    ) -> Result<PaginatedResponse<RecipeBookEntry>, TandoorError> {
        let mut url = format!("{}/api/recipe-book-entry/", self.base_url);
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
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// List all users (returns array, not paginated)
    pub fn list_users(&self) -> Result<Vec<serde_json::Value>, TandoorError> {
        let url = format!("{}/api/user/", self.base_url);
        let response = self.client.get(&url).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Get a user by ID
    pub fn get_user(&self, id: i64) -> Result<serde_json::Value, TandoorError> {
        let url = format!("{}/api/user/{}/", self.base_url, id);
        let response = self.client.get(&url).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Create a shopping list entry
    pub fn create_shopping_list_entry(
        &self,
        mealplan_id: i64,
        request: &CreateShoppingListEntryRequest,
    ) -> Result<ShoppingListEntry, TandoorError> {
        let url = format!("{}/api/meal-plan/{}/shopping/", self.base_url, mealplan_id);
        let response = self.client.post(&url).json(request).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Update a shopping list entry
    pub fn update_shopping_list_entry(
        &self,
        mealplan_id: i64,
        entry_id: i64,
        request: &UpdateShoppingListEntryRequest,
    ) -> Result<ShoppingListEntry, TandoorError> {
        let url = format!(
            "{}/api/meal-plan/{}/shopping/{}/",
            self.base_url, mealplan_id, entry_id
        );
        let response = self.client.patch(&url).json(request).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))
    }

    /// Delete a shopping list entry
    pub fn delete_shopping_list_entry(
        &self,
        mealplan_id: i64,
        entry_id: i64,
    ) -> Result<(), TandoorError> {
        let url = format!(
            "{}/api/meal-plan/{}/shopping/{}/",
            self.base_url, mealplan_id, entry_id
        );
        let response = self.client.delete(&url).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        Ok(())
    }

    /// Add recipe to shopping list (creates entries for all ingredients)
    pub fn add_recipe_to_shopping_list(
        &self,
        mealplan_id: i64,
        recipe_id: i64,
    ) -> Result<Vec<ShoppingListEntry>, TandoorError> {
        let url = format!("{}/api/meal-plan/{}/shopping/", self.base_url, mealplan_id);
        let body = serde_json::json!({"recipe": recipe_id});
        let response = self.client.post(&url).json(&body).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        // API returns paginated response with results
        let paginated: PaginatedResponse<ShoppingListEntry> = response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))?;
        Ok(paginated.results)
    }

    /// List recipes without pagination (flat list) - extracts results from paginated response
    pub fn list_recipes_flat(
        &self,
        limit: Option<u32>,
        offset: Option<u32>,
    ) -> Result<Vec<RecipeSummary>, TandoorError> {
        let mut url = format!("{}/api/recipe/", self.base_url);
        let mut params = Vec::new();
        if let Some(l) = limit {
            params.push(format!("page_size={}", l));
        }
        if let Some(o) = offset {
            // Convert offset to page number (1-indexed)
            let page_size = limit.unwrap_or(50);
            #[allow(clippy::integer_division)]
            let page = if page_size > 0 { o / page_size + 1 } else { 1 };
            params.push(format!("page={}", page));
        }
        if !params.is_empty() {
            url = format!("{}?{}", url, params.join("&"));
        }
        let response = self.client.get(&url).send()?;
        if !response.status().is_success() {
            return Err(TandoorError::ApiError {
                status: response.status().as_u16(),
                message: response.text().unwrap_or_default(),
            });
        }
        let paginated: PaginatedResponse<RecipeSummary> = response
            .json()
            .map_err(|e| TandoorError::ParseError(e.to_string()))?;
        Ok(paginated.results)
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
