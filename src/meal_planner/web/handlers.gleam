/// Web handlers facade module
///
/// This module re-exports all handler functions from the handlers subdirectory.
/// It provides a single import point for all HTTP endpoint handlers.
///
/// Handler organization:
/// - health: Health check endpoint
/// - recipes: Recipe scoring endpoint
/// - diet: Vertical diet compliance check endpoint
/// - macros: Macro calculation endpoint
/// - dashboard: Dashboard UI with nutrition tracking
/// - tandoor: Tandoor Recipe Manager integration
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import meal_planner/config
import meal_planner/email/confirmation as email_confirmation

// import meal_planner/email/executor as email_executor
import meal_planner/email/command.{
  type CommandExecutionResult, type EmailCommand, CommandExecutionResult,
}
import meal_planner/fatsecret/client
import meal_planner/fatsecret/core/config as fs_config
import meal_planner/fatsecret/core/oauth as core_oauth
import meal_planner/fatsecret/foods/handlers as foods_handlers
import meal_planner/fatsecret/profile/handlers as profile_handlers
import meal_planner/fatsecret/profile/oauth as profile_oauth
import meal_planner/fatsecret/service
import meal_planner/fatsecret/storage
import meal_planner/web/handlers/diet
import meal_planner/web/handlers/health
import meal_planner/web/handlers/macros
import meal_planner/web/handlers/recipes
import meal_planner/web/handlers/tandoor
import pog
import wisp

/// API route handler - delegates to API router
pub fn handle_api_routes(_req: wisp.Request) -> wisp.Response {
  // For now, we'll just return a placeholder response
  // In a real implementation, this would route to the API router
  wisp.response(501)
  |> wisp.string_body("API routes handler not yet implemented")
}

/// Health check handler - GET /health or /
pub fn handle_health(req: wisp.Request) -> wisp.Response {
  health.handle(req)
}

/// Detailed health check handler - GET /health/detailed
pub fn handle_health_detailed(
  req: wisp.Request,
  db: pog.Connection,
  app_config: config.Config,
) -> wisp.Response {
  health.handle_detailed(req, db, app_config)
}

/// Recipe scoring handler - POST /api/ai/score-recipe
pub fn handle_score_recipe(req: wisp.Request) -> wisp.Response {
  recipes.handle_score(req)
}

/// Diet compliance handler - GET /api/diet/vertical/compliance/{recipe_id}
pub fn handle_diet_compliance(
  req: wisp.Request,
  recipe_id: String,
) -> wisp.Response {
  diet.handle_compliance(req, recipe_id)
}

/// Macro calculation handler - POST /api/macros/calculate
pub fn handle_macros_calculate(req: wisp.Request) -> wisp.Response {
  macros.handle_calculate(req)
}

/// Dashboard handler - GET /dashboard
/// TODO: Re-enable when dashboard module is available
pub fn handle_dashboard(
  _req: wisp.Request,
  _conn: pog.Connection,
) -> wisp.Response {
  wisp.response(501)
  |> wisp.string_body("Dashboard handler not yet implemented")
}

/// Dashboard data handler - GET /api/dashboard/data
/// TODO: Re-enable when dashboard module is available
pub fn handle_dashboard_data(
  _req: wisp.Request,
  _conn: pog.Connection,
) -> wisp.Response {
  wisp.response(501)
  |> wisp.string_body("Dashboard data handler not yet implemented")
}

/// Log food form handler - GET /log/food/{fdc_id}
/// TODO: Re-enable when foods module is available
pub fn handle_log_food_form(
  _req: wisp.Request,
  _conn: pog.Connection,
  _fdc_id: String,
) -> wisp.Response {
  wisp.response(501)
  |> wisp.string_body("Log food form handler not yet implemented")
}

/// Log food API handler - POST /api/logs/food
/// TODO: Re-enable when foods module is available
pub fn handle_log_food(
  _req: wisp.Request,
  _conn: pog.Connection,
) -> wisp.Response {
  wisp.response(501)
  |> wisp.string_body("Log food handler not yet implemented")
}

// ============================================================================
// FatSecret Foods API Handlers
// ============================================================================

/// FatSecret search foods - GET /api/fatsecret/foods/search
pub fn handle_fatsecret_search_foods(req: wisp.Request) -> wisp.Response {
  foods_handlers.handle_search_foods(req)
}

/// FatSecret get food - GET /api/fatsecret/foods/:id
pub fn handle_fatsecret_get_food(
  req: wisp.Request,
  food_id: String,
) -> wisp.Response {
  foods_handlers.handle_get_food(req, food_id)
}

