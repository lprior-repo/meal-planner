/// Tests for fatsecret CLI domain
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/cli/domains/fatsecret
import meal_planner/env
import meal_planner/fatsecret/foods/types as food_types
import meal_planner/fatsecret/recipes/types as recipe_types

// ============================================================================
// Search Command Tests
// ============================================================================

/// Test search_foods function with valid query
/// Should call FatSecret foods API and return formatted results
pub fn search_foods_with_query_test() {
  // Skip test if FatSecret not configured
  case env.load_fatsecret_config() {
    None -> Nil
    Some(config) -> {
      let result = fatsecret.search_foods(config, "banana")

      result
      |> should.be_ok

      case result {
        Ok(output) -> {
          output
          |> should.not_equal("")
        }
        Error(_) -> should.fail()
      }
    }
  }
}

/// Test search_foods with empty results
/// Should handle gracefully when no foods found
pub fn search_foods_no_results_test() {
  case env.load_fatsecret_config() {
    None -> Nil
    Some(config) -> {
      let result = fatsecret.search_foods(config, "xyznonexistentfood123")

      result
      |> should.be_ok

      case result {
        Ok(output) -> {
          output
          |> should.not_equal("")
        }
        Error(_) -> should.fail()
      }
    }
  }
}

/// Test format_food_search_result helper
/// Should format a single food search result into readable string
pub fn format_food_search_result_test() {
  let food_result =
    food_types.FoodSearchResult(
      food_id: food_types.food_id("12345"),
      food_name: "Banana",
      food_type: "Generic",
      food_description: "Per 100g - Calories: 89kcal | Fat: 0.33g | Carbs: 22.84g | Protein: 1.09g",
      brand_name: None,
      food_url: "https://www.fatsecret.com/calories-nutrition/generic/banana",
    )

  let formatted = fatsecret.format_food_search_result(food_result)

  formatted
  |> should.not_equal("")
}

/// Test format_food_search_results helper
/// Should format list of food results into table
pub fn format_food_search_results_test() {
  let results = [
    food_types.FoodSearchResult(
      food_id: food_types.food_id("12345"),
      food_name: "Banana",
      food_type: "Generic",
      food_description: "Per 100g - Calories: 89kcal",
      brand_name: None,
      food_url: "https://example.com",
    ),
    food_types.FoodSearchResult(
      food_id: food_types.food_id("67890"),
      food_name: "Apple",
      food_type: "Generic",
      food_description: "Per 100g - Calories: 52kcal",
      brand_name: Some("Brand"),
      food_url: "https://example.com",
    ),
  ]

  let formatted = fatsecret.format_food_search_results(results)

  formatted
  |> should.not_equal("")
}

// ============================================================================
// Ingredients Command Tests
// ============================================================================

/// Test get_recipe_ingredients function with valid recipe ID
/// Should call FatSecret recipe API and return formatted ingredients
pub fn get_recipe_ingredients_with_id_test() {
  case env.load_fatsecret_config() {
    None -> Nil
    Some(config) -> {
      // Using a known FatSecret recipe ID (this may need to be updated)
      let result =
        fatsecret.get_recipe_ingredients(config, recipe_types.recipe_id("1234"))

      result
      |> should.be_ok

      case result {
        Ok(output) -> {
          output
          |> should.not_equal("")
        }
        Error(_) -> should.fail()
      }
    }
  }
}

/// Test format_recipe_ingredient helper
/// Should format a single ingredient into readable string
pub fn format_recipe_ingredient_test() {
  let ingredient =
    recipe_types.RecipeIngredient(
      food_id: "12345",
      food_name: "Chicken Breast",
      serving_id: Some("67890"),
      number_of_units: 2.0,
      measurement_description: "breast",
      ingredient_description: "2 breasts chicken breast",
      ingredient_url: Some("https://example.com"),
    )

  let formatted = fatsecret.format_recipe_ingredient(ingredient)

  formatted
  |> should.not_equal("")
}

/// Test format_recipe_ingredients helper
/// Should format list of ingredients into numbered list
pub fn format_recipe_ingredients_test() {
  let ingredients = [
    recipe_types.RecipeIngredient(
      food_id: "12345",
      food_name: "Chicken Breast",
      serving_id: None,
      number_of_units: 2.0,
      measurement_description: "breast",
      ingredient_description: "2 breasts chicken breast",
      ingredient_url: None,
    ),
    recipe_types.RecipeIngredient(
      food_id: "67890",
      food_name: "Rice",
      serving_id: None,
      number_of_units: 1.0,
      measurement_description: "cup",
      ingredient_description: "1 cup rice",
      ingredient_url: None,
    ),
  ]

  let formatted = fatsecret.format_recipe_ingredients(ingredients)

  formatted
  |> should.not_equal("")
}

/// Test format_recipe_info helper
/// Should format recipe information (name, servings, etc.)
pub fn format_recipe_info_test() {
  let recipe =
    recipe_types.Recipe(
      recipe_id: recipe_types.recipe_id("1234"),
      recipe_name: "Grilled Chicken with Rice",
      recipe_url: "https://example.com",
      recipe_description: "A healthy chicken and rice dish",
      recipe_image: Some("https://example.com/image.jpg"),
      number_of_servings: 4.0,
      preparation_time_min: Some(15),
      cooking_time_min: Some(30),
      rating: Some(4.5),
      recipe_types: ["Main Dish"],
      ingredients: [],
      directions: [],
      calories: Some(350.0),
      carbohydrate: Some(45.0),
      protein: Some(30.0),
      fat: Some(8.0),
      saturated_fat: Some(2.0),
      polyunsaturated_fat: None,
      monounsaturated_fat: None,
      cholesterol: None,
      sodium: None,
      potassium: None,
      fiber: Some(3.0),
      sugar: Some(2.0),
      vitamin_a: None,
      vitamin_c: None,
      calcium: None,
      iron: None,
    )

  let formatted = fatsecret.format_recipe_info(recipe)

  formatted
  |> should.not_equal("")
}
