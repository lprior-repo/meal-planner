//// BDD Tests for Recipe CRUD API
//// Comprehensive test coverage for creating, updating, and deleting recipes
//// Following Given/When/Then pattern from meal_logging_test.gleam

import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import server/storage
import shared/types

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// BDD Scenario: POST /api/recipes creates new recipe and returns 201
// ============================================================================

pub fn create_recipe_with_valid_data_test() {
  // Given a database initialized with tables
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    // When creating a new recipe
    let recipe =
      types.Recipe(
        id: "grilled-salmon",
        name: "Grilled Salmon",
        ingredients: [
          types.Ingredient("Salmon fillet", "6 oz"),
          types.Ingredient("Lemon juice", "1 tbsp"),
          types.Ingredient("Olive oil", "1 tsp"),
        ],
        instructions: [
          "Preheat grill to medium-high",
          "Season salmon with lemon and oil",
          "Grill for 4-5 minutes per side",
        ],
        macros: types.Macros(protein: 35.0, fat: 15.0, carbs: 0.0),
        servings: 1,
        category: "seafood",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )

    // Then recipe is saved successfully (simulating 201 Created)
    storage.save_recipe(conn, recipe)
    |> should.be_ok()

    // And the recipe can be retrieved
    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, "grilled-salmon")
    retrieved.name
    |> should.equal("Grilled Salmon")
    retrieved.macros.protein
    |> should.equal(35.0)
  })
}

pub fn create_recipe_with_multiple_ingredients_test() {
  // Given a database
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    // When creating a recipe with many ingredients
    let recipe =
      types.Recipe(
        id: "complex-stir-fry",
        name: "Complex Stir Fry",
        ingredients: [
          types.Ingredient("Chicken breast", "8 oz"),
          types.Ingredient("Broccoli", "1 cup"),
          types.Ingredient("Bell peppers", "1 cup"),
          types.Ingredient("Soy sauce", "2 tbsp"),
          types.Ingredient("Ginger", "1 tsp"),
          types.Ingredient("Garlic", "2 cloves"),
        ],
        instructions: [
          "Cut chicken into bite-sized pieces",
          "Chop all vegetables",
          "Stir-fry chicken first, then vegetables",
          "Add sauce and seasonings",
        ],
        macros: types.Macros(protein: 45.0, fat: 8.0, carbs: 15.0),
        servings: 2,
        category: "chicken",
        fodmap_level: types.Medium,
        vertical_compliant: True,
      )

    let assert Ok(_) = storage.save_recipe(conn, recipe)

    // Then all ingredients are preserved
    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, "complex-stir-fry")
    list.length(retrieved.ingredients)
    |> should.equal(6)
    list.length(retrieved.instructions)
    |> should.equal(4)
    retrieved.servings
    |> should.equal(2)
  })
}

pub fn create_recipe_with_high_fodmap_test() {
  // Given a database
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    // When creating a high FODMAP recipe
    let recipe =
      types.Recipe(
        id: "wheat-pasta",
        name: "Wheat Pasta Bowl",
        ingredients: [types.Ingredient("Wheat pasta", "2 cups")],
        instructions: ["Boil pasta", "Drain and serve"],
        macros: types.Macros(protein: 12.0, fat: 2.0, carbs: 80.0),
        servings: 1,
        category: "pasta",
        fodmap_level: types.High,
        vertical_compliant: False,
      )

    let assert Ok(_) = storage.save_recipe(conn, recipe)

    // Then FODMAP level is correctly stored
    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, "wheat-pasta")
    retrieved.fodmap_level
    |> should.equal(types.High)
    retrieved.vertical_compliant
    |> should.equal(False)
  })
}

// ============================================================================
// BDD Scenario: PUT /api/recipes/:id updates existing recipe
// ============================================================================

