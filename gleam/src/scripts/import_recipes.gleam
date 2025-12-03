/// Import recipes from YAML files into PostgreSQL database
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import meal_planner/recipe_loader
import meal_planner/storage
import pog
import simplifile

pub fn main() {
  io.println("🍳 Starting recipe import...")
  io.println("")

  // Connect to database
  let config = storage.default_config()
  case storage.start_pool(config) {
    Error(e) -> {
      io.println("✗ Failed to connect to database: " <> e)
      io.println("  Make sure PostgreSQL is running and database exists")
      io.println("  Run: ./scripts/start-postgres.sh")
    }
    Ok(conn) -> {
      io.println("✓ Connected to database")

      // List of recipe files to import
      let recipe_files = [
        "../recipes/beef.yaml",
        "../recipes/chicken.yaml",
        "../recipes/mexican.yaml",
        "../recipes/pork.yaml",
        "../recipes/seafood.yaml",
        "../recipes/turkey.yaml",
        "../recipes/vertical-beef.yaml",
        "../recipes/vertical-breakfast.yaml",
        "../recipes/vertical-rice.yaml",
        "../recipes/vertical-sides.yaml",
      ]

      // Import each file
      let results =
        list.map(recipe_files, fn(file) { import_recipe_file(conn, file) })

      // Count successes and failures
      let successes = list.filter(results, fn(r) { result.is_ok(r) })  |> list.length
      let failures = list.filter(results, fn(r) { result.is_error(r) }) |> list.length

      io.println("")
      io.println("📊 Import Summary:")
      io.println("  ✓ Successful: " <> string.inspect(successes))
      io.println("  ✗ Failed: " <> string.inspect(failures))

      case failures {
        0 -> {
          io.println("")
          io.println("🎉 All recipes imported successfully!")
        }
        _ -> {
          io.println("")
          io.println("⚠ Some imports failed - see errors above")
        }
      }
    }
  }
}

/// Import recipes from a single YAML file
fn import_recipe_file(
  conn: pog.Connection,
  file_path: String,
) -> Result(Int, String) {
  io.print("  " <> file_path <> " ... ")

  // Read file
  use content <- result.try(
    simplifile.read(file_path)
    |> result.map_error(fn(_) { "Failed to read file" }),
  )

  // Parse YAML
  use recipes <- result.try(recipe_loader.parse_yaml(content))

  // Import each recipe
  let import_results =
    list.map(recipes, fn(recipe) { storage.save_recipe(conn, recipe) })

  // Count successes
  let success_count =
    list.filter(import_results, fn(r) { result.is_ok(r) })
    |> list.length

  let total_count = list.length(recipes)

  case success_count == total_count {
    True -> {
      io.println(
        "✓ "
        <> string.inspect(success_count)
        <> " recipe"
        <> case success_count {
          1 -> ""
          _ -> "s"
        },
      )
      Ok(success_count)
    }
    False -> {
      let failed = total_count - success_count
      io.println(
        "⚠ "
        <> string.inspect(success_count)
        <> "/"
        <> string.inspect(total_count)
        <> " ("
        <> string.inspect(failed)
        <> " failed)",
      )
      Error(
        "Failed to import "
        <> string.inspect(failed)
        <> " recipe"
        <> case failed {
          1 -> ""
          _ -> "s"
        },
      )
    }
  }
}
