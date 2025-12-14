import envoy
import gleam/option.{type Option, None, Some}

/// FatSecret API configuration
pub type FatSecretConfig {
  FatSecretConfig(
    consumer_key: String,
    consumer_secret: String,
    api_host: Option(String),
    auth_host: Option(String),
  )
}

/// Default FatSecret API host
pub const default_api_host = "platform.fatsecret.com"

/// Default FatSecret authentication host
pub const default_auth_host = "authentication.fatsecret.com"

/// API endpoint path
pub const api_path = "/rest/server.api"

/// Create a new FatSecretConfig from environment variables
///
/// Reads FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET from environment.
/// Optionally reads FATSECRET_API_HOST and FATSECRET_AUTH_HOST for custom hosts.
pub fn from_env() -> Option(FatSecretConfig) {
  case
    envoy.get("FATSECRET_CONSUMER_KEY"),
    envoy.get("FATSECRET_CONSUMER_SECRET")
  {
    Ok(consumer_key), Ok(consumer_secret) -> {
      let api_host = envoy.get("FATSECRET_API_HOST") |> result_to_option
      let auth_host = envoy.get("FATSECRET_AUTH_HOST") |> result_to_option

      Some(FatSecretConfig(
        consumer_key: consumer_key,
        consumer_secret: consumer_secret,
        api_host: api_host,
        auth_host: auth_host,
      ))
    }
    _, _ -> None
  }
}

/// Create a new FatSecretConfig with explicit credentials
pub fn new(consumer_key: String, consumer_secret: String) -> FatSecretConfig {
  FatSecretConfig(
    consumer_key: consumer_key,
    consumer_secret: consumer_secret,
    api_host: None,
    auth_host: None,
  )
}

/// Get the API host, using default if not configured
pub fn get_api_host(config: FatSecretConfig) -> String {
  option.unwrap(config.api_host, default_api_host)
}

/// Get the authentication host, using default if not configured
pub fn get_auth_host(config: FatSecretConfig) -> String {
  option.unwrap(config.auth_host, default_auth_host)
}

/// Get the full API URL
pub fn api_url(config: FatSecretConfig) -> String {
  "https://" <> get_api_host(config) <> api_path
}

/// Get the OAuth authorization URL
pub fn authorization_url(config: FatSecretConfig, oauth_token: String) -> String {
  "https://"
  <> get_auth_host(config)
  <> "/authorize?oauth_token="
  <> oauth_token
}

// Helper to convert Result to Option
fn result_to_option(result: Result(a, b)) -> Option(a) {
  case result {
    Ok(value) -> Some(value)
    Error(_) -> None
  }
}
