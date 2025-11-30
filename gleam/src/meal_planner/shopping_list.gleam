/// Shopping list generation and categorization
///
/// Organizes ingredients by shopping category for easier grocery shopping.
import gleam/list
import gleam/string
import meal_planner/types.{type Ingredient}

/// Category for organizing shopping list items
pub type IngredientCategory {
  Protein
  Dairy
  Produce
  Grains
  Fats
  Seasonings
  Other
}

/// Categorized shopping list organized by food group
pub type CategorizedShoppingList {
  CategorizedShoppingList(
    protein: List(Ingredient),
    dairy: List(Ingredient),
    produce: List(Ingredient),
    grains: List(Ingredient),
    fats: List(Ingredient),
    seasonings: List(Ingredient),
    other: List(Ingredient),
  )
}

/// Protein keywords for categorization
const protein_keywords = [
  "beef", "steak", "chicken", "pork", "fish", "salmon", "shrimp", "turkey",
  "lamb", "ground", "ribeye", "brisket", "sirloin", "eggs", "chorizo",
]

/// Dairy keywords for categorization
const dairy_keywords = [
  "cheese", "butter", "milk", "cream", "yogurt", "sour cream",
]

/// Produce keywords for categorization
const produce_keywords = [
  "spinach", "carrot", "pepper", "potato", "tomato", "lettuce", "cucumber",
  "celery", "orange", "lime", "lemon", "avocado", "cabbage", "cranberry",
]

/// Grains keywords for categorization
const grains_keywords = ["rice", "tortilla", "bread", "cereal", "oat"]

/// Fats & oils keywords for categorization
const fats_keywords = ["oil", "lard", "tallow"]

/// Seasonings keywords for categorization
const seasonings_keywords = [
  "salt", "pepper", "seasoning", "spice", "paprika", "cumin", "oregano", "basil",
  "thyme", "garlic powder", "onion powder", "honey", "mustard", "sauce",
]

/// Determine the shopping category for an ingredient
pub fn categorize_ingredient(ingredient: Ingredient) -> IngredientCategory {
  let name_lower = string.lowercase(ingredient.name)

  // Check fats first (to catch "beef tallow" before "beef" matches protein)
  case contains_any(name_lower, fats_keywords) {
    True -> Fats
    False ->
      case contains_any(name_lower, protein_keywords) {
        True -> Protein
        False ->
          case contains_any(name_lower, dairy_keywords) {
            True -> Dairy
            False ->
              case contains_any(name_lower, produce_keywords) {
                True -> Produce
                False ->
                  case contains_any(name_lower, grains_keywords) {
                    True -> Grains
                    False ->
                      case contains_any(name_lower, seasonings_keywords) {
                        True -> Seasonings
                        False -> Other
                      }
                  }
              }
          }
      }
  }
}

/// Check if a string contains any of the keywords
fn contains_any(text: String, keywords: List(String)) -> Bool {
  list.any(keywords, fn(keyword) { string.contains(text, keyword) })
}

/// Organize a list of ingredients into categories
pub fn organize_shopping_list(
  ingredients: List(Ingredient),
) -> CategorizedShoppingList {
  let initial =
    CategorizedShoppingList(
      protein: [],
      dairy: [],
      produce: [],
      grains: [],
      fats: [],
      seasonings: [],
      other: [],
    )

  list.fold(ingredients, initial, fn(acc, ingredient) {
    case categorize_ingredient(ingredient) {
      Protein ->
        CategorizedShoppingList(..acc, protein: [ingredient, ..acc.protein])
      Dairy -> CategorizedShoppingList(..acc, dairy: [ingredient, ..acc.dairy])
      Produce ->
        CategorizedShoppingList(..acc, produce: [ingredient, ..acc.produce])
      Grains ->
        CategorizedShoppingList(..acc, grains: [ingredient, ..acc.grains])
      Fats -> CategorizedShoppingList(..acc, fats: [ingredient, ..acc.fats])
      Seasonings ->
        CategorizedShoppingList(..acc, seasonings: [
          ingredient,
          ..acc.seasonings
        ])
      Other -> CategorizedShoppingList(..acc, other: [ingredient, ..acc.other])
    }
  })
  |> reverse_all_lists
}

/// Reverse all lists to maintain insertion order
fn reverse_all_lists(list: CategorizedShoppingList) -> CategorizedShoppingList {
  CategorizedShoppingList(
    protein: list.reverse(list.protein),
    dairy: list.reverse(list.dairy),
    produce: list.reverse(list.produce),
    grains: list.reverse(list.grains),
    fats: list.reverse(list.fats),
    seasonings: list.reverse(list.seasonings),
    other: list.reverse(list.other),
  )
}
