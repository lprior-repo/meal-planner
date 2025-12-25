/// Tests for recipe browser model types
///
/// This module tests the construction and manipulation of recipe browser
/// model types following the MVC pattern.
import gleam/dict
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/cli/screens/recipe_browser/model
import meal_planner/fatsecret/recipes/types as recipe_types

pub fn init_recipe_model_test() {
  let m = model.init()

  // Verify initial state
  m.view_state |> should.equal(model.ListView)
  m.recipes |> should.equal([])
  m.selected_recipe |> should.equal(None)
  m.is_loading |> should.equal(False)
  m.error_message |> should.equal(None)
  m.favorites |> should.equal([])
  m.recipe_cache |> dict.size() |> should.equal(0)
  m.recent_recipes |> should.equal([])
}

pub fn create_recipe_list_item_test() {
  let recipe_id = recipe_types.RecipeId(1234)
  let item =
    model.RecipeListItem(
      recipe_id: recipe_id,
      recipe_name: "Spaghetti Carbonara",
      recipe_description: "Classic Italian pasta dish",
      calories_per_serving: Some(450.0),
      cooking_time_min: Some(30),
      number_of_servings: 4.0,
      is_favorite: False,
      rating: Some(4.5),
    )

  item.recipe_id |> should.equal(recipe_id)
  item.recipe_name |> should.equal("Spaghetti Carbonara")
  item.number_of_servings |> should.equal(4.0)
}

pub fn pagination_state_test() {
  let pagination =
    model.PaginationState(
      current_page: 1,
      total_results: 100,
      results_per_page: 20,
      total_pages: 5,
    )

  pagination.current_page |> should.equal(1)
  pagination.total_pages |> should.equal(5)
}

pub fn recipe_filters_default_test() {
  let filters = model.default_filters()

  filters.max_calories |> should.equal(None)
  filters.max_prep_time |> should.equal(None)
  filters.min_protein |> should.equal(None)
  filters.cuisine_type |> should.equal(None)
  filters.diet_type |> should.equal(None)
  filters.sort_by |> should.equal(model.SortByName)
}

pub fn search_state_init_test() {
  let search = model.init_search_state()

  search.query |> should.equal("")
  search.search_type |> should.equal(model.ByName)
  search.is_loading |> should.equal(False)
  search.error |> should.equal(None)
}
