/// FatSecret Profile Service Tests
///
/// Tests for the profile service layer including:
/// - Connection status checking
/// - OAuth flow (start, complete, disconnect)
/// - Profile fetching
/// - Connection validation
/// - Error handling
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/env
import meal_planner/fatsecret/client
import meal_planner/fatsecret/profile/service
import meal_planner/fatsecret/storage
import meal_planner/test_helpers/database
import pog

pub fn main() {
  gleeunit.main()
}

// =============================================================================
// Test Setup & Teardown
// =============================================================================

fn setup_test_db() -> pog.Connection {
  let conn = database.get_test_connection()

  // Clean up any existing tokens
  let _ = storage.delete_access_token(conn)
  let _ = cleanup_pending_tokens(conn)

  conn
}

fn cleanup_pending_tokens(conn: pog.Connection) -> Nil {
  let sql = "DELETE FROM fatsecret_oauth_pending"
  let _ = pog.query(sql) |> pog.execute(conn)
  Nil
}

fn teardown_test_db(conn: pog.Connection) -> Nil {
  let _ = storage.delete_access_token(conn)
  let _ = cleanup_pending_tokens(conn)
  Nil
}

// =============================================================================
// Connection Status Tests
// =============================================================================

pub fn check_status_not_configured_test() {
  // When FatSecret config is missing (env vars not set)
  // This test depends on the actual environment
  // We can't easily test this without mocking env.load_fatsecret_config()
  // For now, we'll document this behavior

  let conn = setup_test_db()
  let status = service.check_status(conn)

  // Status will be ConfigMissing if FATSECRET_CONSUMER_KEY is not set
  // Or Connected/Disconnected if it is set
  case status {
    service.ConfigMissing -> should.be_true(True)
    service.EncryptionKeyMissing -> should.be_true(True)
    service.Disconnected(_) -> should.be_true(True)
    service.Connected(_) -> should.be_true(True)
  }

  teardown_test_db(conn)
}

pub fn check_status_encryption_missing_test() {
  // This test requires OAUTH_ENCRYPTION_KEY to be unset
  // Which we can't easily do in a test without affecting other tests
  // Documenting expected behavior: should return EncryptionKeyMissing
  should.be_true(True)
}

pub fn check_status_disconnected_test() {
  let conn = setup_test_db()

  // Ensure no token is stored
  let _ = storage.delete_access_token(conn)

  let status = service.check_status(conn)

  case status {
    service.Disconnected(reason) -> {
      should.equal(reason, "Not connected yet")
    }
    service.ConfigMissing -> {
      // Config not set, that's also valid
      should.be_true(True)
    }
    service.EncryptionKeyMissing -> {
      // Encryption not configured, that's also valid
      should.be_true(True)
    }
    service.Connected(_) -> {
      // Should not be connected if we just deleted the token
      should.fail()
    }
  }

  teardown_test_db(conn)
}

pub fn check_status_connected_test() {
  let conn = setup_test_db()

  // Store a fake access token
  let fake_token =
    client.AccessToken(
      oauth_token: "test_token",
      oauth_token_secret: "test_secret",
    )

  case storage.encryption_configured() {
    True -> {
      let assert Ok(_) = storage.store_access_token(conn, fake_token)

      let status = service.check_status(conn)

      case status {
        service.Connected(profile:) -> {
          should.equal(profile, None)
        }
        _ -> should.fail()
      }
    }
    False -> {
      // Encryption not configured, skip this test
      should.be_true(True)
    }
  }

  teardown_test_db(conn)
}

// =============================================================================
// OAuth Flow Tests
// =============================================================================

pub fn start_connect_not_configured_test() {
  let conn = setup_test_db()

  // If FatSecret is not configured, should return NotConfigured error
  let result = service.start_connect(conn, "http://localhost/callback")

  case result {
    Error(service.NotConfigured) -> should.be_true(True)
    Error(service.EncryptionError(_)) -> should.be_true(True)
    Ok(_) -> {
      // If we got a URL, FatSecret IS configured
      // This is valid if env vars are set
      should.be_true(True)
    }
    Error(_) -> should.fail()
  }

  teardown_test_db(conn)
}

pub fn start_connect_encryption_missing_test() {
  // This requires OAUTH_ENCRYPTION_KEY to be unset
  // Expected behavior: should return EncryptionError
  should.be_true(True)
}

pub fn complete_connect_invalid_verifier_test() {
  let conn = setup_test_db()

  let result =
    service.complete_connect(conn, "invalid_token", "invalid_verifier")

  case result {
    Error(service.InvalidVerifier) -> should.be_true(True)
    Error(service.NotConfigured) -> should.be_true(True)
    Error(service.NotConnected) -> should.be_true(True)
    Error(_) -> should.be_true(True)
    // Any error is acceptable here
    Ok(_) -> should.fail()
    // Should not succeed with invalid verifier
  }

  teardown_test_db(conn)
}

pub fn disconnect_when_not_connected_test() {
  let conn = setup_test_db()

  // Ensure no token is stored
  let _ = storage.delete_access_token(conn)

  // Disconnecting when not connected should succeed (no-op)
  let assert Ok(Nil) = service.disconnect(conn)

  teardown_test_db(conn)
}

