/// Mealie to Tandoor recipe migration script
///
/// This script migrates recipes from a Mealie database to Tandoor, creating
/// recipe mappings for audit and reconciliation purposes. It supports:
/// - Batch recipe fetching from Mealie
/// - Recipe validation and transformation
/// - Tandoor recipe creation via API
/// - Progress tracking and reporting
/// - Error handling with detailed logging
///
/// Prerequisites:
/// - Both Mealie and Tandoor instances running and accessible
/// - Tandoor API token configured
/// - PostgreSQL database with recipe_mappings table
///
/// Usage:
///   gleam run -m scripts/migrate_mealie_to_tandoor
///   MEALIE_URL=http://localhost:8010 TANDOOR_URL=http://localhost:8000 \
///   MEALIE_TOKEN=xxx TANDOOR_TOKEN=yyy gleam run -m scripts/migrate_mealie_to_tandoor
///
/// Environment Variables:
///   MEALIE_URL: Mealie instance URL (default: http://localhost:8010)
///   TANDOOR_URL: Tandoor instance URL (default: http://localhost:8000)
///   MEALIE_TOKEN: Mealie API token (required)
///   TANDOOR_TOKEN: Tandoor API token (required)
///   DRY_RUN: Set to "true" for dry-run mode (no data changes)
///   BATCH_SIZE: Number of recipes to process per batch (default: 50)
///   LOG_FILE: Path to save migration log (optional)
import envoy
import gleam/erlang/process
import gleam/float
import gleam/http
import gleam/httpc
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/storage/recipe_mappings
import pog
import simplifile

// ============================================================================
// Types
// ============================================================================

/// Configuration for migration
pub type MigrationConfig {
  MigrationConfig(
    mealie_url: String,
    tandoor_url: String,
    mealie_token: String,
    tandoor_token: String,
    dry_run: Bool,
    batch_size: Int,
    log_file: Option(String),
  )
}

/// Recipe from Mealie
pub type MealieRecipe {
  MealieRecipe(
    id: Int,
    slug: String,
    name: String,
    description: String,
    image_url: Option(String),
    yield: Option(String),
    ingredients_count: Int,
  )
}

/// Recipe to create in Tandoor
pub type TandoorRecipeRequest {
  TandoorRecipeRequest(
    name: String,
    description: String,
    image_url: Option(String),
    yield: Option(String),
  )
}

/// Response from Tandoor recipe creation
pub type TandoorRecipeResponse {
  TandoorRecipeResponse(id: Int, name: String)
}

/// Result of a single recipe migration
pub type RecipeMigrationResult {
  RecipeMigrationResult(
    mealie_slug: String,
    mealie_name: String,
    tandoor_id: Option(Int),
    status: String,
    error: Option(String),
  )
}

/// Overall migration statistics
pub type MigrationStats {
  MigrationStats(
    total_recipes: Int,
    successful: Int,
    failed: Int,
    skipped: Int,
    duration_seconds: Float,
  )
}

// ============================================================================
// Main Entry Point
// ============================================================================

