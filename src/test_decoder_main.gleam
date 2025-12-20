import gleam/int
import gleam/io
import gleam/json
import gleam/list
import meal_planner/fatsecret/recipes/decoders

pub fn main() {
  io.println("\n=== Testing Recipe Search Decoder Fix ===\n")

  test_empty_results()
  test_single_recipe()
  test_multiple_recipes()

  io.println("\n=== All Tests Complete ===\n")
}

fn test_empty_results() {
  io.println("Test 1: Empty search results (no recipe field)")
  let empty_json = "{\"recipes\": {\"max_results\": 20, \"total_results\": 0, \"page_number\": 0}}"
  case json.parse(empty_json, decoders.recipe_search_response_decoder()) {
    Ok(response) -> {
      io.println("✓ PASSED")
      io.println("  Recipes count: " <> int.to_string(list.length(response.recipes)))
      io.println("  Total results: " <> int.to_string(response.total_results))
      io.println("")
    }
    Error(_e) -> {
      io.println("✗ FAILED - Could not parse empty results")
      io.println("")
    }
  }
}

fn test_single_recipe() {
  io.println("Test 2: Single recipe result")
  let single_json = "{\"recipes\": {\"recipe\": {\"recipe_id\": \"123\", \"recipe_name\": \"Chicken Curry\", \"recipe_description\": \"A delicious curry\", \"recipe_url\": \"http://example.com/123\"}, \"max_results\": 20, \"total_results\": 1, \"page_number\": 0}}"
  case json.parse(single_json, decoders.recipe_search_response_decoder()) {
    Ok(response) -> {
      io.println("✓ PASSED")
      io.println("  Recipes count: " <> int.to_string(list.length(response.recipes)))
      io.println("  Total results: " <> int.to_string(response.total_results))
      io.println("")
    }
    Error(_e) -> {
      io.println("✗ FAILED - Could not parse single recipe")
      io.println("")
    }
  }
}

fn test_multiple_recipes() {
  io.println("Test 3: Multiple recipe results")
  let multi_json = "{\"recipes\": {\"recipe\": [{\"recipe_id\": \"1\", \"recipe_name\": \"Recipe A\", \"recipe_description\": \"Description A\", \"recipe_url\": \"http://example.com/1\"}, {\"recipe_id\": \"2\", \"recipe_name\": \"Recipe B\", \"recipe_description\": \"Description B\", \"recipe_url\": \"http://example.com/2\"}], \"max_results\": 20, \"total_results\": 2, \"page_number\": 0}}"
  case json.parse(multi_json, decoders.recipe_search_response_decoder()) {
    Ok(response) -> {
      io.println("✓ PASSED")
      io.println("  Recipes count: " <> int.to_string(list.length(response.recipes)))
      io.println("  Total results: " <> int.to_string(response.total_results))
      io.println("")
    }
    Error(_e) -> {
      io.println("✗ FAILED - Could not parse multiple recipes")
      io.println("")
    }
  }
}