/// Handle GET /api/fatsecret/foods/autocomplete
pub fn handle_fatsecret_autocomplete_foods(req: wisp.Request) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use _req <- wisp.handle_head(req)
  wisp.not_found()
}

/// Handle GET /api/fatsecret/recipes/autocomplete
pub fn handle_fatsecret_autocomplete_recipes(req: wisp.Request) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use _req <- wisp.handle_head(req)
  wisp.not_found()
}

// ============================================================================
// Tandoor Recipe Manager Handlers
// ============================================================================

/// Main Tandoor router - routes all Tandoor API requests
/// Handles all endpoints:
/// - GET /tandoor/status
/// - GET/POST/PATCH/DELETE /api/tandoor/recipes/*
/// - GET/POST/PATCH/DELETE /api/tandoor/ingredients/*
/// - GET/POST/PATCH/DELETE /api/tandoor/meal-plans/*
/// - GET /api/tandoor/keywords/*
/// - GET /api/tandoor/units
/// - GET/PUT /api/tandoor/preferences
pub fn handle_tandoor_routes(req: wisp.Request) -> wisp.Response {
  tandoor.handle_tandoor_routes(req)
}

// ============================================================================
// FatSecret OAuth 3-Legged Flow Handlers
// ============================================================================

/// FatSecret OAuth connect - GET /fatsecret/connect
pub fn handle_fatsecret_connect(
  _req: wisp.Request,
  conn: pog.Connection,
  base_url: String,
) -> wisp.Response {
  case fs_config.from_env() {
    None -> {
      wisp.response(500)
      |> wisp.set_header("content-type", "application/json")
      |> wisp.string_body(
        "{\"error\":\"FatSecret API credentials not configured\"}",
      )
    }
    Some(cfg) -> {
      let callback_url = base_url <> "/fatsecret/callback"
      case profile_oauth.get_request_token(cfg, callback_url) {
        Error(_) -> {
          wisp.response(500)
          |> wisp.set_header("content-type", "application/json")
          |> wisp.string_body(
            "{\"error\":\"Failed to get OAuth request token\"}",
          )
        }
        Ok(request_token) -> {
          // Convert from core/oauth.RequestToken to client.RequestToken for storage
          let storage_token =
            client.RequestToken(
              oauth_token: request_token.oauth_token,
              oauth_token_secret: request_token.oauth_token_secret,
              oauth_callback_confirmed: request_token.oauth_callback_confirmed,
            )
          // Store the request token for the callback
          case storage.store_pending_token(conn, storage_token) {
            Error(_) -> {
              wisp.response(500)
              |> wisp.set_header("content-type", "application/json")
              |> wisp.string_body(
                "{\"error\":\"Failed to store pending OAuth token\"}",
              )
            }
            Ok(Nil) -> {
              // Redirect user to FatSecret authorization page
              let auth_url =
                profile_oauth.get_authorization_url(cfg, request_token)
              wisp.response(302)
              |> wisp.set_header("location", auth_url)
              |> wisp.string_body("")
            }
          }
        }
      }
    }
  }
}

