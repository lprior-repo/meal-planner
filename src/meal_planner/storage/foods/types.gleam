/// Type definitions for food storage
import meal_planner/id

/// USDA Food database entry
pub type UsdaFood {
  UsdaFood(
    fdc_id: id.FdcId,
    description: String,
    data_type: String,
    category: String,
    serving_size: String,
  )
}

/// Individual nutrient value for a food
pub type FoodNutrientValue {
  FoodNutrientValue(
    nutrient_id: Int,
    nutrient_name: String,
    amount: Float,
    unit: String,
  )
}

/// USDA food with its associated nutrient values
pub type UsdaFoodWithNutrients {
  UsdaFoodWithNutrients(food: UsdaFood, nutrients: List(FoodNutrientValue))
}
