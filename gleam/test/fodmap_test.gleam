import gleeunit/should
import meal_planner/fodmap.{analyze_recipe_fodmap, is_low_fodmap_exception}
import meal_planner/types.{Ingredient, Low, Macros, Recipe}

// Test is_low_fodmap_exception with apple cider vinegar
pub fn is_low_fodmap_exception_apple_cider_vinegar_test() {
  is_low_fodmap_exception("apple cider vinegar")
  |> should.be_true()
}

// Test is_low_fodmap_exception with garlic-infused oil
pub fn is_low_fodmap_exception_garlic_oil_test() {
  is_low_fodmap_exception("garlic-infused oil")
  |> should.be_true()
}

// Test is_low_fodmap_exception with green onion tops
pub fn is_low_fodmap_exception_green_onion_tops_test() {
  is_low_fodmap_exception("green onion tops")
  |> should.be_true()
}

// Test is_low_fodmap_exception with regular garlic (should be false)
pub fn is_low_fodmap_exception_regular_garlic_test() {
  is_low_fodmap_exception("garlic")
  |> should.be_false()
}

// Test is_low_fodmap_exception with regular onion (should be false)
pub fn is_low_fodmap_exception_regular_onion_test() {
  is_low_fodmap_exception("onion")
  |> should.be_false()
}

// Test analyze_recipe_fodmap with low FODMAP recipe
pub fn analyze_recipe_fodmap_low_fodmap_test() {
  let recipe =
    Recipe(
      name: "Grilled Chicken",
      ingredients: [
        Ingredient(name: "Chicken breast", quantity: "200g"),
        Ingredient(name: "Olive oil", quantity: "1 tbsp"),
        Ingredient(name: "Salt", quantity: "1 tsp"),
      ],
      instructions: ["Grill chicken"],
      macros: Macros(protein: 40.0, fat: 10.0, carbs: 0.0),
      servings: 1,
      category: "chicken",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let result = analyze_recipe_fodmap(recipe)
  result.is_low_fodmap |> should.be_true()
  result.compliance_percentage |> should.equal(100.0)
  result.high_fodmap_found |> should.equal([])
}

// Test analyze_recipe_fodmap with high FODMAP ingredients
pub fn analyze_recipe_fodmap_high_fodmap_test() {
  let recipe =
    Recipe(
      name: "Garlic Bread",
      ingredients: [
        Ingredient(name: "Bread", quantity: "2 slices"),
        Ingredient(name: "Garlic", quantity: "2 cloves"),
        Ingredient(name: "Butter", quantity: "1 tbsp"),
      ],
      instructions: ["Spread on bread"],
      macros: Macros(protein: 5.0, fat: 10.0, carbs: 30.0),
      servings: 1,
      category: "bread",
      fodmap_level: Low,
      vertical_compliant: False,
    )

  let result = analyze_recipe_fodmap(recipe)
  result.is_low_fodmap |> should.be_false()
  // 1 out of 3 ingredients is high FODMAP = 66.67% compliant
  { result.compliance_percentage >=. 66.0 } |> should.be_true()
  { result.compliance_percentage <=. 67.0 } |> should.be_true()
}

// Test analyze_recipe_fodmap with exception ingredient
pub fn analyze_recipe_fodmap_exception_test() {
  let recipe =
    Recipe(
      name: "Salad with Vinegar",
      ingredients: [
        Ingredient(name: "Lettuce", quantity: "1 cup"),
        Ingredient(name: "Apple cider vinegar", quantity: "1 tbsp"),
      ],
      instructions: ["Mix together"],
      macros: Macros(protein: 1.0, fat: 0.0, carbs: 5.0),
      servings: 1,
      category: "salad",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let result = analyze_recipe_fodmap(recipe)
  // Apple cider vinegar is an exception, should be low FODMAP
  result.is_low_fodmap |> should.be_true()
  result.compliance_percentage |> should.equal(100.0)
}

// Test analyze_recipe_fodmap with empty ingredients
pub fn analyze_recipe_fodmap_empty_ingredients_test() {
  let recipe =
    Recipe(
      name: "Empty Recipe",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 0.0, fat: 0.0, carbs: 0.0),
      servings: 1,
      category: "other",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let result = analyze_recipe_fodmap(recipe)
  result.is_low_fodmap |> should.be_true()
  result.compliance_percentage |> should.equal(100.0)
}

// Test analyze_recipe_fodmap with multiple high FODMAP ingredients
pub fn analyze_recipe_fodmap_multiple_high_fodmap_test() {
  let recipe =
    Recipe(
      name: "Bean Soup",
      ingredients: [
        Ingredient(name: "Beans", quantity: "1 cup"),
        Ingredient(name: "Onion", quantity: "1 medium"),
        Ingredient(name: "Garlic", quantity: "3 cloves"),
        Ingredient(name: "Water", quantity: "4 cups"),
      ],
      instructions: ["Cook together"],
      macros: Macros(protein: 15.0, fat: 1.0, carbs: 40.0),
      servings: 4,
      category: "soup",
      fodmap_level: Low,
      vertical_compliant: False,
    )

  let result = analyze_recipe_fodmap(recipe)
  result.is_low_fodmap |> should.be_false()
  // 3 out of 4 ingredients are high FODMAP = 25% compliant
  result.compliance_percentage |> should.equal(25.0)
}
