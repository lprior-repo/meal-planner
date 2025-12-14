import dot_env
import envoy
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

/// Required environment variables for the meal planner application
pub type RequiredVars {
  RequiredVars(
    mailtrap_api_token: String,
    sender_email: String,
    sender_name: String,
    recipient_email: String,
  )
}

/// FatSecret API configuration for calorie tracking sync
pub type FatSecretConfig {
  FatSecretConfig(consumer_key: String, consumer_secret: String)
}

/// Tandoor Recipe Manager configuration
pub type TandoorConfig {
  TandoorConfig(base_url: String, username: String, password: String)
}

/// Error type for environment variable loading
pub type EnvError {
  MissingVars(missing: List(String))
}

/// Load environment variables from the system
/// Returns Ok(RequiredVars) if all required vars are present
/// Returns Error(EnvError) if any required vars are missing
pub fn load_from_env() -> Result(RequiredVars, EnvError) {
  let mailtrap_token = envoy.get("MAILTRAP_API_TOKEN") |> result.unwrap("")
  let sender_email = envoy.get("SENDER_EMAIL") |> result.unwrap("")
  let sender_name = envoy.get("SENDER_NAME") |> result.unwrap("")
  let recipient_email = envoy.get("RECIPIENT_EMAIL") |> result.unwrap("")

  let vars =
    RequiredVars(
      mailtrap_api_token: mailtrap_token,
      sender_email: sender_email,
      sender_name: sender_name,
      recipient_email: recipient_email,
    )

  validate_required_vars(vars)
}

/// Validate that all required environment variables are present (non-empty)
/// Returns Ok(RequiredVars) if all are present
/// Returns Error(EnvError) with list of missing variable names if any are missing
pub fn validate_required_vars(
  vars: RequiredVars,
) -> Result(RequiredVars, EnvError) {
  let missing = []

  let missing = case string.is_empty(vars.mailtrap_api_token) {
    True -> ["MAILTRAP_API_TOKEN", ..missing]
    False -> missing
  }

  let missing = case string.is_empty(vars.sender_email) {
    True -> ["SENDER_EMAIL", ..missing]
    False -> missing
  }

  let missing = case string.is_empty(vars.sender_name) {
    True -> ["SENDER_NAME", ..missing]
    False -> missing
  }

  let missing = case string.is_empty(vars.recipient_email) {
    True -> ["RECIPIENT_EMAIL", ..missing]
    False -> missing
  }

  case missing {
    [] -> Ok(vars)
    _ -> Error(MissingVars(missing: list.reverse(missing)))
  }
}

/// Format error message for missing environment variables
pub fn format_error(error: EnvError) -> String {
  case error {
    MissingVars(missing) ->
      "missing required environment variables: " <> string.join(missing, ", ")
  }
}

/// Load .env file from the project root
/// Silently ignores missing .env file (common in production)
pub fn load_dotenv() -> Nil {
  // Try parent directory first (when running from gleam/), then current dir
  dot_env.new()
  |> dot_env.set_path("../.env")
  |> dot_env.set_debug(False)
  |> dot_env.set_ignore_missing_file(True)
  |> dot_env.load

  dot_env.new()
  |> dot_env.set_path(".env")
  |> dot_env.set_debug(False)
  |> dot_env.set_ignore_missing_file(True)
  |> dot_env.load
}

/// Load environment variables with .env file support
/// First loads .env file (if exists), then reads from environment
pub fn load() -> Result(RequiredVars, EnvError) {
  load_dotenv()
  load_from_env()
}

/// Load email configuration (alias for load function)
pub fn load_email_config() -> Result(RequiredVars, EnvError) {
  load()
}

/// Load FatSecret API configuration
/// Returns Some(FatSecretConfig) if both credentials are present
/// Returns None if credentials are missing (FatSecret sync disabled)
pub fn load_fatsecret_config() -> Option(FatSecretConfig) {
  load_dotenv()
  let key = envoy.get("FATSECRET_CONSUMER_KEY") |> result.unwrap("")
  let secret = envoy.get("FATSECRET_CONSUMER_SECRET") |> result.unwrap("")

  case string.is_empty(key), string.is_empty(secret) {
    False, False ->
      Some(FatSecretConfig(consumer_key: key, consumer_secret: secret))
    _, _ -> None
  }
}

/// Check if FatSecret integration is configured
pub fn fatsecret_enabled() -> Bool {
  case load_fatsecret_config() {
    Some(_) -> True
    None -> False
  }
}

/// Load Tandoor Recipe Manager configuration
/// Returns Some(TandoorConfig) if URL, username, and password are present
/// Returns None if any credential is missing (Tandoor integration disabled)
pub fn load_tandoor_config() -> Option(TandoorConfig) {
  load_dotenv()
  let url = envoy.get("TANDOOR_URL") |> result.unwrap("")
  let username = envoy.get("TANDOOR_USERNAME") |> result.unwrap("")
  let password = envoy.get("TANDOOR_PASSWORD") |> result.unwrap("")

  case
    string.is_empty(url),
    string.is_empty(username),
    string.is_empty(password)
  {
    False, False, False ->
      Some(TandoorConfig(base_url: url, username: username, password: password))
    _, _, _ -> None
  }
}

/// Check if Tandoor integration is configured
pub fn tandoor_enabled() -> Bool {
  case load_tandoor_config() {
    Some(_) -> True
    None -> False
  }
}

/// Get a single environment variable with default
pub fn get_env(name: String, default: String) -> String {
  load_dotenv()
  envoy.get(name) |> result.unwrap(default)
}

/// Get database URL from environment
pub fn get_database_url() -> String {
  get_env("DATABASE_URL", "postgresql://postgres@localhost/meal_planner")
}
