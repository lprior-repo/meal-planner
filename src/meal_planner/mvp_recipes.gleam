/// MVP Recipe Library - 15 generic recipes for testing NCP
import meal_planner/ncp.{type ScoredRecipe, ScoredRecipe}
import meal_planner/types/macros.{Macros}

/// Get all MVP recipes
pub fn all_recipes() -> List(ScoredRecipe) {
  [
    beef_with_peppers(),
    breakfast_sandwich(),
    chicken_breast_rice(),
    salmon_broccoli(),
    turkey_pasta(),
    eggs_toast(),
    oatmeal_banana(),
    greek_yogurt_granola(),
    tuna_salad(),
    ground_turkey_tacos(),
    pork_sweet_potato(),
    cod_asparagus(),
    lean_ground_beef_veggies(),
    cottage_cheese_berries(),
    shrimp_brown_rice(),
  ]
}

fn beef_with_peppers() -> ScoredRecipe {
  ScoredRecipe(
    name: "Lean Beef with Peppers",
    macros: Macros(protein: 45.0, fat: 12.0, carbs: 8.0),
  )
}

fn breakfast_sandwich() -> ScoredRecipe {
  ScoredRecipe(
    name: "Breakfast Sandwich",
    macros: Macros(protein: 20.0, fat: 14.0, carbs: 35.0),
  )
}

fn chicken_breast_rice() -> ScoredRecipe {
  ScoredRecipe(
    name: "Grilled Chicken Breast with Rice",
    macros: Macros(protein: 40.0, fat: 6.0, carbs: 45.0),
  )
}

fn salmon_broccoli() -> ScoredRecipe {
  ScoredRecipe(
    name: "Baked Salmon with Broccoli",
    macros: Macros(protein: 38.0, fat: 15.0, carbs: 12.0),
  )
}

fn turkey_pasta() -> ScoredRecipe {
  ScoredRecipe(
    name: "Ground Turkey Pasta",
    macros: Macros(protein: 35.0, fat: 8.0, carbs: 50.0),
  )
}

fn eggs_toast() -> ScoredRecipe {
  ScoredRecipe(
    name: "Scrambled Eggs with Whole Wheat Toast",
    macros: Macros(protein: 18.0, fat: 10.0, carbs: 25.0),
  )
}

fn oatmeal_banana() -> ScoredRecipe {
  ScoredRecipe(
    name: "Oatmeal with Banana",
    macros: Macros(protein: 12.0, fat: 4.0, carbs: 55.0),
  )
}

fn greek_yogurt_granola() -> ScoredRecipe {
  ScoredRecipe(
    name: "Greek Yogurt with Granola",
    macros: Macros(protein: 20.0, fat: 8.0, carbs: 40.0),
  )
}

fn tuna_salad() -> ScoredRecipe {
  ScoredRecipe(
    name: "Tuna Salad with Olive Oil",
    macros: Macros(protein: 30.0, fat: 12.0, carbs: 10.0),
  )
}

fn ground_turkey_tacos() -> ScoredRecipe {
  ScoredRecipe(
    name: "Ground Turkey Tacos",
    macros: Macros(protein: 32.0, fat: 10.0, carbs: 35.0),
  )
}

fn pork_sweet_potato() -> ScoredRecipe {
  ScoredRecipe(
    name: "Pork Loin with Sweet Potato",
    macros: Macros(protein: 38.0, fat: 8.0, carbs: 28.0),
  )
}

fn cod_asparagus() -> ScoredRecipe {
  ScoredRecipe(
    name: "Pan-Seared Cod with Asparagus",
    macros: Macros(protein: 35.0, fat: 5.0, carbs: 8.0),
  )
}

fn lean_ground_beef_veggies() -> ScoredRecipe {
  ScoredRecipe(
    name: "Lean Ground Beef with Mixed Vegetables",
    macros: Macros(protein: 42.0, fat: 10.0, carbs: 15.0),
  )
}

fn cottage_cheese_berries() -> ScoredRecipe {
  ScoredRecipe(
    name: "Cottage Cheese with Berries",
    macros: Macros(protein: 25.0, fat: 6.0, carbs: 20.0),
  )
}

fn shrimp_brown_rice() -> ScoredRecipe {
  ScoredRecipe(
    name: "Grilled Shrimp with Brown Rice",
    macros: Macros(protein: 28.0, fat: 7.0, carbs: 42.0),
  )
}
