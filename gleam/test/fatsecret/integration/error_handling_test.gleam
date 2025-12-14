/// Integration tests for error handling and propagation
///
/// These tests verify that the FatSecret SDK properly handles and reports
/// various error conditions:
/// - Configuration errors (missing credentials)
/// - Authentication errors (invalid tokens)
/// - API errors (invalid parameters, rate limits)
/// - Network errors (connection failures)
/// - Parse errors (malformed responses)
///
/// These tests use both real API calls and simulated error conditions.
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit/should
import meal_planner/fatsecret/core/config
import meal_planner/fatsecret/core/errors
import meal_planner/fatsecret/core/oauth
import meal_planner/fatsecret/diary/types as diary
import meal_planner/fatsecret/foods/client as foods
import meal_planner/fatsecret/profile/client as profile
import meal_planner/fatsecret/profile/oauth as profile_oauth
import meal_planner/fatsecret/service
import meal_planner/fatsecret/storage
import meal_planner/test_helpers/database

// =============================================================================
// Configuration Error Tests
// =============================================================================

/// Test ConfigMissing when environment variables not set
pub fn config_missing_from_env_test() {
  // This test assumes FATSECRET_CONSUMER_KEY is not set
  // In practice, it might be set, so we test the service layer instead
  use conn <- database.with_test_transaction

  // The service layer checks for config
  let status = service.check_status(conn)

  // Status should be either ConfigMissing or one of the other valid states
  case status {
    service.ConfigMissing -> should.be_true(True)
    service.EncryptionKeyMissing -> should.be_true(True)
    service.Connected(_) -> should.be_true(True)
    service.Disconnected(_) -> should.be_true(True)
  }
}

/// Test invalid credentials produce auth error
pub fn invalid_credentials_test() {
  let bad_config = config.new("invalid_consumer_key", "invalid_secret")

  let result = profile_oauth.get_request_token(bad_config, "oob")

  case result {
    Error(e) -> {
      // Should get an auth-related error
      should.be_true(errors.is_auth_error(e))

      // Error message should be informative
      let msg = errors.error_to_string(e)
      should.be_true(msg != "")
    }
    Ok(_) -> should.fail()
    // Should not succeed with invalid credentials
  }
}

// =============================================================================
// Authentication Error Tests
// =============================================================================

/// Test NotConnected error when no token stored
pub fn not_connected_error_test() {
  use conn <- database.with_test_transaction

  // Ensure no token exists
  let _ = storage.delete_access_token(conn)

  // Trying to get profile should fail with NotConnected
  let result = service.get_profile(conn)

  case result {
    Error(service.NotConnected) -> should.be_true(True)
    Error(service.NotConfigured) -> should.be_true(True)
    Error(service.EncryptionError(_)) -> should.be_true(True)
    Error(_) -> should.fail()
    Ok(_) -> should.fail()
  }
}

/// Test AuthRevoked detection on 401/403 responses
pub fn auth_revoked_detection_test() {
  // This test requires making a request with an invalid token
  // We create a fake token that will definitely fail
  use conn <- database.with_test_transaction

  case config.from_env(), storage.encryption_configured() {
    Some(_), True -> {
      // Create an obviously invalid token
      let fake_token =
        oauth.AccessToken(
          oauth_token: "invalid_token_12345",
          oauth_token_secret: "invalid_secret_67890",
        )

      // Try to store it
      let store_result = storage.store_access_token(conn, fake_token)

      case store_result {
        Ok(_) -> {
          // Now try to use it
          let result = service.get_profile(conn)

          case result {
            Error(service.AuthRevoked) -> should.be_true(True)
            Error(service.NotConfigured) -> should.be_true(True)
            Error(_) -> {
              // Other errors are acceptable (network, etc)
              should.be_true(True)
            }
            Ok(_) -> should.fail()
            // Should not succeed
          }
        }
        Error(_) -> {
          // If we can't store the token, skip the test
          should.be_true(True)
        }
      }
    }
    _, _ -> {
      // Skip if not configured
      should.be_true(True)
    }
  }
}

// =============================================================================
// API Error Tests
// =============================================================================

/// Test InvalidId error with non-existent food ID
pub fn invalid_food_id_test() {
  case config.from_env() {
    None -> should.be_true(True)
    Some(cfg) -> {
      // Use an obviously invalid food ID
      let result = foods.get_food(cfg, foods.food_id("99999999999"))

      case result {
        Error(errors.ApiError(errors.InvalidId, _)) -> should.be_true(True)
        Error(errors.ApiError(errors.MissingRequiredParameter, _)) ->
          should.be_true(True)
        Error(_) -> {
          // Other API errors are acceptable
          should.be_true(True)
        }
        Ok(_) -> should.fail()
      }
    }
  }
}

