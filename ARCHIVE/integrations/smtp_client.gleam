/// SMTP email client module
///
/// Provides email sending functionality using Mailtrap for testing
/// and production SMTP servers for real deployments.
///
/// Configuration via environment variables:
/// - SMTP_HOST: SMTP server hostname (default: sandbox.smtp.mailtrap.io)
/// - SMTP_PORT: SMTP server port (default: 2525)
/// - SMTP_USERNAME: SMTP authentication username
/// - SMTP_PASSWORD: SMTP authentication password
/// - SMTP_FROM_EMAIL: Sender email address (default: noreply@mealplanner.app)
/// - SMTP_FROM_NAME: Sender name (default: Meal Planner)
import gleam/dynamic
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/env

// ============================================================================
// Types
// ============================================================================

/// SMTP configuration
pub type SmtpConfig {
  SmtpConfig(
    host: String,
    port: Int,
    username: String,
    password: String,
    from_email: String,
    from_name: String,
  )
}

/// Email message
pub type Email {
  Email(
    to: String,
    subject: String,
    html_body: String,
    text_body: Option(String),
  )
}

/// Email sending result
pub type EmailError {
  ConfigError(String)
  NetworkError(String)
  SmtpError(String)
}

// ============================================================================
// Configuration
// ============================================================================

/// Get SMTP configuration from environment variables
pub fn get_config() -> Result(SmtpConfig, EmailError) {
  let host =
    env.get_string("SMTP_HOST")
    |> result.unwrap("sandbox.smtp.mailtrap.io")

  let port =
    env.get_string("SMTP_PORT")
    |> result.map(string.to_int)
    |> result.flatten()
    |> result.unwrap(2525)

  let username = env.get_string("SMTP_USERNAME")
  let password = env.get_string("SMTP_PASSWORD")

  let from_email =
    env.get_string("SMTP_FROM_EMAIL")
    |> result.unwrap("noreply@mealplanner.app")

  let from_name =
    env.get_string("SMTP_FROM_NAME")
    |> result.unwrap("Meal Planner")

  case username, password {
    Ok(user), Ok(pass) ->
      Ok(SmtpConfig(
        host: host,
        port: port,
        username: user,
        password: pass,
        from_email: from_email,
        from_name: from_name,
      ))

    Error(_), _ -> Error(ConfigError("SMTP_USERNAME not configured"))
    _, Error(_) -> Error(ConfigError("SMTP_PASSWORD not configured"))
  }
}

/// Create a default config for testing (uses Mailtrap sandbox)
pub fn test_config(username: String, password: String) -> SmtpConfig {
  SmtpConfig(
    host: "sandbox.smtp.mailtrap.io",
    port: 2525,
    username: username,
    password: password,
    from_email: "test@mealplanner.app",
    from_name: "Meal Planner Test",
  )
}

// ============================================================================
// Email Sending (HTTP API Approach)
// ============================================================================

/// Send an email using Mailtrap HTTP API
/// This is simpler than raw SMTP and works well for Gleam
pub fn send_email(config: SmtpConfig, email: Email) -> Result(Nil, EmailError) {
  // For Mailtrap, we can use their HTTP API which is much simpler than SMTP
  // https://api-docs.mailtrap.io/docs/mailtrap-api-docs/b3A6MjgxMzk5MjY-send-email

  let api_url = "https://send.api.mailtrap.io/api/send"

  let json_body =
    json.object([
      #(
        "from",
        json.object([
          #("email", json.string(config.from_email)),
          #("name", json.string(config.from_name)),
        ]),
      ),
      #(
        "to",
        json.array(
          [
            json.object([#("email", json.string(email.to))]),
          ],
          json.identity,
        ),
      ),
      #("subject", json.string(email.subject)),
      #("html", json.string(email.html_body)),
      #("text", case email.text_body {
        Some(text) -> json.string(text)
        None -> json.string(strip_html_simple(email.html_body))
      }),
    ])
    |> json.to_string()

  case
    request.to(api_url)
    |> result.map(fn(req) {
      req
      |> request.set_method(http.Post)
      |> request.set_header("Content-Type", "application/json")
      |> request.set_header("Authorization", "Bearer " <> config.password)
      |> request.set_body(json_body)
    })
    |> result.try(httpc.send)
  {
    Error(_) -> Error(NetworkError("Failed to connect to email API"))
    Ok(response) ->
      case response.status {
        200 -> Ok(Nil)
        401 -> Error(SmtpError("Authentication failed - check API token"))
        400 -> Error(SmtpError("Invalid email format"))
        status ->
          Error(SmtpError("Email API returned status " <> int.to_string(status)))
      }
  }
}

/// Send email with default config from environment
pub fn send_email_with_env(email: Email) -> Result(Nil, EmailError) {
  use config <- result.try(get_config())
  send_email(config, email)
}

/// Create a simple email (just to, subject, and HTML body)
pub fn new_email(to: String, subject: String, html_body: String) -> Email {
  Email(to: to, subject: subject, html_body: html_body, text_body: None)
}

/// Create an email with both HTML and plain text versions
pub fn new_email_with_text(
  to: String,
  subject: String,
  html_body: String,
  text_body: String,
) -> Email {
  Email(
    to: to,
    subject: subject,
    html_body: html_body,
    text_body: Some(text_body),
  )
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Very simple HTML tag stripper for plain text fallback
/// This is a basic implementation - just removes <tags>
fn strip_html_simple(html: String) -> String {
  html
  |> string.replace("<br>", "\n")
  |> string.replace("<br/>", "\n")
  |> string.replace("<br />", "\n")
  |> string.replace("</p>", "\n\n")
  |> string.replace("</div>", "\n")
  |> string.replace("</li>", "\n")
  // Remove all remaining HTML tags
  |> remove_tags("")
}

fn remove_tags(html: String, acc: String) -> String {
  case string.split_once(html, "<") {
    Error(_) -> acc <> html
    Ok(#(before, after)) ->
      case string.split_once(after, ">") {
        Error(_) -> acc <> before
        Ok(#(_, rest)) -> remove_tags(rest, acc <> before)
      }
  }
}

// ============================================================================
// For Testing
// ============================================================================

/// Format email error as string for logging
pub fn format_error(error: EmailError) -> String {
  case error {
    ConfigError(msg) -> "Email configuration error: " <> msg
    NetworkError(msg) -> "Email network error: " <> msg
    SmtpError(msg) -> "Email SMTP error: " <> msg
  }
}
