//// Recipe handlers for API endpoints

import gleam/float
import gleam/http
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import meal_planner/nutrition_constants
import meal_planner/storage
import meal_planner/types.{
  type Macros as MacrosType, type Recipe, Ingredient, Macros,
}
import pog
import wisp

/// Web context holding database connection
pub type Context {
  Context(db: pog.Connection)
}

/// GET /api/recipes - List all recipes
/// POST /api/recipes - Create new recipe
pub fn api_recipes(req: wisp.Request, ctx: Context) -> wisp.Response {
  case req.method {
    http.Get -> {
      let recipes = load_recipes(ctx)
      let json_data = json.array(recipes, recipe_to_json)
      wisp.json_response(json.to_string(json_data), 200)
    }
    http.Post -> create_recipe_handler(req, ctx)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

/// POST /api/recipes - Create new recipe
pub fn create_recipe_handler(req: wisp.Request, ctx: Context) -> wisp.Response {
  use form_data <- wisp.require_form(req)

  case parse_recipe_from_form(form_data.values) {
    Ok(recipe) -> {
      case storage.save_recipe(ctx.db, recipe) {
        Ok(_) -> {
          wisp.redirect("/recipes/" <> recipe.id)
        }
        Error(storage.DatabaseError(msg)) -> {
          let error_json =
            json.object([
              #("error", json.string("Failed to save recipe: " <> msg)),
            ])
          wisp.json_response(json.to_string(error_json), 500)
        }
        Error(storage.NotFound) -> {
          let error_json = json.object([#("error", json.string("Not found"))])
          wisp.json_response(json.to_string(error_json), 404)
        }
        Error(storage.InvalidInput(msg)) -> {
          let error_json =
            json.object([#("error", json.string("Invalid input: " <> msg))])
          wisp.json_response(json.to_string(error_json), 400)
        }
        Error(storage.Unauthorized(msg)) -> {
          let error_json =
            json.object([#("error", json.string("Unauthorized: " <> msg))])
          wisp.json_response(json.to_string(error_json), 401)
        }
      }
    }
    Error(errors) -> {
      let error_json =
        json.object([
          #("error", json.string("Validation failed")),
          #("details", json.array(errors, json.string)),
        ])
      wisp.json_response(json.to_string(error_json), 400)
    }
  }
}

/// GET /api/recipes/:id - Get recipe by ID
/// POST /api/recipes/:id with _method=PUT - Update recipe
/// POST /api/recipes/:id with _method=DELETE - Delete recipe
/// DELETE /api/recipes/:id - Delete recipe
pub fn api_recipe(req: wisp.Request, id: String, ctx: Context) -> wisp.Response {
  case req.method {
    http.Get -> {
      case load_recipe_by_id(ctx, id) {
        Ok(recipe) -> {
          let json_data = recipe_to_json(recipe)
          wisp.json_response(json.to_string(json_data), 200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    http.Post -> {
      // Handle both DELETE (_method=DELETE) and UPDATE (_method=PUT) via method override
      use form_data <- wisp.require_form(req)

      let method_override = list.key_find(form_data.values, "_method")

      case method_override {
        Ok("DELETE") -> {
          // Handle delete
          case storage.delete_recipe(ctx.db, id) {
            Ok(_) -> wisp.redirect("/recipes")
            Error(_) -> wisp.not_found()
          }
        }
        Ok("PUT") -> {
          // Handle update
          case parse_recipe_from_form(form_data.values) {
            Ok(recipe) -> {
              let updated_recipe = types.Recipe(..recipe, id: id)
              case storage.save_recipe(ctx.db, updated_recipe) {
                Ok(_) -> wisp.redirect("/recipes/" <> id)
                Error(storage.DatabaseError(msg)) -> {
                  let error_json =
                    json.object([
                      #(
                        "error",
                        json.string("Failed to update recipe: " <> msg),
                      ),
                    ])
                  wisp.json_response(json.to_string(error_json), 500)
                }
                Error(storage.NotFound) -> {
                  let error_json =
                    json.object([#("error", json.string("Recipe not found"))])
                  wisp.json_response(json.to_string(error_json), 404)
                }
                Error(storage.InvalidInput(msg)) -> {
                  let error_json =
                    json.object([
                      #("error", json.string("Invalid input: " <> msg)),
                    ])
                  wisp.json_response(json.to_string(error_json), 400)
                }
                Error(storage.Unauthorized(msg)) -> {
                  let error_json =
                    json.object([
                      #("error", json.string("Unauthorized: " <> msg)),
                    ])
                  wisp.json_response(json.to_string(error_json), 401)
                }
              }
            }
            Error(errors) -> {
              let error_json =
                json.object([
                  #("error", json.string("Validation failed")),
                  #("details", json.array(errors, json.string)),
                ])
              wisp.json_response(json.to_string(error_json), 400)
            }
          }
        }
        _ -> wisp.method_not_allowed([http.Get, http.Post])
      }
    }
    http.Delete -> {
      case storage.delete_recipe(ctx.db, id) {
        Ok(_) -> wisp.json_response("{\"success\": true}", 200)
        Error(_) -> wisp.not_found()
      }
    }
    _ -> wisp.method_not_allowed([http.Get, http.Post, http.Delete])
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Parse recipe from form data
pub fn parse_recipe_from_form(
  values: List(#(String, String)),
) -> Result(Recipe, List(String)) {
  // Extract basic fields
  let name = case list.key_find(values, "name") {
    Ok(n) if n != "" -> Ok(n)
    _ -> Error("Recipe name is required")
  }

  let category = case list.key_find(values, "category") {
    Ok(c) if c != "" -> Ok(c)
    _ -> Error("Category is required")
  }

  let servings = case list.key_find(values, "servings") {
    Ok(s) ->
      case int.parse(s) {
        Ok(num) if num > 0 -> Ok(num)
        _ -> Error("Servings must be a positive number")
      }
    _ -> Error("Servings is required")
  }

  // Extract macros
  let protein = case list.key_find(values, "protein") {
    Ok(p) ->
      case float.parse(p) {
        Ok(num) if num >=. 0.0 -> Ok(num)
        _ -> Error("Protein must be a non-negative number")
      }
    _ -> Error("Protein is required")
  }

  let fat = case list.key_find(values, "fat") {
    Ok(f) ->
      case float.parse(f) {
        Ok(num) if num >=. 0.0 -> Ok(num)
        _ -> Error("Fat must be a non-negative number")
      }
    _ -> Error("Fat is required")
  }

  let carbs = case list.key_find(values, "carbs") {
    Ok(c) ->
      case float.parse(c) {
        Ok(num) if num >=. 0.0 -> Ok(num)
        _ -> Error("Carbs must be a non-negative number")
      }
    _ -> Error("Carbs is required")
  }

  // Extract FODMAP level
  let fodmap_level = case list.key_find(values, "fodmap_level") {
    Ok("low") -> Ok(types.Low)
    Ok("medium") -> Ok(types.Medium)
    Ok("high") -> Ok(types.High)
    _ -> Error("FODMAP level must be 'low', 'medium', or 'high'")
  }

  // Extract vertical_compliant (checkbox)
  let vertical_compliant = case list.key_find(values, "vertical_compliant") {
    Ok("true") -> True
    _ -> False
  }

  // Extract ingredients (dynamic fields)
  let ingredients = extract_ingredients(values)
  let ingredients_result = case ingredients {
    [] -> Error("At least one ingredient is required")
    _ -> Ok(ingredients)
  }

  // Extract instructions (dynamic fields)
  let instructions = extract_instructions(values)
  let instructions_result = case instructions {
    [] -> Error("At least one instruction is required")
    _ -> Ok(instructions)
  }

  // Collect all errors
  let all_errors =
    []
    |> add_error(name)
    |> add_error(category)
    |> add_error(servings)
    |> add_error(protein)
    |> add_error(fat)
    |> add_error(carbs)
    |> add_error(fodmap_level)
    |> add_error(ingredients_result)
    |> add_error(instructions_result)

  case all_errors {
    [] -> {
      // All validations passed, create Recipe
      let assert Ok(name_val) = name
      let assert Ok(category_val) = category
      let assert Ok(servings_val) = servings
      let assert Ok(protein_val) = protein
      let assert Ok(fat_val) = fat
      let assert Ok(carbs_val) = carbs
      let assert Ok(fodmap_val) = fodmap_level
      let assert Ok(ingredients_val) = ingredients_result
      let assert Ok(instructions_val) = instructions_result

      let recipe =
        types.Recipe(
          id: generate_recipe_id(name_val),
          name: name_val,
          ingredients: ingredients_val,
          instructions: instructions_val,
          macros: types.Macros(
            protein: protein_val,
            fat: fat_val,
            carbs: carbs_val,
          ),
          servings: servings_val,
          category: category_val,
          fodmap_level: fodmap_val,
          vertical_compliant: vertical_compliant,
        )

      Ok(recipe)
    }
    errs -> Error(errs)
  }
}

fn add_error(errors: List(String), result: Result(a, String)) -> List(String) {
  case result {
    Ok(_) -> errors
    Error(msg) -> [msg, ..errors]
  }
}

fn extract_ingredients(
  values: List(#(String, String)),
) -> List(types.Ingredient) {
  let ingredient_pairs =
    list.filter_map(values, fn(pair) {
      let #(key, _) = pair
      case string.starts_with(key, "ingredient_name_") {
        True -> {
          let index = string.replace(key, "ingredient_name_", "")
          Ok(index)
        }
        False -> Error(Nil)
      }
    })

  list.filter_map(ingredient_pairs, fn(index) {
    let name_key = "ingredient_name_" <> index
    let quantity_key = "ingredient_quantity_" <> index

    let name = list.key_find(values, name_key) |> result.unwrap("")
    let quantity = list.key_find(values, quantity_key) |> result.unwrap("")

    case name != "" && quantity != "" {
      True -> Ok(types.Ingredient(name: name, quantity: quantity))
      False -> Error(Nil)
    }
  })
}

fn extract_instructions(values: List(#(String, String))) -> List(String) {
  let instruction_indices =
    list.filter_map(values, fn(pair) {
      let #(key, _) = pair
      case string.starts_with(key, "instruction_") {
        True -> {
          let index = string.replace(key, "instruction_", "")
          Ok(index)
        }
        False -> Error(Nil)
      }
    })

  list.filter_map(instruction_indices, fn(index) {
    let key = "instruction_" <> index
    case list.key_find(values, key) {
      Ok(instruction) -> {
        case instruction != "" {
          True -> Ok(instruction)
          False -> Error(Nil)
        }
      }
      Error(_) -> Error(Nil)
    }
  })
}

pub fn generate_recipe_id(name: String) -> String {
  let normalized =
    name
    |> string.lowercase
    |> string.replace(" ", "-")
    |> string.replace("'", "")
    |> string.replace("\"", "")

  // Add timestamp to ensure uniqueness
  let timestamp = get_timestamp_string()
  normalized <> "-" <> timestamp
}

@external(erlang, "erlang", "system_time")
fn system_time(unit: Int) -> Int

fn get_timestamp_string() -> String {
  // Get milliseconds since epoch
  let millis = system_time(1000)
  // Take last 6 digits to keep ID shorter
  let short_id = millis % 1_000_000
  int.to_string(short_id)
}

/// Load all recipes from storage
fn load_recipes(ctx: Context) -> List(Recipe) {
  case storage.get_all_recipes(ctx.db) {
    Ok([]) -> []
    Ok(recipes) -> recipes
    Error(_) -> []
  }
}

/// Load recipe by ID
fn load_recipe_by_id(ctx: Context, id: String) -> Result(Recipe, Nil) {
  case storage.get_recipe_by_id(ctx.db, id) {
    Ok(recipe) -> Ok(recipe)
    Error(_) -> Error(Nil)
  }
}

/// Convert recipe to JSON
fn recipe_to_json(r: Recipe) -> json.Json {
  json.object([
    #("id", json.string(r.id)),
    #("name", json.string(r.name)),
    #(
      "ingredients",
      json.array(r.ingredients, fn(i) {
        json.object([
          #("name", json.string(i.name)),
          #("quantity", json.string(i.quantity)),
        ])
      }),
    ),
    #("instructions", json.array(r.instructions, json.string)),
    #("macros", macros_to_json(r.macros)),
    #("servings", json.int(r.servings)),
    #("category", json.string(r.category)),
  ])
}

fn macros_to_json(m: MacrosType) -> json.Json {
  json.object([
    #("protein", json.float(m.protein)),
    #("fat", json.float(m.fat)),
    #("carbs", json.float(m.carbs)),
    #("calories", json.float(types.macros_calories(m))),
  ])
}
