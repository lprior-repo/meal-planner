//// Comprehensive tests for Recipe CRUD operations

import gleam/list
import gleeunit/should
import server/storage
import shared/types

pub fn create_recipe_test() {
  // Test creating a new recipe
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "test-recipe-1",
        name: "Test Recipe",
        ingredients: [
          types.Ingredient(name: "Ingredient 1", quantity: "100g"),
          types.Ingredient(name: "Ingredient 2", quantity: "200g"),
        ],
        instructions: ["Step 1", "Step 2", "Step 3"],
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
        servings: 2,
        category: "test",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )

    // Save the recipe
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    // Verify it was saved
    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, "test-recipe-1")
    retrieved.name |> should.equal("Test Recipe")
    retrieved.servings |> should.equal(2)
    retrieved.macros.protein |> should.equal(30.0)
    retrieved.ingredients |> list.length |> should.equal(2)
    retrieved.instructions |> list.length |> should.equal(3)
  })
}

pub fn read_recipe_test() {
  // Test reading a recipe by ID
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "read-test",
        name: "Read Test Recipe",
        ingredients: [
          types.Ingredient(name: "Test Ingredient", quantity: "1 cup"),
        ],
        instructions: ["Mix ingredients"],
        macros: types.Macros(protein: 20.0, fat: 5.0, carbs: 30.0),
        servings: 1,
        category: "breakfast",
        fodmap_level: types.Medium,
        vertical_compliant: False,
      )

    let assert Ok(_) = storage.save_recipe(conn, recipe)

    // Read the recipe
    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, "read-test")
    retrieved.id |> should.equal("read-test")
    retrieved.name |> should.equal("Read Test Recipe")
    retrieved.category |> should.equal("breakfast")
    retrieved.vertical_compliant |> should.equal(False)
  })
}

pub fn read_nonexistent_recipe_test() {
  // Test reading a recipe that doesn't exist
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let result = storage.get_recipe_by_id(conn, "nonexistent-id")
    result |> should.be_error
    case result {
      Error(storage.NotFound) -> Nil
      _ -> panic as "Expected NotFound error"
    }
  })
}

pub fn update_recipe_test() {
  // Test updating an existing recipe
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let original =
      types.Recipe(
        id: "update-test",
        name: "Original Name",
        ingredients: [types.Ingredient(name: "Original", quantity: "1 cup")],
        instructions: ["Original instruction"],
        macros: types.Macros(protein: 10.0, fat: 5.0, carbs: 20.0),
        servings: 1,
        category: "original",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )

    let assert Ok(_) = storage.save_recipe(conn, original)

    // Update the recipe
    let updated =
      types.Recipe(
        id: "update-test",
        name: "Updated Name",
        ingredients: [
          types.Ingredient(name: "Updated 1", quantity: "2 cups"),
          types.Ingredient(name: "Updated 2", quantity: "3 cups"),
        ],
        instructions: ["Updated step 1", "Updated step 2"],
        macros: types.Macros(protein: 25.0, fat: 12.0, carbs: 35.0),
        servings: 3,
        category: "updated",
        fodmap_level: types.High,
        vertical_compliant: False,
      )

    let assert Ok(_) = storage.save_recipe(conn, updated)

    // Verify the update
    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, "update-test")
    retrieved.name |> should.equal("Updated Name")
    retrieved.servings |> should.equal(3)
    retrieved.macros.protein |> should.equal(25.0)
    retrieved.category |> should.equal("updated")
    retrieved.vertical_compliant |> should.equal(False)
    retrieved.ingredients |> list.length |> should.equal(2)
    retrieved.instructions |> list.length |> should.equal(2)
  })
}

pub fn delete_recipe_test() {
  // Test deleting a recipe
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "delete-test",
        name: "Delete Test Recipe",
        ingredients: [types.Ingredient(name: "Ingredient", quantity: "1 cup")],
        instructions: ["Instruction"],
        macros: types.Macros(protein: 15.0, fat: 8.0, carbs: 25.0),
        servings: 1,
        category: "test",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )

    let assert Ok(_) = storage.save_recipe(conn, recipe)

    // Verify it exists
    let assert Ok(_) = storage.get_recipe_by_id(conn, "delete-test")

    // Delete the recipe
    let assert Ok(_) = storage.delete_recipe(conn, "delete-test")

    // Verify it's gone
    let result = storage.get_recipe_by_id(conn, "delete-test")
    result |> should.be_error
    case result {
      Error(storage.NotFound) -> Nil
      _ -> panic as "Expected NotFound error after deletion"
    }
  })
}

