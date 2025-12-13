# Email Notification System

This document describes the email notification system implemented for meal-planner.

## Overview

The email notification system provides automated nutrition summary and alert emails using:
- **Mailtrap** for testing (sandbox environment)
- **HTML email templates** with inline CSS for compatibility
- **OTP actor-based scheduler** for periodic tasks
- **PostgreSQL queries** for weekly nutrition summaries

## Components

### 1. Email Templates (`ui/email_templates.gleam`)

Renders HTML emails with inline CSS for maximum email client compatibility.

**Functions:**
- `render_weekly_email(summary: WeeklySummary) -> String`
  - Renders a weekly nutrition summary with:
    - Total meals logged
    - Average daily macros (protein, fat, carbs, calories)
    - Top 10 foods consumed
    - Professional gradient header design
    - Responsive card-based layout

- `render_ncp_alert_email(current: Macros, target: Macros, deficit: Macros) -> String`
  - Renders a nutrition compliance alert when macros are significantly off target
  - Shows current vs target comparison table
  - Provides specific recommendations based on deficits

### 2. SMTP Client (`integrations/smtp_client.gleam`)

Handles email sending via Mailtrap HTTP API (simpler than raw SMTP).

**Configuration (Environment Variables):**
```bash
SMTP_HOST=sandbox.smtp.mailtrap.io           # Mailtrap sandbox
SMTP_PORT=2525                                # Mailtrap port
SMTP_USERNAME=<your-mailtrap-username>        # From Mailtrap dashboard
SMTP_PASSWORD=<your-mailtrap-api-token>       # API token (not password!)
SMTP_FROM_EMAIL=noreply@mealplanner.app      # Sender email
SMTP_FROM_NAME="Meal Planner"                 # Sender name
```

**Functions:**
- `send_email(config: SmtpConfig, email: Email) -> Result(Nil, EmailError)`
  - Sends email via Mailtrap HTTP API
  - Returns `Ok(Nil)` on success or `Error(EmailError)` on failure

- `send_email_with_env(email: Email) -> Result(Nil, EmailError)`
  - Convenience function that reads config from environment variables

- `new_email(to, subject, html_body) -> Email`
  - Creates an email message

- `format_error(error: EmailError) -> String`
  - Formats errors for logging

### 3. Weekly Summary Query (`storage/logs/summaries.gleam`)

Already implemented - provides nutrition data aggregation.

**Function:**
- `get_weekly_summary(conn, user_id, start_date) -> Result(WeeklySummary, StorageError)`
  - Fetches logs for 7 days starting from `start_date`
  - Aggregates total logs, average macros
  - Groups by food with individual averages

### 4. Scheduler Actor (`actors/scheduler_actor.gleam`)

OTP actor that runs periodic checks and sends emails.

**Functions:**
- `start(db_conn, user_id, user_email) -> Result(Subject(Message), StartError)`
  - Starts the scheduler actor
  - Wakes every hour to check if it's time to send emails

- `trigger_weekly_summary(scheduler) -> Nil`
  - Manually triggers a weekly summary email (useful for testing)

- `trigger_ncp_alert(scheduler, current, target) -> Nil`
  - Manually triggers an NCP alert email

- `stop(scheduler) -> Nil`
  - Stops the scheduler actor

**Messages:**
- `CheckSchedule` - Periodic check (every hour)
- `SendWeeklySummary` - Trigger weekly email
- `SendNcpAlert(current, target)` - Trigger NCP alert
- `Stop` - Shutdown actor

## Usage Examples

### Send a Test Weekly Summary

```gleam
import meal_planner/integrations/smtp_client
import meal_planner/storage
import meal_planner/ui/email_templates

// Configure SMTP (or use environment variables)
let config = smtp_client.test_config("mailtrap_user", "mailtrap_token")

// Get weekly summary from database
let summary = storage.get_weekly_summary(conn, user_id: 1, start_date: "2025-12-06")

case summary {
  Ok(data) -> {
    // Render HTML
    let html = email_templates.render_weekly_email(data)

    // Create email
    let email = smtp_client.new_email(
      "user@example.com",
      "Your Weekly Nutrition Summary",
      html
    )

    // Send
    case smtp_client.send_email(config, email) {
      Ok(_) -> io.println("Email sent!")
      Error(err) -> io.println("Failed: " <> smtp_client.format_error(err))
    }
  }
  Error(_) -> io.println("Failed to fetch summary")
}
```

