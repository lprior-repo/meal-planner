/// FatSecret OAuth 1.0a 3-legged authentication handlers
///
/// Routes:
/// - GET /fatsecret/connect - Start OAuth flow, redirect to FatSecret
/// - GET /fatsecret/callback - Handle OAuth callback, exchange for access token
/// - GET /fatsecret/status - Check connection status (JSON)
/// - POST /fatsecret/disconnect - Remove stored access token
import gleam/http
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import meal_planner/env
import meal_planner/fatsecret/client as fatsecret
import meal_planner/fatsecret/service as fatsecret_service
import meal_planner/fatsecret/storage
import pog
import wisp

/// GET /fatsecret/connect
/// Initiates the OAuth flow by:
/// 1. Getting a request token from FatSecret
/// 2. Storing the token secret in the database (encrypted)
/// 3. Redirecting the user to FatSecret's authorization page
pub fn handle_connect(
  req: wisp.Request,
  conn: pog.Connection,
  base_url: String,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  case storage.encryption_configured() {
    False -> {
      error_response(
        500,
        "Encryption not configured. Set OAUTH_ENCRYPTION_KEY (64 hex chars).",
      )
    }
    True -> {
      case env.load_fatsecret_config() {
        None -> {
          error_response(
            500,
            "FatSecret not configured. Set FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET.",
          )
        }
        Some(config) -> {
          handle_connect_with_config(req, conn, base_url, config)
        }
      }
    }
  }
}

fn handle_connect_with_config(
  _req: wisp.Request,
  conn: pog.Connection,
  base_url: String,
  config: env.FatSecretConfig,
) -> wisp.Response {
  let callback_url = base_url <> "/fatsecret/callback"

  case fatsecret.get_request_token(config, callback_url) {
    Ok(request_token) -> {
      case storage.store_pending_token(conn, request_token) {
        Ok(Nil) -> {
          let auth_url = fatsecret.get_authorization_url(request_token)
          wisp.redirect(auth_url)
        }
        Error(storage.DatabaseError(msg)) -> {
          error_response(500, "Failed to store request token: " <> msg)
        }
        Error(storage.EncryptionError(msg)) -> {
          error_response(500, "Encryption error: " <> msg)
        }
        Error(storage.NotFound) -> {
          error_response(500, "Unexpected storage error")
        }
      }
    }
    Error(fatsecret.RequestFailed(status, body)) -> {
      error_response(
        502,
        "FatSecret request failed: HTTP "
          <> int.to_string(status)
          <> " - "
          <> body,
      )
    }
    Error(fatsecret.NetworkError(msg)) -> {
      error_response(502, "Network error: " <> msg)
    }
    Error(fatsecret.OAuthError(msg)) -> {
      error_response(400, "OAuth error: " <> msg)
    }
    Error(e) -> {
      error_response(500, "Failed to get request token: " <> error_to_string(e))
    }
  }
}

/// GET /fatsecret/callback?oauth_token=...&oauth_verifier=...
/// Handles the OAuth callback from FatSecret:
/// 1. Retrieves the stored request token secret
/// 2. Exchanges the authorized request token for an access token
/// 3. Stores the access token for future API calls
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
      complete_oauth_flow(conn, token, verifier)
    }
    _, _ -> {
      let denied =
        list.find(query_params, fn(p) { p.0 == "denied" })
        |> result.is_ok

      case denied {
        True -> {
          html_response(
            200,
            "<h1>Authorization Denied</h1>
             <p>You declined to authorize the connection to FatSecret.</p>
             <p><a href=\"/dashboard\">Return to Dashboard</a></p>",
          )
        }
        False -> {
          error_response(
            400,
            "Missing oauth_token or oauth_verifier in callback",
          )
        }
      }
    }
  }
}