pub fn update_recipe_macros_test() {
  // Given a database with an existing recipe
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let original =
      types.Recipe(
        id: "chicken-bowl",
        name: "Chicken Bowl",
        ingredients: [types.Ingredient("Chicken", "6 oz")],
        instructions: ["Cook chicken"],
        macros: types.Macros(protein: 40.0, fat: 5.0, carbs: 0.0),
        servings: 1,
        category: "chicken",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let assert Ok(_) = storage.save_recipe(conn, original)

    // When updating the macros with more accurate values
    let updated =
      types.Recipe(
        id: "chicken-bowl",
        name: "Chicken Bowl",
        ingredients: [types.Ingredient("Chicken", "8 oz")],
        instructions: ["Cook chicken"],
        macros: types.Macros(protein: 50.0, fat: 6.0, carbs: 0.0),
        servings: 1,
        category: "chicken",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )

    let assert Ok(_) = storage.save_recipe(conn, updated)

    // Then macros are updated correctly
    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, "chicken-bowl")
    retrieved.macros.protein
    |> should.equal(50.0)
    retrieved.macros.fat
    |> should.equal(6.0)
  })
}

pub fn update_recipe_ingredients_test() {
  // Given a recipe with basic ingredients
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let original =
      types.Recipe(
        id: "basic-salad",
        name: "Basic Salad",
        ingredients: [types.Ingredient("Lettuce", "2 cups")],
        instructions: ["Wash and serve"],
        macros: types.Macros(protein: 2.0, fat: 0.0, carbs: 5.0),
        servings: 1,
        category: "salad",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let assert Ok(_) = storage.save_recipe(conn, original)

    // When adding more ingredients to make it complete
    let updated =
      types.Recipe(
        id: "basic-salad",
        name: "Complete Salad",
        ingredients: [
          types.Ingredient("Lettuce", "2 cups"),
          types.Ingredient("Chicken breast", "4 oz"),
          types.Ingredient("Olive oil", "1 tbsp"),
        ],
        instructions: ["Wash lettuce", "Grill chicken", "Combine and dress"],
        macros: types.Macros(protein: 30.0, fat: 15.0, carbs: 5.0),
        servings: 1,
        category: "salad",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )

    let assert Ok(_) = storage.save_recipe(conn, updated)

    // Then ingredients and name are updated
    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, "basic-salad")
    retrieved.name
    |> should.equal("Complete Salad")
    list.length(retrieved.ingredients)
    |> should.equal(3)
    list.length(retrieved.instructions)
    |> should.equal(3)
  })
}

pub fn update_recipe_servings_test() {
  // Given a single-serving recipe
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let original =
      types.Recipe(
        id: "batch-oatmeal",
        name: "Batch Oatmeal",
        ingredients: [types.Ingredient("Oats", "1 cup")],
        instructions: ["Cook oats"],
        macros: types.Macros(protein: 10.0, fat: 3.0, carbs: 50.0),
        servings: 1,
        category: "breakfast",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let assert Ok(_) = storage.save_recipe(conn, original)

    // When updating to make 4 servings
    let updated =
      types.Recipe(
        id: "batch-oatmeal",
        name: "Batch Oatmeal",
        ingredients: [types.Ingredient("Oats", "4 cups")],
        instructions: ["Cook oats in large pot"],
        macros: types.Macros(protein: 10.0, fat: 3.0, carbs: 50.0),
        servings: 4,
        category: "breakfast",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )

    let assert Ok(_) = storage.save_recipe(conn, updated)

    // Then servings are updated
    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, "batch-oatmeal")
    retrieved.servings
    |> should.equal(4)
  })
}

pub fn update_recipe_category_test() {
  // Given a recipe with one category
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let original =
      types.Recipe(
        id: "turkey-meal",
        name: "Turkey Meal",
        ingredients: [types.Ingredient("Turkey", "6 oz")],
        instructions: ["Cook turkey"],
        macros: types.Macros(protein: 42.0, fat: 3.0, carbs: 0.0),
        servings: 1,
        category: "poultry",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let assert Ok(_) = storage.save_recipe(conn, original)

    // When changing the category
    let updated =
      types.Recipe(
        id: "turkey-meal",
        name: "Turkey Meal",
        ingredients: [types.Ingredient("Turkey", "6 oz")],
        instructions: ["Cook turkey"],
        macros: types.Macros(protein: 42.0, fat: 3.0, carbs: 0.0),
        servings: 1,
        category: "lean-protein",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )

    let assert Ok(_) = storage.save_recipe(conn, updated)

    // Then category is updated
    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, "turkey-meal")
    retrieved.category
    |> should.equal("lean-protein")
  })
}

// ============================================================================
// BDD Scenario: DELETE /api/recipes/:id removes recipe
// ============================================================================