/// FatSecret OAuth callback - GET /fatsecret/callback
/// Receives oauth_token and oauth_verifier from FatSecret after user authorization
pub fn handle_fatsecret_callback(
  req: wisp.Request,
  conn: pog.Connection,
) -> wisp.Response {
  // Get oauth_token and oauth_verifier from query params
  let query = wisp.get_query(req)
  let oauth_token =
    list.find(query, fn(pair) { pair.0 == "oauth_token" })
    |> result.map(fn(pair) { pair.1 })
  let oauth_verifier =
    list.find(query, fn(pair) { pair.0 == "oauth_verifier" })
    |> result.map(fn(pair) { pair.1 })

  case oauth_token, oauth_verifier {
    Error(_), _ | _, Error(_) -> {
      wisp.response(400)
      |> wisp.set_header("content-type", "application/json")
      |> wisp.string_body(
        "{\"error\":\"Missing oauth_token or oauth_verifier parameter\"}",
      )
    }
    Ok(token), Ok(verifier) -> {
      // Get the pending token secret from storage
      case storage.get_pending_token(conn, token) {
        Error(_) -> {
          wisp.response(400)
          |> wisp.set_header("content-type", "application/json")
          |> wisp.string_body(
            "{\"error\":\"OAuth token expired or not found. Please try connecting again.\"}",
          )
        }
        Ok(token_secret) -> {
          case fs_config.from_env() {
            None -> {
              wisp.response(500)
              |> wisp.set_header("content-type", "application/json")
              |> wisp.string_body(
                "{\"error\":\"FatSecret API credentials not configured\"}",
              )
            }
            Some(cfg) -> {
              // Reconstruct the request token for the exchange
              let request_token =
                core_oauth.RequestToken(
                  oauth_token: token,
                  oauth_token_secret: token_secret,
                  oauth_callback_confirmed: True,
                )
              // Exchange for access token
              case
                profile_oauth.get_access_token(cfg, request_token, verifier)
              {
                Error(_) -> {
                  wisp.response(500)
                  |> wisp.set_header("content-type", "application/json")
                  |> wisp.string_body(
                    "{\"error\":\"Failed to exchange OAuth token\"}",
                  )
                }
                Ok(access_token) -> {
                  // Convert and store the access token
                  let storage_access_token =
                    client.AccessToken(
                      oauth_token: access_token.oauth_token,
                      oauth_token_secret: access_token.oauth_token_secret,
                    )
                  case storage.store_access_token(conn, storage_access_token) {
                    Error(_) -> {
                      wisp.response(500)
                      |> wisp.set_header("content-type", "application/json")
                      |> wisp.string_body(
                        "{\"error\":\"Failed to store access token\"}",
                      )
                    }
                    Ok(Nil) -> {
                      // Success! Redirect to status page or show success message
                      wisp.response(200)
                      |> wisp.set_header("content-type", "application/json")
                      |> wisp.string_body(
                        "{\"success\":true,\"message\":\"FatSecret connected successfully!\"}",
                      )
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

/// FatSecret status - GET /fatsecret/status
pub fn handle_fatsecret_status(
  _req: wisp.Request,
  conn: pog.Connection,
) -> wisp.Response {
  let status = service.check_status(conn)
  let json_body = case status {
    service.Connected(_) -> "{\"connected\":true}"
    service.Disconnected(reason) ->
      "{\"connected\":false,\"reason\":\"" <> reason <> "\"}"
    service.ConfigMissing ->
      "{\"connected\":false,\"reason\":\"FatSecret API not configured\"}"
    service.EncryptionKeyMissing ->
      "{\"connected\":false,\"reason\":\"Encryption key not configured\"}"
  }

  wisp.response(200)
  |> wisp.set_header("content-type", "application/json")
  |> wisp.string_body(json_body)
}

/// FatSecret disconnect - POST /fatsecret/disconnect
pub fn handle_fatsecret_disconnect(
  _req: wisp.Request,
  conn: pog.Connection,
) -> wisp.Response {
  case storage.is_connected(conn) {
    False -> {
      wisp.response(404)
      |> wisp.set_header("content-type", "application/json")
      |> wisp.string_body("{\"error\":\"No OAuth connection found\"}")
    }
    True -> {
      case storage.delete_access_token(conn) {
        Ok(Nil) -> {
          wisp.response(200)
          |> wisp.set_header("content-type", "application/json")
          |> wisp.string_body("{\"disconnected\":true}")
        }
        Error(_) -> {
          wisp.response(500)
          |> wisp.set_header("content-type", "application/json")
          |> wisp.string_body("{\"error\":\"Failed to disconnect\"}")
        }
      }
    }
  }
}

/// FatSecret get profile - GET /api/fatsecret/profile
pub fn handle_fatsecret_profile(
  req: wisp.Request,
  conn: pog.Connection,
) -> wisp.Response {
  profile_handlers.get_profile(req, conn)
}

/// FatSecret create profile - POST /api/fatsecret/profile
pub fn handle_fatsecret_create_profile(
  req: wisp.Request,
  conn: pog.Connection,
) -> wisp.Response {
  profile_handlers.create_profile(req, conn)
}

/// FatSecret get profile auth - GET /api/fatsecret/profile/auth/:user_id
pub fn handle_fatsecret_get_profile_auth(
  req: wisp.Request,
  conn: pog.Connection,
  user_id: String,
) -> wisp.Response {
  profile_handlers.get_profile_auth(req, conn, user_id)
}

// ============================================================================
// Email Command Executor
// ============================================================================

/// Execute parsed email command with database connection
/// Routes command to appropriate handler (adjust meal, preferences, regeneration, etc.)
pub fn execute_email_command(
  command: EmailCommand,
  _conn: pog.Connection,
) -> CommandExecutionResult {
  CommandExecutionResult(
    success: False,
    message: "Email executor temporarily disabled",
    command: option.Some(command),
  )
  // email_executor.execute_command(command, conn)
}

/// Generate confirmation email for executed command
/// Returns email with formatted subject, body, and HTML content
pub fn generate_confirmation_email(
  result: CommandExecutionResult,
  user_email: String,
) -> email_confirmation.ConfirmationEmail {
  email_confirmation.generate_confirmation(result, user_email)
}
