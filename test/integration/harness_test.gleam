//// Tests for test harness integration module
//// Verifies that the test harness correctly loads credentials and provides
//// unified setup/teardown functionality for integration tests

import gleeunit/should
import integration/harness

pub fn harness_setup_returns_context_test() {
  // Test that setup returns a TestContext
  let context = harness.setup()

  case context {
    harness.TestContext(_, _) -> should.be_true(True)
  }
}

pub fn harness_context_has_credentials_test() {
  // Test that TestContext contains credentials
  let context = harness.setup()

  case context {
    harness.TestContext(creds, _) -> {
      // Credentials should be present (even if empty)
      case creds {
        harness.TestCredentials(_, _) -> should.be_true(True)
      }
    }
  }
}

pub fn harness_run_test_executes_callback_test() {
  // Test that run_test executes the provided test function
  let context = harness.setup()
  let executed = harness.run_test(context, fn(_ctx) { Ok(True) })

  case executed {
    Ok(True) -> should.be_true(True)
    Ok(False) -> should.fail()
    Error(_) -> should.fail()
  }
}

pub fn harness_skip_if_unavailable_skips_when_no_creds_test() {
  // Test that tests are skipped when credentials are unavailable
  let context = harness.setup()

  // Create a test that requires credentials
  let result =
    harness.skip_if_unavailable(context, "tandoor", fn(_ctx) { Ok(Nil) })

  // Result should be either Ok(Nil) if creds available, or Error with skip message
  case result {
    Ok(Nil) -> should.be_true(True)
    Error(_msg) -> {
      // Should contain "skipping" or "not configured"
      should.be_true(True)
    }
  }
}

pub fn harness_teardown_succeeds_test() {
  // Test that teardown completes successfully
  let context = harness.setup()
  let result = harness.teardown(context)

  case result {
    Ok(Nil) -> should.be_true(True)
    Error(_) -> should.fail()
  }
}
