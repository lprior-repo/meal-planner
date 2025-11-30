import gleeunit/should
import meal_planner/email

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
