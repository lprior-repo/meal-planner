import gleam/list
import gleam/option.{None}
import gleeunit/should
import meal_planner/shopping_list.{
  Dairy, Fats, Grains, Other, Produce, Protein, Seasonings,
  categorize_ingredient, organize_shopping_list,
}
import meal_planner/types.{Ingredient}

// Test categorize_ingredient for protein items
pub fn categorize_ingredient_protein_beef_test() {
  let ing = Ingredient(name: "Ground beef", quantity: "1 lb")
  categorize_ingredient(ing) |> should.equal(Protein)
}

pub fn categorize_ingredient_protein_chicken_test() {
  let ing = Ingredient(name: "Chicken breast", quantity: "200g")
  categorize_ingredient(ing) |> should.equal(Protein)
}

pub fn categorize_ingredient_protein_salmon_test() {
  let ing = Ingredient(name: "Salmon fillet", quantity: "6 oz")
  categorize_ingredient(ing) |> should.equal(Protein)
}

pub fn categorize_ingredient_protein_eggs_test() {
  let ing = Ingredient(name: "Eggs", quantity: "4")
  categorize_ingredient(ing) |> should.equal(Protein)
}

// Test categorize_ingredient for dairy items
pub fn categorize_ingredient_dairy_cheese_test() {
  let ing = Ingredient(name: "Cheddar cheese", quantity: "2 oz")
  categorize_ingredient(ing) |> should.equal(Dairy)
}

pub fn categorize_ingredient_dairy_butter_test() {
  let ing = Ingredient(name: "Butter", quantity: "1 tbsp")
  categorize_ingredient(ing) |> should.equal(Dairy)
}

// Test categorize_ingredient for produce items
pub fn categorize_ingredient_produce_spinach_test() {
  let ing = Ingredient(name: "Baby spinach", quantity: "1 cup")
  categorize_ingredient(ing) |> should.equal(Produce)
}

pub fn categorize_ingredient_produce_potato_test() {
  let ing = Ingredient(name: "Russet potato", quantity: "1 medium")
  categorize_ingredient(ing) |> should.equal(Produce)
}

// Test categorize_ingredient for grains
pub fn categorize_ingredient_grains_rice_test() {
  let ing = Ingredient(name: "White rice", quantity: "1 cup")
  categorize_ingredient(ing) |> should.equal(Grains)
}

pub fn categorize_ingredient_grains_tortilla_test() {
  let ing = Ingredient(name: "Corn tortilla", quantity: "2")
  categorize_ingredient(ing) |> should.equal(Grains)
}

// Test categorize_ingredient for fats & oils
pub fn categorize_ingredient_fats_olive_oil_test() {
  let ing = Ingredient(name: "Olive oil", quantity: "1 tbsp")
  categorize_ingredient(ing) |> should.equal(Fats)
}

pub fn categorize_ingredient_fats_tallow_test() {
  let ing = Ingredient(name: "Beef tallow", quantity: "2 tbsp")
  categorize_ingredient(ing) |> should.equal(Fats)
}

// Test categorize_ingredient for seasonings
pub fn categorize_ingredient_seasonings_salt_test() {
  let ing = Ingredient(name: "Sea salt", quantity: "1 tsp")
  categorize_ingredient(ing) |> should.equal(Seasonings)
}

pub fn categorize_ingredient_seasonings_paprika_test() {
  let ing = Ingredient(name: "Smoked paprika", quantity: "1/2 tsp")
  categorize_ingredient(ing) |> should.equal(Seasonings)
}

// Test categorize_ingredient for other items
pub fn categorize_ingredient_other_test() {
  let ing = Ingredient(name: "Water", quantity: "1 cup")
  categorize_ingredient(ing) |> should.equal(Other)
}

// Test organize_shopping_list
pub fn organize_shopping_list_empty_test() {
  let result = organize_shopping_list([])
  result.protein |> should.equal([])
  result.dairy |> should.equal([])
  result.produce |> should.equal([])
  result.grains |> should.equal([])
  result.fats |> should.equal([])
  result.seasonings |> should.equal([])
  result.other |> should.equal([])
}

pub fn organize_shopping_list_mixed_test() {
  let ingredients = [
    Ingredient(name: "Ground beef", quantity: "1 lb"),
    Ingredient(name: "Cheddar cheese", quantity: "2 oz"),
    Ingredient(name: "Spinach", quantity: "1 cup"),
    Ingredient(name: "White rice", quantity: "1 cup"),
    Ingredient(name: "Olive oil", quantity: "1 tbsp"),
    Ingredient(name: "Salt", quantity: "1 tsp"),
    Ingredient(name: "Water", quantity: "2 cups"),
  ]

  let result = organize_shopping_list(ingredients)

  list.length(result.protein) |> should.equal(1)
  list.length(result.dairy) |> should.equal(1)
  list.length(result.produce) |> should.equal(1)
  list.length(result.grains) |> should.equal(1)
  list.length(result.fats) |> should.equal(1)
  list.length(result.seasonings) |> should.equal(1)
  list.length(result.other) |> should.equal(1)
}

pub fn organize_shopping_list_multiple_proteins_test() {
  let ingredients = [
    Ingredient(name: "Ground beef", quantity: "1 lb"),
    Ingredient(name: "Chicken breast", quantity: "8 oz"),
    Ingredient(name: "Salmon", quantity: "6 oz"),
  ]

  let result = organize_shopping_list(ingredients)

  list.length(result.protein) |> should.equal(3)
  list.length(result.dairy) |> should.equal(0)
}
