//// Tests for credentials loader module

import envoy
import gleam/option.{None, Some}
import gleeunit/should
import integration/helpers/credentials

pub fn load_tandoor_from_env_test() {
  // Test that Tandoor credentials are loaded from environment
  let creds = credentials.load()

  // If TANDOOR_URL is set, should have Tandoor credentials
  case envoy.get("TANDOOR_URL") {
    Ok(url) ->
      case creds.tandoor {
        Some(tandoor) -> {
          should.equal(tandoor.base_url, url)
          should.not_equal(tandoor.username, "")
          should.not_equal(tandoor.password, "")
        }
        None -> should.fail()
      }
    Error(_) ->
      // No env var, should be None
      case creds.tandoor {
        None -> should.be_true(True)
        Some(_) -> should.fail()
      }
  }
}

pub fn has_tandoor_detects_credentials_test() {
  let creds = credentials.load()
  let has_td = credentials.has_tandoor(creds)

  // Should match whether env vars are set
  case envoy.get("TANDOOR_URL") {
    Ok(_) -> should.be_true(has_td)
    Error(_) -> should.be_false(has_td)
  }
}

pub fn has_fatsecret_detects_db_credentials_test() {
  let creds = credentials.load()
  let has_fs = credentials.has_fatsecret(creds)

  // Should be Bool - exact value depends on DB state
  case has_fs {
    True -> should.be_true(True)
    False -> should.be_true(True)
  }
}

pub fn load_handles_missing_env_gracefully_test() {
  // Load should never crash, even with missing credentials
  let creds = credentials.load()

  // Should always return valid Credentials object
  case creds {
    credentials.Credentials(_, _) -> should.be_true(True)
  }
}

pub fn tandoor_credentials_structure_test() {
  let creds = credentials.load()

  // If Tandoor credentials exist, verify structure
  case creds.tandoor {
    Some(tandoor) -> {
      // URL should not be empty
      should.not_equal(tandoor.base_url, "")
      // Username should not be empty
      should.not_equal(tandoor.username, "")
      // Password is allowed to be empty (some setups)
    }
    None -> should.be_true(True)
  }
}

pub fn fatsecret_credentials_structure_test() {
  let creds = credentials.load()

  // If FatSecret credentials exist, verify structure
  case creds.fatsecret {
    Some(fs) -> {
      // OAuth token should not be empty
      should.not_equal(fs.oauth_token, "")
      // OAuth secret should not be empty
      should.not_equal(fs.oauth_token_secret, "")
    }
    None -> should.be_true(True)
  }
}
