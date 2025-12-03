//// Comprehensive tests for auto_planner/storage module
//// Following TDD and Martin Fowler's testing principles

import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit/should
import meal_planner/auto_planner/storage
import meal_planner/auto_planner/types as auto_types
import meal_planner/storage as base_storage
import meal_planner/types.{type Recipe, High, Ingredient, Low, Macros, Medium, Recipe}
import pog

// =============================================================================
// Test Fixtures - Reusable Test Data Setup
// =============================================================================

/// Test database connection for integration tests
fn get_test_connection() -> Result(pog.Connection, String) {
  let config =
    base_storage.DbConfig(
      host: "localhost",
      port: 5432,
      database: "meal_planner_test",
      user: "postgres",
      password: Some("postgres"),
      pool_size: 1,
    )

  case
    pog.Config(
      host: config.host,
      port: config.port,
      database: config.database,
      user: config.user,
      password: option.unwrap(config.password, ""),
      ssl: False,
      connection_parameters: [],
      pool_size: config.pool_size,
    )
    |> pog.connect
  {
    Ok(conn) -> Ok(conn)
    Error(_) ->
      Error(
        "Could not connect to test database. Ensure PostgreSQL is running and meal_planner_test database exists.",
      )
  }
}

/// Clean up test data - called before/after tests
fn cleanup_test_data(conn: pog.Connection) -> Nil {
  // Clean up auto_meal_plans
  let _ =
    pog.query("DELETE FROM auto_meal_plans WHERE id LIKE 'test-%'")
    |> pog.execute(conn)

  // Clean up recipe_sources
  let _ =
    pog.query("DELETE FROM recipe_sources WHERE id LIKE 'test-%'")
    |> pog.execute(conn)

  // Clean up test recipes
  let _ =
    pog.query("DELETE FROM recipes WHERE id LIKE 'test-%'")
    |> pog.execute(conn)

  Nil
}

// =============================================================================
// Test Data Builders - Fluent Interfaces for Test Objects
// =============================================================================

