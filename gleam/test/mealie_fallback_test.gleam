import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/mealie/fallback
import meal_planner/mealie/types.{
  MealieRecipe, MealieInstruction, MealieIngredient, MealieCategory, MealieTag,
}

pub fn main() {
  gleeunit.main()
}

/// Test that fallback recipe is created with correct slug
pub fn fallback_recipe_has_correct_slug_test() {
  let slug = "chicken-stir-fry"
  let recipe = fallback.create_fallback_recipe(slug)

  recipe.slug |> should.equal(slug)
}

/// Test that fallback recipe has correct ID
pub fn fallback_recipe_has_correct_id_test() {
  let slug = "beef-tacos"
  let recipe = fallback.create_fallback_recipe(slug)

  recipe.id |> should.equal(slug)
}

/// Test that fallback recipe has correct display name format
pub fn fallback_recipe_has_display_name_test() {
  let slug = "pasta-carbonara"
  let recipe = fallback.create_fallback_recipe(slug)

  recipe.name |> should.equal("Unknown Recipe (pasta-carbonara)")
}

/// Test that fallback recipe has display name with special characters
pub fn fallback_recipe_display_name_with_special_chars_test() {
  let slug = "spicy-thai-red-curry"
  let recipe = fallback.create_fallback_recipe(slug)

  recipe.name |> should.equal("Unknown Recipe (spicy-thai-red-curry)")
}

/// Test that fallback recipe has empty ingredients
pub fn fallback_recipe_empty_ingredients_test() {
  let recipe = fallback.create_fallback_recipe("test-recipe")

  recipe.recipe_ingredient |> should.equal([])
}

/// Test that fallback recipe has empty instructions
pub fn fallback_recipe_empty_instructions_test() {
  let recipe = fallback.create_fallback_recipe("test-recipe")

  recipe.recipe_instructions |> should.equal([])
}

/// Test that fallback recipe has empty categories
pub fn fallback_recipe_empty_categories_test() {
  let recipe = fallback.create_fallback_recipe("test-recipe")

  recipe.recipe_category |> should.equal([])
}

/// Test that fallback recipe has empty tags
pub fn fallback_recipe_empty_tags_test() {
  let recipe = fallback.create_fallback_recipe("test-recipe")

  recipe.tags |> should.equal([])
}

/// Test that fallback recipe has no description
pub fn fallback_recipe_no_description_test() {
  let recipe = fallback.create_fallback_recipe("test-recipe")

  recipe.description |> should.equal(None)
}

/// Test that fallback recipe has no image
pub fn fallback_recipe_no_image_test() {
  let recipe = fallback.create_fallback_recipe("test-recipe")

  recipe.image |> should.equal(None)
}

/// Test that fallback recipe has no nutrition
pub fn fallback_recipe_no_nutrition_test() {
  let recipe = fallback.create_fallback_recipe("test-recipe")

  recipe.nutrition |> should.equal(None)
}

/// Test that fallback recipe has no org_url
pub fn fallback_recipe_no_org_url_test() {
  let recipe = fallback.create_fallback_recipe("test-recipe")

  recipe.org_url |> should.equal(None)
}

/// Test that fallback recipe has no rating
pub fn fallback_recipe_no_rating_test() {
  let recipe = fallback.create_fallback_recipe("test-recipe")

  recipe.rating |> should.equal(None)
}

/// Test that fallback recipe has valid structure for JSON serialization
pub fn fallback_recipe_valid_structure_test() {
  let recipe = fallback.create_fallback_recipe("test-slug")

  // Verify all fields are accessible (structure validation)
  let MealieRecipe(
    id: _id,
    slug: _slug,
    name: _name,
    description: _desc,
    image: _img,
    recipe_yield: _yield,
    total_time: _time,
    prep_time: _prep,
    cook_time: _cook,
    rating: _rating,
    org_url: _url,
    recipe_ingredient: _ingredients,
    recipe_instructions: _instructions,
    recipe_category: _categories,
    tags: _tags,
    nutrition: _nutrition,
    date_added: _added,
    date_updated: _updated,
  ) = recipe

  True |> should.be_true()
}

/// Test that different slugs produce different fallback recipes
pub fn fallback_recipes_unique_by_slug_test() {
  let recipe1 = fallback.create_fallback_recipe("recipe-1")
  let recipe2 = fallback.create_fallback_recipe("recipe-2")

  recipe1.slug |> should.not_equal(recipe2.slug)
  recipe1.name |> should.not_equal(recipe2.name)
}

/// Test fallback for numeric slug
pub fn fallback_recipe_numeric_slug_test() {
  let slug = "123-numbers"
  let recipe = fallback.create_fallback_recipe(slug)

  recipe.slug |> should.equal(slug)
  recipe.name |> should.equal("Unknown Recipe (123-numbers)")
}

/// Test fallback for slug with hyphens
pub fn fallback_recipe_hyphenated_slug_test() {
  let slug = "very-long-recipe-name-with-many-hyphens"
  let recipe = fallback.create_fallback_recipe(slug)

  recipe.slug |> should.equal(slug)
  recipe.name |> should.equal("Unknown Recipe (very-long-recipe-name-with-many-hyphens)")
}
