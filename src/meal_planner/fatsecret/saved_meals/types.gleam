/// FatSecret Saved Meals API - Core Types
///
/// Opaque types for type-safe IDs and domain types for saved meals and items.
/// These types mirror the FatSecret API structure for saved meal templates.
import gleam/option.{type Option}

/// Opaque type for saved meal IDs (from FatSecret)
pub opaque type SavedMealId {
  SavedMealId(String)
}

pub fn saved_meal_id_to_string(id: SavedMealId) -> String {
  let SavedMealId(s) = id
  s
}

pub fn saved_meal_id_from_string(s: String) -> SavedMealId {
  SavedMealId(s)
}

/// Opaque type for saved meal item IDs (from FatSecret)
pub opaque type SavedMealItemId {
  SavedMealItemId(String)
}

pub fn saved_meal_item_id_to_string(id: SavedMealItemId) -> String {
  let SavedMealItemId(s) = id
  s
}

pub fn saved_meal_item_id_from_string(s: String) -> SavedMealItemId {
  SavedMealItemId(s)
}

/// Meal types that a saved meal can be used for
pub type MealType {
  Breakfast
  Lunch
  Dinner
  Other
}

/// Convert meal type to API string format
pub fn meal_type_to_string(meal: MealType) -> String {
  case meal {
    Breakfast -> "breakfast"
    Lunch -> "lunch"
    Dinner -> "dinner"
    Other -> "other"
  }
}

/// Parse meal type from API string
pub fn meal_type_from_string(s: String) -> Result(MealType, Nil) {
  case s {
    "breakfast" -> Ok(Breakfast)
    "lunch" -> Ok(Lunch)
    "dinner" -> Ok(Dinner)
    "other" -> Ok(Other)
    _ -> Error(Nil)
  }
}

/// A saved meal template (collection of food items)
pub type SavedMeal {
  SavedMeal(
    saved_meal_id: SavedMealId,
    saved_meal_name: String,
    saved_meal_description: Option(String),
    meals: List(MealType),
    calories: Float,
    carbohydrate: Float,
    protein: Float,
    fat: Float,
  )
}

/// A food item within a saved meal
pub type SavedMealItem {
  SavedMealItem(
    saved_meal_item_id: SavedMealItemId,
    food_id: String,
    food_entry_name: String,
    serving_id: String,
    number_of_units: Float,
    calories: Float,
    carbohydrate: Float,
    protein: Float,
    fat: Float,
  )
}

/// Input for creating/editing saved meal items
/// Can either reference an existing food or provide custom nutrition
pub type SavedMealItemInput {
  /// Reference an existing FatSecret food by ID and serving
  ByFoodId(food_id: String, serving_id: String, number_of_units: Float)
  /// Create custom entry with nutrition values
  ByNutrition(
    food_entry_name: String,
    serving_description: String,
    number_of_units: Float,
    calories: Float,
    carbohydrate: Float,
    protein: Float,
    fat: Float,
  )
}

/// Response from saved_meals.get.v2 API
pub type SavedMealsResponse {
  SavedMealsResponse(saved_meals: List(SavedMeal), meal_filter: Option(String))
}

/// Response from saved_meal_items.get.v2 API
pub type SavedMealItemsResponse {
  SavedMealItemsResponse(saved_meal_id: SavedMealId, items: List(SavedMealItem))
}