/// Builder for test recipes with sensible defaults
fn build_test_recipe(id: String, name: String) -> Recipe {
  Recipe(
    id: id,
    name: name,
    ingredients: [Ingredient("test ingredient", "1 cup")],
    instructions: ["Test instruction"],
    macros: Macros(protein: 30.0, fat: 15.0, carbs: 45.0),
    servings: 1,
    category: "test-main",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

/// Builder for test auto meal plan with sensible defaults
fn build_test_auto_plan(id: String) -> auto_types.AutoMealPlan {
  let config =
    auto_types.AutoPlanConfig(
      user_id: "test-user-123",
      diet_principles: [auto_types.VerticalDiet],
      macro_targets: Macros(protein: 180.0, fat: 60.0, carbs: 250.0),
      recipe_count: 3,
      variety_factor: 0.7,
    )

  let recipes = [
    build_test_recipe("test-recipe-1", "Test Recipe 1"),
    build_test_recipe("test-recipe-2", "Test Recipe 2"),
    build_test_recipe("test-recipe-3", "Test Recipe 3"),
  ]

  auto_types.AutoMealPlan(
    id: id,
    recipes: recipes,
    generated_at: "2025-12-03T12:00:00Z",
    total_macros: Macros(protein: 90.0, fat: 45.0, carbs: 135.0),
    config: config,
  )
}

/// Builder for test recipe source with sensible defaults
fn build_test_recipe_source(
  id: String,
  name: String,
) -> auto_types.RecipeSource {
  auto_types.RecipeSource(
    id: id,
    name: name,
    source_type: auto_types.Database,
    config: None,
  )
}

/// Insert test recipe into database for foreign key constraints
fn insert_test_recipe(conn: pog.Connection, recipe: Recipe) -> Nil {
  let sql =
    "INSERT INTO recipes
     (id, name, ingredients, instructions, protein, fat, carbs, servings, category, fodmap_level, vertical_compliant)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
     ON CONFLICT (id) DO NOTHING"

  let ingredients_str =
    recipe.ingredients
    |> list.map(fn(i) { i.name <> ":" <> i.quantity })
    |> string.join("|")

  let instructions_str = string.join(recipe.instructions, "|")

  let fodmap_str = case recipe.fodmap_level {
    Low -> "low"
    Medium -> "medium"
    High -> "high"
  }

  let _ =
    pog.query(sql)
    |> pog.parameter(pog.text(recipe.id))
    |> pog.parameter(pog.text(recipe.name))
    |> pog.parameter(pog.text(ingredients_str))
    |> pog.parameter(pog.text(instructions_str))
    |> pog.parameter(pog.float(recipe.macros.protein))
    |> pog.parameter(pog.float(recipe.macros.fat))
    |> pog.parameter(pog.float(recipe.macros.carbs))
    |> pog.parameter(pog.int(recipe.servings))
    |> pog.parameter(pog.text(recipe.category))
    |> pog.parameter(pog.text(fodmap_str))
    |> pog.parameter(pog.bool(recipe.vertical_compliant))
    |> pog.execute(conn)

  Nil
}

// =============================================================================
// Auto Meal Plan CRUD Tests
// =============================================================================

pub fn save_auto_plan_valid_data_creates_record_test() {
  // Arrange
  case get_test_connection() {
    Error(_) -> Nil
    Ok(conn) -> {
      cleanup_test_data(conn)

      let plan = build_test_auto_plan("test-plan-001")

      // Insert recipes for foreign key constraints
      list.each(plan.recipes, fn(r) { insert_test_recipe(conn, r) })

      // Act
      let result = storage.save_auto_plan(conn, plan)

      // Assert
      result
      |> should.be_ok

      // Verify data was actually saved
      let verify_result = storage.get_auto_plan(conn, "test-plan-001")
      verify_result
      |> should.be_ok

      cleanup_test_data(conn)
      pog.disconnect(conn)
    }
  }
}

pub fn save_auto_plan_upsert_updates_existing_test() {
  // Arrange
  case get_test_connection() {
    Error(_) -> Nil
    Ok(conn) -> {
      cleanup_test_data(conn)

      let plan = build_test_auto_plan("test-plan-002")
      list.each(plan.recipes, fn(r) { insert_test_recipe(conn, r) })

      // First save
      let _ = storage.save_auto_plan(conn, plan)

      // Act - Save again with different data
      let updated_plan =
        auto_types.AutoMealPlan(
          ..plan,
          total_macros: Macros(protein: 200.0, fat: 70.0, carbs: 300.0),
        )

      let result = storage.save_auto_plan(conn, updated_plan)

      // Assert
      result
      |> should.be_ok

      // Verify data was updated
      case storage.get_auto_plan(conn, "test-plan-002") {
        Ok(retrieved) -> {
          retrieved.total_macros.protein
          |> should.equal(200.0)
        }
        Error(_) -> should.fail()
      }

      cleanup_test_data(conn)
      pog.disconnect(conn)
    }
  }
}

pub fn get_auto_plan_existing_returns_plan_test() {
  // Arrange
  case get_test_connection() {
    Error(_) -> Nil
    Ok(conn) -> {
      cleanup_test_data(conn)

      let plan = build_test_auto_plan("test-plan-003")
      list.each(plan.recipes, fn(r) { insert_test_recipe(conn, r) })
      let _ = storage.save_auto_plan(conn, plan)

      // Act
      let result = storage.get_auto_plan(conn, "test-plan-003")

      // Assert
      case result {
        Ok(retrieved) -> {
          // Verify plan properties
          retrieved.id
          |> should.equal("test-plan-003")

          retrieved.recipes
          |> list.length
          |> should.equal(3)

          retrieved.total_macros.protein
          |> should.equal(90.0)

          // Verify config
          retrieved.config.recipe_count
          |> should.equal(3)
        }
        Error(_) -> should.fail()
      }

      cleanup_test_data(conn)
      pog.disconnect(conn)
    }
  }
}

pub fn get_auto_plan_nonexistent_returns_not_found_test() {
  // Arrange
  case get_test_connection() {
    Error(_) -> Nil
    Ok(conn) -> {
      cleanup_test_data(conn)

      // Act
      let result = storage.get_auto_plan(conn, "nonexistent-plan")

      // Assert
      case result {
        Error(base_storage.NotFound) -> {
          // Success - expected error
          Nil
        }
        Error(_) -> should.fail()
        Ok(_) -> should.fail()
      }

      cleanup_test_data(conn)
      pog.disconnect(conn)
    }
  }
}

pub fn get_auto_plan_reconstructs_recipes_correctly_test() {
  // Arrange
  case get_test_connection() {
    Error(_) -> Nil
    Ok(conn) -> {
      cleanup_test_data(conn)

      // Create recipes with specific data
      let recipe1 =
        Recipe(
          id: "test-recipe-detailed-1",
          name: "Detailed Recipe 1",
          ingredients: [
            Ingredient("chicken breast", "8 oz"),
            Ingredient("white rice", "1 cup"),
          ],
          instructions: ["Grill chicken", "Cook rice", "Combine and serve"],
          macros: Macros(protein: 50.0, fat: 10.0, carbs: 45.0),
          servings: 2,
          category: "chicken-main",
          fodmap_level: Low,
          vertical_compliant: True,
        )

      let recipe2 =
        Recipe(
          id: "test-recipe-detailed-2",
          name: "Detailed Recipe 2",
          ingredients: [Ingredient("spinach", "2 cups")],
          instructions: ["Sauté spinach"],
          macros: Macros(protein: 6.0, fat: 8.0, carbs: 4.0),
          servings: 1,
          category: "vegetable-side",
          fodmap_level: Medium,
          vertical_compliant: False,
        )

      insert_test_recipe(conn, recipe1)
      insert_test_recipe(conn, recipe2)

      let plan =
        auto_types.AutoMealPlan(
          id: "test-plan-detailed",
          recipes: [recipe1, recipe2],
          generated_at: "2025-12-03T12:00:00Z",
          total_macros: Macros(protein: 56.0, fat: 18.0, carbs: 49.0),
          config: auto_types.AutoPlanConfig(
            user_id: "test-user",
            diet_principles: [auto_types.VerticalDiet],
            macro_targets: Macros(protein: 180.0, fat: 60.0, carbs: 250.0),
            recipe_count: 2,
            variety_factor: 0.7,
          ),
        )

      let _ = storage.save_auto_plan(conn, plan)

      // Act
      let result = storage.get_auto_plan(conn, "test-plan-detailed")

      // Assert
      case result {
        Ok(retrieved) -> {
          // Verify first recipe reconstruction
          case list.first(retrieved.recipes) {
            Ok(r1) -> {
              r1.id
              |> should.equal("test-recipe-detailed-1")

              r1.name
              |> should.equal("Detailed Recipe 1")

              r1.ingredients
              |> list.length
              |> should.equal(2)

              r1.instructions
              |> list.length
              |> should.equal(3)

              r1.macros.protein
              |> should.equal(50.0)

              r1.servings
              |> should.equal(2)

              r1.category
              |> should.equal("chicken-main")

              r1.fodmap_level
              |> should.equal(Low)

              r1.vertical_compliant
              |> should.be_true
            }
            Error(_) -> should.fail()
          }
        }
        Error(_) -> should.fail()
      }

      cleanup_test_data(conn)
      pog.disconnect(conn)
    }
  }
}

// =============================================================================
// Recipe Source Storage Tests
// =============================================================================

pub fn save_recipe_source_valid_data_creates_record_test() {
  // Arrange
  case get_test_connection() {
    Error(_) -> Nil
    Ok(conn) -> {
      cleanup_test_data(conn)

      let source = build_test_recipe_source("test-source-001", "Test Database")

      // Act
      let result = storage.save_recipe_source(conn, source)

      // Assert
      result
      |> should.be_ok

      cleanup_test_data(conn)
      pog.disconnect(conn)
    }
  }
}

pub fn save_recipe_source_with_config_stores_config_test() {
  // Arrange
  case get_test_connection() {
    Error(_) -> Nil
    Ok(conn) -> {
      cleanup_test_data(conn)

      let source =
        auto_types.RecipeSource(
          id: "test-source-002",
          name: "API Source",
          source_type: auto_types.Api,
          config: Some("{\"api_key\": \"test123\", \"endpoint\": \"https://api.example.com\"}"),
        )

      // Act
      let result = storage.save_recipe_source(conn, source)

      // Assert
      result
      |> should.be_ok

      // Verify config was saved
      case storage.get_recipe_sources(conn) {
        Ok(sources) -> {
          let found =
            sources
            |> list.find(fn(s) { s.id == "test-source-002" })

          case found {
            Ok(retrieved) -> {
              case retrieved.config {
                Some(cfg) -> {
                  cfg
                  |> string.contains("test123")
                  |> should.be_true
                }
                None -> should.fail()
              }
            }
            Error(_) -> should.fail()
          }
        }
        Error(_) -> should.fail()
      }

      cleanup_test_data(conn)
      pog.disconnect(conn)
    }
  }
}

pub fn save_recipe_source_upsert_updates_existing_test() {
  // Arrange
  case get_test_connection() {
    Error(_) -> Nil
    Ok(conn) -> {
      cleanup_test_data(conn)

      let source = build_test_recipe_source("test-source-003", "Original Name")
      let _ = storage.save_recipe_source(conn, source)

      // Act - Update with new name
      let updated =
        auto_types.RecipeSource(
          ..source,
          name: "Updated Name",
          source_type: auto_types.Api,
        )

      let result = storage.save_recipe_source(conn, updated)

      // Assert
      result
      |> should.be_ok

      // Verify update
      case storage.get_recipe_sources(conn) {
        Ok(sources) -> {
          let found =
            sources
            |> list.find(fn(s) { s.id == "test-source-003" })

          case found {
            Ok(retrieved) -> {
              retrieved.name
              |> should.equal("Updated Name")

              case retrieved.source_type {
                auto_types.Api -> Nil
                _ -> should.fail()
              }
            }
            Error(_) -> should.fail()
          }
        }
        Error(_) -> should.fail()
      }

      cleanup_test_data(conn)
      pog.disconnect(conn)
    }
  }
}

pub fn get_recipe_sources_returns_all_sources_test() {
  // Arrange
  case get_test_connection() {
    Error(_) -> Nil
    Ok(conn) -> {
      cleanup_test_data(conn)

      // Create multiple sources
      let source1 =
        build_test_recipe_source("test-source-multi-1", "Source Alpha")
      let source2 =
        auto_types.RecipeSource(
          id: "test-source-multi-2",
          name: "Source Beta",
          source_type: auto_types.Api,
          config: Some("{\"key\": \"value\"}"),
        )
      let source3 =
        auto_types.RecipeSource(
          id: "test-source-multi-3",
          name: "Source Gamma",
          source_type: auto_types.UserProvided,
          config: None,
        )

      let _ = storage.save_recipe_source(conn, source1)
      let _ = storage.save_recipe_source(conn, source2)
      let _ = storage.save_recipe_source(conn, source3)

      // Act
      let result = storage.get_recipe_sources(conn)

      // Assert
      case result {
        Ok(sources) -> {
          let test_sources =
            sources
            |> list.filter(fn(s) { string.starts_with(s.id, "test-source-multi") })

          test_sources
          |> list.length
          |> should.equal(3)

          // Verify ordering by name
          let names = list.map(test_sources, fn(s) { s.name })

          // Should be alphabetically ordered
          case names {
            ["Source Alpha", "Source Beta", "Source Gamma"] -> Nil
            _ -> should.fail()
          }
        }
        Error(_) -> should.fail()
      }

      cleanup_test_data(conn)
      pog.disconnect(conn)
    }
  }
}

pub fn get_recipe_sources_empty_database_returns_empty_list_test() {
  // Arrange
  case get_test_connection() {
    Error(_) -> Nil
    Ok(conn) -> {
      cleanup_test_data(conn)

      // Act
      let result = storage.get_recipe_sources(conn)

      // Assert
      case result {
        Ok(sources) -> {
          let test_sources =
            sources
            |> list.filter(fn(s) { string.starts_with(s.id, "test-") })

          test_sources
          |> list.length
          |> should.equal(0)
        }
        Error(_) -> should.fail()
      }

      cleanup_test_data(conn)
      pog.disconnect(conn)
    }
  }
}

// =============================================================================
// Data Validation Tests
// =============================================================================

pub fn save_auto_plan_with_empty_recipe_list_test() {
  // Arrange
  case get_test_connection() {
    Error(_) -> Nil
    Ok(conn) -> {
      cleanup_test_data(conn)

      let plan =
        auto_types.AutoMealPlan(
          id: "test-plan-empty",
          recipes: [],
          generated_at: "2025-12-03T12:00:00Z",
          total_macros: Macros(protein: 0.0, fat: 0.0, carbs: 0.0),
          config: auto_types.AutoPlanConfig(
            user_id: "test-user",
            diet_principles: [auto_types.VerticalDiet],
            macro_targets: Macros(protein: 180.0, fat: 60.0, carbs: 250.0),
            recipe_count: 0,
            variety_factor: 0.7,
          ),
        )

      // Act
      let result = storage.save_auto_plan(conn, plan)

      // Assert - Should succeed (business logic validation is elsewhere)
      result
      |> should.be_ok

      cleanup_test_data(conn)
      pog.disconnect(conn)
    }
  }
}

pub fn save_recipe_source_all_types_test() {
  // Arrange
  case get_test_connection() {
    Error(_) -> Nil
    Ok(conn) -> {
      cleanup_test_data(conn)

      // Test all source types
      let sources = [
        auto_types.RecipeSource(
          id: "test-type-db",
          name: "Database Type",
          source_type: auto_types.Database,
          config: None,
        ),
        auto_types.RecipeSource(
          id: "test-type-api",
          name: "API Type",
          source_type: auto_types.Api,
          config: Some("{\"endpoint\": \"https://api.test.com\"}"),
        ),
        auto_types.RecipeSource(
          id: "test-type-user",
          name: "User Provided Type",
          source_type: auto_types.UserProvided,
          config: None,
        ),
      ]

      // Act
      let results =
        sources
        |> list.map(fn(s) { storage.save_recipe_source(conn, s) })

      // Assert - All should succeed
      results
      |> list.all(fn(r) {
        case r {
          Ok(_) -> True
          Error(_) -> False
        }
      })
      |> should.be_true

      // Verify retrieval
      case storage.get_recipe_sources(conn) {
        Ok(retrieved) -> {
          let test_types =
            retrieved
            |> list.filter(fn(s) { string.starts_with(s.id, "test-type-") })

          test_types
          |> list.length
          |> should.equal(3)
        }
        Error(_) -> should.fail()
      }

      cleanup_test_data(conn)
      pog.disconnect(conn)
    }
  }
}

// =============================================================================
// Edge Case Tests
// =============================================================================

pub fn save_auto_plan_with_special_characters_test() {
  // Arrange
  case get_test_connection() {
    Error(_) -> Nil
    Ok(conn) -> {
      cleanup_test_data(conn)

      let recipe =
        Recipe(
          id: "test-special-recipe",
          name: "Recipe with 'quotes' and \"double quotes\"",
          ingredients: [Ingredient("ingredient's name", "1 cup")],
          instructions: ["Step with \"quotes\""],
          macros: Macros(protein: 30.0, fat: 15.0, carbs: 45.0),
          servings: 1,
          category: "test-category",
          fodmap_level: Low,
          vertical_compliant: True,
        )

      insert_test_recipe(conn, recipe)

      let plan =
        auto_types.AutoMealPlan(
          id: "test-plan-special",
          recipes: [recipe],
          generated_at: "2025-12-03T12:00:00Z",
          total_macros: Macros(protein: 30.0, fat: 15.0, carbs: 45.0),
          config: auto_types.AutoPlanConfig(
            user_id: "user-with-special-chars!@#",
            diet_principles: [auto_types.VerticalDiet],
            macro_targets: Macros(protein: 180.0, fat: 60.0, carbs: 250.0),
            recipe_count: 1,
            variety_factor: 0.7,
          ),
        )

      // Act
      let result = storage.save_auto_plan(conn, plan)

      // Assert
      result
      |> should.be_ok

      // Verify retrieval
      case storage.get_auto_plan(conn, "test-plan-special") {
        Ok(retrieved) -> {
          retrieved.config.user_id
          |> should.equal("user-with-special-chars!@#")
        }
        Error(_) -> should.fail()
      }

      cleanup_test_data(conn)
      pog.disconnect(conn)
    }
  }
}

pub fn save_recipe_source_null_config_test() {
  // Arrange
  case get_test_connection() {
    Error(_) -> Nil
    Ok(conn) -> {
      cleanup_test_data(conn)

      let source =
        auto_types.RecipeSource(
          id: "test-null-config",
          name: "Source with Null Config",
          source_type: auto_types.Database,
          config: None,
        )

      // Act
      let result = storage.save_recipe_source(conn, source)

      // Assert
      result
      |> should.be_ok

      // Verify retrieval handles None properly
      case storage.get_recipe_sources(conn) {
        Ok(sources) -> {
          let found =
            sources
            |> list.find(fn(s) { s.id == "test-null-config" })

          case found {
            Ok(retrieved) -> {
              case retrieved.config {
                None -> Nil
                Some(_) -> should.fail()
              }
            }
            Error(_) -> should.fail()
          }
        }
        Error(_) -> should.fail()
      }

      cleanup_test_data(conn)
      pog.disconnect(conn)
    }
  }
}

pub fn get_auto_plan_with_large_recipe_count_test() {
  // Arrange
  case get_test_connection() {
    Error(_) -> Nil
    Ok(conn) -> {
      cleanup_test_data(conn)

      // Create 10 recipes
      let recipes =
        list.range(1, 10)
        |> list.map(fn(i) {
          let id = "test-large-" <> string.inspect(i)
          build_test_recipe(id, "Recipe " <> string.inspect(i))
        })

      // Insert all recipes
      list.each(recipes, fn(r) { insert_test_recipe(conn, r) })

      let plan =
        auto_types.AutoMealPlan(
          id: "test-plan-large",
          recipes: recipes,
          generated_at: "2025-12-03T12:00:00Z",
          total_macros: Macros(protein: 300.0, fat: 150.0, carbs: 450.0),
          config: auto_types.AutoPlanConfig(
            user_id: "test-user",
            diet_principles: [auto_types.VerticalDiet],
            macro_targets: Macros(protein: 300.0, fat: 150.0, carbs: 450.0),
            recipe_count: 10,
            variety_factor: 0.7,
          ),
        )

      let _ = storage.save_auto_plan(conn, plan)

      // Act
      let result = storage.get_auto_plan(conn, "test-plan-large")

      // Assert
      case result {
        Ok(retrieved) -> {
          retrieved.recipes
          |> list.length
          |> should.equal(10)

          // Verify all recipes were retrieved
          let ids = list.map(retrieved.recipes, fn(r) { r.id })

          list.all(ids, fn(id) { string.starts_with(id, "test-large-") })
          |> should.be_true
        }
        Error(_) -> should.fail()
      }

      cleanup_test_data(conn)
      pog.disconnect(conn)
    }
  }
}
