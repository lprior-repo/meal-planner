/// Supermarket Category API
///
/// This module provides CRUD operations for supermarket categories in the Tandoor API.
/// Categories are used to organize foods by store aisles/sections.
import gleam/dynamic/decode
import gleam/httpc
import gleam/int
import gleam/json
import gleam/option.{type Option}
import gleam/result
import gleam/string
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, NetworkError, ParseError,
}
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
  let path = case limit, offset {
    option.Some(l), option.Some(o) ->
      "/api/supermarket-category/?page_size="
      <> int.to_string(l)
      <> "&offset="
      <> int.to_string(o)
    option.Some(l), option.None ->
      "/api/supermarket-category/?page_size=" <> int.to_string(l)
    option.None, option.Some(o) ->
      "/api/supermarket-category/?offset=" <> int.to_string(o)
    option.None, option.None -> "/api/supermarket-category/"
  }

  // Build and execute request
  use req <- result.try(client.build_get_request(config, path, []))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Parse JSON response
  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      // Decode paginated response with category items
      case
        decode.run(
          json_data,
          http.paginated_decoder(supermarket_category_decoder.decoder()),
        )
      {
        Ok(paginated) -> Ok(paginated)
        Error(errors) -> {
          let error_msg =
            "Failed to decode supermarket category list: "
            <> string.inspect(errors)
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Failed to parse JSON response"))
  }
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

  // Build and execute request
  use req <- result.try(client.build_get_request(config, path, []))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Parse JSON response
  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, supermarket_category_decoder.decoder()) {
        Ok(category) -> Ok(category)
        Error(errors) -> {
          let error_msg =
            "Failed to decode supermarket category: " <> string.inspect(errors)
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Failed to parse JSON response"))
  }
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
  let path = "/api/supermarket-category/"

  // Encode category data to JSON
  let body =
    supermarket_category_encoder.encode_supermarket_category_create(
      category_data,
    )
    |> json.to_string

  // Build and execute request
  use req <- result.try(client.build_post_request(config, path, body))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Convert to ApiResponse and parse JSON
  let api_resp = client.ApiResponse(resp.status, resp.headers, resp.body)
  client.parse_json_body(api_resp, fn(dyn) {
    decode.run(dyn, supermarket_category_decoder.decoder())
    |> result.map_error(fn(_) { "Failed to decode created category" })
  })
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
  let request_body =
    supermarket_category_encoder.encode_supermarket_category_create(
      category_data,
    )
    |> json.to_string

  // Build and execute PATCH request
  use req <- result.try(client.build_patch_request(config, path, request_body))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Parse JSON response
  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, supermarket_category_decoder.decoder()) {
        Ok(category) -> Ok(category)
        Error(errors) -> {
          let error_msg =
            "Failed to decode updated category: " <> string.inspect(errors)
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Failed to parse JSON response"))
  }
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

  // Build and execute DELETE request
  use req <- result.try(client.build_delete_request(config, path))

  use _resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // DELETE returns 204 No Content on success
  Ok(Nil)
}