fn complete_oauth_flow(
  conn: pog.Connection,
  oauth_token: String,
  oauth_verifier: String,
) -> wisp.Response {
  case env.load_fatsecret_config() {
    None -> error_response(500, "FatSecret not configured")
    Some(config) -> {
      case storage.get_pending_token(conn, oauth_token) {
        Ok(token_secret) -> {
          let request_token =
            fatsecret.RequestToken(
              oauth_token:,
              oauth_token_secret: token_secret,
              oauth_callback_confirmed: True,
            )

          case
            fatsecret.get_access_token(config, request_token, oauth_verifier)
          {
            Ok(access_token) -> {
              case storage.store_access_token(conn, access_token) {
                Ok(Nil) -> {
                  html_response(
                    200,
                    "<h1>Connected to FatSecret!</h1>
                     <p>Your FatSecret account is now linked. You can now sync your food diary.</p>
                     <p><a href=\"/dashboard\">Return to Dashboard</a></p>",
                  )
                }
                Error(storage.DatabaseError(msg)) -> {
                  error_response(500, "Failed to store access token: " <> msg)
                }
                Error(storage.EncryptionError(msg)) -> {
                  error_response(500, "Encryption error: " <> msg)
                }
                Error(storage.NotFound) -> {
                  error_response(500, "Unexpected storage error")
                }
              }
            }
            Error(fatsecret.RequestFailed(status, body)) -> {
              error_response(
                502,
                "Failed to exchange token: HTTP "
                  <> int.to_string(status)
                  <> " - "
                  <> body,
              )
            }
            Error(e) -> {
              error_response(
                500,
                "Failed to get access token: " <> error_to_string(e),
              )
            }
          }
        }
        Error(storage.NotFound) -> {
          error_response(
            400,
            "Request token not found or expired. Please try connecting again.",
          )
        }
        Error(storage.DatabaseError(msg)) -> {
          error_response(500, "Database error: " <> msg)
        }
        Error(storage.EncryptionError(msg)) -> {
          error_response(500, "Encryption error: " <> msg)
        }
      }
    }
  }
}

/// GET /fatsecret/status
/// Returns HTML status page with management options
pub fn handle_status(req: wisp.Request, conn: pog.Connection) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  let status = fatsecret_service.check_status(conn)

  let status_html = case status {
    fatsecret_service.Connected(_) -> {
      // Validate the connection is actually working
      case fatsecret_service.validate_connection(conn) {
        Ok(True) ->
          "<div class=\"status connected\">
            <h2>✓ Connected to FatSecret</h2>
            <p>Your account is linked and working correctly.</p>
            <form action=\"/fatsecret/disconnect\" method=\"POST\" style=\"margin-top: 20px;\">
              <button type=\"submit\" class=\"btn danger\">Disconnect</button>
            </form>
          </div>"
        Ok(False) ->
          "<div class=\"status warning\">
            <h2>⚠ Connection Expired</h2>
            <p>Your FatSecret authorization was revoked. Please reconnect.</p>
            <a href=\"/fatsecret/connect\" class=\"btn\">Reconnect to FatSecret</a>
          </div>"
        Error(_) ->
          "<div class=\"status warning\">
            <h2>⚠ Connection Issue</h2>
            <p>Could not verify connection. The API may be temporarily unavailable.</p>
            <a href=\"/fatsecret/connect\" class=\"btn\">Reconnect</a>
          </div>"
      }
    }

    fatsecret_service.Disconnected(_) ->
      "<div class=\"status disconnected\">
        <h2>Not Connected</h2>
        <p>Connect your FatSecret account to sync your food diary automatically.</p>
        <a href=\"/fatsecret/connect\" class=\"btn\">Connect to FatSecret</a>
      </div>"

    fatsecret_service.ConfigMissing ->
      "<div class=\"status error\">
        <h2>✗ Not Configured</h2>
        <p>FatSecret API credentials are not set. Add FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET to your .env file.</p>
      </div>"

    fatsecret_service.EncryptionKeyMissing ->
      "<div class=\"status error\">
        <h2>✗ Encryption Not Configured</h2>
        <p>OAUTH_ENCRYPTION_KEY is required for secure token storage.</p>
        <p>Generate one with: <code>openssl rand -hex 32</code></p>
      </div>"
  }

  let html = "<!DOCTYPE html>
