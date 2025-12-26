# ERROR RECOVERY - ACTIONABLE RECOMMENDATIONS

## Quick Reference for Implementing Priority Improvements

This document provides **copy-paste ready** code examples for implementing the recommended improvements from the Error Recovery Validation Report.

---

## 1. Add Retry Integration Tests

### File: `test/meal_planner/errors/retry_test.gleam`

```gleam
/// Tests for error recovery and retry mechanisms
import gleeunit
import gleeunit/should
import meal_planner/errors

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Recovery Strategy Tests
// ============================================================================

pub fn network_error_has_retry_strategy_test() {
  let error = errors.NetworkError("Connection timeout")
  let strategy = errors.recovery_strategy(error)

  strategy
  |> should.equal(errors.RetryWithBackoff(max_attempts: 3, backoff_ms: 1000))
}

pub fn database_error_has_longer_retry_test() {
  let error = errors.DatabaseError("select", "Connection failed")
  let strategy = errors.recovery_strategy(error)

  strategy
  |> should.equal(errors.RetryWithBackoff(max_attempts: 5, backoff_ms: 2000))
}

pub fn rate_limit_has_retry_after_test() {
  let error = errors.RateLimitError(60)
  let strategy = errors.recovery_strategy(error)

  strategy
  |> should.equal(errors.RetryAfter(60))
}

pub fn validation_error_has_no_retry_test() {
  let error = errors.ValidationError("email", "Invalid format")
  let strategy = errors.recovery_strategy(error)

  strategy
  |> should.equal(errors.NoRetry)
}

// ============================================================================
// Recoverable Error Classification Tests
// ============================================================================

pub fn network_error_is_recoverable_test() {
  errors.NetworkError("timeout")
  |> errors.is_recoverable
  |> should.be_true
}

pub fn validation_error_is_not_recoverable_test() {
  errors.ValidationError("email", "invalid")
  |> errors.is_recoverable
  |> should.be_false
}

pub fn authentication_error_is_not_recoverable_test() {
  errors.AuthenticationError("Invalid token")
  |> errors.is_recoverable
  |> should.be_false
}

pub fn database_select_is_recoverable_test() {
  errors.DatabaseError("select", "timeout")
  |> errors.is_recoverable
  |> should.be_true
}

pub fn database_insert_is_not_recoverable_test() {
  errors.DatabaseError("insert", "duplicate key")
  |> errors.is_recoverable
  |> should.be_false
}

// ============================================================================
// Error Wrapping and Context Tests
// ============================================================================

pub fn wrapped_error_preserves_recoverability_test() {
  let original = errors.NetworkError("Connection failed")
  let wrapped = errors.wrap_error(original, errors.ServiceError("api", "timeout"))

  wrapped
  |> errors.is_recoverable
  |> should.be_true
}

pub fn add_context_preserves_error_test() {
  let error = errors.DatabaseError("select", "timeout")
  let with_context = errors.add_context(error, "table", "users")

  errors.get_context(with_context, "table")
  |> should.equal(option.Some("users"))
}

pub fn get_root_cause_traverses_chain_test() {
  let cause = errors.NetworkError("DNS failure")
  let error = errors.ServiceError("api", "unreachable")
  let wrapped = errors.wrap_error(cause, error)

  errors.get_root_cause(wrapped)
  |> should.equal(cause)
}

pub fn error_chain_length_counts_correctly_test() {
  let error1 = errors.NetworkError("error1")
  let error2 = errors.wrap_error(error1, errors.ServiceError("api", "error2"))
  let error3 = errors.wrap_error(error2, errors.InternalError("error3"))

  errors.error_chain_length(error3)
  |> should.equal(3)
}
```

---

## 2. Add `is_recoverable()` to Tandoor Error Module

### File: `src/meal_planner/tandoor/core/error.gleam`

Add this function after the existing `error_to_string()` function:

```gleam
/// Determine if an error is recoverable (i.e., retrying might succeed)
///
/// Recoverable errors are typically transient network or server issues.
/// Non-recoverable errors are permanent failures like authentication or validation errors.
///
/// ## Examples
///
/// ```gleam
/// is_recoverable(NetworkError("Connection refused"))  // -> True
/// is_recoverable(TimeoutError)                        // -> True
/// is_recoverable(AuthenticationError)                 // -> False
/// is_recoverable(NotFoundError("Recipe not found"))   // -> False
/// ```
pub fn is_recoverable(error: TandoorError) -> Bool {
  case error {
    // Recoverable - Network and transient errors
    NetworkError(_) -> True
    TimeoutError -> True

    // Recoverable - Server errors (5xx)
    ServerError(status_code, _) if status_code >= 500 -> True

    // Non-recoverable - Client errors (4xx)
    AuthenticationError -> False
    AuthorizationError -> False
    NotFoundError(_) -> False
    BadRequestError(_) -> False

    // Non-recoverable - Parse and unknown errors
    ParseError(_) -> False
    UnknownError(_) -> False

    // Server errors below 500 are not recoverable
    ServerError(_, _) -> False
  }
}

/// Get recovery strategy for a Tandoor error
///
/// Maps errors to appropriate retry strategies.
pub fn recovery_strategy(error: TandoorError) -> RecoveryStrategy {
  case error {
    // Network errors - retry with backoff
    NetworkError(_) | TimeoutError ->
      RetryWithBackoff(max_attempts: 3, backoff_ms: 1000)

    // Server errors - retry with backoff
    ServerError(status, _) if status >= 500 ->
      RetryWithBackoff(max_attempts: 3, backoff_ms: 1000)

    // All other errors - no retry
    _ -> NoRetry
  }
}
```

### File: `test/tandoor/core/error_test.gleam`

Add these tests at the end of the file:

```gleam
// ============================================================================
// Error Recovery Tests
// ============================================================================

pub fn test_network_error_is_recoverable() {
  error.NetworkError("Connection refused")
  |> error.is_recoverable
  |> should.be_true
}

pub fn test_timeout_error_is_recoverable() {
  error.TimeoutError
  |> error.is_recoverable
  |> should.be_true
}

pub fn test_server_error_5xx_is_recoverable() {
  error.ServerError(503, "Service unavailable")
  |> error.is_recoverable
  |> should.be_true
}

pub fn test_server_error_4xx_is_not_recoverable() {
  error.ServerError(400, "Bad request")
  |> error.is_recoverable
  |> should.be_false
}

pub fn test_authentication_error_is_not_recoverable() {
  error.AuthenticationError
  |> error.is_recoverable
  |> should.be_false
}

pub fn test_not_found_error_is_not_recoverable() {
  error.NotFoundError("Recipe not found")
  |> error.is_recoverable
  |> should.be_false
}

pub fn test_parse_error_is_not_recoverable() {
  error.ParseError("Invalid JSON")
  |> error.is_recoverable
  |> should.be_false
}
```

---

## 3. Health Check Degradation Tests

### File: `test/meal_planner/web/handlers/health_test.gleam`

```gleam
/// Tests for health check handler and graceful degradation
import gleeunit
import gleeunit/should
import meal_planner/web/handlers/health

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Component Status Tests
// ============================================================================

pub fn healthy_component_status_test() {
  let check = health.HealthCheck(
    status: health.Healthy,
    message: "Component operational",
    details: option.None,
  )

  check.status
  |> should.equal(health.Healthy)
}

pub fn degraded_component_status_test() {
  let check = health.HealthCheck(
    status: health.Degraded,
    message: "Component degraded",
    details: option.Some("High latency detected"),
  )

  check.status
  |> should.equal(health.Degraded)
}

// ============================================================================
// Status Aggregation Tests
// ============================================================================

pub fn all_healthy_components_aggregate_to_healthy_test() {
  let statuses = [
    health.Healthy,
    health.Healthy,
    health.Healthy,
  ]

  health.calculate_overall_status(statuses)
  |> should.equal(health.Healthy)
}

pub fn one_degraded_component_makes_system_degraded_test() {
  let statuses = [
    health.Healthy,
    health.Degraded,  // ← One degraded
    health.Healthy,
  ]

  health.calculate_overall_status(statuses)
  |> should.equal(health.Degraded)
}

pub fn one_unhealthy_component_makes_system_unhealthy_test() {
  let statuses = [
    health.Healthy,
    health.Degraded,
    health.Unhealthy,  // ← One unhealthy
  ]

  health.calculate_overall_status(statuses)
  |> should.equal(health.Unhealthy)
}

