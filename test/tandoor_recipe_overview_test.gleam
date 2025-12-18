//// Unit Tests for RecipeOverview JSON Decoding
////
//// Tests for parsing RecipeOverview from Tandoor API JSON responses.
//// Validates that keywords are parsed as full Keyword objects (id, name, description)
//// rather than just strings, as per Tandoor API 2.3.6 spec.

import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/tandoor/recipe

pub fn main() {
  gleeunit.main()
}

// =============================================================================
// Test Fixtures
// =============================================================================

/// Sample RecipeOverview JSON response from Tandoor API
/// Includes full Keyword objects with id, name, description
fn recipe_overview_json_response() -> String {
  "{
    \"id\": 42,
    \"name\": \"Pasta Carbonara\",
    \"description\": \"Classic Italian pasta dish\",
    \"image\": \"https://example.com/image.jpg\",
    \"keywords\": [
      {\"id\": 1, \"name\": \"Italian\", \"description\": \"Italian cuisine\"},
      {\"id\": 2, \"name\": \"Pasta\", \"description\": \"Pasta dishes\"},
      {\"id\": 3, \"name\": \"Quick\", \"description\": \"Quick recipes\"}
    ],
    \"rating\": 4.5,
    \"last_cooked\": \"2024-01-10T18:30:00Z\"
  }"
}

// =============================================================================
// Tests
// =============================================================================

/// Test that RecipeOverview decoder parses keywords as full Keyword objects
pub fn test_recipe_overview_decodes_keywords_as_keyword_objects() {
  let json_str = recipe_overview_json_response()

  case json.parse(json_str, recipe.recipe_overview_decoder()) {
    Ok(overview) -> {
      overview.id
      |> should.equal(42)

      overview.name
      |> should.equal("Pasta Carbonara")

      // Verify keywords list has 3 items (not strings, but Keyword objects)
      list.length(overview.keywords)
      |> should.equal(3)

      // Verify first keyword is properly structured
      case overview.keywords {
        [first, second, third] -> {
          first.id
          |> should.equal(1)

          first.name
          |> should.equal("Italian")

          first.description
          |> should.equal("Italian cuisine")

          second.id
          |> should.equal(2)

          second.name
          |> should.equal("Pasta")

          third.id
          |> should.equal(3)

          third.name
          |> should.equal("Quick")

          Nil
        }
        _ -> should.fail()
      }

      overview.rating
      |> should.equal(Some(4.5))

      overview.last_cooked
      |> should.equal(Some("2024-01-10T18:30:00Z"))
    }
    Error(_) -> should.fail()
  }
}

/// Test that RecipeOverview decoder handles missing optional fields
pub fn test_recipe_overview_with_missing_optional_fields() {
  let json_str =
    "{
    \"id\": 10,
    \"name\": \"Simple Recipe\",
    \"description\": \"A simple recipe\",
    \"image\": null,
    \"keywords\": [],
    \"rating\": null,
    \"last_cooked\": null
  }"

  case json.parse(json_str, recipe.recipe_overview_decoder()) {
    Ok(overview) -> {
      overview.id
      |> should.equal(10)

      overview.image
      |> should.equal(None)

      overview.keywords
      |> should.equal([])

      overview.rating
      |> should.equal(None)

      overview.last_cooked
      |> should.equal(None)
    }
    Error(_) -> should.fail()
  }
}
