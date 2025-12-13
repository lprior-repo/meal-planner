/// Vertical diet compliance checker for recipes
/// Validates recipes against Stan Efferding's Vertical Diet principles
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string

/// Recipe ingredient for compliance checking
pub type RecipeIngredient {
  RecipeIngredient(display: String)
}

/// Recipe instruction for compliance checking
pub type RecipeInstruction {
  RecipeInstruction(text: String)
}

/// Recipe for vertical diet compliance checking
pub type Recipe {
  Recipe(
    name: String,
    description: option.Option(String),
    recipe_ingredient: List(RecipeIngredient),
    recipe_instructions: List(RecipeInstruction),
    rating: option.Option(Int),
  )
}

/// Vertical diet compliance check result
pub type VerticalDietCompliance {
  VerticalDietCompliance(
    compliant: Bool,
    score: Int,
    reasons: List(String),
    recommendations: List(String),
  )
}

/// Check if a recipe complies with vertical diet guidelines
pub fn check_compliance(recipe: Recipe) -> VerticalDietCompliance {
  // Validate recipe has minimum required data
  case
    list.length(recipe.recipe_ingredient),
    list.length(recipe.recipe_instructions)
  {
    0, _ | _, 0 ->
      VerticalDietCompliance(
        compliant: False,
        score: 0,
        reasons: ["Recipe must have ingredients and instructions"],
        recommendations: ["Add recipe ingredients and preparation instructions"],
      )
    _, _ -> evaluate_recipe_compliance(recipe)
  }
}

/// Evaluate recipe compliance with vertical diet guidelines
fn evaluate_recipe_compliance(recipe: Recipe) -> VerticalDietCompliance {
  let has_red_meat = contains_red_meat(recipe)
  let has_simple_carbs = contains_simple_carbs(recipe)
  let has_low_fodmap = contains_low_fodmap_vegetables(recipe)
  let ingredient_count = list.length(recipe.recipe_ingredient)
  let instruction_count = list.length(recipe.recipe_instructions)
  let simple_ingredients = ingredient_count <= 8
  let simple_prep = instruction_count <= 6

  // Calculate base compliance score (out of 100)
  let protein_score = case has_red_meat {
    True -> 25
    False -> 0
  }

  let carb_score = case has_simple_carbs {
    True -> 25
    False -> 0
  }

  let vegetable_score = case has_low_fodmap {
    True -> 20
    False -> 10
  }

  let ingredient_score = case simple_ingredients {
    True -> 15
    False -> 5
  }

  let prep_score = case simple_prep {
    True -> 10
    False -> 5
  }

  let quality_score = case recipe.rating {
    Some(rating) if rating >= 4 -> 5
    Some(_) -> 2
    None -> 0
  }

  let total_score =
    protein_score
    + carb_score
    + vegetable_score
    + ingredient_score
    + prep_score
    + quality_score

  // Normalize score to 0-100 range
  let normalized_score = int.min(total_score, 100)

  // Determine compliance (70% or higher)
  let compliant = normalized_score >= 70

  // Build reasons list (highlight missing elements)
  let reasons = []
  let reasons = case has_red_meat {
    True -> reasons
    False -> ["No red meat detected as primary protein source", ..reasons]
  }

  let reasons = case has_simple_carbs {
    True -> reasons
    False -> ["No simple carbs (white rice, potatoes) detected", ..reasons]
  }

  let reasons = case simple_ingredients {
    True -> reasons
    False -> [
      "Complex recipe with "
        <> string.inspect(ingredient_count)
        <> " ingredients (vertical diet aims for 5-8)",
      ..reasons
    ]
  }

  // Build recommendations
  let recommendations = []
  let recommendations = case has_red_meat {
    False -> [
      "Add red meat (beef, lamb, bison) as primary protein source",
      ..recommendations
    ]
    True -> recommendations
  }

  let recommendations = case has_simple_carbs {
    False -> [
      "Include simple carbs: white rice, potatoes, or jasmine rice",
      ..recommendations
    ]
    True -> recommendations
  }

  let recommendations = case has_low_fodmap {
    False -> [
      "Add low FODMAP vegetables (carrots, spinach, bok choy, green beans)",
      ..recommendations
    ]
    True -> recommendations
  }

  let recommendations = case simple_ingredients {
    False -> [
      "Reduce to 5-8 core ingredients for vertical diet compliance",
      ..recommendations
    ]
    True -> recommendations
  }

  VerticalDietCompliance(
    compliant: compliant,
    score: normalized_score,
    reasons: reasons,
    recommendations: recommendations,
  )
}

/// Check if recipe contains red meat as primary protein
fn contains_red_meat(recipe: Recipe) -> Bool {
  let red_meat_keywords = [
    "beef", "bison", "lamb", "venison", "steak", "ground beef", "chuck",
    "ribeye", "sirloin", "ground lamb",
  ]

  let recipe_name_lower = string.lowercase(recipe.name)
  let recipe_desc_lower = case recipe.description {
    Some(desc) -> string.lowercase(desc)
    None -> ""
  }

  // Check recipe name
  let name_match =
    list.any(red_meat_keywords, fn(keyword) {
      string.contains(recipe_name_lower, keyword)
    })

  // Check description
  let desc_match =
    list.any(red_meat_keywords, fn(keyword) {
      string.contains(recipe_desc_lower, keyword)
    })

  // Check ingredients
  let ingredients_match =
    list.any(recipe.recipe_ingredient, fn(ingredient) {
      let display_lower = string.lowercase(ingredient.display)
      list.any(red_meat_keywords, fn(keyword) {
        string.contains(display_lower, keyword)
      })
    })

  name_match || desc_match || ingredients_match
}

/// Check if recipe contains simple carbs (white rice, potatoes)
fn contains_simple_carbs(recipe: Recipe) -> Bool {
  let carb_keywords = [
    "white rice", "rice", "white potato", "potato", "sweet potato",
    "jasmine rice", "basmati", "mashed potato", "baked potato",
  ]

  let recipe_name_lower = string.lowercase(recipe.name)
  let recipe_desc_lower = case recipe.description {
    Some(desc) -> string.lowercase(desc)
    None -> ""
  }

  // Check recipe name
  let name_match =
    list.any(carb_keywords, fn(keyword) {
      string.contains(recipe_name_lower, keyword)
    })

  // Check description
  let desc_match =
    list.any(carb_keywords, fn(keyword) {
      string.contains(recipe_desc_lower, keyword)
    })

  // Check ingredients
  let ingredients_match =
    list.any(recipe.recipe_ingredient, fn(ingredient) {
      let display_lower = string.lowercase(ingredient.display)
      list.any(carb_keywords, fn(keyword) {
        string.contains(display_lower, keyword)
      })
    })

  name_match || desc_match || ingredients_match
}

/// Check if recipe contains low FODMAP vegetables
fn contains_low_fodmap_vegetables(recipe: Recipe) -> Bool {
  let low_fodmap_keywords = [
    "carrot", "spinach", "kale", "lettuce", "bell pepper", "cucumber",
    "zucchini", "bok choy", "cabbage", "green bean", "broccoli",
  ]

  list.any(recipe.recipe_ingredient, fn(ingredient) {
    let display_lower = string.lowercase(ingredient.display)
    list.any(low_fodmap_keywords, fn(keyword) {
      string.contains(display_lower, keyword)
    })
  })
}