pub fn not_configured_does_not_affect_healthy_system_test() {
  let statuses = [
    health.Healthy,
    health.NotConfigured,  // ← Not configured
    health.Healthy,
  ]

  health.calculate_overall_status(statuses)
  |> should.equal(health.Healthy)
}
```

---

## 4. Expanded I18n Tests

### File: `test/meal_planner/errors/i18n_test.gleam`

```gleam
/// Tests for internationalized error messages
import gleeunit
import gleeunit/should
import meal_planner/errors

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// English Messages
// ============================================================================

pub fn english_not_found_message_test() {
  let error = errors.NotFoundError("recipe", "123")

  errors.localized_message(error, locale: "en")
  |> should.equal("The recipe you're looking for was not found.")
}

pub fn english_validation_message_test() {
  let error = errors.ValidationError("email", "Invalid format")

  errors.localized_message(error, locale: "en")
  |> should.equal("The field 'email' is invalid: Invalid format")
}

// ============================================================================
// Spanish Messages
// ============================================================================

pub fn spanish_not_found_recipe_message_test() {
  let error = errors.NotFoundError("recipe", "123")

  errors.localized_message(error, locale: "es")
  |> should.equal("La receta que buscas no fue encontrada.")
}

pub fn spanish_fallback_to_english_test() {
  let error = errors.ValidationError("email", "Invalid format")

  errors.localized_message(error, locale: "es")
  |> should.equal("The field 'email' is invalid: Invalid format")
}

// ============================================================================
// French Messages
// ============================================================================

pub fn french_not_found_recipe_message_test() {
  let error = errors.NotFoundError("recipe", "123")

  errors.localized_message(error, locale: "fr")
  |> should.equal("La recette que vous recherchez n'a pas été trouvée.")
}

// ============================================================================
// Template Parameter Tests
// ============================================================================

pub fn template_params_validation_error_test() {
  let error = errors.ValidationError("email", "Invalid format")

  errors.get_template_params(error)
  |> should.equal([
    #("field", "email"),
    #("reason", "Invalid format"),
  ])
}

pub fn template_params_not_found_error_test() {
  let error = errors.NotFoundError("recipe", "123")

  errors.get_template_params(error)
  |> should.equal([
    #("resource", "recipe"),
    #("id", "123"),
  ])
}

