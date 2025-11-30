import gleam/list
import gleeunit
import gleeunit/should
import meal_planner/fodmap
import meal_planner/types.{Ingredient, Low, Macros, Recipe}

pub fn main() {
  gleeunit.main()
}

// Test is_low_fodmap_exception function
pub fn is_low_fodmap_exception_for_apple_cider_vinegar_test() {
  fodmap.is_low_fodmap_exception("apple cider vinegar")
  |> should.be_true()
}

pub fn is_low_fodmap_exception_for_garlic_infused_oil_test() {
  fodmap.is_low_fodmap_exception("garlic-infused oil")
  |> should.be_true()
}

pub fn is_low_fodmap_exception_for_green_onion_tops_test() {
  fodmap.is_low_fodmap_exception("green onion tops")
  |> should.be_true()
}

pub fn is_low_fodmap_exception_for_regular_garlic_test() {
  fodmap.is_low_fodmap_exception("garlic")
  |> should.be_false()
}

pub fn is_low_fodmap_exception_for_onion_test() {
  fodmap.is_low_fodmap_exception("onion")
  |> should.be_false()
}

// Test analyze_recipe_fodmap function
pub fn analyze_recipe_fodmap_compliant_recipe_test() {
  let recipe =
    Recipe(
      name: "Beef and Rice",
      ingredients: [
        Ingredient("Beef", "1 lb"),
        Ingredient("White Rice", "2 cups"),
        Ingredient("Salt", "1 tsp"),
      ],
      instructions: ["Cook beef", "Cook rice", "Combine"],
      macros: Macros(protein: 50.0, fat: 20.0, carbs: 45.0),
      servings: 4,
      category: "beef",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let analysis = fodmap.analyze_recipe_fodmap(recipe)

  analysis.recipe
  |> should.equal("Beef and Rice")

  analysis.is_low_fodmap
  |> should.be_true()

  analysis.high_fodmap_found
  |> list.length()
  |> should.equal(0)

  analysis.compliance_percentage
  |> should.equal(100.0)
}

pub fn analyze_recipe_fodmap_with_high_fodmap_ingredient_test() {
  let recipe =
    Recipe(
      name: "Beef with Garlic",
      ingredients: [
        Ingredient("Beef", "1 lb"),
        Ingredient("Garlic", "3 cloves"),
        Ingredient("Salt", "1 tsp"),
      ],
      instructions: ["Cook beef", "Add garlic"],
      macros: Macros(protein: 50.0, fat: 20.0, carbs: 5.0),
      servings: 4,
      category: "beef",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let analysis = fodmap.analyze_recipe_fodmap(recipe)

  analysis.recipe
  |> should.equal("Beef with Garlic")

  analysis.is_low_fodmap
  |> should.be_false()

  analysis.high_fodmap_found
  |> should.equal(["Garlic"])

  // 2 out of 3 ingredients are compliant = 66.67%
  let expected = 66.66666666666666
  let diff = analysis.compliance_percentage -. expected
  let abs_diff = case diff <. 0.0 {
    True -> diff *. -1.0
    False -> diff
  }
  abs_diff <. 0.01
  |> should.be_true()
}

pub fn analyze_recipe_fodmap_with_exception_test() {
  let recipe =
    Recipe(
      name: "Beef with Garlic Oil",
      ingredients: [
        Ingredient("Beef", "1 lb"),
        Ingredient("Garlic-infused oil", "2 tbsp"),
        Ingredient("Salt", "1 tsp"),
      ],
      instructions: ["Cook beef", "Add garlic oil"],
      macros: Macros(protein: 50.0, fat: 25.0, carbs: 5.0),
      servings: 4,
      category: "beef",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let analysis = fodmap.analyze_recipe_fodmap(recipe)

  analysis.recipe
  |> should.equal("Beef with Garlic Oil")

  analysis.is_low_fodmap
  |> should.be_true()

  analysis.high_fodmap_found
  |> list.length()
  |> should.equal(0)

  analysis.compliance_percentage
  |> should.equal(100.0)
}

pub fn analyze_recipe_fodmap_with_multiple_high_fodmap_test() {
  let recipe =
    Recipe(
      name: "Beef with Onion and Garlic",
      ingredients: [
        Ingredient("Beef", "1 lb"),
        Ingredient("Onion", "1 medium"),
        Ingredient("Garlic", "3 cloves"),
        Ingredient("Salt", "1 tsp"),
      ],
      instructions: ["Cook everything"],
      macros: Macros(protein: 50.0, fat: 20.0, carbs: 10.0),
      servings: 4,
      category: "beef",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let analysis = fodmap.analyze_recipe_fodmap(recipe)

  analysis.recipe
  |> should.equal("Beef with Onion and Garlic")

  analysis.is_low_fodmap
  |> should.be_false()

  analysis.high_fodmap_found
  |> should.equal(["Onion", "Garlic"])

  // 2 out of 4 ingredients are compliant = 50%
  analysis.compliance_percentage
  |> should.equal(50.0)
}

pub fn analyze_recipe_fodmap_empty_ingredients_test() {
  let recipe =
    Recipe(
      name: "Empty Recipe",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 0.0, fat: 0.0, carbs: 0.0),
      servings: 1,
      category: "test",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let analysis = fodmap.analyze_recipe_fodmap(recipe)

  analysis.recipe
  |> should.equal("Empty Recipe")

  analysis.is_low_fodmap
  |> should.be_true()

  analysis.high_fodmap_found
  |> list.length()
  |> should.equal(0)

  analysis.compliance_percentage
  |> should.equal(100.0)
}

pub fn analyze_recipe_fodmap_case_insensitive_test() {
  let recipe =
    Recipe(
      name: "Beef with GARLIC",
      ingredients: [
        Ingredient("Beef", "1 lb"),
        Ingredient("GARLIC", "3 cloves"),
        Ingredient("ONION", "1 medium"),
      ],
      instructions: ["Cook everything"],
      macros: Macros(protein: 50.0, fat: 20.0, carbs: 10.0),
      servings: 4,
      category: "beef",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let analysis = fodmap.analyze_recipe_fodmap(recipe)

  analysis.is_low_fodmap
  |> should.be_false()

  // Should find both uppercase ingredients
  analysis.high_fodmap_found
  |> list.length()
  |> should.equal(2)
}
