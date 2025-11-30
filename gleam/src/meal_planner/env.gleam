import envoy
import gleam/list
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
      "missing required environment variables: "
      <> string.join(missing, ", ")
  }
}