pub fn template_params_rate_limit_error_test() {
  let error = errors.RateLimitError(60)

  errors.get_template_params(error)
  |> should.equal([#("seconds", "60")])
}
```

---

## 5. Error Severity Tests

### File: `test/meal_planner/errors/severity_test.gleam`

```gleam
/// Tests for error severity classification
import gleeunit
import gleeunit/should
import meal_planner/errors

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Severity Classification Tests
// ============================================================================

pub fn not_found_error_is_info_level_test() {
  errors.NotFoundError("recipe", "123")
  |> errors.error_severity
  |> should.equal(errors.Info)
}

pub fn validation_error_is_warning_level_test() {
  errors.ValidationError("email", "Invalid")
  |> errors.error_severity
  |> should.equal(errors.Warning)
}

pub fn network_error_is_warning_level_test() {
  errors.NetworkError("Connection timeout")
  |> errors.error_severity
  |> should.equal(errors.Warning)
}

pub fn service_error_is_error_level_test() {
  errors.ServiceError("api", "Unavailable")
  |> errors.error_severity
  |> should.equal(errors.Error)
}

pub fn database_error_is_critical_level_test() {
  errors.DatabaseError("select", "Connection failed")
  |> errors.error_severity
  |> should.equal(errors.Critical)
}

pub fn internal_error_is_critical_level_test() {
  errors.InternalError("Unexpected condition")
  |> errors.error_severity
  |> should.equal(errors.Critical)
}

// ============================================================================
// Alert Strategy Tests
// ============================================================================

pub fn critical_errors_should_alert_test() {
  errors.DatabaseError("select", "failed")
  |> errors.should_alert
  |> should.be_true
}

pub fn warning_errors_should_not_alert_test() {
  errors.ValidationError("email", "invalid")
  |> errors.should_alert
  |> should.be_false
}

pub fn info_errors_should_not_alert_test() {
  errors.NotFoundError("recipe", "123")
  |> errors.should_alert
  |> should.be_false
}
```

---

## 6. Error Classification Tests

### File: `test/meal_planner/errors/classification_test.gleam`

```gleam
/// Tests for error classification utilities
import gleeunit
import gleeunit/should
import meal_planner/errors

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Client Error Tests (4xx)
// ============================================================================

pub fn validation_error_is_client_error_test() {
  errors.ValidationError("email", "invalid")
  |> errors.is_client_error
  |> should.be_true
}

pub fn not_found_error_is_client_error_test() {
  errors.NotFoundError("recipe", "123")
  |> errors.is_client_error
  |> should.be_true
}

pub fn authentication_error_is_client_error_test() {
  errors.AuthenticationError("Invalid token")
  |> errors.is_client_error
  |> should.be_true
}

pub fn database_error_is_not_client_error_test() {
  errors.DatabaseError("select", "failed")
  |> errors.is_client_error
  |> should.be_false
}

// ============================================================================
// Server Error Tests (5xx)
// ============================================================================

pub fn database_error_is_server_error_test() {
  errors.DatabaseError("select", "failed")
  |> errors.is_server_error
  |> should.be_true
}

pub fn network_error_is_server_error_test() {
  errors.NetworkError("timeout")
  |> errors.is_server_error
  |> should.be_true
}

pub fn internal_error_is_server_error_test() {
  errors.InternalError("unexpected")
  |> errors.is_server_error
  |> should.be_true
}

pub fn validation_error_is_not_server_error_test() {
  errors.ValidationError("email", "invalid")
  |> errors.is_server_error
  |> should.be_false
}

// ============================================================================
// Authentication Error Tests
// ============================================================================

pub fn authentication_error_is_authentication_error_test() {
  errors.AuthenticationError("Invalid token")
  |> errors.is_authentication_error
  |> should.be_true
}

pub fn validation_error_is_not_authentication_error_test() {
  errors.ValidationError("email", "invalid")
  |> errors.is_authentication_error
  |> should.be_false
}

// ============================================================================
// Wrapped Error Classification Tests
// ============================================================================

pub fn wrapped_client_error_is_client_error_test() {
  let error = errors.ValidationError("email", "invalid")
  let wrapped = errors.wrap_error(error, errors.BadRequestError("malformed"))

  wrapped
  |> errors.is_client_error
  |> should.be_true
}

pub fn wrapped_server_error_is_server_error_test() {
  let error = errors.NetworkError("timeout")
  let wrapped = errors.wrap_error(error, errors.ServiceError("api", "failed"))

  wrapped
  |> errors.is_server_error
  |> should.be_true
}
```

---

## 7. Running the New Tests

### Add to CI/CD Pipeline

```bash
# Run all error-related tests
gleam test --module meal_planner/errors/retry_test
gleam test --module meal_planner/errors/i18n_test
gleam test --module meal_planner/errors/severity_test
gleam test --module meal_planner/errors/classification_test
gleam test --module tandoor/core/error_test
gleam test --module meal_planner/web/handlers/health_test
```

### Local Development

```bash
# Run specific test file
gleam test --module meal_planner/errors/retry_test

# Run all tests
make test
```

---

## 8. Implementation Checklist

- [ ] Create `test/meal_planner/errors/retry_test.gleam`
- [ ] Create `test/meal_planner/errors/i18n_test.gleam`
- [ ] Create `test/meal_planner/errors/severity_test.gleam`
- [ ] Create `test/meal_planner/errors/classification_test.gleam`
- [ ] Create `test/meal_planner/web/handlers/health_test.gleam`
- [ ] Add `is_recoverable()` to `src/meal_planner/tandoor/core/error.gleam`
- [ ] Add recovery tests to `test/tandoor/core/error_test.gleam`
- [ ] Run `gleam format` on all new files
- [ ] Run `make test` to verify all tests pass
- [ ] Update CI/CD pipeline to include new tests

---

## 9. Expected Outcomes

After implementing these recommendations:

1. **Test Coverage:** Increase from 7/10 to 9/10
2. **Error Recovery:** Comprehensive validation of retry logic
3. **Consistency:** Tandoor errors aligned with FatSecret pattern
4. **Confidence:** Full test suite validates error behavior
5. **Documentation:** Tests serve as examples for error handling

---

## 10. Next Steps

1. **Phase 1:** Implement Priority 1 items (retry tests, Tandoor consistency)
2. **Phase 2:** Add health check and degradation tests
3. **Phase 3:** Expand I18n coverage and tests
4. **Phase 4:** Document error handling patterns in ADR
5. **Phase 5:** Add error metrics and monitoring

---

**Document Version:** 1.0
**Last Updated:** 2025-12-24
**Status:** Ready for Implementation
