/// Email webhook handler for processing email commands
///
/// This module provides HTTP endpoints for receiving email webhooks and
/// processing email commands from Lewis. It integrates with the email parser
/// to extract and validate @Claude mentions.
import gleam/dynamic
import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/result

import meal_planner/email/parser
import meal_planner/types.{
  type EmailCommand, type EmailCommandError, EmailRequest, InvalidCommand,
}

import wisp

// =============================================================================
// Email Webhook Request/Response Types
// =============================================================================

/// Webhook payload structure (from email service provider)
pub type EmailWebhookPayload {
  EmailWebhookPayload(
    from: String,
    subject: String,
    body: String,
    is_reply: Bool,
  )
}

/// Response structure for webhook handler
pub type EmailWebhookResponse {
  EmailWebhookResponse(
    success: Bool,
    command: Option(EmailCommand),
    error: Option(String),
    message: String,
  )
}

// =============================================================================
// Main Handler
// =============================================================================

/// Handle incoming email webhook
///
/// POST /api/email/webhook
/// Body: EmailWebhookPayload JSON
/// Response: EmailWebhookResponse JSON
pub fn handle_email_webhook(req: wisp.Request) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_webhook_payload(body) {
    Ok(payload) -> {
      let email =
        EmailRequest(
          from_email: payload.from,
          subject: payload.subject,
          body: payload.body,
          is_reply: payload.is_reply,
        )

      case parser.parse_email_command(email) {
        Ok(command) -> {
          let response =
            EmailWebhookResponse(
              success: True,
              command: Some(command),
              error: None,
              message: "Command parsed successfully",
            )
          encode_webhook_response(response)
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(error_msg) -> {
          let response =
            EmailWebhookResponse(
              success: False,
              command: None,
              error: Some(error_to_string(error_msg)),
              message: "Failed to parse email command",
            )
          encode_webhook_response(response)
          |> json.to_string
          |> wisp.json_response(400)
        }
      }
    }
    Error(msg) -> {
      let response =
        EmailWebhookResponse(
          success: False,
          command: None,
          error: Some(msg),
          message: "Invalid webhook payload",
        )
      encode_webhook_response(response)
      |> json.to_string
      |> wisp.json_response(400)
    }
  }
}

// =============================================================================
// JSON Encoding and Decoding
// =============================================================================

pub fn parse_webhook_payload(
  json_data: dynamic.Dynamic,
) -> Result(EmailWebhookPayload, String) {
  decode.run(json_data, webhook_payload_decoder())
  |> result.map_error(fn(_) { "Invalid webhook payload structure" })
}

fn webhook_payload_decoder() -> decode.Decoder(EmailWebhookPayload) {
  use from <- decode.field("from", decode.string)
  use subject <- decode.field("subject", decode.string)
  use body <- decode.field("body", decode.string)
  use is_reply <- decode.field("is_reply", decode.bool)
  decode.success(EmailWebhookPayload(
    from: from,
    subject: subject,
    body: body,
    is_reply: is_reply,
  ))
}

pub fn encode_webhook_response(response: EmailWebhookResponse) -> json.Json {
  json.object([
    #("success", json.bool(response.success)),
    #("command", encode_command_option(response.command)),
    #("error", encode_string_option(response.error)),
    #("message", json.string(response.message)),
  ])
}

fn encode_command_option(cmd: Option(EmailCommand)) -> json.Json {
  case cmd {
    Some(_) -> json.string("command_parsed")
    None -> json.null()
  }
}

fn encode_string_option(s: Option(String)) -> json.Json {
  case s {
    Some(str) -> json.string(str)
    None -> json.null()
  }
}

fn error_to_string(error: EmailCommandError) -> String {
  case error {
    InvalidCommand(reason: reason) -> "InvalidCommand: " <> reason
    _ -> "Unknown command error"
  }
}
