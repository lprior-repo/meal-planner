# Security Audit Report: Email Feedback Loop
**Phase**: meal-planner-aejt Phase 3
**Date**: 2025-12-19
**Scope**: Email command processing system (`src/meal_planner/email/`)
**Auditor**: Security Specialist Agent

---

## Executive Summary

**CRITICAL SECURITY FINDING**: The email feedback loop has **NO AUTHENTICATION** or **AUTHORIZATION** controls. Any email containing `@Claude` can execute commands to modify meal plans, preferences, and dietary data.

**Risk Level**: 🔴 **HIGH** (Exploitability: TRIVIAL, Impact: HIGH)

**Immediate Action Required**: Implement sender verification before production deployment.

---

## Vulnerability Summary

### 🔴 HIGH Severity

1. **No Email Sender Verification** (CRITICAL)
2. **Missing User ID Context** (CRITICAL)
3. **Hardcoded Recipe ID Fallback** (CRITICAL)
4. **Missing Rate Limiting** (HIGH)
5. **No Webhook Endpoint Route** (HIGH - Deployment Blocker)

### 🟡 MEDIUM Severity

6. **Limited Input Sanitization** (MEDIUM)
7. **Error Message Information Disclosure** (MEDIUM)

### 🟢 LOW Severity

8. **Missing CSRF Protection** (LOW - webhook context)
9. **No Request Logging** (LOW)

---

## Detailed Vulnerability Analysis

### 🔴 1. No Email Sender Verification (CRITICAL)

**Location**: `src/meal_planner/email/parser.gleam:22-30`
**Issue**: Parser only checks for `@Claude` mention, not sender identity.

```gleam
pub fn parse_email_command(email: EmailRequest) -> Result(...) {
  let EmailRequest(_, _, body, _) = email  // from_email IGNORED!
  let body_lower = string.lowercase(body)
  case string.contains(body_lower, "@claude") {
    False -> Error(InvalidCommand(reason: "No @Claude mention found"))
    True -> parse_command_body(body)  // ⚠️ NO SENDER CHECK
  }
}
```

**Exploit Scenario**:
```
From: attacker@evil.com
To: lewis@meal-planner.com
Body: @Claude adjust Friday dinner to pizza
```
Result: Attacker modifies Lewis's meal plan.

**Risk Assessment**:
- **Exploitability**: TRIVIAL - Send email with `@Claude`
- **Impact**: HIGH - Full meal plan manipulation
- **Attack Vector**: Email spoofing (trivial)
- **Data at Risk**: Meal plans, dietary preferences, dislike lists

**Remediation**:
```gleam
// Add to parser.gleam
const allowed_sender_domain = "lewis@yourdomain.com"

pub fn parse_email_command(email: EmailRequest) -> Result(...) {
  let EmailRequest(from_email, _, body, _) = email

  // Step 1: Validate sender
  case validate_sender(from_email) {
    Error(_) -> Error(InvalidCommand(reason: "Unauthorized sender"))
    Ok(_) -> {
      // Step 2: Check @Claude mention
      let body_lower = string.lowercase(body)
      case string.contains(body_lower, "@claude") {
        False -> Error(InvalidCommand(reason: "No @Claude mention found"))
        True -> parse_command_body(body)
      }
    }
  }
}

fn validate_sender(from_email: String) -> Result(Nil, Nil) {
  case string.contains(from_email, allowed_sender_domain) {
    True -> Ok(Nil)
    False -> Error(Nil)
  }
}
```

**Test Plan**:
```gleam
// test/meal_planner/email/parser_test.gleam
pub fn test_rejects_external_sender() {
  let email = EmailRequest(
    from_email: "attacker@evil.com",
    subject: "Meal change",
    body: "@Claude adjust Friday dinner to pasta",
    is_reply: False,
  )

  let result = parser.parse_email_command(email)

  result
  |> should.be_error()
  |> should.equal(InvalidCommand(reason: "Unauthorized sender"))
}

pub fn test_accepts_authorized_sender() {
  let email = EmailRequest(
    from_email: "lewis@yourdomain.com",
    subject: "Meal change",
    body: "@Claude adjust Friday dinner to pasta",
    is_reply: False,
  )

  let result = parser.parse_email_command(email)

  result
  |> should.be_ok()
}
```

**Time to Fix**: 30 minutes
**Blocking**: YES - Must fix before production

