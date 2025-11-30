import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/json
import gleam/result

/// Represents the sender or recipient of an email
pub type EmailAddress {
  EmailAddress(email: String, name: String)
}

/// Represents the complete email payload structure for Mailtrap API
pub type EmailPayload {
  EmailPayload(
    from: EmailAddress,
    to: List(EmailAddress),
    subject: String,
    text: String,
    category: String,
  )
}

/// Creates a new email payload with a single recipient
pub fn new_payload(
  from_email from_email: String,
  from_name from_name: String,
  to_email to_email: String,
  subject subject: String,
  text text: String,
  category category: String,
) -> EmailPayload {
  EmailPayload(
    from: EmailAddress(email: from_email, name: from_name),
    to: [EmailAddress(email: to_email, name: "")],
    subject: subject,
    text: text,
    category: category,
  )
}

/// Converts an EmailAddress to JSON
fn email_address_to_json(addr: EmailAddress) -> json.Json {
  case addr.name {
    "" -> json.object([#("email", json.string(addr.email))])
    _ ->
      json.object([
        #("email", json.string(addr.email)),
        #("name", json.string(addr.name)),
      ])
  }
}

/// Converts an EmailPayload to JSON string
pub fn payload_to_json(payload: EmailPayload) -> Result(String, Nil) {
  let json_obj =
    json.object([
      #("from", email_address_to_json(payload.from)),
      #("to", json.array(payload.to, of: email_address_to_json)),
      #("subject", json.string(payload.subject)),
      #("text", json.string(payload.text)),
      #("category", json.string(payload.category)),
    ])

  Ok(json.to_string(json_obj))
}

/// Sends an email via the Mailtrap API
pub fn send_email(
  payload: EmailPayload,
  api_token: String,
) -> Result(String, String) {
  // Convert payload to JSON
  use json_body <- result.try(
    payload_to_json(payload)
    |> result.replace_error("Failed to serialize email payload"),
  )

  // Create HTTP request
  let req =
    request.new()
    |> request.set_method(http.Post)
    |> request.set_host("send.api.mailtrap.io")
    |> request.set_path("/api/send")
    |> request.set_header("authorization", "Bearer " <> api_token)
    |> request.set_header("content-type", "application/json")
    |> request.set_body(json_body)

  // Send request
  case httpc.send(req) {
    Ok(resp) ->
      case resp.status {
        200 | 201 | 202 -> Ok(resp.body)
        _ -> Error("HTTP " <> int.to_string(resp.status) <> ": " <> resp.body)
      }
    Error(_) -> Error("Failed to send HTTP request")
  }
}
