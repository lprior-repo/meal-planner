/// FatSecret Recipes API client
/// All recipe methods use 2-legged OAuth (no user token required)
/// API Docs: https://platform.fatsecret.com/api/Default.aspx?screen=rapiref2
import gleam/dict
import gleam/int
import gleam/json
import gleam/option.{type Option}
import gleam/result
import meal_planner/env.{type FatSecretConfig}
import meal_planner/fatsecret/client.{type FatSecretError}
import meal_planner/fatsecret/recipes/decoders
import meal_planner/fatsecret/recipes/types

// Re-export FatSecretError for convenience
pub type RecipeError =
  FatSecretError

/// Make a 2-legged API request for recipes (no user token required)
/// Uses the exposed make_api_request from client module
fn make_recipe_request(
  config: FatSecretConfig,
  method_name: String,
  params: dict.Dict(String, String),
) -> Result(String, FatSecretError) {
  client.make_api_request(config, method_name, params)
}

/// Get recipe details by ID (recipe.get.v2 - 2-legged)
pub fn get_recipe(
  config: FatSecretConfig,
  recipe_id: types.RecipeId,
) -> Result(String, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("recipe_id", types.recipe_id_to_string(recipe_id))

  // Use internal helper that will be exposed
  make_recipe_request(config, "recipe.get.v2", params)
}

/// Get recipe details and parse to Recipe type
pub fn get_recipe_parsed(
  config: FatSecretConfig,
  recipe_id: types.RecipeId,
) -> Result(types.Recipe, FatSecretError) {
  use response <- result.try(get_recipe(config, recipe_id))

  let recipe_decoder = decode.at(["recipe"], decoders.recipe_decoder())

  case json.parse(response, recipe_decoder) {
    Ok(recipe) -> Ok(recipe)
    Error(_) -> Error(client.ParseError("Failed to parse recipe: " <> response))
  }
}

/// Search for recipes (recipes.search.v3 - 2-legged)
pub fn search_recipes(
  config: FatSecretConfig,
  query: String,
  page_number: Option(Int),
  max_results: Option(Int),
) -> Result(String, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("search_expression", query)

  let params = case page_number {
    option.Some(page) -> dict.insert(params, "page_number", int.to_string(page))
    option.None -> params
  }

  let params = case max_results {
    option.Some(max) -> dict.insert(params, "max_results", int.to_string(max))
    option.None -> dict.insert(params, "max_results", "20")
  }

  make_recipe_request(config, "recipes.search.v3", params)
}

/// Search for recipes and parse response
pub fn search_recipes_parsed(
  config: FatSecretConfig,
  query: String,
  page_number: Option(Int),
  max_results: Option(Int),
) -> Result(types.RecipeSearchResponse, FatSecretError) {
  use response <- result.try(search_recipes(
    config,
    query,
    page_number,
    max_results,
  ))

  case json.parse(response, decoders.recipe_search_response_decoder()) {
    Ok(search_response) -> Ok(search_response)
    Error(_) ->
      Error(client.ParseError("Failed to parse recipe search: " <> response))
  }
}

/// Get all recipe types/categories (recipe_types.get.v2 - 2-legged)
pub fn get_recipe_types(
  config: FatSecretConfig,
) -> Result(String, FatSecretError) {
  make_recipe_request(config, "recipe_types.get.v2", dict.new())
}

/// Get recipe types and parse response
pub fn get_recipe_types_parsed(
  config: FatSecretConfig,
) -> Result(types.RecipeTypesResponse, FatSecretError) {
  use response <- result.try(get_recipe_types(config))

  case json.parse(response, decoders.recipe_types_response_decoder()) {
    Ok(types_response) -> Ok(types_response)
    Error(_) ->
      Error(client.ParseError("Failed to parse recipe types: " <> response))
  }
}

/// Filter recipes by type (recipes.search.v3 with recipe_type_id)
pub fn search_recipes_by_type(
  config: FatSecretConfig,
  recipe_type_id: String,
  page_number: Option(Int),
  max_results: Option(Int),
) -> Result(String, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("recipe_type_id", recipe_type_id)

  let params = case page_number {
    option.Some(page) -> dict.insert(params, "page_number", int.to_string(page))
    option.None -> params
  }

  let params = case max_results {
    option.Some(max) -> dict.insert(params, "max_results", int.to_string(max))
    option.None -> dict.insert(params, "max_results", "20")
  }

  make_recipe_request(config, "recipes.search.v3", params)
}

/// Search recipes by type and parse response
pub fn search_recipes_by_type_parsed(
  config: FatSecretConfig,
  recipe_type_id: String,
  page_number: Option(Int),
  max_results: Option(Int),
) -> Result(types.RecipeSearchResponse, FatSecretError) {
  use response <- result.try(search_recipes_by_type(
    config,
    recipe_type_id,
    page_number,
    max_results,
  ))

  case json.parse(response, decoders.recipe_search_response_decoder()) {
    Ok(search_response) -> Ok(search_response)
    Error(_) ->
      Error(client.ParseError("Failed to parse recipe search: " <> response))
  }
}