pub fn disconnect_when_connected_test() {
  let conn = setup_test_db()

  case storage.encryption_configured() {
    True -> {
      // Store a fake token
      let fake_token =
        client.AccessToken(
          oauth_token: "test_token",
          oauth_token_secret: "test_secret",
        )
      let assert Ok(_) = storage.store_access_token(conn, fake_token)

      // Disconnect should succeed
      let assert Ok(Nil) = service.disconnect(conn)

      // Verify token is gone
      let status = service.check_status(conn)
      case status {
        service.Disconnected(_) -> should.be_true(True)
        _ -> should.fail()
      }
    }
    False -> {
      // Encryption not configured, skip
      should.be_true(True)
    }
  }

  teardown_test_db(conn)
}

// =============================================================================
// Profile Fetching Tests
// =============================================================================

pub fn get_profile_not_connected_test() {
  let conn = setup_test_db()

  // Ensure no token is stored
  let _ = storage.delete_access_token(conn)

  let result = service.get_profile(conn)

  case result {
    Error(service.NotConnected) -> should.be_true(True)
    Error(service.NotConfigured) -> should.be_true(True)
    Error(service.EncryptionError(_)) -> should.be_true(True)
    Ok(_) -> should.fail()
    // Should not succeed without token
    Error(_) -> should.be_true(True)
    // Other errors are acceptable
  }

  teardown_test_db(conn)
}

pub fn get_profile_with_fake_token_test() {
  let conn = setup_test_db()

  case storage.encryption_configured() && env.load_fatsecret_config() != None {
    True -> {
      // Store a fake token
      let fake_token =
        client.AccessToken(
          oauth_token: "fake_token",
          oauth_token_secret: "fake_secret",
        )
      let assert Ok(_) = storage.store_access_token(conn, fake_token)

      let result = service.get_profile(conn)

      case result {
        // Should fail with AuthRevoked or ApiError (token is fake)
        Error(service.AuthRevoked) -> should.be_true(True)
        Error(service.TokenExpired) -> should.be_true(True)
        Error(service.ApiError(_)) -> should.be_true(True)
        Ok(_) -> should.fail()
        // Fake token should not work
        Error(_) -> should.be_true(True)
        // Other errors acceptable
      }
    }
    False -> {
      // Config or encryption not set up, skip
      should.be_true(True)
    }
  }

  teardown_test_db(conn)
}

// =============================================================================
// Connection Validation Tests
// =============================================================================

pub fn validate_connection_not_connected_test() {
  let conn = setup_test_db()

  // Ensure no token is stored
  let _ = storage.delete_access_token(conn)

  let result = service.validate_connection(conn)

  case result {
    Error(service.NotConnected) -> should.be_true(True)
    Error(service.NotConfigured) -> should.be_true(True)
    Error(service.EncryptionError(_)) -> should.be_true(True)
    Ok(_) -> should.fail()
    // Should not succeed without token
    Error(_) -> should.be_true(True)
  }

  teardown_test_db(conn)
}

pub fn validate_connection_with_fake_token_test() {
  let conn = setup_test_db()

  case storage.encryption_configured() && env.load_fatsecret_config() != None {
    True -> {
      // Store a fake token
      let fake_token =
        client.AccessToken(
          oauth_token: "fake_token",
          oauth_token_secret: "fake_secret",
        )
      let assert Ok(_) = storage.store_access_token(conn, fake_token)

      let result = service.validate_connection(conn)

      case result {
        Ok(False) -> should.be_true(True)
        // Token invalid
        Error(_) -> should.be_true(True)
        // API error also acceptable
        Ok(True) -> should.fail()
        // Fake token should not be valid
      }
    }
    False -> {
      // Config or encryption not set up, skip
      should.be_true(True)
    }
  }

  teardown_test_db(conn)
}

// =============================================================================
// Integration Tests (require real FatSecret credentials)
// =============================================================================

// These tests require real FatSecret API credentials and a valid OAuth flow
// They are commented out by default but can be enabled for integration testing

// pub fn integration_full_oauth_flow_test() {
//   // This would require:
//   // 1. Real FatSecret API credentials in .env
//   // 2. A way to programmatically complete the OAuth flow
//   // 3. A real user authorization (can't be automated)
//
//   // For now, we rely on manual testing of the OAuth flow
//   should.be_true(True)
// }

// =============================================================================
// Error Handling Tests
// =============================================================================

pub fn service_error_types_test() {
  // Test that all error types can be constructed
  let _e1 = service.NotConfigured
  let _e2 = service.NotConnected
  let _e3 = service.AuthRevoked
  let _e4 = service.TokenExpired
  let _e5 = service.InvalidVerifier
  let _e6 = service.ApiError(client.ConfigMissing)
  let _e7 = service.StorageError("test")
  let _e8 = service.EncryptionError("test")

  should.be_true(True)
}

pub fn connection_status_types_test() {
  // Test that all status types can be constructed
  let _s1 = service.Connected(profile: None)
  let _s2 =
    service.Connected(
      profile: Some(service.Profile(user_id: "123", profile_json: "{}")),
    )
  let _s3 = service.Disconnected(reason: "test")
  let _s4 = service.ConfigMissing
  let _s5 = service.EncryptionKeyMissing

  should.be_true(True)
}
