/// Tests for Tandoor mapper module
///
/// Tests the conversion between Tandoor API format and internal Recipe format
import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/id
import meal_planner/tandoor/mapper.{
  type TandoorNutrition, type TandoorRecipe, type TandoorRecipeStep,
  TandoorNutrition, TandoorRecipe, TandoorRecipeStep, extract_category,
  infer_fodmap_level, recipe_to_tandoor, tandoor_recipes_to_list,
  tandoor_recipes_to_list_with_errors, tandoor_to_recipe,
}
import meal_planner/types.{High, Low, Macros, Medium, Recipe}

pub fn main() {
  gleeunit.main()
}

// Test helper: Create a basic Tandoor recipe
fn make_tandoor_recipe(
  id: Int,
  name: String,
  protein: Float,
  fat: Float,
  carbs: Float,
) -> TandoorRecipe {
  TandoorRecipe(
    id: id,
    name: name,
    slug: "test-recipe",
    author: "test-user",
    description: "Test recipe",
    keywords: ["protein"],
    servings: 1,
    servings_text: "1 serving",
    prep_time: 10,
    cook_time: 20,
    nutrition: Some(TandoorNutrition(
      energy: Some(protein *. 4.0 +. fat *. 9.0 +. carbs *. 4.0),
      protein: Some(protein),
      fat: Some(fat),
      carbohydrates: Some(carbs),
    )),
    steps: [
      TandoorRecipeStep(
        step: 1,
        instruction: "Mix ingredients",
        ingredients: [],
      ),
      TandoorRecipeStep(step: 2, instruction: "Cook", ingredients: []),
    ],
  )
}

/// Test basic Tandoor to Recipe conversion
pub fn tandoor_to_recipe_basic_test() {
  let tandoor = make_tandoor_recipe(1, "Test Recipe", 30.0, 20.0, 50.0)

  let result = tandoor_to_recipe(tandoor)

  result
  |> should.be_ok()

  case result {
    Ok(recipe) -> {
      recipe.name
      |> should.equal("Test Recipe")
      recipe.servings
      |> should.equal(1)
      recipe.macros.protein
      |> should.equal(30.0)
      recipe.macros.fat
      |> should.equal(20.0)
      recipe.macros.carbs
      |> should.equal(50.0)
      recipe.instructions
      |> list.length()
      |> should.equal(2)
    }
    Error(_) -> should.fail("Conversion should not fail")
  }
}

/// Test extraction of macros from nutrition
pub fn extract_macros_from_nutrition_test() {
  let tandoor =
    TandoorRecipe(
      id: 1,
      name: "Nutrition Test",
      slug: "nutrition-test",
      author: "test",
      description: "Test",
      keywords: [],
      servings: 1,
      servings_text: "1 serving",
      prep_time: 0,
      cook_time: 0,
      nutrition: Some(TandoorNutrition(
        energy: Some(500.0),
        protein: Some(40.0),
        fat: Some(25.0),
        carbohydrates: Some(35.0),
      )),
      steps: [],
    )

  case tandoor_to_recipe(tandoor) {
    Ok(recipe) -> {
      recipe.macros.protein |> should.equal(40.0)
      recipe.macros.fat |> should.equal(25.0)
      recipe.macros.carbs |> should.equal(35.0)
    }
    Error(_) -> should.fail("Conversion should succeed")
  }
}

/// Test handling of missing nutrition data
pub fn missing_nutrition_test() {
  let tandoor =
    TandoorRecipe(
      id: 1,
      name: "No Nutrition",
      slug: "no-nutrition",
      author: "test",
      description: "Test",
      keywords: [],
      servings: 1,
      servings_text: "1 serving",
      prep_time: 0,
      cook_time: 0,
      nutrition: None,
      steps: [],
    )

  case tandoor_to_recipe(tandoor) {
    Ok(recipe) -> {
      recipe.macros.protein |> should.equal(0.0)
      recipe.macros.fat |> should.equal(0.0)
      recipe.macros.carbs |> should.equal(0.0)
    }
    Error(_) -> should.fail("Conversion should handle missing nutrition")
  }
}

/// Test category extraction from keywords
pub fn extract_category_protein_test() {
  extract_category(["beef", "vertical-diet"])
  |> should.equal("Protein")
}

pub fn extract_category_vegetable_test() {
  extract_category(["vegetables", "salad"])
  |> should.equal("Vegetable")
}

