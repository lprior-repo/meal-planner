/// FatSecret Display Formatters
///
/// This module provides formatting functions for displaying FatSecret
/// food and recipe data in a consistent, readable format.
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/string
import meal_planner/fatsecret/foods/types as food_types
import meal_planner/fatsecret/recipes/types as recipe_types

// ============================================================================
// Food Display
// ============================================================================

/// Display food details in formatted output
pub fn display_food_details(food: food_types.Food) -> Nil {
  io.println("\n" <> repeat("=", 80))
  io.println("FOOD DETAILS")
  io.println(repeat("=", 80))
  io.println("")

  // Food header
  io.println("Name: " <> food.food_name)
  io.println("Type: " <> food.food_type)
  case food.brand_name {
    option.Some(brand) -> io.println("Brand: " <> brand)
    option.None -> Nil
  }
  io.println("FatSecret URL: " <> food.food_url)
  io.println("")

  // Servings section
  io.println(
    "AVAILABLE SERVINGS ("
    <> int.to_string(list.length(food.servings))
    <> " options)",
  )
  io.println(repeat("-", 80))
  io.println("")

  // Display each serving
  food.servings
  |> list.each(fn(serving) { display_serving(serving) })

  io.println(repeat("=", 80))
  io.println("")
}

/// Display a single serving with nutrition info
pub fn display_serving(serving: food_types.Serving) -> Nil {
  // Serving header
  io.println("Serving: " <> serving.serving_description)
  io.println(
    "  Measurement: "
    <> float.to_string(serving.number_of_units)
    <> " "
    <> serving.measurement_description,
  )

  // Metric info if available
  case serving.metric_serving_amount, serving.metric_serving_unit {
    option.Some(amount), option.Some(unit) ->
      io.println("  Metric: " <> float.to_string(amount) <> unit)
    _, _ -> Nil
  }

  // Is default serving?
  case serving.is_default {
    option.Some(1) -> io.println("  [DEFAULT SERVING]")
    _ -> Nil
  }

  io.println("")

  // Nutrition information
  let nutrition = serving.nutrition
  io.println("  NUTRITION PER SERVING:")
  io.println("    Calories: " <> float.to_string(nutrition.calories) <> " kcal")
  io.println("    Protein: " <> float.to_string(nutrition.protein) <> "g")
  io.println("    Carbs: " <> float.to_string(nutrition.carbohydrate) <> "g")
  io.println("    Fat: " <> float.to_string(nutrition.fat) <> "g")

  // Optional nutrients
  case nutrition.fiber {
    option.Some(fiber) ->
      io.println("    Fiber: " <> float.to_string(fiber) <> "g")
    option.None -> Nil
  }

  case nutrition.sugar {
    option.Some(sugar) ->
      io.println("    Sugar: " <> float.to_string(sugar) <> "g")
    option.None -> Nil
  }

  case nutrition.saturated_fat {
    option.Some(sat_fat) ->
      io.println("    Saturated Fat: " <> float.to_string(sat_fat) <> "g")
    option.None -> Nil
  }

  case nutrition.sodium {
    option.Some(sodium) ->
      io.println("    Sodium: " <> float.to_string(sodium) <> "mg")
    option.None -> Nil
  }

  case nutrition.cholesterol {
    option.Some(chol) ->
      io.println("    Cholesterol: " <> float.to_string(chol) <> "mg")
    option.None -> Nil
  }

  io.println("")
}

// ============================================================================
// Recipe Display
// ============================================================================

/// Display recipe ingredients with nutrition info
pub fn display_recipe_ingredients(recipe: recipe_types.Recipe) -> Nil {
  io.println("\n" <> repeat("=", 80))
  io.println("RECIPE INGREDIENTS")
  io.println(repeat("=", 80))
  io.println("")

  // Recipe header
  io.println("Recipe: " <> recipe.recipe_name)
  io.println("Servings: " <> float.to_string(recipe.number_of_servings))
  case recipe.recipe_description {
    "" -> Nil
    desc -> io.println("Description: " <> desc)
  }
  io.println("")

  // Check if recipe has ingredients
  case list.is_empty(recipe.ingredients) {
    True -> {
      io.println("No ingredients found for this recipe.")
      io.println("")
    }
    False -> {
      // Display ingredients section
      io.println(
        "INGREDIENTS ("
        <> int.to_string(list.length(recipe.ingredients))
        <> " items)",
      )
      io.println(repeat("-", 80))
      io.println("")

      // Display each ingredient
      recipe.ingredients
      |> list.each(fn(ingredient) { display_ingredient(ingredient) })

      // Display total nutrition
      io.println(repeat("-", 80))
      io.println("TOTAL NUTRITION (entire recipe)")
      io.println("")
      display_recipe_nutrition_totals(recipe)
      io.println("")
    }
  }

  io.println(repeat("=", 80))
  io.println("")
}

/// Display a single ingredient
pub fn display_ingredient(ingredient: recipe_types.RecipeIngredient) -> Nil {
  io.println("• " <> ingredient.food_name)
  io.println("  Amount: " <> ingredient.ingredient_description)
  io.println(
    "  Quantity: "
    <> float.to_string(ingredient.number_of_units)
    <> " "
    <> ingredient.measurement_description,
  )
  io.println("  Food ID: " <> ingredient.food_id)
  io.println("")
}

/// Display nutrition totals for the recipe
pub fn display_recipe_nutrition_totals(recipe: recipe_types.Recipe) -> Nil {
  // Display nutrition from recipe level (these are per serving values from the recipe)
  case recipe.calories {
    option.Some(cal) ->
      io.println(
        "Calories: "
        <> float.to_string(cal *. recipe.number_of_servings)
        <> " kcal (total)",
      )
    option.None -> Nil
  }

  case recipe.protein {
    option.Some(prot) ->
      io.println(
        "Protein: "
        <> float.to_string(prot *. recipe.number_of_servings)
        <> "g (total)",
      )
    option.None -> Nil
  }

  case recipe.carbohydrate {
    option.Some(carb) ->
      io.println(
        "Carbs: "
        <> float.to_string(carb *. recipe.number_of_servings)
        <> "g (total)",
      )
    option.None -> Nil
  }

  case recipe.fat {
    option.Some(f) ->
      io.println(
        "Fat: "
        <> float.to_string(f *. recipe.number_of_servings)
        <> "g (total)",
      )
    option.None -> Nil
  }

  // Optional nutrients
  case recipe.fiber {
    option.Some(fiber) ->
      io.println(
        "Fiber: "
        <> float.to_string(fiber *. recipe.number_of_servings)
        <> "g (total)",
      )
    option.None -> Nil
  }

  case recipe.sugar {
    option.Some(sugar) ->
      io.println(
        "Sugar: "
        <> float.to_string(sugar *. recipe.number_of_servings)
        <> "g (total)",
      )
    option.None -> Nil
  }
}

// ============================================================================
// Helpers
// ============================================================================

/// Helper to repeat a string n times
pub fn repeat(str: String, n: Int) -> String {
  case n <= 0 {
    True -> ""
    False -> str <> repeat(str, n - 1)
  }
}