---

### 🔴 2. Missing User ID Context (CRITICAL)

**Location**: `src/meal_planner/email/executor.gleam:25-42`
**Issue**: Executor receives no `user_id`, cannot scope database operations.

```gleam
pub fn execute_command(
  command: EmailCommand,
  conn: pog.Connection,
  // ⚠️ MISSING: user_id: UserId
) -> CommandExecutionResult {
  // TODO implementations have no user context
  // Cannot scope queries to specific user!
}
```

**Risk Assessment**:
- **Exploitability**: HIGH (if multi-user)
- **Impact**: CRITICAL - Data isolation breach
- **Attack Vector**: Cross-user data access
- **Data at Risk**: All user meal plans, preferences

**Remediation**:
```gleam
// Update executor signature
pub fn execute_command(
  command: EmailCommand,
  user_id: UserId,  // ⚠️ ADD THIS
  conn: pog.Connection,
) -> CommandExecutionResult {
  case command {
    AdjustMeal(day, meal_type, recipe_id) ->
      execute_adjust_meal(user_id, day, meal_type, recipe_id, conn)
    AddPreference(preference) ->
      execute_add_preference(user_id, preference, conn)
    // ... etc
  }
}

// Example updated handler
fn execute_adjust_meal(
  user_id: UserId,
  day: DayOfWeek,
  meal_type: MealType,
  recipe_id: RecipeId,
  conn: pog.Connection,
) -> CommandExecutionResult {
  // SQL: WHERE user_id = $1 AND day = $2 AND meal_type = $3
  // Prevents cross-user modification
}
```

**Database Query Pattern** (when implemented):
```sql
-- BAD (no user scoping)
UPDATE meal_plans
SET recipe_id = $1
WHERE day = $2 AND meal_type = $3;

-- GOOD (user scoped)
UPDATE meal_plans
SET recipe_id = $1
WHERE user_id = $2 AND day = $3 AND meal_type = $4;
```

**Test Plan**:
```gleam
pub fn test_user_isolation() {
  let user_a = id.user_id("user-a")
  let user_b = id.user_id("user-b")

  // User A adjusts meal
  let cmd = AdjustMeal(Monday, Dinner, recipe_id("pasta"))
  let _ = executor.execute_command(cmd, user_a, conn)

  // Verify User B's plan unchanged
  let user_b_plan = get_meal_plan(user_b, Monday, conn)
  user_b_plan.dinner
  |> should.not_equal(recipe_id("pasta"))
}
```

**Time to Fix**: 1 hour
**Blocking**: YES - Critical for multi-user support

---

### 🔴 3. Hardcoded Recipe ID Fallback (CRITICAL)

**Location**: `src/meal_planner/email/parser.gleam:102-107`
**Issue**: Parser falls back to `"recipe-123"` if parsing fails.

```gleam
fn extract_recipe_from_body(body: String) -> id.RecipeId {
  case string.split(body, " to ") {
    [_, recipe_name] -> id.recipe_id(string.trim(recipe_name))
    _ -> id.recipe_id("recipe-123")  // ⚠️ DANGEROUS FALLBACK
  }
}
```

**Risk Assessment**:
- **Exploitability**: MEDIUM (malformed commands)
- **Impact**: HIGH - Incorrect meal assignments
- **Attack Vector**: Malformed adjust commands
- **Data at Risk**: Meal plan integrity

**Exploit Scenario**:
```
Input: "@Claude adjust Friday dinner"
Result: Assigns "recipe-123" (likely doesn't exist or wrong recipe)
```

**Remediation**:
```gleam
fn extract_recipe_from_body(body: String) -> Result(id.RecipeId, String) {
  case string.split(body, " to ") {
    [_, recipe_name] -> {
      let trimmed = string.trim(recipe_name)
      case string.length(trimmed) > 0 {
        True -> Ok(id.recipe_id(trimmed))
        False -> Error("Missing recipe name")
      }
    }
    _ -> Error("Could not parse recipe from command")
  }
}

// Update caller
fn parse_adjust_arguments(...) -> Result(...) {
  let remaining = list.drop(words, adjust_idx + 1)
  case remaining {
    [day_str, meal_str, ..] -> {
      let day_result = day_of_week_from_string(day_str)
      let meal_result = string_to_meal_type(meal_str)

      use recipe_id <- result.try(extract_recipe_from_body(body))
      build_adjust_command(day_result, meal_result, recipe_id)
    }
    _ -> Error(InvalidCommand(reason: "Missing day or meal type"))
  }
}
```

