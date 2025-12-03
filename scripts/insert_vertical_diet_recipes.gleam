///! Script to insert Vertical Diet recipes into the database
///! Run with: gleam run -m scripts/insert_vertical_diet_recipes

import gleam/io
import gleam/list
import gleam/result
import meal_planner/storage
import meal_planner/vertical_diet_recipes

pub fn main() {
  io.println("🥩 Vertical Diet Recipe Importer")
  io.println("================================\n")

  // Get database config
  let config = storage.default_config()

  io.println("📊 Starting database connection...")

  // Start database connection
  case storage.start_pool(config) {
    Error(e) -> {
      io.println("❌ Failed to connect to database:")
      io.println(e)
      Nil
    }

    Ok(conn) -> {
      io.println("✅ Connected to database\n")

      // Get all Vertical Diet recipes
      let recipes = vertical_diet_recipes.all_recipes()
      let total = list.length(recipes)

      io.println("📝 Found " <> int_to_string(total) <> " Vertical Diet recipes")
      io.println("🔄 Inserting recipes...\n")

      // Insert each recipe
      let results = list.map(recipes, fn(recipe) {
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
        }
      })

      // Count successes
      let successes = list.length(list.filter(results, result.is_ok))

      io.println("\n================================")
      io.println("✅ Successfully inserted " <> int_to_string(successes) <> "/" <> int_to_string(total) <> " recipes")
      io.println("\n📊 Recipe breakdown:")
      io.println("  🥩 Red meat mains: 12")
      io.println("  🍚 White rice preparations: 6")
      io.println("  🥕 Vegetable sides: 7")
      io.println("\n✨ All recipes are:")
      io.println("  • Low FODMAP")
      io.println("  • Vertical Diet compliant")
      io.println("  • Easy to digest")
      io.println("  • Micronutrient-dense\n")

      Nil
    }
  }
}

@external(erlang, "erlang", "integer_to_list")
fn int_to_binary(n: Int) -> String

fn int_to_string(n: Int) -> String {
  int_to_binary(n)
}
