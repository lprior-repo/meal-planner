//// Credentials loader for integration tests
//// Loads Tandoor and FatSecret credentials from environment and database

import envoy
import gleam/option.{type Option, None, Some}
import gleam/result
import meal_planner/fatsecret/storage
import meal_planner/postgres

pub type Credentials {
  Credentials(tandoor: Option(TandoorCreds), fatsecret: Option(FatSecretCreds))
}

pub type TandoorCreds {
  TandoorCreds(base_url: String, username: String, password: String)
}

pub type FatSecretCreds {
  FatSecretCreds(oauth_token: String, oauth_token_secret: String)
}

/// Load credentials from environment variables and database
pub fn load() -> Credentials {
  let tandoor = load_tandoor_from_env()
  let fatsecret = load_fatsecret_from_db()

  Credentials(tandoor: tandoor, fatsecret: fatsecret)
}

/// Load Tandoor credentials from environment variables
fn load_tandoor_from_env() -> Option(TandoorCreds) {
  case envoy.get("TANDOOR_URL") {
    Ok(url) -> {
      let username =
        envoy.get("TANDOOR_USERNAME")
        |> result.unwrap("admin")
      let password =
        envoy.get("TANDOOR_PASSWORD")
        |> result.unwrap("")

      Some(TandoorCreds(base_url: url, username: username, password: password))
    }
    Error(_) -> None
  }
}

/// Load FatSecret OAuth credentials from PostgreSQL database
fn load_fatsecret_from_db() -> Option(FatSecretCreds) {
  // Try to connect to database and get access token
  case postgres.config_from_env() {
    Ok(config) ->
      case postgres.connect(config) {
        Ok(conn) ->
          case storage.get_access_token(conn) {
            Ok(token) ->
              Some(FatSecretCreds(
                oauth_token: token.oauth_token,
                oauth_token_secret: token.oauth_token_secret,
              ))
            Error(_) -> None
          }
        Error(_) -> None
      }
    Error(_) -> None
  }
}

/// Check if FatSecret credentials are available
pub fn has_fatsecret(creds: Credentials) -> Bool {
  case creds.fatsecret {
    Some(_) -> True
    None -> False
  }
}

/// Check if Tandoor credentials are available
pub fn has_tandoor(creds: Credentials) -> Bool {
  case creds.tandoor {
    Some(_) -> True
    None -> False
  }
}