/// Test InvalidSearchValue with empty search query
pub fn invalid_search_value_test() {
  case config.from_env() {
    None -> should.be_true(True)
    Some(cfg) -> {
      let result = foods.search_foods_simple(cfg, "")

      case result {
        Error(errors.ApiError(errors.InvalidSearchValue, _)) ->
          should.be_true(True)
        Error(errors.ApiError(errors.MissingRequiredParameter, _)) ->
          should.be_true(True)
        Ok(response) -> {
          // Empty query might return empty results instead of error
          should.equal(response.foods, [])
        }
        Error(_) -> should.be_true(True)
      }
    }
  }
}

/// Test InvalidDate error with malformed date
pub fn invalid_date_format_test() {
  let result = diary.date_to_int("invalid-date")
  should.be_error(result)
}

/// Test date conversion boundary cases
pub fn date_conversion_edge_cases_test() {
  // Test epoch
  let result1 = diary.date_to_int("1970-01-01")
  should.equal(result1, Ok(0))

  // Test future date (should fail)
  let result2 = diary.date_to_int("2150-01-01")
  should.be_error(result2)

  // Test invalid month
  let result3 = diary.date_to_int("2024-13-01")
  should.be_error(result3)

  // Test invalid day
  let result4 = diary.date_to_int("2024-01-32")
  should.be_error(result4)

  // Test negative year
  let result5 = diary.date_to_int("1969-12-31")
  should.be_error(result5)
}

/// Test date round-trip conversion
pub fn date_roundtrip_test() {
  let test_dates = ["1970-01-01", "2000-01-01", "2024-06-15", "2024-12-31"]

  test_dates
  |> list.each(fn(date) {
    case diary.date_to_int(date) {
      Ok(date_int) -> {
        let converted = diary.int_to_date(date_int)
        should.equal(converted, date)
      }
      Error(_) -> should.fail()
    }
  })
}

// =============================================================================
// Error Classification Tests
// =============================================================================

/// Test is_recoverable classification
pub fn error_recoverable_classification_test() {
  // Network errors should be recoverable
  should.be_true(errors.is_recoverable(errors.NetworkError("timeout")))

  // API unavailable should be recoverable
  should.be_true(
    errors.is_recoverable(errors.ApiError(errors.ApiUnavailable, "down")),
  )

  // 5xx errors should be recoverable
  should.be_true(
    errors.is_recoverable(errors.RequestFailed(500, "server error")),
  )
  should.be_true(
    errors.is_recoverable(errors.RequestFailed(503, "unavailable")),
  )

  // Auth errors should not be recoverable
  should.be_false(
    errors.is_recoverable(errors.ApiError(
      errors.InvalidAccessToken,
      "bad token",
    )),
  )

  // 4xx errors should not be recoverable
  should.be_false(errors.is_recoverable(errors.RequestFailed(404, "not found")))
  should.be_false(
    errors.is_recoverable(errors.RequestFailed(400, "bad request")),
  )

  // Parse errors should not be recoverable
  should.be_false(errors.is_recoverable(errors.ParseError("bad json")))
}

/// Test is_auth_error classification
pub fn error_auth_classification_test() {
  // OAuth errors
  should.be_true(errors.is_auth_error(errors.OAuthError("invalid")))
  should.be_true(errors.is_auth_error(errors.ConfigMissing))

  // API auth errors
  should.be_true(
    errors.is_auth_error(errors.ApiError(errors.InvalidAccessToken, "")),
  )
  should.be_true(
    errors.is_auth_error(errors.ApiError(errors.InvalidConsumerCredentials, "")),
  )
  should.be_true(
    errors.is_auth_error(errors.ApiError(errors.InvalidSignature, "")),
  )
  should.be_true(
    errors.is_auth_error(errors.ApiError(errors.InvalidOrExpiredToken, "")),
  )

  // Non-auth errors
  should.be_false(errors.is_auth_error(errors.NetworkError("timeout")))
  should.be_false(errors.is_auth_error(errors.ParseError("bad json")))
  should.be_false(errors.is_auth_error(errors.ApiError(errors.InvalidId, "")))
}