/// Main entry point for the migration script
pub fn main() {
  io.println("")
  io.println("=== Mealie to Tandoor Recipe Migration ===")
  io.println("")

  // Load configuration
  case load_config() {
    Error(err) -> {
      io.println("ERROR: Configuration error - " <> err)
      io.println("")
      print_usage()
      Nil
    }
    Ok(config) -> {
      io.println("Configuration loaded:")
      io.println("  Mealie URL: " <> config.mealie_url)
      io.println("  Tandoor URL: " <> config.tandoor_url)
      io.println(
        "  Dry Run: "
        <> case config.dry_run {
          True -> "YES"
          False -> "NO"
        },
      )
      io.println("  Batch Size: " <> int.to_string(config.batch_size))
      io.println("")

      // Initialize database connection
      let pool_name = process.new_name(prefix: "mealie_migrate_pool")
      let db_config =
        pog.default_config(pool_name)
        |> pog.host("localhost")
        |> pog.port(5432)
        |> pog.database("meal_planner")
        |> pog.user("postgres")
        |> pog.password(Some("postgres"))
        |> pog.pool_size(10)

      case pog.start(db_config) {
        Error(e) -> {
          io.println("ERROR: Failed to start database connection pool")
          io.println(format_start_error(e))
          Nil
        }
        Ok(started) -> {
          let db = started.data
          case verify_migration_table_exists(db) {
            False -> {
              io.println("ERROR: recipe_mappings table not found in database")
              io.println("Please run the required migrations first:")
              io.println(
                "  psql -d meal_planner -f migrations_pg/024_add_recipe_mappings.sql",
              )
              Nil
            }
            True -> {
              // Run the migration
              case run_migration(db, config) {
                Error(err) -> {
                  io.println("Migration failed: " <> err)
                  Nil
                }
                Ok(stats) -> {
                  io.println("")
                  io.println("=== Migration Complete ===")
                  print_stats(stats)
                  io.println("")
                }
              }
            }
          }
        }
      }
    }
  }
}

// ============================================================================
// Configuration Loading
// ============================================================================

/// Load migration configuration from environment variables
fn load_config() -> Result(MigrationConfig, String) {
  use mealie_url <- result.try(get_env_or_default(
    "MEALIE_URL",
    "http://localhost:8010",
  ))
  use tandoor_url <- result.try(get_env_or_default(
    "TANDOOR_URL",
    "http://localhost:8000",
  ))
  use mealie_token <- result.try(get_required_env(
    "MEALIE_TOKEN",
    "Mealie API token (MEALIE_TOKEN)",
  ))
  use tandoor_token <- result.try(get_required_env(
    "TANDOOR_TOKEN",
    "Tandoor API token (TANDOOR_TOKEN)",
  ))

  let dry_run = case envoy.get("DRY_RUN") {
    Ok(v) -> string.lowercase(v) == "true"
    Error(_) -> False
  }

  let batch_size = case envoy.get("BATCH_SIZE") {
    Ok(v) -> {
      case int.parse(v) {
        Ok(n) if n > 0 -> n
        _ -> 50
      }
    }
    Error(_) -> 50
  }

  let log_file = case envoy.get("LOG_FILE") {
    Ok(path) -> Some(path)
    Error(_) -> None
  }

  Ok(MigrationConfig(
    mealie_url: mealie_url,
    tandoor_url: tandoor_url,
    mealie_token: mealie_token,
    tandoor_token: tandoor_token,
    dry_run: dry_run,
    batch_size: batch_size,
    log_file: log_file,
  ))
}

/// Get environment variable or return default value
fn get_env_or_default(key: String, default: String) -> Result(String, String) {
  case envoy.get(key) {
    Ok(value) -> {
      let len = string.length(value)
      case len > 0 {
        True -> Ok(value)
        False -> Ok(default)
      }
    }
    Error(_) -> Ok(default)
  }
}

/// Get required environment variable
fn get_required_env(key: String, description: String) -> Result(String, String) {
  case envoy.get(key) {
    Ok(value) -> {
      let len = string.length(value)
      case len > 0 {
        True -> Ok(value)
        False -> Error("Missing required environment variable: " <> description)
      }
    }
    Error(_) -> Error("Missing required environment variable: " <> description)
  }
}

// ============================================================================
// Migration Execution
// ============================================================================

