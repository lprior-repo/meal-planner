import gleeunit/should
import shared/types.{
  High, Low, Macros, Recipe, is_vertical_diet_compliant, macros_per_serving,
  total_macros,
}

pub fn recipe_is_vertical_diet_compliant_true_test() {
  let recipe =
    Recipe(
      id: "grilled-chicken",
      name: "Grilled Chicken",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 30.0, fat: 5.0, carbs: 0.0),
      servings: 1,
      category: "protein",
      fodmap_level: Low,
      vertical_compliant: True,
    )
  is_vertical_diet_compliant(recipe) |> should.be_true()
}

pub fn recipe_is_vertical_diet_compliant_high_fodmap_test() {
  let recipe =
    Recipe(
      id: "garlic-bread",
      name: "Garlic Bread",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 5.0, fat: 10.0, carbs: 30.0),
      servings: 2,
      category: "carbs",
      fodmap_level: High,
      vertical_compliant: True,
    )
  // High FODMAP means not compliant even if marked vertical_compliant
  is_vertical_diet_compliant(recipe) |> should.be_false()
}

pub fn recipe_is_vertical_diet_compliant_not_marked_test() {
  let recipe =
    Recipe(
      id: "rice",
      name: "Rice",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 3.0, fat: 0.5, carbs: 45.0),
      servings: 1,
      category: "carbs",
      fodmap_level: Low,
      vertical_compliant: False,
    )
  // Not marked as compliant
  is_vertical_diet_compliant(recipe) |> should.be_false()
}

pub fn recipe_total_macros_test() {
  let recipe =
    Recipe(
      id: "chicken",
      name: "Chicken",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 25.0, fat: 5.0, carbs: 0.0),
      servings: 4,
      category: "protein",
      fodmap_level: Low,
      vertical_compliant: True,
    )
  let total = total_macros(recipe)
  total.protein |> should.equal(100.0)
  total.fat |> should.equal(20.0)
  total.carbs |> should.equal(0.0)
}

pub fn recipe_total_macros_zero_servings_test() {
  let recipe =
    Recipe(
      id: "test-zero",
      name: "Test",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 10.0, fat: 5.0, carbs: 20.0),
      servings: 0,
      category: "test",
      fodmap_level: Low,
      vertical_compliant: False,
    )
  // Should default to 1 serving
  let total = total_macros(recipe)
  total.protein |> should.equal(10.0)
}

pub fn recipe_macros_per_serving_test() {
  let recipe =
    Recipe(
      id: "test-per-serving",
      name: "Test",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
      servings: 2,
      category: "test",
      fodmap_level: Low,
      vertical_compliant: False,
    )
  let per_serving = macros_per_serving(recipe)
  // Macros are already per serving in the Go version
  per_serving.protein |> should.equal(30.0)
}