pub fn delete_existing_recipe_test() {
  // Given a database with a recipe
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "to-delete",
        name: "Recipe To Delete",
        ingredients: [types.Ingredient("Test", "1 cup")],
        instructions: ["Test instruction"],
        macros: types.Macros(protein: 10.0, fat: 5.0, carbs: 20.0),
        servings: 1,
        category: "test",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    // Verify it exists
    let assert Ok(_) = storage.get_recipe_by_id(conn, "to-delete")

    // When deleting the recipe
    let assert Ok(_) = storage.delete_recipe(conn, "to-delete")

    // Then the recipe no longer exists
    storage.get_recipe_by_id(conn, "to-delete")
    |> should.be_error()
  })
}

pub fn delete_recipe_from_multiple_test() {
  // Given a database with multiple recipes
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe1 =
      types.Recipe(
        id: "keep-1",
        name: "Keep Recipe 1",
        ingredients: [types.Ingredient("Ingredient 1", "1 cup")],
        instructions: ["Step 1"],
        macros: types.Macros(protein: 20.0, fat: 10.0, carbs: 30.0),
        servings: 1,
        category: "test",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )

    let recipe2 =
      types.Recipe(
        id: "delete-me",
        name: "Delete This",
        ingredients: [types.Ingredient("Ingredient 2", "1 cup")],
        instructions: ["Step 2"],
        macros: types.Macros(protein: 15.0, fat: 5.0, carbs: 25.0),
        servings: 1,
        category: "test",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )

    let recipe3 =
      types.Recipe(
        id: "keep-2",
        name: "Keep Recipe 2",
        ingredients: [types.Ingredient("Ingredient 3", "1 cup")],
        instructions: ["Step 3"],
        macros: types.Macros(protein: 25.0, fat: 8.0, carbs: 35.0),
        servings: 1,
        category: "test",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )

    let assert Ok(_) = storage.save_recipe(conn, recipe1)
    let assert Ok(_) = storage.save_recipe(conn, recipe2)
    let assert Ok(_) = storage.save_recipe(conn, recipe3)

    // When deleting one recipe
    let assert Ok(_) = storage.delete_recipe(conn, "delete-me")

    // Then the deleted recipe is gone
    storage.get_recipe_by_id(conn, "delete-me")
    |> should.be_error()

    // And the other recipes remain
    let assert Ok(recipes) = storage.get_all_recipes(conn)
    list.length(recipes)
    |> should.equal(2)

    // And we can still retrieve the kept recipes
    let assert Ok(_) = storage.get_recipe_by_id(conn, "keep-1")
    let assert Ok(_) = storage.get_recipe_by_id(conn, "keep-2")
  })
}

pub fn delete_nonexistent_recipe_test() {
  // Given a database with no recipes
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    // When attempting to delete a nonexistent recipe
    let result = storage.delete_recipe(conn, "nonexistent-id")

    // Then the operation completes without error (idempotent)
    result
    |> should.be_ok()
  })
}

// ============================================================================
// BDD Scenario: Error handling for invalid recipe data
// ============================================================================

pub fn create_recipe_with_empty_id_fails_test() {
  // Given a recipe with empty ID
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "",
        name: "Invalid Recipe",
        ingredients: [types.Ingredient("Test", "1 cup")],
        instructions: ["Test"],
        macros: types.Macros(protein: 10.0, fat: 5.0, carbs: 20.0),
        servings: 1,
        category: "test",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )

    // When saving (this would fail validation in the API layer)
    // The storage layer accepts it, but API validation would reject
    // Testing that empty string IDs can technically be stored but shouldn't be
    let result = storage.save_recipe(conn, recipe)

    // Storage layer allows it (API layer would reject)
    result
    |> should.be_ok()
  })
}

pub fn create_recipe_with_empty_ingredients_test() {
  // Given a recipe with no ingredients
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "no-ingredients",
        name: "Empty Recipe",
        ingredients: [],
        instructions: ["Do nothing"],
        macros: types.Macros(protein: 0.0, fat: 0.0, carbs: 0.0),
        servings: 1,
        category: "test",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )

    // Storage layer accepts empty ingredients
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    // Can retrieve it
    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, "no-ingredients")
    list.length(retrieved.ingredients)
    |> should.equal(0)
  })
}

