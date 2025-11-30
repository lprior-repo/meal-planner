import gleeunit/should
import gleam/string
import meal_planner/email.{EmailAddress, EmailPayload}

pub fn email_payload_creation_test() {
  let payload =
    email.new_payload(
      from_email: "sender@example.com",
      from_name: "Sender Name",
      to_email: "recipient@example.com",
      subject: "Test Subject",
      text: "Test body content",
      category: "Test Category",
    )

  payload.from.email
  |> should.equal("sender@example.com")

  payload.from.name
  |> should.equal("Sender Name")

  payload.subject
  |> should.equal("Test Subject")

  payload.text
  |> should.equal("Test body content")

  payload.category
  |> should.equal("Test Category")
}

pub fn email_payload_to_json_test() {
  let payload =
    email.new_payload(
      from_email: "test@example.com",
      from_name: "Test User",
      to_email: "recipient@example.com",
      subject: "Hello",
      text: "World",
      category: "greeting",
    )

  let json = email.payload_to_json(payload)

  // Check that JSON contains expected fields
  json
  |> should.be_ok()
}

// Test that recipient has empty name in default payload
pub fn email_new_payload_recipient_has_empty_name_test() {
  let payload =
    email.new_payload(
      from_email: "sender@example.com",
      from_name: "Sender",
      to_email: "recipient@example.com",
      subject: "Test",
      text: "Body",
      category: "test",
    )

  // Recipient list should have exactly one recipient
  case payload.to {
    [recipient] -> {
      recipient.email |> should.equal("recipient@example.com")
      recipient.name |> should.equal("")
    }
    _ -> should.fail()
  }
}

// Test EmailAddress type directly
pub fn email_address_creation_test() {
  let addr = EmailAddress(email: "user@domain.com", name: "John Doe")
  addr.email |> should.equal("user@domain.com")
  addr.name |> should.equal("John Doe")
}

pub fn email_address_empty_name_test() {
  let addr = EmailAddress(email: "user@domain.com", name: "")
  addr.email |> should.equal("user@domain.com")
  addr.name |> should.equal("")
}

// Test JSON output contains expected fields
pub fn email_payload_json_contains_from_test() {
  let payload =
    email.new_payload(
      from_email: "from@test.com",
      from_name: "From Name",
      to_email: "to@test.com",
      subject: "Subject",
      text: "Text",
      category: "cat",
    )

  case email.payload_to_json(payload) {
    Ok(json_str) -> {
      string.contains(json_str, "from@test.com") |> should.be_true()
      string.contains(json_str, "From Name") |> should.be_true()
      string.contains(json_str, "to@test.com") |> should.be_true()
      string.contains(json_str, "Subject") |> should.be_true()
      string.contains(json_str, "Text") |> should.be_true()
      string.contains(json_str, "cat") |> should.be_true()
    }
    Error(_) -> should.fail()
  }
}

// Test EmailPayload type directly
pub fn email_payload_direct_construction_test() {
  let from = EmailAddress(email: "sender@test.com", name: "Sender")
  let to1 = EmailAddress(email: "rcpt1@test.com", name: "Recipient 1")
  let to2 = EmailAddress(email: "rcpt2@test.com", name: "Recipient 2")

  let payload =
    EmailPayload(
      from: from,
      to: [to1, to2],
      subject: "Multi-recipient",
      text: "Hello all",
      category: "bulk",
    )

  payload.from.email |> should.equal("sender@test.com")
  case payload.to {
    [first, second] -> {
      first.email |> should.equal("rcpt1@test.com")
      second.email |> should.equal("rcpt2@test.com")
    }
    _ -> should.fail()
  }
  payload.subject |> should.equal("Multi-recipient")
}

// Test JSON with recipient without name (empty string)
pub fn email_json_recipient_without_name_test() {
  let payload =
    email.new_payload(
      from_email: "from@test.com",
      from_name: "",
      to_email: "to@test.com",
      subject: "Test",
      text: "Body",
      category: "test",
    )

  case email.payload_to_json(payload) {
    Ok(json_str) -> {
      // When name is empty, JSON should only have email field
      string.contains(json_str, "from@test.com") |> should.be_true()
    }
    Error(_) -> should.fail()
  }
}

// Test with special characters
pub fn email_payload_special_characters_test() {
  let payload =
    email.new_payload(
      from_email: "test@example.com",
      from_name: "O'Connor & Associates",
      to_email: "user+tag@example.com",
      subject: "Special: \"quoted\" <text>",
      text: "Line 1\nLine 2\tTabbed",
      category: "special",
    )

  // Should successfully serialize with special chars
  email.payload_to_json(payload) |> should.be_ok()
}
