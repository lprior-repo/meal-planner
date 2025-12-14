/// Test script to verify Tandoor API connection with session auth
/// Run with: gleam run -m scripts/test_tandoor
import dot_env
import envoy
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import meal_planner/tandoor/client as tandoor

pub fn main() {
  dot_env.new()
  |> dot_env.set_path("../.env")
  |> dot_env.set_debug(False)
  |> dot_env.load

  io.println("Testing Tandoor API Connection (Session Auth)...")
  io.println("")

  let base_url = result.unwrap(envoy.get("TANDOOR_URL"), "http://localhost:8000")
  let username = result.unwrap(envoy.get("TANDOOR_USERNAME"), "admin")
  let password = result.unwrap(envoy.get("TANDOOR_PASSWORD"), "")

  case string.is_empty(password) {
    True -> {
      io.println("Tandoor not configured")
      io.println("Set TANDOOR_URL, TANDOOR_USERNAME, and TANDOOR_PASSWORD in .env")
      io.println("")
      io.println("Example .env entries:")
      io.println("  TANDOOR_URL=http://localhost:8000")
      io.println("  TANDOOR_USERNAME=admin")
      io.println("  TANDOOR_PASSWORD=your_password")
    }
    False -> {
      io.println("Configuration:")
      io.println("  URL: " <> base_url)
      io.println("  Username: " <> username)
      io.println("")

      let config = tandoor.session_config(base_url, username, password)

      io.println("Step 1: Testing login...")
      test_login(config)
    }
  }
}

fn test_login(config: tandoor.ClientConfig) {
  case tandoor.login(config) {
    Ok(auth_config) -> {
      io.println("  ✓ Login successful!")
      io.println("")

      io.println("Step 2: Testing recipe list...")
      test_recipes(auth_config)

      io.println("")
      io.println("Step 4: Testing meal plan...")
      test_meal_plan(auth_config)

      io.println("")
      io.println("✓ All Tandoor API tests passed!")
    }
    Error(e) -> {
      io.println("  ✗ Login failed: " <> tandoor.error_to_string(e))
    }
  }
}

fn test_recipes(config: tandoor.ClientConfig) {
  case tandoor.get_recipes(config, Some(10), None) {
    Ok(response) -> {
      io.println(
        "  ✓ Found "
        <> string.inspect(response.count)
        <> " recipes",
      )
      case response.results {
        [first, ..] -> {
          io.println("    First recipe: " <> first.name)
          io.println("")
          io.println("Step 3: Testing recipe detail (with ingredients, steps, nutrition)...")
          test_recipe_detail(config, first.id)
        }
        [] -> {
          io.println("    (No recipes yet)")
        }
      }
    }
    Error(e) -> {
      io.println("  ✗ Failed to fetch recipes: " <> tandoor.error_to_string(e))
    }
  }
}

fn test_recipe_detail(config: tandoor.ClientConfig, recipe_id: Int) {
  case tandoor.get_recipe_detail(config, recipe_id) {
    Ok(detail) -> {
      io.println("  ✓ Recipe: " <> detail.name)
      io.println("    Servings: " <> int.to_string(detail.servings))

      let step_count = list.length(detail.steps)
      io.println("    Steps: " <> int.to_string(step_count))

      let ingredient_count =
        detail.steps
        |> list.flat_map(fn(step) { step.ingredients })
        |> list.length
      io.println("    Total ingredients: " <> int.to_string(ingredient_count))

      case detail.nutrition {
        Some(nutrition) -> {
          io.println("    Nutrition (per serving):")
          io.println("      Calories: " <> float.to_string(nutrition.calories))
          io.println("      Protein: " <> float.to_string(nutrition.proteins) <> "g")
          io.println("      Carbs: " <> float.to_string(nutrition.carbohydrates) <> "g")
          io.println("      Fat: " <> float.to_string(nutrition.fats) <> "g")
        }
        None -> {
          io.println("    Nutrition: (not set)")
        }
      }

      case detail.steps {
        [step, ..] -> {
          io.println("    First step preview:")
          let instruction_preview = case string.length(step.instruction) > 80 {
            True -> string.slice(step.instruction, 0, 80) <> "..."
            False -> step.instruction
          }
          io.println("      \"" <> instruction_preview <> "\"")

          case step.ingredients {
            [ing, ..] -> {
              let food_name = case ing.food {
                Some(f) -> f.name
                None -> "(no food)"
              }
              let unit_name = case ing.unit {
                Some(u) -> u.name
                None -> ""
              }
              io.println("      First ingredient: "
                <> float.to_string(ing.amount) <> " "
                <> unit_name <> " "
                <> food_name)
            }
            [] -> Nil
          }
        }
        [] -> Nil
      }
    }
    Error(e) -> {
      io.println("  ✗ Failed to fetch recipe detail: " <> tandoor.error_to_string(e))
    }
  }
}

fn test_meal_plan(config: tandoor.ClientConfig) {
  case tandoor.get_meal_plan(config, None, None) {
    Ok(response) -> {
      io.println(
        "  ✓ Found "
        <> string.inspect(response.count)
        <> " meal plan entries",
      )
    }
    Error(e) -> {
      io.println(
        "  ✗ Failed to fetch meal plan: " <> tandoor.error_to_string(e),
      )
    }
  }
}