pub fn delete_nonexistent_recipe_test() {
  // Test deleting a recipe that doesn't exist (should succeed silently)
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    // Delete a nonexistent recipe - should not error
    let result = storage.delete_recipe(conn, "nonexistent")
    result |> should.be_ok
  })
}

pub fn list_all_recipes_test() {
  // Test listing all recipes
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    // Initially empty
    let assert Ok(recipes) = storage.get_all_recipes(conn)
    recipes |> list.length |> should.equal(0)

    // Add three recipes
    let recipe1 =
      types.Recipe(
        id: "recipe-1",
        name: "Recipe 1",
        ingredients: [types.Ingredient(name: "Ing 1", quantity: "1")],
        instructions: ["Step 1"],
        macros: types.Macros(protein: 10.0, fat: 5.0, carbs: 20.0),
        servings: 1,
        category: "cat1",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )

    let recipe2 =
      types.Recipe(
        id: "recipe-2",
        name: "Recipe 2",
        ingredients: [types.Ingredient(name: "Ing 2", quantity: "2")],
        instructions: ["Step 2"],
        macros: types.Macros(protein: 15.0, fat: 7.0, carbs: 25.0),
        servings: 2,
        category: "cat2",
        fodmap_level: types.Medium,
        vertical_compliant: False,
      )

    let recipe3 =
      types.Recipe(
        id: "recipe-3",
        name: "Recipe 3",
        ingredients: [types.Ingredient(name: "Ing 3", quantity: "3")],
        instructions: ["Step 3"],
        macros: types.Macros(protein: 20.0, fat: 10.0, carbs: 30.0),
        servings: 3,
        category: "cat3",
        fodmap_level: types.High,
        vertical_compliant: True,
      )

    let assert Ok(_) = storage.save_recipe(conn, recipe1)
    let assert Ok(_) = storage.save_recipe(conn, recipe2)
    let assert Ok(_) = storage.save_recipe(conn, recipe3)

    // Verify all three are listed
    let assert Ok(all_recipes) = storage.get_all_recipes(conn)
    all_recipes |> list.length |> should.equal(3)

    // Verify they're sorted by name
    let names = list.map(all_recipes, fn(r) { r.name })
    names |> should.equal(["Recipe 1", "Recipe 2", "Recipe 3"])
  })
}

pub fn recipe_macros_calculation_test() {
  // Test that macros are correctly stored and retrieved
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "macros-test",
        name: "Macros Test",
        ingredients: [types.Ingredient(name: "Food", quantity: "100g")],
        instructions: ["Cook"],
        macros: types.Macros(protein: 35.5, fat: 12.3, carbs: 48.7),
        servings: 1,
        category: "test",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )

    let assert Ok(_) = storage.save_recipe(conn, recipe)

    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, "macros-test")
    retrieved.macros.protein |> should.equal(35.5)
    retrieved.macros.fat |> should.equal(12.3)
    retrieved.macros.carbs |> should.equal(48.7)

    // Verify calories calculation
    let calories = types.macros_calories(retrieved.macros)
    // (35.5 * 4) + (12.3 * 9) + (48.7 * 4) = 142 + 110.7 + 194.8 = 447.5
    calories |> should.equal(447.5)
  })
}

pub fn recipe_with_multiple_ingredients_test() {
  // Test recipe with many ingredients
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "multi-ing",
        name: "Multi Ingredient Recipe",
        ingredients: [
          types.Ingredient(name: "Chicken breast", quantity: "8 oz"),
          types.Ingredient(name: "Rice", quantity: "1 cup"),
          types.Ingredient(name: "Broccoli", quantity: "2 cups"),
          types.Ingredient(name: "Olive oil", quantity: "1 tbsp"),
          types.Ingredient(name: "Garlic", quantity: "2 cloves"),
          types.Ingredient(name: "Salt", quantity: "1 tsp"),
          types.Ingredient(name: "Pepper", quantity: "1/2 tsp"),
        ],
        instructions: [
          "Prepare ingredients",
          "Cook rice",
          "Grill chicken",
          "Steam broccoli",
          "Combine all",
          "Season to taste",
        ],
        macros: types.Macros(protein: 45.0, fat: 15.0, carbs: 50.0),
        servings: 2,
        category: "dinner",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )

    let assert Ok(_) = storage.save_recipe(conn, recipe)

    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, "multi-ing")
    retrieved.ingredients |> list.length |> should.equal(7)
    retrieved.instructions |> list.length |> should.equal(6)

    // Verify specific ingredients
    let first_ing = list.first(retrieved.ingredients)
    case first_ing {
      Ok(ing) -> {
        ing.name |> should.equal("Chicken breast")
        ing.quantity |> should.equal("8 oz")
      }
      _ -> panic as "Expected ingredient"
    }
  })
}