**Test Plan**:
```gleam
pub fn test_rejects_malformed_adjust() {
  let email = EmailRequest(
    from_email: "lewis@domain.com",
    subject: "Test",
    body: "@Claude adjust Friday dinner",  // Missing recipe!
    is_reply: False,
  )

  let result = parser.parse_email_command(email)

  result
  |> should.be_error()
  |> should.equal(InvalidCommand(reason: "Could not parse recipe from command"))
}
```

**Time to Fix**: 20 minutes
**Blocking**: YES - Data integrity risk

---

### 🔴 4. Missing Rate Limiting (HIGH)

**Location**: `src/meal_planner/email/handler.gleam:52-105` (webhook endpoint)
**Issue**: No rate limiting on webhook endpoint.

**Risk Assessment**:
- **Exploitability**: MEDIUM (requires email access)
- **Impact**: MEDIUM - Spam/DoS, cost escalation
- **Attack Vector**: Email flood
- **Data at Risk**: Service availability, costs

**Exploit Scenario**:
```bash
# Attacker floods webhook
for i in {1..1000}; do
  curl -X POST https://api/email/webhook \
    -d '{"from":"lewis@domain.com","body":"@Claude regenerate week"}'
done
```

**Remediation Options**:

**Option A: In-Memory Rate Limiter** (Simple, stateless)
```gleam
import gleam/erlang/process
import gleam/dict

// Rate limiter actor (holds state)
type RateLimiterState {
  RateLimiterState(
    requests: dict.Dict(String, #(Int, Int)),  // email -> (count, timestamp)
    max_per_hour: Int,
  )
}

pub fn check_rate_limit(email: String) -> Result(Nil, String) {
  // Check if email has exceeded limit
  // Return Error("Rate limit exceeded") if over threshold
}
```

**Option B: Database-Backed** (Persistent, multi-instance safe)
```sql
CREATE TABLE email_rate_limits (
  sender_email TEXT PRIMARY KEY,
  request_count INTEGER DEFAULT 0,
  window_start TIMESTAMP DEFAULT NOW()
);

-- Query: Check and increment
UPDATE email_rate_limits
SET request_count = request_count + 1
WHERE sender_email = $1
  AND window_start > NOW() - INTERVAL '1 hour'
RETURNING request_count;
```

**Recommended Limits**:
- **10 commands per hour per sender** (prevents spam)
- **50 commands per day per sender** (generous for legitimate use)

**Test Plan**:
```gleam
pub fn test_rate_limit_enforcement() {
  let email = "lewis@domain.com"

  // Send 11 commands in quick succession
  list.range(1, 11)
  |> list.each(fn(_) {
    let cmd = EmailRequest(...)
    let result = handler.handle_email_webhook(cmd)
    // First 10 should succeed, 11th should fail
  })
}
```

**Time to Fix**: 2-4 hours (depending on approach)
**Blocking**: MEDIUM - Can deploy with monitoring, add later

---

### 🔴 5. No Webhook Endpoint Route (HIGH - Deployment Blocker)

**Location**: `src/meal_planner/web/routes/*.gleam`
**Issue**: `handle_email_webhook` exists but is NOT ROUTED.

**Finding**:
```gleam
// handler.gleam defines it
pub fn handle_email_webhook(req: wisp.Request) -> wisp.Response { ... }

// But NO route in routes/*.gleam!
// Checked: misc.gleam, auth.gleam, nutrition.gleam, etc.
// POST /api/email/webhook → 404
```

