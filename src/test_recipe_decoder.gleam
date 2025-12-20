import gleam/io
import gleam/json
import meal_planner/fatsecret/recipes/decoders

pub fn main() {
  // Test 1: Empty results
  let empty_json =
    "{\"recipes\": {\"max_results\": 20, \"total_results\": 0, \"page_number\": 0}}"
  case json.parse(empty_json, decoders.recipe_search_response_decoder()) {
    Ok(response) -> {
      io.println("✓ Empty results test PASSED")
      io.println(
        "  Recipes count: " <> String.inspect(List.length(response.recipes)),
      )
      io.println("  Total results: " <> String.inspect(response.total_results))
    }
    Error(_) -> io.println("✗ Empty results test FAILED")
  }

  // Test 2: Single recipe
  let single_json =
    "{\"recipes\": {\"recipe\": {\"recipe_id\": \"123\", \"recipe_name\": \"Test\", \"recipe_description\": \"Desc\", \"recipe_url\": \"http://example.com\"}, \"max_results\": 20, \"total_results\": 1, \"page_number\": 0}}"
  case json.parse(single_json, decoders.recipe_search_response_decoder()) {
    Ok(response) -> {
      io.println("✓ Single recipe test PASSED")
      io.println(
        "  Recipes count: " <> String.inspect(List.length(response.recipes)),
      )
    }
    Error(_) -> io.println("✗ Single recipe test FAILED")
  }

  // Test 3: Multiple recipes
  let multi_json =
    "{\"recipes\": {\"recipe\": [{\"recipe_id\": \"1\", \"recipe_name\": \"A\", \"recipe_description\": \"D1\", \"recipe_url\": \"http://a.com\"}, {\"recipe_id\": \"2\", \"recipe_name\": \"B\", \"recipe_description\": \"D2\", \"recipe_url\": \"http://b.com\"}], \"max_results\": 20, \"total_results\": 2, \"page_number\": 0}}"
  case json.parse(multi_json, decoders.recipe_search_response_decoder()) {
    Ok(response) -> {
      io.println("✓ Multiple recipes test PASSED")
      io.println(
        "  Recipes count: " <> String.inspect(List.length(response.recipes)),
      )
    }
    Error(e) -> {
      io.println("✗ Multiple recipes test FAILED")
      io.debug(e)
    }
  }
}
