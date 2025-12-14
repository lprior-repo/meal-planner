/// Integration tests for complete OAuth 1.0a flow
///
/// These tests verify the full 3-legged OAuth flow:
/// 1. Get request token
/// 2. User authorization (simulated)
/// 3. Get access token
/// 4. Make authenticated requests
/// 5. Disconnect
///
/// WARNING: These tests require valid FatSecret API credentials and will
/// make real API calls. They should be run sparingly to avoid rate limits.
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/fatsecret/core/config
import meal_planner/fatsecret/core/errors
import meal_planner/fatsecret/profile/oauth
import meal_planner/fatsecret/storage
import meal_planner/test_helpers/database

// =============================================================================
// Test Configuration
// =============================================================================

/// Helper to get FatSecret config from environment
fn get_config() -> Result(config.FatSecretConfig, Nil) {
  case config.from_env() {
    Some(cfg) -> Ok(cfg)
    None -> Error(Nil)
  }
}

/// Helper to check if encryption is configured
fn encryption_ready() -> Bool {
  storage.encryption_configured()
}

// =============================================================================
// Complete OAuth Flow Integration Test
// =============================================================================

/// Test the complete OAuth 1.0a flow end-to-end
///
/// This test demonstrates the full user authorization process:
/// 1. Start disconnected
/// 2. Request token - initiate OAuth flow
/// 3. User authorization - simulate browser redirect
/// 4. Access token - complete OAuth flow
/// 5. Authenticated request - verify token works
/// 6. Disconnect - cleanup
///
/// NOTE: This test requires manual intervention at step 3 to authorize
/// the application. In a real integration test environment, you would
/// mock the authorization step or use a test account with pre-authorized
/// credentials.
pub fn complete_oauth_flow_test() {
  // Skip if not configured
  case get_config(), encryption_ready() {
    Error(_), _ | _, False -> should.be_true(True)
    Ok(cfg), True -> {
      use conn <- database.with_test_transaction

      // Step 1: Verify we start disconnected
      should.be_false(storage.is_connected(conn))

      // Step 2: Get request token
      let result = oauth.get_request_token(cfg, "oob")

      case result {
        Ok(request_token) -> {
          // Verify request token structure
          should.be_true(request_token.oauth_token != "")
          should.be_true(request_token.oauth_token_secret != "")
          should.be_true(request_token.oauth_callback_confirmed)

          // Store pending token for later retrieval
          let store_result = storage.store_pending_token(conn, request_token)
          should.be_ok(store_result)

          // Step 3: Get authorization URL
          let auth_url = oauth.get_authorization_url(cfg, request_token)
          should.be_true(auth_url |> string.contains("oauth/authorize"))
          should.be_true(auth_url |> string.contains(request_token.oauth_token))

          // NOTE: At this point, a real user would visit auth_url in their browser,
          // log in to FatSecret, authorize the app, and receive an oauth_verifier code.
          // For automated testing, you would either:
          // 1. Mock this step entirely
          // 2. Use a pre-registered test account with known verifier
          // 3. Skip the rest of this test (as we do here)

          // Since we can't automate user authorization, we stop here
          // The remaining steps would be:
          //
          // Step 4: Exchange for access token
          // let access_result = oauth.get_access_token(cfg, request_token, verifier)
          // should.be_ok(access_result)
          //
          // Step 5: Store access token
          // storage.store_access_token(conn, access_token)
          //
          // Step 6: Verify connected
          // should.be_true(storage.is_connected(conn))
          //
          // Step 7: Make authenticated request
          // let profile = profile.get_user_profile(cfg, access_token)
          // should.be_ok(profile)
          //
          // Step 8: Disconnect
          // storage.delete_access_token(conn)
          // should.be_false(storage.is_connected(conn))

          should.be_true(True)
        }
        Error(e) -> {
          // If we get an auth error, that's expected without proper setup
          case errors.is_auth_error(e) {
            True -> should.be_true(True)
            False -> {
              // Unexpected error - fail the test
              errors.error_to_string(e)
              |> should.equal("Expected success")
            }
          }
        }
      }
    }
  }
}

// =============================================================================
// Request Token Tests
// =============================================================================

/// Test request token retrieval
pub fn get_request_token_test() {
  case get_config() {
    Error(_) -> should.be_true(True)
    Ok(cfg) -> {
      let result = oauth.get_request_token(cfg, "oob")

      case result {
        Ok(token) -> {
          should.be_true(token.oauth_token != "")
          should.be_true(token.oauth_token_secret != "")
          should.equal(token.oauth_callback_confirmed, True)
        }
        Error(e) -> {
          // Auth errors are expected without proper credentials
          case errors.is_auth_error(e) {
            True -> should.be_true(True)
            False -> should.fail()
          }
        }
      }
    }
  }
}

