/// Tests for FatSecret Recipes domain
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/fatsecret/recipes/types

pub fn recipe_id_creation_test() {
  let id = types.recipe_id("12345")
  types.recipe_id_to_string(id)
  |> should.equal("12345")
}

pub fn recipe_id_opaque_test() {
  // This test verifies that RecipeId is opaque
  // We can create it but cannot directly access the inner string
  let id1 = types.recipe_id("123")
  let id2 = types.recipe_id("123")

  // Can convert to string
  types.recipe_id_to_string(id1)
  |> should.equal("123")

  types.recipe_id_to_string(id2)
  |> should.equal("123")
}

pub fn recipe_ingredient_creation_test() {
  let ingredient =
    types.RecipeIngredient(
      food_id: "1234",
      food_name: "Chicken Breast",
      serving_id: Some("5678"),
      number_of_units: 2.0,
      measurement_description: "cup",
      ingredient_description: "2 cups diced chicken breast",
      ingredient_url: Some("https://example.com/chicken"),
    )

  ingredient.food_name
  |> should.equal("Chicken Breast")

  ingredient.number_of_units
  |> should.equal(2.0)
}

pub fn recipe_direction_creation_test() {
  let direction =
    types.RecipeDirection(
      direction_number: 1,
      direction_description: "Preheat oven to 350F",
    )

  direction.direction_number
  |> should.equal(1)

  direction.direction_description
  |> should.equal("Preheat oven to 350F")
}

pub fn recipe_type_creation_test() {
  let recipe_type =
    types.RecipeType(recipe_type_id: "1", recipe_type: "Breakfast")

  recipe_type.recipe_type
  |> should.equal("Breakfast")
}

pub fn recipe_creation_test() {
  let recipe =
    types.Recipe(
      recipe_id: types.recipe_id("123"),
      recipe_name: "Test Recipe",
      recipe_url: "https://example.com/recipe",
      recipe_description: "A test recipe",
      recipe_image: Some("https://example.com/image.jpg"),
      number_of_servings: 4.0,
      preparation_time_min: Some(15),
      cooking_time_min: Some(30),
      rating: Some(4.5),
      recipe_types: [types.RecipeType("1", "Breakfast")],
      ingredients: [],
      directions: [],
      calories: Some(250.0),
      carbohydrate: Some(30.0),
      protein: Some(20.0),
      fat: Some(10.0),
      saturated_fat: None,
      polyunsaturated_fat: None,
      monounsaturated_fat: None,
      cholesterol: None,
      sodium: None,
      potassium: None,
      fiber: None,
      sugar: None,
      vitamin_a: None,
      vitamin_c: None,
      calcium: None,
      iron: None,
    )

  recipe.recipe_name
  |> should.equal("Test Recipe")

  recipe.number_of_servings
  |> should.equal(4.0)

  types.recipe_id_to_string(recipe.recipe_id)
  |> should.equal("123")
}

pub fn recipe_search_result_creation_test() {
  let result =
    types.RecipeSearchResult(
      recipe_id: types.recipe_id("456"),
      recipe_name: "Search Result Recipe",
      recipe_description: "A recipe from search",
      recipe_url: "https://example.com/search-recipe",
      recipe_image: Some("https://example.com/search-image.jpg"),
    )

  result.recipe_name
  |> should.equal("Search Result Recipe")

  types.recipe_id_to_string(result.recipe_id)
  |> should.equal("456")
}

pub fn recipe_search_response_creation_test() {
  let response =
    types.RecipeSearchResponse(
      recipes: [
        types.RecipeSearchResult(
          recipe_id: types.recipe_id("1"),
          recipe_name: "Recipe 1",
          recipe_description: "First recipe",
          recipe_url: "https://example.com/1",
          recipe_image: None,
        ),
        types.RecipeSearchResult(
          recipe_id: types.recipe_id("2"),
          recipe_name: "Recipe 2",
          recipe_description: "Second recipe",
          recipe_url: "https://example.com/2",
          recipe_image: Some("https://example.com/2.jpg"),
        ),
      ],
      max_results: 20,
      total_results: 42,
      page_number: 1,
    )

  response.total_results
  |> should.equal(42)

  response.page_number
  |> should.equal(1)

  response.recipes
  |> list.length
  |> should.equal(2)
}

pub fn recipe_types_response_creation_test() {
  let response =
    types.RecipeTypesResponse(recipe_types: [
      types.RecipeType("1", "Breakfast"),
      types.RecipeType("2", "Lunch"),
      types.RecipeType("3", "Dinner"),
    ])

  response.recipe_types
  |> list.length
  |> should.equal(3)
}