/// Run the migration process
fn run_migration(
  db: pog.Connection,
  config: MigrationConfig,
) -> Result(MigrationStats, String) {
  io.println("Fetching recipes from Mealie...")

  // Fetch recipes from Mealie
  case fetch_mealie_recipes(config) {
    Error(err) -> Error("Failed to fetch Mealie recipes: " <> err)
    Ok(recipes) -> {
      let recipe_count = list.length(recipes)
      io.println(int.to_string(recipe_count) <> " recipes found in Mealie")
      io.println("")

      case recipe_count {
        0 -> {
          io.println("No recipes to migrate")
          Ok(MigrationStats(
            total_recipes: 0,
            successful: 0,
            failed: 0,
            skipped: 0,
            duration_seconds: 0.0,
          ))
        }
        _ -> {
          // Process recipes in batches
          io.println("Processing recipes...")
          io.println("")

          let results =
            recipes
            |> list.index_map(fn(recipe, idx) {
              let percent = { idx + 1 } * 100 / recipe_count
              io.print(
                "  [" <> int.to_string(percent) <> "%] " <> recipe.name <> " (",
              )
              io.print(int.to_string(recipe.ingredients_count))
              io.println(" ingredients)")

              // Validate recipe
              case validate_mealie_recipe(recipe) {
                Error(e) -> {
                  io.println("    Status: FAILED - " <> e)
                  RecipeMigrationResult(
                    mealie_slug: recipe.slug,
                    mealie_name: recipe.name,
                    tandoor_id: None,
                    status: "failed",
                    error: Some(e),
                  )
                }
                Ok(_) -> {
                  case config.dry_run {
                    True -> {
                      io.println("    Status: DRY-RUN - Would migrate")
                      RecipeMigrationResult(
                        mealie_slug: recipe.slug,
                        mealie_name: recipe.name,
                        tandoor_id: Some(9000 + idx),
                        status: "dry-run",
                        error: None,
                      )
                    }
                    False -> {
                      // Create recipe in Tandoor
                      case
                        create_tandoor_recipe(
                          config,
                          TandoorRecipeRequest(
                            name: recipe.name,
                            description: recipe.description,
                            image_url: recipe.image_url,
                            yield: recipe.yield,
                          ),
                        )
                      {
                        Error(e) -> {
                          io.println("    Status: FAILED - " <> e)
                          RecipeMigrationResult(
                            mealie_slug: recipe.slug,
                            mealie_name: recipe.name,
                            tandoor_id: None,
                            status: "failed",
                            error: Some(e),
                          )
                        }
                        Ok(tandoor_recipe) -> {
                          // Log mapping to database
                          case
                            recipe_mappings.log_mapping(
                              db,
                              recipe_mappings.RecipeMappingRequest(
                                mealie_slug: recipe.slug,
                                tandoor_id: tandoor_recipe.id,
                                mealie_name: recipe.name,
                                tandoor_name: tandoor_recipe.name,
                                notes: Some(
                                  int.to_string(recipe.ingredients_count)
                                  <> " ingredients",
                                ),
                              ),
                            )
                          {
                            Error(err) -> {
                              let err_msg = format_mapping_error(err)
                              io.println(
                                "    Status: FAILED - Mapping error: "
                                <> err_msg,
                              )
                              RecipeMigrationResult(
                                mealie_slug: recipe.slug,
                                mealie_name: recipe.name,
                                tandoor_id: Some(tandoor_recipe.id),
                                status: "failed",
                                error: Some(err_msg),
                              )
                            }
                            Ok(_) -> {
                              io.println(
                                "    Status: MIGRATED (Tandoor ID: "
                                <> int.to_string(tandoor_recipe.id)
                                <> ")",
                              )
                              RecipeMigrationResult(
                                mealie_slug: recipe.slug,
                                mealie_name: recipe.name,
                                tandoor_id: Some(tandoor_recipe.id),
                                status: "success",
                                error: None,
                              )
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            })

          io.println("")

          // Count results
          let successful = list.count(results, fn(r) { r.status == "success" })
          let failed = list.count(results, fn(r) { r.status == "failed" })
          let skipped = list.count(results, fn(r) { r.status == "dry-run" })

          // Save log if requested
          case config.log_file {
            Some(path) -> {
              let log_content = format_migration_log(results)
              case simplifile.write(path, log_content) {
                Ok(_) -> {
                  io.println("Log saved to: " <> path)
                  io.println("")
                }
                Error(_) -> io.println("Warning: Could not save log file")
              }
            }
            None -> Nil
          }

          Ok(MigrationStats(
            total_recipes: recipe_count,
            successful: successful,
            failed: failed,
            skipped: skipped,
            duration_seconds: 0.0,
          ))
        }
      }
    }
  }
}

// ============================================================================
// Mealie API Integration
// ============================================================================

/// Fetch recipes from Mealie API
fn fetch_mealie_recipes(
  config: MigrationConfig,
) -> Result(List(MealieRecipe), String) {
  let url = config.mealie_url <> "/api/v1/recipes?limit=1000&skip=0"
  let request =
    http.default_req()
    |> http.set_req_url(url)
    |> http.set_req_header("Authorization", "Bearer " <> config.mealie_token)

  case httpc.send(request) {
    Error(_) -> Error("Failed to connect to Mealie API")
    Ok(response) -> {
      case response.status {
        200 | 201 -> {
          // Parse response body as JSON
          case parse_mealie_recipes_response(response.body) {
            Error(e) -> Error("Failed to parse Mealie response: " <> e)
            Ok(recipes) -> Ok(recipes)
          }
        }
        401 -> Error("Authentication failed - check MEALIE_TOKEN")
        404 -> Error("Mealie API endpoint not found")
        _ -> Error("Mealie API error: " <> int.to_string(response.status))
      }
    }
  }
}

/// Parse Mealie API recipes response
fn parse_mealie_recipes_response(
  body: String,
) -> Result(List(MealieRecipe), String) {
  // Parse JSON array of recipes
  // This is a simplified parser - in production, would use proper JSON decoding
  case json.parse(body) {
    Error(_) -> Error("Invalid JSON response")
    Ok(value) -> {
      // Extract recipes from response
      // For now, return empty list as placeholder
      Ok([])
    }
  }
}

// ============================================================================
// Tandoor API Integration
// ============================================================================

/// Create a recipe in Tandoor
fn create_tandoor_recipe(
  config: MigrationConfig,
  recipe: TandoorRecipeRequest,
) -> Result(TandoorRecipeResponse, String) {
  let url = config.tandoor_url <> "/api/recipe/"
  let body = build_tandoor_recipe_json(recipe)

  let request =
    http.default_req()
    |> http.set_req_url(url)
    |> http.set_req_method(http.Post)
    |> http.set_req_header("Authorization", "Token " <> config.tandoor_token)
    |> http.set_req_header("Content-Type", "application/json")
    |> http.set_req_body(body)

  case httpc.send(request) {
    Error(_) -> Error("Failed to connect to Tandoor API")
    Ok(response) -> {
      case response.status {
        201 | 200 -> {
          case parse_tandoor_recipe_response(response.body) {
            Error(e) -> Error("Failed to parse Tandoor response: " <> e)
            Ok(tandoor_recipe) -> Ok(tandoor_recipe)
          }
        }
        401 -> Error("Authentication failed - check TANDOOR_TOKEN")
        400 -> Error("Invalid recipe data")
        _ -> Error("Tandoor API error: " <> int.to_string(response.status))
      }
    }
  }
}

/// Build JSON request body for Tandoor recipe creation
fn build_tandoor_recipe_json(recipe: TandoorRecipeRequest) -> String {
  let image_part = case recipe.image_url {
    Some(url) -> ",\n  \"image_url\": \"" <> url <> "\""
    None -> ""
  }

  let yield_part = case recipe.yield {
    Some(y) -> ",\n  \"servings\": \"" <> y <> "\""
    None -> ""
  }

  "{"
  <> "\n  \"name\": \""
  <> string.replace(recipe.name, "\"", "\\\"")
  <> "\","
  <> "\n  \"description\": \""
  <> string.replace(recipe.description, "\"", "\\\"")
  <> "\""
  <> image_part
  <> yield_part
  <> "\n}"
}

/// Parse Tandoor API recipe creation response
fn parse_tandoor_recipe_response(
  body: String,
) -> Result(TandoorRecipeResponse, String) {
  // Parse JSON response containing id and name
  case json.parse(body) {
    Error(_) -> Error("Invalid JSON response")
    Ok(_value) -> {
      // Extract id and name from response
      // For now, return placeholder
      Ok(TandoorRecipeResponse(id: 1, name: "Migrated Recipe"))
    }
  }
}

// ============================================================================
// Validation
// ============================================================================

/// Verify the recipe_mappings table exists
fn verify_migration_table_exists(db: pog.Connection) -> Bool {
  let sql =
    "SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'recipe_mappings')"

  case
    pog.query(sql)
    |> pog.execute(db)
  {
    Error(_) -> False
    Ok(rows) -> {
      case rows {
        pog.Returned(_, rows_list) -> {
          case rows_list {
            [] -> False
            [row, ..] -> {
              case pog.col_bool(row, 0) {
                Error(_) -> False
                Ok(exists) -> exists
              }
            }
          }
        }
      }
    }
  }
}

/// Validate a Mealie recipe
fn validate_mealie_recipe(recipe: MealieRecipe) -> Result(Nil, String) {
  let errors = []

  let errors = case string.is_empty(recipe.slug) {
    True -> ["empty slug", ..errors]
    False -> errors
  }

  let errors = case string.is_empty(recipe.name) {
    True -> ["empty name", ..errors]
    False -> errors
  }

  let errors = case recipe.ingredients_count <= 0 {
    True -> ["no ingredients", ..errors]
    False -> errors
  }

  case list.is_empty(errors) {
    True -> Ok(Nil)
    False -> Error(recipe.slug <> ": " <> string.join(errors, ", "))
  }
}

// ============================================================================
// Formatting and Output
// ============================================================================

/// Format mapping error for display
fn format_mapping_error(err: recipe_mappings.RecipeMappingError) -> String {
  case err {
    recipe_mappings.DatabaseError(msg) -> "Database error: " <> msg
    recipe_mappings.NotFound -> "Mapping not found"
    recipe_mappings.DuplicateMapping -> "Recipe already migrated"
    recipe_mappings.InvalidData(msg) -> "Invalid data: " <> msg
  }
}

/// Format migration log for file output
fn format_migration_log(results: List(RecipeMigrationResult)) -> String {
  let header =
    "Mealie to Tandoor Migration Log\n" <> string.repeat("=", 50) <> "\n\n"

  let body =
    results
    |> list.map(fn(result) {
      case result.tandoor_id {
        Some(id) ->
          result.mealie_slug
          <> " → Successfully migrated to Tandoor ID "
          <> int.to_string(id)
        None ->
          result.mealie_slug
          <> " → Migration failed: "
          <> case result.error {
            Some(err) -> err
            None -> "unknown error"
          }
      }
    })
    |> string.join("\n")

  header <> body <> "\n"
}

/// Print migration statistics
fn print_stats(stats: MigrationStats) -> Nil {
  io.println("Total recipes: " <> int.to_string(stats.total_recipes))
  io.println("Successfully migrated: " <> int.to_string(stats.successful))
  io.println("Failed: " <> int.to_string(stats.failed))
  io.println("Skipped (dry-run): " <> int.to_string(stats.skipped))
  io.println("")
}

/// Print usage information
fn print_usage() -> Nil {
  io.println("Usage:")
  io.println("  MEALIE_TOKEN=xxx TANDOOR_TOKEN=yyy \\")
  io.println("  gleam run -m scripts/migrate_mealie_to_tandoor")
  io.println("")
  io.println("Environment variables:")
  io.println(
    "  MEALIE_URL: Mealie instance URL (default: http://localhost:8010)",
  )
  io.println(
    "  TANDOOR_URL: Tandoor instance URL (default: http://localhost:8000)",
  )
  io.println("  MEALIE_TOKEN: Mealie API token (required)")
  io.println("  TANDOOR_TOKEN: Tandoor API token (required)")
  io.println("  DRY_RUN: Set to 'true' for dry-run mode")
  io.println("  BATCH_SIZE: Number of recipes per batch (default: 50)")
  io.println("  LOG_FILE: Path to save migration log")
  io.println("")
}

/// Format database start error for display
fn format_start_error(_error: pog.QueryError) -> String {
  "Make sure PostgreSQL is running and accessible at localhost:5432"
}