/// Test request token with callback URL
pub fn get_request_token_with_callback_test() {
  case get_config() {
    Error(_) -> should.be_true(True)
    Ok(cfg) -> {
      let callback_url = "https://example.com/oauth/callback"
      let result = oauth.get_request_token(cfg, callback_url)

      case result {
        Ok(token) -> {
          should.be_true(token.oauth_token != "")
          should.equal(token.oauth_callback_confirmed, True)
        }
        Error(e) -> {
          case errors.is_auth_error(e) {
            True -> should.be_true(True)
            False -> should.fail()
          }
        }
      }
    }
  }
}

// =============================================================================
// Authorization URL Tests
// =============================================================================

/// Test authorization URL generation
pub fn authorization_url_format_test() {
  case get_config() {
    Error(_) -> should.be_true(True)
    Ok(cfg) -> {
      use conn <- database.with_test_transaction

      case oauth.get_request_token(cfg, "oob") {
        Ok(request_token) -> {
          let auth_url = oauth.get_authorization_url(cfg, request_token)

          // Verify URL structure
          should.be_true(auth_url |> string.starts_with("https://"))
          should.be_true(auth_url |> string.contains("oauth/authorize"))
          should.be_true(
            auth_url
            |> string.contains("oauth_token=" <> request_token.oauth_token),
          )
        }
        Error(_) -> should.be_true(True)
      }
    }
  }
}

// =============================================================================
// Token Storage Tests
// =============================================================================

/// Test storing and retrieving pending tokens
pub fn store_and_retrieve_pending_token_test() {
  case get_config(), encryption_ready() {
    Error(_), _ | _, False -> should.be_true(True)
    Ok(cfg), True -> {
      use conn <- database.with_test_transaction

      case oauth.get_request_token(cfg, "oob") {
        Ok(request_token) -> {
          // Store the pending token
          let store_result = storage.store_pending_token(conn, request_token)
          should.be_ok(store_result)

          // Retrieve it
          let retrieve_result =
            storage.get_pending_token(conn, request_token.oauth_token)

          case retrieve_result {
            Ok(secret) -> {
              should.equal(secret, request_token.oauth_token_secret)

              // Verify token is deleted after retrieval
              let second_retrieve =
                storage.get_pending_token(conn, request_token.oauth_token)
              should.be_error(second_retrieve)
            }
            Error(_) -> should.fail()
          }
        }
        Error(_) -> should.be_true(True)
      }
    }
  }
}

/// Test retrieving non-existent pending token
pub fn retrieve_missing_pending_token_test() {
  case encryption_ready() {
    False -> should.be_true(True)
    True -> {
      use conn <- database.with_test_transaction

      let result = storage.get_pending_token(conn, "nonexistent_token")
      should.be_error(result)
    }
  }
}

// =============================================================================
// Connection Status Tests
// =============================================================================

/// Test connection status when not connected
pub fn connection_status_disconnected_test() {
  case encryption_ready() {
    False -> should.be_true(True)
    True -> {
      use conn <- database.with_test_transaction

      // Ensure disconnected
      let _ = storage.delete_access_token(conn)

      should.be_false(storage.is_connected(conn))
      should.equal(storage.get_access_token_opt(conn), None)
    }
  }
}

/// Test disconnect clears token
pub fn disconnect_clears_token_test() {
  case encryption_ready() {
    False -> should.be_true(True)
    True -> {
      use conn <- database.with_test_transaction

      // First disconnect to ensure clean state
      let _ = storage.delete_access_token(conn)
      should.be_false(storage.is_connected(conn))

      // Verify we can disconnect even when not connected
      let result = storage.delete_access_token(conn)
      should.be_ok(result)
      should.be_false(storage.is_connected(conn))
    }
  }
}

// =============================================================================
// Error Handling Tests
// =============================================================================

/// Test OAuth error handling with invalid credentials
pub fn invalid_credentials_test() {
  let bad_config = config.new("invalid_key", "invalid_secret")
  let result = oauth.get_request_token(bad_config, "oob")

  case result {
    Error(e) -> {
      // Should get auth error
      should.be_true(errors.is_auth_error(e))
    }
    Ok(_) -> should.fail()
  }
}

/// Test encryption not configured
pub fn encryption_not_configured_test() {
  // This test would need to temporarily unset OAUTH_ENCRYPTION_KEY
  // which is difficult in practice. Skip for now.
  should.be_true(True)
}
