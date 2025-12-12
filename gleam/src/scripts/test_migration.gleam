import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string

// Recipe for migration
pub type Recipe {
  Recipe(
    id: Int,
    slug: String,
    name: String,
    description: String,
    ingredient_count: Int,
  )
}

// Validate single recipe
fn validate_recipe(recipe: Recipe) -> Result(Nil, String) {
  let errors = []

  let errors = case string.is_empty(recipe.slug) {
    True -> ["empty slug", ..errors]
    False -> errors
  }

  let errors = case string.is_empty(recipe.name) {
    True -> ["empty name", ..errors]
    False -> errors
  }

  let errors = case recipe.ingredient_count <= 0 {
    True -> ["no ingredients", ..errors]
    False -> errors
  }

  case list.is_empty(errors) {
    True -> Ok(Nil)
    False ->
      Error(
        recipe.slug
        <> ": "
        <> string.join(errors, ", "),
      )
  }
}

// Test recipes
fn get_test_recipes() -> List(Recipe) {
  [
    Recipe(
      id: 1,
      slug: "chocolate-chip-cookies",
      name: "Chocolate Chip Cookies",
      description: "Classic homemade chocolate chip cookies",
      ingredient_count: 8,
    ),
    Recipe(
      id: 2,
      slug: "pasta-carbonara",
      name: "Pasta Carbonara",
      description: "Traditional Italian carbonara",
      ingredient_count: 5,
    ),
    Recipe(
      id: 3,
      slug: "chicken-stir-fry",
      name: "Chicken Stir Fry",
      description: "Quick and delicious stir fry",
      ingredient_count: 12,
    ),
    Recipe(
      id: 4,
      slug: "tomato-soup",
      name: "Tomato Soup",
      description: "Creamy homemade tomato soup",
      ingredient_count: 6,
    ),
    Recipe(
      id: 5,
      slug: "greek-salad",
      name: "Greek Salad",
      description: "Fresh Mediterranean salad",
      ingredient_count: 7,
    ),
  ]
}

pub fn main() {
  let recipes = get_test_recipes()

  io.println("=== Testing Tandoor Recipe Migration Dry-Run ===")
  io.println("")
  io.println("Total recipes found: " <> int.to_string(list.length(recipes)))
  io.println("")

  // Validate all recipes
  let validation_results =
    recipes
    |> list.map(fn(recipe) {
      #(recipe.slug, validate_recipe(recipe))
    })

  let successful = list.count(
    validation_results,
    fn(result) { result.1 |> result.is_ok },
  )
  let failed = list.count(
    validation_results,
    fn(result) { result.1 |> result.is_error },
  )

  io.println("Validation Results:")
  io.println("  Valid recipes: " <> int.to_string(successful))
  io.println("  Invalid recipes: " <> int.to_string(failed))
  io.println("")

  io.println("Recipe Details:")
  list.each(validation_results, fn(result) {
    let #(slug, validation) = result
    case validation {
      Ok(_) ->
        io.println("  [OK] " <> slug)
      Error(err) ->
        io.println("  [ERROR] " <> err)
    }
  })

  io.println("")
  io.println("=== Dry-Run Complete ===")
  io.println("All recipes validated. Ready for migration.")
}