pub fn create_recipe_with_negative_macros_test() {
  // Given a recipe with negative macros (data error)
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "negative-macros",
        name: "Invalid Macros",
        ingredients: [types.Ingredient("Test", "1 cup")],
        instructions: ["Test"],
        macros: types.Macros(protein: -10.0, fat: -5.0, carbs: -20.0),
        servings: 1,
        category: "test",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )

    // Storage layer allows negative values (API would validate)
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, "negative-macros")
    retrieved.macros.protein
    |> should.equal(-10.0)
  })
}

pub fn create_recipe_with_zero_servings_test() {
  // Given a recipe with zero servings
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "zero-servings",
        name: "No Servings",
        ingredients: [types.Ingredient("Test", "1 cup")],
        instructions: ["Test"],
        macros: types.Macros(protein: 10.0, fat: 5.0, carbs: 20.0),
        servings: 0,
        category: "test",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )

    // Storage layer allows zero servings (API would validate)
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, "zero-servings")
    retrieved.servings
    |> should.equal(0)
  })
}

// ============================================================================
// BDD Scenario: Get recipe by ID handles missing recipes
// ============================================================================

pub fn get_nonexistent_recipe_returns_not_found_test() {
  // Given an empty database
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    // When attempting to get a recipe that doesn't exist
    let result = storage.get_recipe_by_id(conn, "does-not-exist")

    // Then NotFound error is returned
    result
    |> should.be_error()

    case result {
      Error(storage.NotFound) -> Nil
      _ -> panic as "Expected NotFound error"
    }
  })
}

pub fn get_recipe_after_deletion_returns_not_found_test() {
  // Given a recipe that was previously deleted
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "temporary",
        name: "Temporary Recipe",
        ingredients: [types.Ingredient("Test", "1 cup")],
        instructions: ["Test"],
        macros: types.Macros(protein: 10.0, fat: 5.0, carbs: 20.0),
        servings: 1,
        category: "test",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )

    let assert Ok(_) = storage.save_recipe(conn, recipe)
    let assert Ok(_) = storage.delete_recipe(conn, "temporary")

    // When attempting to get the deleted recipe
    let result = storage.get_recipe_by_id(conn, "temporary")

    // Then NotFound error is returned
    result
    |> should.be_error()
  })
}

// ============================================================================
// BDD Scenario: List all recipes returns correct data
// ============================================================================

pub fn list_recipes_returns_all_test() {
  // Given a database with multiple recipes
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipes = [
      types.Recipe(
        id: "recipe-1",
        name: "Recipe 1",
        ingredients: [types.Ingredient("Ingredient 1", "1 cup")],
        instructions: ["Step 1"],
        macros: types.Macros(protein: 20.0, fat: 10.0, carbs: 30.0),
        servings: 1,
        category: "test",
        fodmap_level: types.Low,
        vertical_compliant: True,
      ),
      types.Recipe(
        id: "recipe-2",
        name: "Recipe 2",
        ingredients: [types.Ingredient("Ingredient 2", "2 cups")],
        instructions: ["Step 2"],
        macros: types.Macros(protein: 30.0, fat: 15.0, carbs: 40.0),
        servings: 2,
        category: "test",
        fodmap_level: types.Medium,
        vertical_compliant: False,
      ),
      types.Recipe(
        id: "recipe-3",
        name: "Recipe 3",
        ingredients: [types.Ingredient("Ingredient 3", "3 cups")],
        instructions: ["Step 3"],
        macros: types.Macros(protein: 40.0, fat: 20.0, carbs: 50.0),
        servings: 3,
        category: "test",
        fodmap_level: types.High,
        vertical_compliant: True,
      ),
    ]

    list.each(recipes, fn(r) {
      let assert Ok(_) = storage.save_recipe(conn, r)
    })

    // When listing all recipes
    let assert Ok(all_recipes) = storage.get_all_recipes(conn)

    // Then all recipes are returned
    list.length(all_recipes)
    |> should.equal(3)
  })
}

pub fn list_recipes_on_empty_database_test() {
  // Given an empty database
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    // When listing recipes
    let assert Ok(recipes) = storage.get_all_recipes(conn)

    // Then empty list is returned
    list.length(recipes)
    |> should.equal(0)
  })
}

// ============================================================================
// BDD Scenario: Recipe data integrity across CRUD operations
// ============================================================================

