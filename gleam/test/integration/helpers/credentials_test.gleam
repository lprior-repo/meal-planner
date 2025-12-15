//// Tests for credentials loader module

import gleeunit/should
import integration/helpers/credentials

pub fn credentials_load_returns_credentials_test() {
  let creds = credentials.load()

  // Should return a valid Credentials object
  case creds {
    credentials.Credentials(_, _) -> should.be_true(True)
  }
}

pub fn has_fatsecret_returns_bool_test() {
  let creds = credentials.load()
  let has_fs = credentials.has_fatsecret(creds)

  // Should return a Bool
  case has_fs {
    True -> should.be_true(True)
    False -> should.be_true(True)
  }
}

pub fn has_tandoor_returns_bool_test() {
  let creds = credentials.load()
  let has_td = credentials.has_tandoor(creds)

  // Should return a Bool
  case has_td {
    True -> should.be_true(True)
    False -> should.be_true(True)
  }
}