### Start the Scheduler Actor

```gleam
import meal_planner/actors/scheduler_actor

// Start scheduler
let scheduler = scheduler_actor.start(
  db_conn: conn,
  user_id: 1,
  user_email: "user@example.com"
)

case scheduler {
  Ok(actor) -> {
    // Scheduler is now running
    // It will check every hour and send weekly summaries on Sundays at 8 PM

    // To manually trigger an email:
    scheduler_actor.trigger_weekly_summary(actor)

    // To stop:
    scheduler_actor.stop(actor)
  }
  Error(_) -> io.println("Failed to start scheduler")
}
```

### Send an NCP Alert

```gleam
import meal_planner/types.{Macros}
import meal_planner/actors/scheduler_actor

let current = Macros(protein: 100.0, fat: 40.0, carbs: 150.0)
let target = Macros(protein: 150.0, fat: 60.0, carbs: 200.0)

scheduler_actor.trigger_ncp_alert(scheduler, current, target)
```

## Testing

### Unit Tests

```bash
cd gleam
gleam test --target erlang
```

Tests are located in `test/meal_planner/email_notifications_test.gleam`:
- Email template rendering
- SMTP configuration
- Error handling
- Email creation

### Manual Integration Test with Mailtrap

1. Sign up for a free Mailtrap account at https://mailtrap.io
2. Create an inbox in the Mailtrap dashboard
3. Copy the SMTP credentials (use the HTTP API token, not SMTP password)
4. Set environment variables:

```bash
export SMTP_USERNAME="your-mailtrap-username"
export SMTP_PASSWORD="your-mailtrap-api-token"
```

5. Uncomment and run the integration test in `email_notifications_test.gleam`

6. Check your Mailtrap inbox to see the email

## Production Deployment

For production, replace Mailtrap with a real SMTP provider:

### Option 1: SendGrid
```bash
export SMTP_HOST=smtp.sendgrid.net
export SMTP_PORT=587
export SMTP_USERNAME=apikey
export SMTP_PASSWORD=<your-sendgrid-api-key>
```

### Option 2: Amazon SES
```bash
export SMTP_HOST=email-smtp.us-east-1.amazonaws.com
export SMTP_PORT=587
export SMTP_USERNAME=<your-ses-smtp-username>
export SMTP_PASSWORD=<your-ses-smtp-password>
```

### Option 3: Gmail (for testing only, not recommended for production)
```bash
export SMTP_HOST=smtp.gmail.com
export SMTP_PORT=587
export SMTP_USERNAME=your-email@gmail.com
export SMTP_PASSWORD=<app-specific-password>  # Not your regular password!
```

## Architecture Decisions

### Why Mailtrap HTTP API instead of raw SMTP?

1. **Simpler** - HTTP API is easier to work with than SMTP protocol
2. **Better error messages** - HTTP status codes are more descriptive
3. **No FFI required** - Pure Gleam using `gleam/httpc`
4. **Same API** - Mailtrap HTTP API works identically in sandbox and production

### Why OTP Actor for Scheduling?

1. **Fault tolerance** - Actors can be supervised and restarted
2. **State management** - Actor maintains schedule state
3. **Erlang/OTP** integration - Native to the BEAM platform
4. **Manual triggers** - Easy to test by sending messages

### Why Weekly Summaries on Sundays at 8 PM?

- End of week review is common practice
- Evening timing allows users to plan for the upcoming week
- Configurable via the scheduler state if needed

## Bead References

- `meal-planner-i96s`: Email template function
- `meal-planner-ji68`: SMTP wrapper module
- `meal-planner-mvjz`: Weekly summary storage query (already existed)
- `meal-planner-agy7`: Scheduler actor module
- `meal-planner-atfe`: Wire scheduler to email sending
- `meal-planner-2ux0`: SMTP email sending implementation
- `meal-planner-bn3`: Complete email notifications feature (parent epic)

## Future Enhancements

1. **Personalized recommendations** - Based on user goals and activity level
2. **Micronutrient tracking** - Include vitamin/mineral summaries in emails
3. **Recipe suggestions** - Recommend recipes based on macro needs
4. **Customizable schedule** - Allow users to choose email frequency and timing
5. **Unsubscribe links** - Allow users to opt out of certain email types
6. **Email preferences** - HTML vs plain text, digest vs individual alerts
7. **Mobile-optimized templates** - Better responsive design for mobile email clients
