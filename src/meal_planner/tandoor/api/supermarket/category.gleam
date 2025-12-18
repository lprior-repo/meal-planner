/// Supermarket Category API
///
/// This module provides CRUD operations for supermarket categories in the Tandoor API.
/// Categories are used to organize foods by store aisles/sections.
import gleam/int
import gleam/json
import gleam/option.{type Option}
import gleam/result
import meal_planner/tandoor/api/crud_helpers
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/core/http.{type PaginatedResponse}
import meal_planner/tandoor/decoders/supermarket/supermarket_category_decoder
import meal_planner/tandoor/encoders/supermarket/supermarket_category_encoder
import meal_planner/tandoor/types/supermarket/supermarket_category.{
  type SupermarketCategory,
}
import meal_planner/tandoor/types/supermarket/supermarket_category_create.{
  type SupermarketCategoryCreateRequest,
}

/// List supermarket categories from Tandoor API with pagination
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `limit` - Optional number of results per page (page_size parameter)
/// * `offset` - Optional offset for pagination
///
/// # Returns
/// Result with paginated supermarket category list or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = list_categories(config, limit: Some(20), offset: Some(0))
/// ```
pub fn list_categories(
  config: ClientConfig,
  limit limit: Option(Int),
  offset offset: Option(Int),
) -> Result(PaginatedResponse(SupermarketCategory), TandoorError) {
  // Build query parameters
  let query_params = case limit, offset {
    option.Some(l), option.Some(o) -> [
      #("page_size", int.to_string(l)),
      #("offset", int.to_string(o)),
    ]
    option.Some(l), option.None -> [#("page_size", int.to_string(l))]
    option.None, option.Some(o) -> [#("offset", int.to_string(o))]
    option.None, option.None -> []
  }

  // Execute GET and parse paginated response
  use resp <- result.try(crud_helpers.execute_get(
    config,
    "/api/supermarket-category/",
    query_params,
  ))
  crud_helpers.parse_json_paginated(
    resp,
    supermarket_category_decoder.decoder(),
  )
}

/// Get a single supermarket category by ID from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `category_id` - The ID of the category to fetch
///
/// # Returns
/// Result with category details or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = get_category(config, category_id: 1)
/// ```
pub fn get_category(
  config: ClientConfig,
  category_id category_id: Int,
) -> Result(SupermarketCategory, TandoorError) {
  let path = "/api/supermarket-category/" <> int.to_string(category_id) <> "/"

  // Execute GET and parse single response
  use resp <- result.try(crud_helpers.execute_get(config, path, []))
  crud_helpers.parse_json_single(resp, supermarket_category_decoder.decoder())
}

/// Create a new supermarket category in Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `category_data` - Category data to create (name, description)
///
/// # Returns
/// Result with created category or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let category_data = SupermarketCategoryCreateRequest(
///   name: "Produce",
///   description: Some("Fresh fruits and vegetables")
/// )
/// let result = create_category(config, category_data)
/// ```
pub fn create_category(
  config: ClientConfig,
  category_data: SupermarketCategoryCreateRequest,
) -> Result(SupermarketCategory, TandoorError) {
  // Encode category data to JSON
  let body =
    supermarket_category_encoder.encode_supermarket_category_create(
      category_data,
    )
    |> json.to_string

  // Execute POST and parse single response
  use resp <- result.try(crud_helpers.execute_post(
    config,
    "/api/supermarket-category/",
    body,
  ))
  crud_helpers.parse_json_single(resp, supermarket_category_decoder.decoder())
}

/// Update an existing supermarket category in Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `category_id` - The ID of the category to update
/// * `category_data` - Updated category data (name, description)
///
/// # Returns
/// Result with updated category or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let category_data = SupermarketCategoryCreateRequest(
///   name: "Fresh Produce",
///   description: Some("Organic fruits and vegetables")
/// )
/// let result = update_category(config, category_id: 1, category_data: category_data)
/// ```
pub fn update_category(
  config: ClientConfig,
  category_id category_id: Int,
  category_data category_data: SupermarketCategoryCreateRequest,
) -> Result(SupermarketCategory, TandoorError) {
  let path = "/api/supermarket-category/" <> int.to_string(category_id) <> "/"

  // Encode category data to JSON
  let body =
    supermarket_category_encoder.encode_supermarket_category_create(
      category_data,
    )
    |> json.to_string

  // Execute PATCH and parse single response
  use resp <- result.try(crud_helpers.execute_patch(config, path, body))
  crud_helpers.parse_json_single(resp, supermarket_category_decoder.decoder())
}

/// Delete a supermarket category from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `category_id` - The ID of the category to delete
///
/// # Returns
/// Result with Nil on success or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = delete_category(config, category_id: 1)
/// ```
pub fn delete_category(
  config: ClientConfig,
  category_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/supermarket-category/" <> int.to_string(category_id) <> "/"

  // Execute DELETE and verify empty response
  use resp <- result.try(crud_helpers.execute_delete(config, path))
  crud_helpers.parse_empty_response(resp)
}