**Risk Assessment**:
- **Exploitability**: N/A (feature doesn't work)
- **Impact**: HIGH - Feature non-functional
- **Attack Vector**: N/A
- **Data at Risk**: None (endpoint unreachable)

**Remediation**:

**Option A: Add to misc.gleam**
```gleam
// src/meal_planner/web/routes/misc.gleam
pub fn route(req, segments, ctx) -> Option(wisp.Response) {
  case segments {
    // ... existing routes ...

    ["api", "email", "webhook"] -> {
      case req.method {
        Post -> Some(email_handler.handle_email_webhook(req))
        _ -> Some(wisp.method_not_allowed([Post]))
      }
    }

    _ -> None
  }
}
```

**Option B: Create dedicated email router**
```gleam
// src/meal_planner/web/routes/email.gleam
import meal_planner/email/handler
import wisp

pub fn route(req, segments, ctx) -> Option(wisp.Response) {
  case segments {
    ["api", "email", "webhook"] -> {
      case req.method {
        Post -> Some(handler.handle_email_webhook(req))
        _ -> Some(wisp.method_not_allowed([Post]))
      }
    }
    _ -> None
  }
}

// Update web/routes.gleam to include email.route(...)
```

**Test Plan**:
```bash
# Manual test
curl -X POST http://localhost:8000/api/email/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "from": "lewis@domain.com",
    "subject": "Test",
    "body": "@Claude skip breakfast Monday",
    "is_reply": false
  }'

# Expected: 200 OK with parsed command
# Current: 404 Not Found
```

**Time to Fix**: 10 minutes
**Blocking**: YES - Feature non-functional without route

---

### 🟡 6. Limited Input Sanitization (MEDIUM)

**Location**: `src/meal_planner/email/parser.gleam` (various functions)
**Issue**: String parsing lacks sanitization for edge cases.

**Risk Assessment**:
- **Exploitability**: LOW (limited injection surface)
- **Impact**: MEDIUM - Parsing errors, potential command injection
- **Attack Vector**: Malicious input strings
- **Data at Risk**: Command parsing integrity

**Example Issues**:
```gleam
// No length limits
fn extract_after_word(body: String, word: String) -> Option(String) {
  case string.split(body, word) {
    [_, after] -> Some(string.trim(after))
    // ⚠️ What if 'after' is 10MB of text?
    _ -> None
  }
}

// No validation on constraint values
fn extract_regeneration_constraints(body: String) -> Option(String) {
  case string.contains(body, "high protein") {
    True -> Some("high_protein")  // Hardcoded, safe
    False -> ...
  }
  // But what if we add free-form constraints later?
}
```

**Remediation**:
```gleam
const max_input_length = 5000  // 5KB limit for email body
const max_preference_length = 200
const max_food_name_length = 100

fn validate_input_length(text: String, max: Int) -> Result(String, String) {
  case string.length(text) <= max {
    True -> Ok(text)
    False -> Error("Input exceeds maximum length")
  }
}

// Update parser entry point
pub fn parse_email_command(email: EmailRequest) -> Result(...) {
  let EmailRequest(from_email, _, body, _) = email

  // Validate body length
  use validated_body <- result.try(
    validate_input_length(body, max_input_length)
    |> result.map_error(fn(_) {
      InvalidCommand(reason: "Email body too large")
    })
  )

  // ... continue parsing
}
```

**Test Plan**:
```gleam
pub fn test_rejects_oversized_body() {
  let huge_body = string.repeat("A", 10_000)
  let email = EmailRequest(
    from_email: "lewis@domain.com",
    subject: "Test",
    body: "@Claude " <> huge_body,
    is_reply: False,
  )

  let result = parser.parse_email_command(email)

  result
  |> should.be_error()
}
```

**Time to Fix**: 30 minutes
**Blocking**: NO - Nice to have

---

### 🟡 7. Error Message Information Disclosure (MEDIUM)

**Location**: `src/meal_planner/email/handler.gleam:78-89`
**Issue**: Error messages may leak internal details.

```gleam
Error(error_msg) -> {
  let response = EmailWebhookResponse(
    success: False,
    command: None,
    error: Some(error_to_string(error_msg)),  // ⚠️ Exposes internal errors
    message: "Failed to parse email command",
  )
  encode_webhook_response(response)
  |> json.to_string
  |> wisp.json_response(400)
}
```

**Risk Assessment**:
- **Exploitability**: LOW (limited info)
- **Impact**: LOW - Minor info leak
- **Attack Vector**: Error probing
- **Data at Risk**: System internals

**Example Leak**:
```json
{
  "success": false,
  "error": "InvalidCommand: Database connection failed at executor.gleam:42",
  "message": "Failed to parse email command"
}
```

**Remediation**:
```gleam
fn sanitize_error_message(error: EmailCommandError) -> String {
  case error {
    InvalidCommand(reason: reason) -> {
      // Log full error internally
      wisp.log_error("Email command error: " <> reason)

      // Return sanitized message to client
      case string.contains(reason, "Database") {
        True -> "Internal server error"
        False -> "Invalid command format"
      }
    }
    _ -> "Command processing failed"
  }
}
```

**Test Plan**:
```gleam
pub fn test_sanitizes_internal_errors() {
  // Simulate DB error
  let email = EmailRequest(...)
  let response = handler.handle_email_webhook(email)

  // Parse JSON response
  let body = response.body

  // Assert: No stack traces, file paths, or internal details
  body
  |> should.not_contain("gleam:")
  |> should.not_contain("Database")
}
```

**Time to Fix**: 15 minutes
**Blocking**: NO - Low risk

---

## Additional Security Considerations

### 8. Missing CSRF Protection (LOW)

**Status**: Low priority for webhook endpoint
**Reason**: Webhooks receive POST from external email service, not browser
**Action**: Monitor if endpoint is ever called from browser client

### 9. No Request Logging (LOW)

**Issue**: No audit trail of email commands
**Remediation**: Add structured logging

```gleam
pub fn handle_email_webhook(req: wisp.Request) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_webhook_payload(body) {
    Ok(payload) -> {
      // ⚠️ ADD LOGGING
      wisp.log_info(
        "Email webhook received from: "
        <> payload.from
        <> " | Subject: "
        <> payload.subject
      )

      // ... continue processing
    }
  }
}
```

**Benefits**:
- Audit trail for security investigations
- Detect anomalous patterns (spam, attacks)
- Debugging production issues

**Time to Add**: 10 minutes

---

## Risk Matrix

| Vulnerability | Exploitability | Impact | Risk | Blocking |
|--------------|----------------|---------|------|----------|
| No sender verification | TRIVIAL | HIGH | 🔴 CRITICAL | YES |
| Missing user_id | HIGH | CRITICAL | 🔴 CRITICAL | YES |
| Hardcoded recipe fallback | MEDIUM | HIGH | 🔴 HIGH | YES |
| No rate limiting | MEDIUM | MEDIUM | 🔴 HIGH | PARTIAL |
| Missing route | N/A | HIGH | 🔴 HIGH | YES |
| Limited sanitization | LOW | MEDIUM | 🟡 MEDIUM | NO |
| Error disclosure | LOW | LOW | 🟡 MEDIUM | NO |

---

## Remediation Roadmap

### Phase 1: Critical Fixes (PRE-DEPLOYMENT - BLOCKING)
**Time Estimate**: 2 hours

1. **Add webhook route** (10 min)
   - File: `src/meal_planner/web/routes/misc.gleam`
   - Action: Add `["api", "email", "webhook"]` case

2. **Implement sender validation** (30 min)
   - File: `src/meal_planner/email/parser.gleam`
   - Action: Add `validate_sender()` function
   - Test: `test_rejects_external_sender()`

3. **Add user_id to executor** (1 hour)
   - Files: `executor.gleam`, `handler.gleam`, `types.gleam`
   - Action: Thread `user_id` through command execution
   - Test: `test_user_isolation()`

4. **Fix hardcoded recipe fallback** (20 min)
   - File: `parser.gleam`
   - Action: Return `Result` instead of fallback
   - Test: `test_rejects_malformed_adjust()`

### Phase 2: High Priority (POST-DEPLOYMENT - URGENT)
**Time Estimate**: 3 hours

5. **Implement rate limiting** (2-4 hours)
   - Approach: Database-backed (persistent)
   - Files: New `rate_limiter.gleam`, migration SQL
   - Test: `test_rate_limit_enforcement()`

6. **Add input sanitization** (30 min)
   - File: `parser.gleam`
   - Action: Add length limits, validation
   - Test: `test_rejects_oversized_body()`

### Phase 3: Nice to Have (ONGOING)
**Time Estimate**: 1 hour

7. **Sanitize error messages** (15 min)
8. **Add request logging** (10 min)
9. **Add security monitoring** (30 min)
   - Metrics: Failed auth attempts, rate limit hits
   - Alerts: Suspicious patterns

---

## Testing Strategy

### Unit Tests
```bash
# Create test file
touch test/meal_planner/email/security_test.gleam
```

```gleam
// test/meal_planner/email/security_test.gleam
import gleeunit/should
import meal_planner/email/parser
import meal_planner/types.{EmailRequest, InvalidCommand}

pub fn test_unauthorized_sender_rejected() {
  let email = EmailRequest(
    from_email: "attacker@evil.com",
    subject: "Hacking attempt",
    body: "@Claude adjust Friday dinner to pizza",
    is_reply: False,
  )

  let result = parser.parse_email_command(email)

  result
  |> should.be_error()
  |> should.equal(InvalidCommand(reason: "Unauthorized sender"))
}

pub fn test_authorized_sender_accepted() {
  let email = EmailRequest(
    from_email: "lewis@yourdomain.com",
    subject: "Legit request",
    body: "@Claude adjust Friday dinner to pasta",
    is_reply: False,
  )

  let result = parser.parse_email_command(email)

  result
  |> should.be_ok()
}

pub fn test_rate_limit_enforced() {
  // Test that 11th request in hour is rejected
}

pub fn test_user_isolation() {
  // Test that user A cannot modify user B's data
}
```

### Integration Tests
```bash
# Test webhook endpoint
curl -X POST http://localhost:8000/api/email/webhook \
  -H "Content-Type: application/json" \
  -d '{"from":"attacker@evil.com","body":"@Claude skip Monday","is_reply":false}'

# Expected: 400 Bad Request, "Unauthorized sender"
```

### Security Regression Tests
```gleam
// Ensure vulnerabilities stay fixed
pub fn test_no_hardcoded_recipe_fallback() {
  // Verify recipe-123 never appears in executor output
}

pub fn test_all_queries_user_scoped() {
  // Verify all SQL queries include user_id filter
}
```

---

## Compliance & Best Practices

### OWASP Top 10 Alignment

| OWASP Category | Status | Compliance |
|----------------|---------|-----------|
| A01: Broken Access Control | 🔴 FAIL | Missing sender verification, user scoping |
| A02: Cryptographic Failures | ✅ PASS | No sensitive data in transit (webhook) |
| A03: Injection | 🟡 PARTIAL | Limited SQL (TODOs), needs validation |
| A04: Insecure Design | 🔴 FAIL | No auth design, missing rate limits |
| A05: Security Misconfiguration | 🔴 FAIL | Verbose errors, no route protection |
| A07: Identification & Auth Failures | 🔴 FAIL | No sender authentication |
| A10: Server-Side Request Forgery | ✅ PASS | No SSRF surface |

### Recommendations for Production

1. **Add HTTPS enforcement** (webhook endpoint)
2. **Implement webhook secret validation** (HMAC signature)
3. **Set up security monitoring** (Sentry, Datadog)
4. **Add IP allowlisting** (restrict to email provider IPs)
5. **Implement audit logging** (all command executions)

---

## Conclusion

The email feedback loop has **5 CRITICAL vulnerabilities** that MUST be fixed before production deployment. The most severe issue is the **complete lack of sender authentication**, allowing any external attacker to modify meal plans via email spoofing.

**Estimated Total Remediation Time**: 6-8 hours
**Blocking Issues**: 5 (all Phase 1 fixes)
**Recommended Action**: Complete Phase 1 before any production deployment

**Next Steps**:
1. Create Beads tasks for each Phase 1 vulnerability
2. Implement fixes in order of severity
3. Run full test suite after each fix
4. Deploy to staging for integration testing
5. Schedule Phase 2 for week 2 post-deployment

---

## Appendix: Attack Scenarios

### Scenario 1: Email Spoofing Attack
```
Attacker: spoofs@evil.com (spoofed as lewis@domain.com)
Command: "@Claude regenerate week with high protein"
Impact: Overwrites Lewis's entire weekly meal plan
Prevention: Sender domain validation (Phase 1, Fix #2)
```

### Scenario 2: Spam Flooding
```
Attacker: Sends 1000 "@Claude regenerate week" emails
Impact: Service degradation, cost escalation
Prevention: Rate limiting (Phase 2, Fix #5)
```

### Scenario 3: Cross-User Modification
```
Attacker: User A sends command to modify User B's data
Impact: Data breach, unauthorized access
Prevention: user_id scoping (Phase 1, Fix #3)
```

### Scenario 4: Recipe Injection
```
Input: "@Claude adjust Friday dinner to <script>alert('xss')</script>"
Impact: Potential XSS if recipe IDs rendered unsafely
Prevention: Input sanitization (Phase 2, Fix #6)
```

---

**Report Version**: 1.0
**Last Updated**: 2025-12-19
**Contact**: Security Specialist Agent (meal-planner-aejt)
