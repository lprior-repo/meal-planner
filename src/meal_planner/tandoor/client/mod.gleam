/// Main client module for Tandoor API
///
/// This module provides the main entry point for the Tandoor API client,
/// exposing key types and functionality.
import meal_planner/tandoor/client

/// HTTP client configuration for Tandoor API
pub type ClientConfig =
  client.ClientConfig

/// Authentication method for Tandoor API
pub type AuthMethod =
  client.AuthMethod

/// Re-export core client functions for convenience
pub fn session_config(
  base_url: String,
  username: String,
  password: String,
) -> ClientConfig {
  client.session_config(base_url, username, password)
}

pub fn bearer_config(base_url: String, token: String) -> ClientConfig {
  client.bearer_config(base_url, token)
}

/// Re-export authentication functions
pub fn login(config: ClientConfig) -> Result(ClientConfig, client.TandoorError) {
  client.login(config)
}

/// Re-export authentication helpers
pub fn is_authenticated(config: ClientConfig) -> Bool {
  client.is_authenticated(config)
}

pub fn ensure_authenticated(
  config: ClientConfig,
) -> Result(ClientConfig, client.TandoorError) {
  client.ensure_authenticated(config)
}

/// Re-export API request builders
pub fn build_get_request(
  config: ClientConfig,
  path: String,
  query_params: List(#(String, String)),
) -> Result(client.Request(String), client.TandoorError) {
  client.build_get_request(config, path, query_params)
}

pub fn build_post_request(
  config: ClientConfig,
  path: String,
  body: String,
) -> Result(client.Request(String), client.TandoorError) {
  client.build_post_request(config, path, body)
}

pub fn build_put_request(
  config: ClientConfig,
  path: String,
  body: String,
) -> Result(client.Request(String), client.TandoorError) {
  client.build_put_request(config, path, body)
}

pub fn build_patch_request(
  config: ClientConfig,
  path: String,
  body: String,
) -> Result(client.Request(String), client.TandoorError) {
  client.build_patch_request(config, path, body)
}

pub fn build_delete_request(
  config: ClientConfig,
  path: String,
) -> Result(client.Request(String), client.TandoorError) {
  client.build_delete_request(config, path)
}

/// Re-export recipe API functions
pub fn get_recipes(
  config: ClientConfig,
  limit: Option(Int),
  offset: Option(Int),
) -> Result(client.RecipeListResponse, client.TandoorError) {
  client.get_recipes(config, limit, offset)
}

pub fn get_recipe_by_id(
  config: ClientConfig,
  recipe_id: Int,
) -> Result(client.Recipe, client.TandoorError) {
  client.get_recipe_by_id(config, recipe_id)
}

pub fn get_recipe_detail(
  config: ClientConfig,
  recipe_id: Int,
) -> Result(client.RecipeDetail, client.TandoorError) {
  client.get_recipe_detail(config, recipe_id)
}

pub fn create_recipe(
  config: ClientConfig,
  recipe_request: client.CreateRecipeRequest,
) -> Result(client.Recipe, client.TandoorError) {
  client.create_recipe(config, recipe_request)
}

pub fn delete_recipe(
  config: ClientConfig,
  recipe_id: Int,
) -> Result(Nil, client.TandoorError) {
  client.delete_recipe(config, recipe_id)
}

/// Re-export API response helpers
pub fn execute_and_parse(
  req: client.Request(String),
) -> Result(client.ApiResponse, client.TandoorError) {
  client.execute_and_parse(req)
}

pub fn parse_response(
  response: client.Response(String),
) -> Result(client.ApiResponse, client.TandoorError) {
  client.parse_response(response)
}

pub fn parse_json_body(
  response: client.ApiResponse,
  decoder: fn(dynamic.Dynamic) -> Result(a, String),
) -> Result(a, client.TandoorError) {
  client.parse_json_body(response, decoder)
}

/// Re-export error handling
pub fn is_transient_error(error: client.TandoorError) -> Bool {
  client.is_transient_error(error)
}

pub fn error_to_string(error: client.TandoorError) -> String {
  client.error_to_string(error)
}

/// Re-export API types
pub type Recipe =
  client.Recipe

pub type RecipeDetail =
  client.RecipeDetail

pub type RecipeListResponse =
  client.RecipeListResponse

pub type CreateRecipeRequest =
  client.CreateRecipeRequest

pub type Step =
  client.Step

pub type Ingredient =
  client.Ingredient

pub type Food =
  client.Food

pub type Unit =
  client.Unit

pub type SupermarketCategory =
  client.SupermarketCategory

pub type Keyword =
  client.Keyword

pub type NutritionInfo =
  client.NutritionInfo

pub type ApiResponse =
  client.ApiResponse

pub type TandoorError =
  client.TandoorError

pub type HttpMethod =
  client.HttpMethod
