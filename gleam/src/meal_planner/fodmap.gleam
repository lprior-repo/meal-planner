/// FODMAP analysis functions for recipe compliance checking
///
/// FODMAP (Fermentable Oligosaccharides, Disaccharides, Monosaccharides, and Polyols)
/// are short-chain carbohydrates that can cause digestive issues. The Vertical Diet
/// emphasizes low-FODMAP foods for better digestion and nutrient absorption.
import gleam/int
import gleam/list
import gleam/string
import shared/types.{type Recipe}

/// FODMAPAnalysis represents the result of analyzing a recipe for FODMAP content
pub type FODMAPAnalysis {
  FODMAPAnalysis(
    recipe: String,
    high_fodmap_found: List(String),
    is_low_fodmap: Bool,
    compliance_percentage: Float,
  )
}

/// High FODMAP ingredients that should be avoided or limited on the Vertical Diet
const high_fodmap_ingredients = [
  "garlic", "onion", "beans", "chickpea", "lentil", "cauliflower", "broccoli",
  "asparagus", "mushroom", "apples", "pear", "mango", "watermelon", "wheat",
  "rye", "barley", "honey",
]

/// Low FODMAP exceptions - ingredients that contain high-FODMAP keywords
/// but are actually low-FODMAP and should not be flagged
const low_fodmap_exceptions = [
  "apple cider vinegar", "garlic-infused oil", "green onion tops",
]

/// Check if an ingredient is a known low-FODMAP exception
pub fn is_low_fodmap_exception(ingredient_lower: String) -> Bool {
  list.any(low_fodmap_exceptions, fn(exception) {
    string.contains(ingredient_lower, exception)
  })
}

/// Analyze a recipe's ingredients against the high-FODMAP list
pub fn analyze_recipe_fodmap(recipe: Recipe) -> FODMAPAnalysis {
  // Find all high FODMAP ingredients in the recipe
  let high_fodmap_found =
    list.filter_map(recipe.ingredients, fn(ingredient) {
      let ingredient_lower = string.lowercase(ingredient.name)

      // Skip known low-FODMAP exceptions
      case is_low_fodmap_exception(ingredient_lower) {
        True -> Error(Nil)
        False -> {
          // Check if ingredient contains any high FODMAP keywords
          let is_high_fodmap =
            list.any(high_fodmap_ingredients, fn(fodmap) {
              string.contains(ingredient_lower, fodmap)
            })

          case is_high_fodmap {
            True -> Ok(ingredient.name)
            False -> Error(Nil)
          }
        }
      }
    })

  let is_low_fodmap = list.is_empty(high_fodmap_found)

  // Calculate compliance percentage
  let compliance_percentage = case list.length(recipe.ingredients) {
    0 -> 100.0
    total -> {
      let compliant_count = total - list.length(high_fodmap_found)
      let compliant_float = int.to_float(compliant_count)
      let total_float = int.to_float(total)
      compliant_float /. total_float *. 100.0
    }
  }

  FODMAPAnalysis(
    recipe: recipe.name,
    high_fodmap_found: high_fodmap_found,
    is_low_fodmap: is_low_fodmap,
    compliance_percentage: compliance_percentage,
  )
}
