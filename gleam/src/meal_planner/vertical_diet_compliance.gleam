/// Vertical diet compliance checker for Mealie recipes
/// Validates recipes against Stan Efferding's Vertical Diet principles
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import meal_planner/mealie/types

/// Vertical diet compliance check result
pub type VerticalDietCompliance {
  VerticalDietCompliance(
    compliant: Bool,
    score: Int,
    reasons: List(String),
    recommendations: List(String),
  )
}

/// Check if a Mealie recipe complies with vertical diet guidelines
pub fn check_compliance(recipe: types.MealieRecipe) -> VerticalDietCompliance {
  let mut_reasons = []
  let mut_recommendations = []
  let mut_score = 0

  // Check 1: Primary protein source (red meat)
  let has_red_meat = contains_red_meat(recipe)
  let mut_reasons = case has_red_meat {
    True -> mut_reasons
    False -> ["No red meat detected as primary protein source", ..mut_reasons]
  }
  let mut_score = case has_red_meat {
    True -> mut_score + 25
    False -> mut_score
  }

  // Check 2: Simple carbs (white rice, potatoes)
  let has_simple_carbs = contains_simple_carbs(recipe)
  let mut_reasons = case has_simple_carbs {
    True -> mut_reasons
    False -> ["No simple carbs (white rice, potatoes) detected", ..mut_reasons]
  }
  let mut_score = case has_simple_carbs {
    True -> mut_score + 25
    False -> mut_score
  }

  // Check 3: Low FODMAP vegetables
  let has_low_fodmap = contains_low_fodmap_vegetables(recipe)
  let mut_score = case has_low_fodmap {
    True -> mut_score + 20
    False -> mut_score + 10
  }

  // Check 4: Simple ingredient list
  let ingredient_count = list.length(recipe.recipe_ingredient)
  let simple_ingredients = ingredient_count <= 8
  let mut_reasons = case simple_ingredients {
    True -> mut_reasons
    False -> [
      "Complex recipe with "
        <> string.inspect(ingredient_count)
        <> " ingredients (vertical diet aims for 5-8)",
      ..mut_reasons
    ]
  }
  let mut_score = case simple_ingredients {
    True -> mut_score + 15
    False -> mut_score + 5
  }

  // Check 5: Preparation simplicity (instructions count)
  let instruction_count = list.length(recipe.recipe_instructions)
  let simple_prep = instruction_count <= 6
  let mut_score = case simple_prep {
    True -> mut_score + 10
    False -> mut_score + 5
  }

  // Check 6: Rating/Quality
  let quality_score = case recipe.rating {
    Some(rating) if rating >= 4 -> 5
    Some(_) -> 2
    None -> 0
  }
  let mut_score = mut_score + quality_score

  // Generate recommendations
  let mut_recommendations = case has_red_meat {
    False -> [
      "Consider adding or replacing protein with red meat (beef, lamb, bison)",
      ..mut_recommendations
    ]
    True -> mut_recommendations
  }

  let mut_recommendations = case has_simple_carbs {
    False -> [
      "Add simple carbs like white rice or potatoes for vertical diet compliance",
      ..mut_recommendations
    ]
    True -> mut_recommendations
  }

  let mut_recommendations = case has_low_fodmap {
    False -> [
      "Include low FODMAP vegetables (carrots, white potatoes, spinach) for better digestion",
      ..mut_recommendations
    ]
    True -> mut_recommendations
  }

  let mut_recommendations = case simple_ingredients {
    False -> [
      "Simplify ingredients - vertical diet emphasizes 5-8 core ingredients",
      ..mut_recommendations
    ]
    True -> mut_recommendations
  }

  let compliant = mut_score >= 70

  VerticalDietCompliance(
    compliant: compliant,
    score: mut_score,
    reasons: mut_reasons,
    recommendations: mut_recommendations,
  )
}

/// Check if recipe contains red meat as primary protein
fn contains_red_meat(recipe: types.MealieRecipe) -> Bool {
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
fn contains_simple_carbs(recipe: types.MealieRecipe) -> Bool {
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
fn contains_low_fodmap_vegetables(recipe: types.MealieRecipe) -> Bool {
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
