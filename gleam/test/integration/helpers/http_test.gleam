//// Tests for HTTP client helper module
//// These tests verify basic HTTP method functionality

import gleeunit
import gleeunit/should
import integration/helpers/http

pub fn http_get_returns_tuple_test() {
  // Test that GET returns a tuple of (status_code, body)
  let result = http.get("/health")

  case result {
    Ok(#(status, _body)) -> should.be_true(status >= 200)
    Error(_) -> should.fail()
  }
}

pub fn http_post_returns_tuple_test() {
  // Test that POST returns a tuple of (status_code, body)
  let result = http.post("/api/test", "{\"test\": true}")

  case result {
    Ok(#(status, _body)) -> should.be_true(status >= 200)
    Error(_) -> should.fail()
  }
}

pub fn http_patch_returns_tuple_test() {
  // Test that PATCH returns a tuple of (status_code, body)
  let result = http.patch("/api/test", "{\"updated\": true}")

  case result {
    Ok(#(status, _body)) -> should.be_true(status >= 200)
    Error(_) -> should.fail()
  }
}

pub fn http_delete_returns_tuple_test() {
  // Test that DELETE returns a tuple of (status_code, body)
  let result = http.delete("/api/test")

  case result {
    Ok(#(status, _body)) -> should.be_true(status >= 200)
    Error(_) -> should.fail()
  }
}
