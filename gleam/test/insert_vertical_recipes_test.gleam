/// Test to insert Vertical Diet recipes into the database
/// Run with: gleam test --target erlang --module insert_vertical_recipes_test

import gleeunit
import gleeunit/should
import gleam/io
import gleam/list
import gleam/int
import meal_planner/storage
import meal_planner/vertical_diet_recipes

pub fn main() {
  gleeunit.main()
}

/// Insert all Vertical Diet recipes into the database
pub fn insert_all_vertical_diet_recipes_test() {
  io.println("\n🥩 Vertical Diet Recipe Importer")
  io.println("================================\n")

  let config = storage.default_config()

  case storage.start_pool(config) {
    Error(e) -> {
      io.println("❌ Failed to connect to database:")
      io.println(e)
      should.fail()
    }

    Ok(conn) -> {
      io.println("✅ Connected to database\n")

      let recipes = vertical_diet_recipes.all_recipes()
      let total = list.length(recipes)

      io.println("📝 Found " <> int.to_string(total) <> " Vertical Diet recipes")
      io.println("🔄 Inserting recipes...\n")

      // Insert each recipe and track results
      let results =
        list.map(recipes, fn(recipe) {
          case storage.save_recipe(conn, recipe) {
            Ok(_) -> {
              io.println("  ✓ " <> recipe.name)
              Ok(Nil)
            }
            Error(storage.DatabaseError(msg)) -> {
              io.println("  ✗ " <> recipe.name <> " - Error: " <> msg)
              Error(Nil)
            }
            Error(storage.NotFound) -> {
              io.println("  ✗ " <> recipe.name <> " - Not found error")
              Error(Nil)
            }
            Error(storage.InvalidInput(msg)) -> {
              io.println("  ✗ " <> recipe.name <> " - Invalid input: " <> msg)
              Error(Nil)
            }
            Error(storage.Unauthorized(msg)) -> {
              io.println("  ✗ " <> recipe.name <> " - Unauthorized: " <> msg)
              Error(Nil)
            }
          }
        })

      // Count successes
      let successes =
        results
        |> list.filter(fn(r) {
          case r {
            Ok(_) -> True
            Error(_) -> False
          }
        })
        |> list.length()

      io.println("\n================================")
      io.println(
        "✅ Successfully inserted "
        <> int.to_string(successes)
        <> "/"
        <> int.to_string(total)
        <> " recipes",
      )

      // Verify by reading back from database
      io.println("\n🔍 Verifying insertions...")

      let beef_count = case storage.get_recipes_by_category(conn, "beef-main") {
        Ok(r) -> list.length(r)
        Error(_) -> 0
      }

      let bison_count = case storage.get_recipes_by_category(conn, "bison-main")
      {
        Ok(r) -> list.length(r)
        Error(_) -> 0
      }

      let lamb_count = case storage.get_recipes_by_category(conn, "lamb-main") {
        Ok(r) -> list.length(r)
        Error(_) -> 0
      }

      let rice_count = case storage.get_recipes_by_category(conn, "rice-side") {
        Ok(r) -> list.length(r)
        Error(_) -> 0
      }

      let veg_count =
        case storage.get_recipes_by_category(conn, "vegetable-side") {
          Ok(r) -> list.length(r)
          Error(_) -> 0
        }

      io.println("\n📊 Recipe breakdown:")
      io.println("  🥩 Beef mains: " <> int.to_string(beef_count))
      io.println("  🦬 Bison mains: " <> int.to_string(bison_count))
      io.println("  🐑 Lamb mains: " <> int.to_string(lamb_count))
      io.println("  🍚 Rice sides: " <> int.to_string(rice_count))
      io.println("  🥕 Vegetable sides: " <> int.to_string(veg_count))

      io.println("\n✨ All recipes are:")
      io.println("  • Low FODMAP")
      io.println("  • Vertical Diet compliant")
      io.println("  • Easy to digest")
      io.println("  • Micronutrient-dense\n")

      // Assert all inserted successfully
      successes |> should.equal(total)

      // Assert correct category counts
      beef_count |> should.equal(9)
      bison_count |> should.equal(2)
      lamb_count |> should.equal(2)
      rice_count |> should.equal(6)
      veg_count |> should.equal(7)
    }
  }
}
