/// FatSecret Profile HTTP Handlers
///
/// Routes:
/// - GET /api/fatsecret/connect - Redirect to FatSecret OAuth authorization
/// - GET /api/fatsecret/callback - Handle OAuth callback and complete connection
/// - POST /api/fatsecret/disconnect - Revoke connection and delete tokens
/// - GET /api/fatsecret/status - Check connection status (JSON response)
import gleam/http
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import meal_planner/fatsecret/client
import meal_planner/fatsecret/profile/service
import pog
import wisp

/// GET /api/fatsecret/connect
/// Initiates OAuth flow and redirects user to FatSecret authorization page
/// Query params:
///   - callback_url (optional): Custom callback URL (defaults to /api/fatsecret/callback)
pub fn handle_connect(
  req: wisp.Request,
  conn: pog.Connection,
  base_url: String,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  let callback_url = base_url <> "/api/fatsecret/callback"

  case service.start_connect(conn, callback_url) {
    Ok(auth_url) -> wisp.redirect(auth_url)
    Error(service.NotConfigured) ->
      error_response(
        500,
        "FatSecret not configured. Set FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET.",
      )
    Error(service.EncryptionError(msg)) -> error_response(500, msg)
    Error(service.ApiError(inner)) ->
      error_response(
        502,
        "FatSecret API error: " <> client_error_to_string(inner),
      )
    Error(service.StorageError(msg)) ->
      error_response(500, "Storage error: " <> msg)
    Error(e) ->
      error_response(500, "Failed to start connection: " <> error_to_string(e))
  }
}

/// GET /api/fatsecret/callback?oauth_token=...&oauth_verifier=...
/// Handles OAuth callback from FatSecret
/// Exchanges the verifier for an access token and stores it
pub fn handle_callback(req: wisp.Request, conn: pog.Connection) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  let query_params = wisp.get_query(req)

  let oauth_token =
    list.find(query_params, fn(p) { p.0 == "oauth_token" })
    |> result.map(fn(p) { p.1 })

  let oauth_verifier =
    list.find(query_params, fn(p) { p.0 == "oauth_verifier" })
    |> result.map(fn(p) { p.1 })

  case oauth_token, oauth_verifier {
    Ok(token), Ok(verifier) -> {
      case service.complete_connect(conn, token, verifier) {
        Ok(_profile) ->
          html_response(
            200,
            "<h1>Connected to FatSecret!</h1>
             <p>Your FatSecret account is now linked.</p>
             <p><a href=\"/dashboard\">Return to Dashboard</a></p>",
          )
        Error(service.InvalidVerifier) ->
          error_response(400, "Invalid or expired verifier. Please try again.")
        Error(service.NotConfigured) ->
          error_response(500, "FatSecret not configured")
        Error(service.ApiError(inner)) ->
          error_response(
            502,
            "Failed to exchange token: " <> client_error_to_string(inner),
          )
        Error(e) ->
          error_response(
            500,
            "Failed to complete connection: " <> error_to_string(e),
          )
      }
    }
    _, _ -> {
      // Check if user denied authorization
      let denied =
        list.find(query_params, fn(p) { p.0 == "denied" })
        |> result.is_ok

      case denied {
        True ->
          html_response(
            200,
            "<h1>Authorization Denied</h1>
             <p>You declined to authorize the connection to FatSecret.</p>
             <p><a href=\"/dashboard\">Return to Dashboard</a></p>",
          )
        False -> error_response(400, "Missing oauth_token or oauth_verifier")
      }
    }
  }
}

/// POST /api/fatsecret/disconnect
/// Removes the stored access token and disconnects from FatSecret
pub fn handle_disconnect(
  req: wisp.Request,
  conn: pog.Connection,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Post)

  case service.disconnect(conn) {
    Ok(Nil) -> {
      let body =
        json.object([
          #("success", json.bool(True)),
          #("message", json.string("Disconnected from FatSecret")),
        ])
        |> json.to_string
      wisp.json_response(body, 200)
    }
    Error(service.StorageError(msg)) ->
      error_response(500, "Failed to disconnect: " <> msg)
    Error(e) ->
      error_response(500, "Failed to disconnect: " <> error_to_string(e))
  }
}

