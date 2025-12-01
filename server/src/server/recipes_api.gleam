//// Recipe CRUD API endpoints

import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/list
import gleam/string
import wisp

import server/storage
import shared/types

// ============================================================================
// Recipe API Handlers
// ============================================================================

/// Handle /api/recipes endpoint (GET list, POST create)
pub fn handle_recipes_list(req: wisp.Request) -> wisp.Response {
  case req.method {
    // GET /api/recipes - List all recipes
    http.Get -> list_recipes()

    // POST /api/recipes - Create new recipe
    http.Post -> create_recipe(req)

    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

/// Handle /api/recipes/:id endpoint (GET detail, PUT update, DELETE remove)
pub fn handle_recipe_detail(req: wisp.Request, id: String) -> wisp.Response {
  case req.method {
    // GET /api/recipes/:id - Get recipe by ID
    http.Get -> get_recipe(id)

    // PUT /api/recipes/:id - Update recipe
    http.Put -> update_recipe(req, id)

    // DELETE /api/recipes/:id - Delete recipe
    http.Delete -> delete_recipe(id)

    _ -> wisp.method_not_allowed([http.Get, http.Put, http.Delete])
  }
}

// ============================================================================
// CRUD Operations
// ============================================================================

fn list_recipes() -> wisp.Response {
  storage.with_connection(storage.db_path, fn(conn) {
    case storage.get_all_recipes(conn) {
      Ok(recipes) -> {
        let json_data = json.array(recipes, types.recipe_to_json)
        wisp.json_response(json.to_string(json_data), 200)
      }
      Error(storage.DatabaseError(msg)) -> {
        error_response(msg, 500)
      }
      Error(storage.NotFound) -> {
        let empty = json.array([], types.recipe_to_json)
        wisp.json_response(json.to_string(empty), 200)
      }
    }
  })
}

fn get_recipe(id: String) -> wisp.Response {
  storage.with_connection(storage.db_path, fn(conn) {
    case storage.get_recipe_by_id(conn, id) {
      Ok(recipe) -> {
        let json_data = types.recipe_to_json(recipe)
        wisp.json_response(json.to_string(json_data), 200)
      }
      Error(storage.NotFound) -> wisp.not_found()
      Error(storage.DatabaseError(msg)) -> {
        error_response(msg, 500)
      }
    }
  })
}

fn create_recipe(req: wisp.Request) -> wisp.Response {
  use json_body <- wisp.require_json(req)

  case decode.run(json_body, types.recipe_decoder()) {
    Ok(recipe) -> {
      case validate_recipe(recipe) {
        Ok(_) -> {
          storage.with_connection(storage.db_path, fn(conn) {
            case storage.save_recipe(conn, recipe) {
              Ok(_) -> {
                let json_data = types.recipe_to_json(recipe)
                wisp.json_response(json.to_string(json_data), 201)
              }
              Error(storage.DatabaseError(msg)) -> {
                error_response(msg, 500)
              }
              Error(_) -> {
                error_response("Failed to save recipe", 500)
              }
            }
          })
        }
        Error(msg) -> {
          error_response(msg, 400)
        }
      }
    }
    Error(_) -> {
      error_response("Invalid recipe data", 400)
    }
  }
}

fn update_recipe(req: wisp.Request, id: String) -> wisp.Response {
  use json_body <- wisp.require_json(req)

  case decode.run(json_body, types.recipe_decoder()) {
    Ok(recipe) -> {
      // Ensure the ID in the URL matches the ID in the body
      case recipe.id == id {
        True -> {
          case validate_recipe(recipe) {
            Ok(_) -> {
              storage.with_connection(storage.db_path, fn(conn) {
                // Check if recipe exists before updating
                case storage.get_recipe_by_id(conn, id) {
                  Ok(_) -> {
                    case storage.save_recipe(conn, recipe) {
                      Ok(_) -> {
                        let json_data = types.recipe_to_json(recipe)
                        wisp.json_response(json.to_string(json_data), 200)
                      }
                      Error(storage.DatabaseError(msg)) -> {
                        error_response(msg, 500)
                      }
                      Error(_) -> {
                        error_response("Failed to update recipe", 500)
                      }
                    }
                  }
                  Error(storage.NotFound) -> wisp.not_found()
                  Error(storage.DatabaseError(msg)) -> {
                    error_response(msg, 500)
                  }
                }
              })
            }
            Error(msg) -> {
              error_response(msg, 400)
            }
          }
        }
        False -> {
          error_response("Recipe ID mismatch", 400)
        }
      }
    }
    Error(_) -> {
      error_response("Invalid recipe data", 400)
    }
  }
}

fn delete_recipe(id: String) -> wisp.Response {
  storage.with_connection(storage.db_path, fn(conn) {
    // Check if recipe exists before deleting
    case storage.get_recipe_by_id(conn, id) {
      Ok(_) -> {
        case storage.delete_recipe(conn, id) {
          Ok(_) -> {
            let success =
              json.object([
                #("message", json.string("Recipe deleted successfully")),
              ])
            wisp.json_response(json.to_string(success), 200)
          }
          Error(storage.DatabaseError(msg)) -> {
            error_response(msg, 500)
          }
          Error(_) -> {
            error_response("Failed to delete recipe", 500)
          }
        }
      }
      Error(storage.NotFound) -> wisp.not_found()
      Error(storage.DatabaseError(msg)) -> {
        error_response(msg, 500)
      }
    }
  })
}

// ============================================================================
// Validation
// ============================================================================

/// Validate recipe data before saving
fn validate_recipe(recipe: types.Recipe) -> Result(Nil, String) {
  // Check required fields
  case string.trim(recipe.id) {
    "" -> Error("Recipe ID is required")
    _ ->
      case string.trim(recipe.name) {
        "" -> Error("Recipe name is required")
        _ ->
          case list.is_empty(recipe.ingredients) {
            True -> Error("At least one ingredient is required")
            False ->
              case list.is_empty(recipe.instructions) {
                True -> Error("At least one instruction is required")
                False ->
                  case recipe.servings < 1 {
                    True -> Error("Servings must be at least 1")
                    False -> validate_macros(recipe.macros)
                  }
              }
          }
      }
  }
}

fn validate_macros(macros: types.Macros) -> Result(Nil, String) {
  case macros.protein <. 0.0 {
    True -> Error("Protein cannot be negative")
    False ->
      case macros.fat <. 0.0 {
        True -> Error("Fat cannot be negative")
        False ->
          case macros.carbs <. 0.0 {
            True -> Error("Carbs cannot be negative")
            False -> Ok(Nil)
          }
      }
  }
}

// ============================================================================
// Helpers
// ============================================================================

fn error_response(message: String, status: Int) -> wisp.Response {
  let error = json.object([#("error", json.string(message))])
  wisp.json_response(json.to_string(error), status)
}