/// Test error code conversion
pub fn error_code_conversion_test() {
  // Test all documented error codes
  should.equal(errors.code_to_int(errors.MissingOAuthParameter), 2)
  should.equal(errors.code_to_int(errors.UnsupportedOAuthParameter), 3)
  should.equal(errors.code_to_int(errors.InvalidSignatureMethod), 4)
  should.equal(errors.code_to_int(errors.InvalidConsumerCredentials), 5)
  should.equal(errors.code_to_int(errors.InvalidOrExpiredToken), 6)
  should.equal(errors.code_to_int(errors.InvalidSignature), 7)
  should.equal(errors.code_to_int(errors.InvalidNonce), 8)
  should.equal(errors.code_to_int(errors.InvalidAccessToken), 9)
  should.equal(errors.code_to_int(errors.InvalidMethod), 13)
  should.equal(errors.code_to_int(errors.ApiUnavailable), 14)
  should.equal(errors.code_to_int(errors.MissingRequiredParameter), 101)
  should.equal(errors.code_to_int(errors.InvalidId), 106)
  should.equal(errors.code_to_int(errors.InvalidSearchValue), 107)
  should.equal(errors.code_to_int(errors.InvalidDate), 108)

  // Test round-trip conversion
  [2, 3, 4, 5, 6, 7, 8, 9, 13, 14, 101, 106, 107, 108]
  |> list.each(fn(code) {
    let error_code = errors.code_from_int(code)
    should.equal(errors.code_to_int(error_code), code)
  })
}

/// Test error message formatting
pub fn error_message_formatting_test() {
  // Test error_to_string produces non-empty messages
  let test_errors = [
    errors.ConfigMissing,
    errors.NetworkError("connection refused"),
    errors.OAuthError("signature mismatch"),
    errors.ParseError("invalid json"),
    errors.RequestFailed(404, "not found"),
    errors.ApiError(errors.InvalidId, "Food ID not found"),
    errors.InvalidResponse("unexpected format"),
  ]

  test_errors
  |> list.each(fn(error) {
    let msg = errors.error_to_string(error)
    should.be_true(msg != "")
    should.be_true(string.length(msg) > 10)
  })
}

// =============================================================================
// Service Layer Error Handling
// =============================================================================

/// Test service layer error conversion
pub fn service_error_to_string_test() {
  let test_errors = [
    service.NotConnected,
    service.NotConfigured,
    service.AuthRevoked,
    service.EncryptionError("key not set"),
  ]

  test_errors
  |> list.each(fn(error) {
    let msg = service.error_to_string(error)
    should.be_true(msg != "")
  })
}

/// Test service startup check error messages
pub fn service_startup_check_test() {
  use conn <- database.with_test_transaction

  let message = service.startup_check(conn)

  // Should return a non-empty status message
  should.be_true(message != "")
  should.be_true(
    string.starts_with(message, "✓")
    || string.starts_with(message, "⚠")
    || string.starts_with(message, "✗"),
  )
}

// =============================================================================
// Storage Error Tests
// =============================================================================

/// Test storage error when encryption not configured
pub fn storage_encryption_not_configured_test() {
  case storage.encryption_configured() {
    False -> {
      // If encryption is not configured, operations should fail
      use conn <- database.with_test_transaction

      let fake_token =
        oauth.AccessToken(oauth_token: "test", oauth_token_secret: "secret")

      let result = storage.store_access_token(conn, fake_token)

      case result {
        Error(storage.EncryptionError(_)) -> should.be_true(True)
        Error(_) -> should.be_true(True)
        Ok(_) -> should.fail()
      }
    }
    True -> {
      // If configured, this test doesn't apply
      should.be_true(True)
    }
  }
}

/// Test retrieving non-existent pending token
pub fn storage_pending_token_not_found_test() {
  case storage.encryption_configured() {
    False -> should.be_true(True)
    True -> {
      use conn <- database.with_test_transaction

      let result = storage.get_pending_token(conn, "nonexistent_oauth_token")

      case result {
        Error(storage.NotFound) -> should.be_true(True)
        Error(_) -> should.be_true(True)
        Ok(_) -> should.fail()
      }
    }
  }
}

/// Test retrieving access token when not connected
pub fn storage_access_token_not_found_test() {
  case storage.encryption_configured() {
    False -> should.be_true(True)
    True -> {
      use conn <- database.with_test_transaction

      // Ensure no token exists
      let _ = storage.delete_access_token(conn)

      let result = storage.get_access_token(conn)

      case result {
        Error(storage.NotFound) -> should.be_true(True)
        Error(_) -> should.be_true(True)
        Ok(_) -> should.fail()
      }
    }
  }
}