pub fn extract_category_sauce_test() {
  extract_category(["sauce", "dressing"])
  |> should.equal("Sauce")
}

pub fn extract_category_default_test() {
  extract_category(["random", "unknown"])
  |> should.equal("Other")
}

/// Test FODMAP level inference
pub fn infer_fodmap_low_explicit_test() {
  infer_fodmap_level(["low-fodmap"], "Low FODMAP recipe")
  |> should.equal(Low)
}

pub fn infer_fodmap_high_explicit_test() {
  infer_fodmap_level(["high-fodmap"], "High FODMAP recipe")
  |> should.equal(High)
}

pub fn infer_fodmap_from_keywords_test() {
  infer_fodmap_level(["protein", "beef"], "Protein recipe")
  |> should.equal(Low)
}

pub fn infer_fodmap_default_test() {
  infer_fodmap_level(["unknown", "random"], "Unknown recipe")
  |> should.equal(Medium)
}

/// Test vertical diet compliance detection
pub fn vertical_diet_compliance_test() {
  let tandoor =
    TandoorRecipe(
      id: 1,
      name: "Vertical Diet Recipe",
      slug: "vertical-diet-recipe",
      author: "test",
      description: "Test",
      keywords: ["beef", "vertical-diet"],
      servings: 1,
      servings_text: "1 serving",
      prep_time: 0,
      cook_time: 0,
      nutrition: None,
      steps: [],
    )

  case tandoor_to_recipe(tandoor) {
    Ok(recipe) -> {
      recipe.vertical_compliant
      |> should.be_true()
    }
    Error(_) -> should.fail("Conversion should succeed")
  }
}

/// Test recipe to Tandoor conversion
pub fn recipe_to_tandoor_basic_test() {
  let recipe =
    Recipe(
      id: id.recipe_id("test-recipe"),
      name: "Test Recipe",
      ingredients: [],
      instructions: ["Mix", "Cook"],
      macros: Macros(protein: 30.0, fat: 20.0, carbs: 50.0),
      servings: 1,
      category: "Protein",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let tandoor = recipe_to_tandoor(recipe)

  tandoor.name
  |> should.equal("Test Recipe")
  tandoor.servings
  |> should.equal(1)
  tandoor.nutrition
  |> should.be_ok()
  tandoor.keywords
  |> should.contain("protein")
  tandoor.keywords
  |> should.contain("low-fodmap")
  tandoor.keywords
  |> should.contain("vertical-diet")
}

/// Test bulk recipe conversion
pub fn bulk_recipe_conversion_test() {
  let tandoor_recipes = [
    make_tandoor_recipe(1, "Recipe 1", 30.0, 20.0, 50.0),
    make_tandoor_recipe(2, "Recipe 2", 35.0, 25.0, 45.0),
    make_tandoor_recipe(3, "Recipe 3", 28.0, 22.0, 48.0),
  ]

  let recipes = tandoor_recipes_to_list(tandoor_recipes)

  recipes
  |> list.length()
  |> should.equal(3)
}

/// Test bulk conversion with error tracking
pub fn bulk_conversion_with_errors_test() {
  let tandoor_recipes = [
    make_tandoor_recipe(1, "Valid Recipe", 30.0, 20.0, 50.0),
  ]

  let #(successful, errors) =
    tandoor_recipes_to_list_with_errors(tandoor_recipes)

  successful
  |> list.length()
  |> should.equal(1)
  errors
  |> list.length()
  |> should.equal(0)
}

/// Test instructions extraction and ordering
pub fn instructions_ordering_test() {
  let tandoor =
    TandoorRecipe(
      id: 1,
      name: "Ordered Steps",
      slug: "ordered-steps",
      author: "test",
      description: "Test",
      keywords: [],
      servings: 1,
      servings_text: "1 serving",
      prep_time: 0,
      cook_time: 0,
      nutrition: None,
      steps: [
        TandoorRecipeStep(step: 3, instruction: "Finish", ingredients: []),
        TandoorRecipeStep(step: 1, instruction: "Start", ingredients: []),
        TandoorRecipeStep(step: 2, instruction: "Middle", ingredients: []),
      ],
    )

  case tandoor_to_recipe(tandoor) {
    Ok(recipe) -> {
      recipe.instructions
      |> should.equal(["Start", "Middle", "Finish"])
    }
    Error(_) -> should.fail("Conversion should succeed")
  }
}

// Import list module for additional tests
import gleam/list