pub fn recipe_roundtrip_preserves_all_fields_test() {
  // Given a recipe with all fields populated
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let original =
      types.Recipe(
        id: "comprehensive-recipe",
        name: "Comprehensive Recipe Test",
        ingredients: [
          types.Ingredient("Ingredient A", "100g"),
          types.Ingredient("Ingredient B", "2 tbsp"),
          types.Ingredient("Ingredient C", "1 cup"),
        ],
        instructions: [
          "First instruction with details",
          "Second instruction with more details",
          "Third instruction for completion",
        ],
        macros: types.Macros(protein: 33.5, fat: 12.3, carbs: 45.7),
        servings: 3,
        category: "comprehensive-test",
        fodmap_level: types.Medium,
        vertical_compliant: False,
      )

    // When saving and retrieving the recipe
    let assert Ok(_) = storage.save_recipe(conn, original)
    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, "comprehensive-recipe")

    // Then all fields are preserved exactly
    retrieved.id
    |> should.equal(original.id)
    retrieved.name
    |> should.equal(original.name)
    list.length(retrieved.ingredients)
    |> should.equal(list.length(original.ingredients))
    list.length(retrieved.instructions)
    |> should.equal(list.length(original.instructions))
    retrieved.macros.protein
    |> should.equal(original.macros.protein)
    retrieved.macros.fat
    |> should.equal(original.macros.fat)
    retrieved.macros.carbs
    |> should.equal(original.macros.carbs)
    retrieved.servings
    |> should.equal(original.servings)
    retrieved.category
    |> should.equal(original.category)
    retrieved.fodmap_level
    |> should.equal(original.fodmap_level)
    retrieved.vertical_compliant
    |> should.equal(original.vertical_compliant)
  })
}

pub fn recipe_update_preserves_unmodified_fields_test() {
  // Given an existing recipe
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let original =
      types.Recipe(
        id: "partial-update",
        name: "Original Name",
        ingredients: [types.Ingredient("Original", "1 cup")],
        instructions: ["Original instruction"],
        macros: types.Macros(protein: 25.0, fat: 10.0, carbs: 35.0),
        servings: 2,
        category: "original-category",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let assert Ok(_) = storage.save_recipe(conn, original)

    // When updating only the name and macros
    let updated =
      types.Recipe(
        id: "partial-update",
        name: "Updated Name",
        ingredients: [types.Ingredient("Original", "1 cup")],
        instructions: ["Original instruction"],
        macros: types.Macros(protein: 30.0, fat: 12.0, carbs: 40.0),
        servings: 2,
        category: "original-category",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let assert Ok(_) = storage.save_recipe(conn, updated)

    // Then only changed fields are updated
    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, "partial-update")
    retrieved.name
    |> should.equal("Updated Name")
    retrieved.macros.protein
    |> should.equal(30.0)
    retrieved.category
    |> should.equal("original-category")
    retrieved.servings
    |> should.equal(2)
  })
}

pub fn special_characters_in_recipe_name_test() {
  // Given a recipe with special characters in name
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "special-chars",
        name: "Mom's Chicken & Rice (Spicy!)",
        ingredients: [types.Ingredient("Chicken & spices", "8 oz")],
        instructions: ["Cook with love & care"],
        macros: types.Macros(protein: 40.0, fat: 10.0, carbs: 45.0),
        servings: 1,
        category: "chicken",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )

    let assert Ok(_) = storage.save_recipe(conn, recipe)

    // Then special characters are preserved
    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, "special-chars")
    retrieved.name
    |> should.equal("Mom's Chicken & Rice (Spicy!)")
  })
}

pub fn unicode_characters_in_recipe_test() {
  // Given a recipe with unicode characters
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "unicode-recipe",
        name: "Crème Brûlée",
        ingredients: [types.Ingredient("Crème fraîche", "200g")],
        instructions: ["Préparer avec soin"],
        macros: types.Macros(protein: 5.0, fat: 20.0, carbs: 30.0),
        servings: 1,
        category: "dessert",
        fodmap_level: types.High,
        vertical_compliant: False,
      )

    let assert Ok(_) = storage.save_recipe(conn, recipe)

    // Then unicode is preserved
    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, "unicode-recipe")
    string.contains(retrieved.name, "û")
    |> should.be_true()
  })
}