/// GET /api/fatsecret/status
/// Returns JSON status of the FatSecret connection
/// Response format:
/// {
///   "status": "connected" | "disconnected" | "config_missing" | "encryption_missing",
///   "connected": true | false,
///   "reason": "..." (if disconnected),
///   "profile": {...} (if connected and available)
/// }
pub fn handle_status(req: wisp.Request, conn: pog.Connection) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  let status = service.check_status(conn)

  let status_json = case status {
    service.Connected(profile:) -> {
      // Optionally validate the connection
      let validated = service.validate_connection(conn)
      case validated {
        Ok(True) ->
          case profile {
            Some(p) ->
              json.object([
                #("status", json.string("connected")),
                #("connected", json.bool(True)),
                #("profile", json.string(p.profile_json)),
              ])
            None ->
              json.object([
                #("status", json.string("connected")),
                #("connected", json.bool(True)),
              ])
          }
        Ok(False) ->
          json.object([
            #("status", json.string("disconnected")),
            #("connected", json.bool(False)),
            #("reason", json.string("Token was revoked or expired")),
          ])
        Error(_) ->
          json.object([
            #("status", json.string("connected")),
            #("connected", json.bool(True)),
            #("validation", json.string("failed")),
          ])
      }
    }

    service.Disconnected(reason:) ->
      json.object([
        #("status", json.string("disconnected")),
        #("connected", json.bool(False)),
        #("reason", json.string(reason)),
      ])

    service.ConfigMissing ->
      json.object([
        #("status", json.string("config_missing")),
        #("connected", json.bool(False)),
        #(
          "reason",
          json.string(
            "FatSecret API credentials not set. Add FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET to .env",
          ),
        ),
      ])

    service.EncryptionKeyMissing ->
      json.object([
        #("status", json.string("encryption_missing")),
        #("connected", json.bool(False)),
        #(
          "reason",
          json.string(
            "OAUTH_ENCRYPTION_KEY not set. Generate one with: openssl rand -hex 32",
          ),
        ),
      ])
  }

  wisp.json_response(json.to_string(status_json), 200)
}

// =============================================================================
// Internal Helpers
// =============================================================================

fn error_to_string(error: service.ServiceError) -> String {
  case error {
    service.NotConfigured -> "FatSecret not configured"
    service.NotConnected -> "Not connected to FatSecret"
    service.AuthRevoked -> "Authorization was revoked"
    service.TokenExpired -> "Token expired"
    service.InvalidVerifier -> "Invalid or expired verifier"
    service.ApiError(inner) -> "API error: " <> client_error_to_string(inner)
    service.StorageError(msg) -> "Storage error: " <> msg
    service.EncryptionError(msg) -> "Encryption error: " <> msg
  }
}

fn client_error_to_string(error: client.FatSecretError) -> String {
  case error {
    client.ConfigMissing -> "Configuration missing"
    client.RequestFailed(status, body) ->
      "Request failed: HTTP " <> int.to_string(status) <> " - " <> body
    client.InvalidResponse(msg) -> "Invalid response: " <> msg
    client.OAuthError(msg) -> "OAuth error: " <> msg
    client.NetworkError(msg) -> "Network error: " <> msg
    client.ApiError(code, msg) -> "API error " <> code <> ": " <> msg
    client.ParseError(msg) -> "Parse error: " <> msg
  }
}

fn error_response(status: Int, message: String) -> wisp.Response {
  let body =
    json.object([#("error", json.string(message))])
    |> json.to_string

  wisp.json_response(body, status)
}

fn html_response(status: Int, body: String) -> wisp.Response {
  let html = "<!DOCTYPE html>
<html>
<head>
  <meta charset=\"utf-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
  <title>FatSecret Connection</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 600px; margin: 40px auto; padding: 20px; }
    h1 { color: #333; }
    p { color: #666; line-height: 1.6; }
    a { color: #0066cc; }
  </style>
</head>
<body>" <> body <> "</body></html>"

  wisp.response(status)
  |> wisp.set_header("content-type", "text/html; charset=utf-8")
  |> wisp.set_body(wisp.Text(html))
}