<html>
<head>
  <meta charset=\"utf-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
  <title>FatSecret Status</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 600px; margin: 40px auto; padding: 20px; background: #f5f5f5; }
    .card { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    h1 { color: #333; margin-bottom: 20px; }
    h2 { margin-top: 0; }
    p { color: #666; line-height: 1.6; }
    .status { padding: 20px; border-radius: 6px; margin-bottom: 20px; }
    .status.connected { background: #d4edda; border: 1px solid #28a745; }
    .status.disconnected { background: #fff3cd; border: 1px solid #ffc107; }
    .status.warning { background: #fff3cd; border: 1px solid #ffc107; }
    .status.error { background: #f8d7da; border: 1px solid #dc3545; }
    .btn { display: inline-block; padding: 10px 20px; background: #3498db; color: white; text-decoration: none; border-radius: 4px; border: none; cursor: pointer; font-size: 16px; }
    .btn:hover { background: #2980b9; }
    .btn.danger { background: #dc3545; }
    .btn.danger:hover { background: #c82333; }
    code { background: #e9ecef; padding: 2px 6px; border-radius: 3px; }
    .back-link { display: block; margin-top: 20px; color: #3498db; }
  </style>
</head>
<body>
  <div class=\"card\">
    <h1>FatSecret Integration</h1>
    " <> status_html <> "
    <a href=\"/dashboard\" class=\"back-link\">← Back to Dashboard</a>
  </div>
</body>
</html>"

  wisp.response(200)
  |> wisp.set_header("content-type", "text/html; charset=utf-8")
  |> wisp.set_body(wisp.Text(html))
}

/// POST /fatsecret/disconnect
/// Removes the stored access token
pub fn handle_disconnect(
  req: wisp.Request,
  conn: pog.Connection,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Post)

  case storage.delete_access_token(conn) {
    Ok(Nil) -> {
      let body =
        json.object([
          #("success", json.bool(True)),
          #("message", json.string("Disconnected from FatSecret")),
        ])
        |> json.to_string
      wisp.json_response(body, 200)
    }
    Error(storage.DatabaseError(msg)) -> {
      error_response(500, "Failed to disconnect: " <> msg)
    }
    Error(_) -> {
      error_response(500, "Failed to disconnect")
    }
  }
}

/// GET /api/fatsecret/profile
/// Get the connected FatSecret user's profile
pub fn handle_get_profile(
  req: wisp.Request,
  conn: pog.Connection,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  case fatsecret_service.get_profile(conn) {
    Ok(profile_json) -> wisp.json_response(profile_json, 200)
    Error(fatsecret_service.NotConnected) ->
      error_response(
        401,
        "Not connected to FatSecret. Visit /fatsecret/connect to authorize.",
      )
    Error(fatsecret_service.NotConfigured) ->
      error_response(500, "FatSecret API not configured")
    Error(fatsecret_service.AuthRevoked) ->
      error_response(
        401,
        "FatSecret authorization was revoked. Please reconnect.",
      )
    Error(e) ->
      error_response(
        500,
        "Failed to get profile: " <> fatsecret_service.error_to_string(e),
      )
  }
}

/// GET /api/fatsecret/entries?date=YYYY-MM-DD
/// Get food entries for a specific date
pub fn handle_get_entries(
  req: wisp.Request,
  conn: pog.Connection,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  let query_params = wisp.get_query(req)
  let date =
    list.find(query_params, fn(p) { p.0 == "date" })
    |> result.map(fn(p) { p.1 })
    |> result.unwrap("")

  case string.is_empty(date) {
    True -> error_response(400, "Missing 'date' query parameter (YYYY-MM-DD)")
    False -> {
      case fatsecret_service.get_food_entries(conn, date) {
        Ok(entries_json) -> wisp.json_response(entries_json, 200)
        Error(fatsecret_service.NotConnected) ->
          error_response(
            401,
            "Not connected to FatSecret. Visit /fatsecret/connect to authorize.",
          )
        Error(fatsecret_service.NotConfigured) ->
          error_response(500, "FatSecret API not configured")
        Error(fatsecret_service.AuthRevoked) ->
          error_response(
            401,
            "FatSecret authorization was revoked. Please reconnect.",
          )
        Error(e) ->
          error_response(
            500,
            "Failed to get entries: " <> fatsecret_service.error_to_string(e),
          )
      }
    }
  }
}

fn error_to_string(error: fatsecret.FatSecretError) -> String {
  case error {
    fatsecret.ConfigMissing -> "Configuration missing"
    fatsecret.RequestFailed(status, body) ->
      "Request failed: HTTP " <> int.to_string(status) <> " - " <> body
    fatsecret.InvalidResponse(msg) -> "Invalid response: " <> msg
    fatsecret.OAuthError(msg) -> "OAuth error: " <> msg
    fatsecret.NetworkError(msg) -> "Network error: " <> msg
    fatsecret.ApiError(code, msg) -> "API error " <> code <> ": " <> msg
    fatsecret.ParseError(msg) -> "Parse error: " <> msg
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
