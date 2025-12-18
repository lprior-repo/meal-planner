//// Tests for assertion helpers module

import gleeunit/should
import integration/helpers/assertions

pub fn assert_status_passes_for_matching_code_test() {
  let response = #(200, "{\"ok\": true}")

  case assertions.assert_status(response, 200) {
    Ok(_) -> should.be_true(True)
    Error(_) -> should.fail()
  }
}

pub fn assert_status_fails_for_mismatched_code_test() {
  let response = #(404, "{\"error\": \"not found\"}")

  case assertions.assert_status(response, 200) {
    Ok(_) -> should.fail()
    Error(_) -> should.be_true(True)
  }
}

pub fn assert_valid_json_succeeds_for_valid_json_test() {
  let body = "{\"test\": \"value\"}"

  case assertions.assert_valid_json(body) {
    Ok(_) -> should.be_true(True)
    Error(_) -> should.fail()
  }
}

pub fn assert_valid_json_fails_for_invalid_json_test() {
  let body = "{invalid json}"

  case assertions.assert_valid_json(body) {
    Ok(_) -> should.fail()
    Error(_) -> should.be_true(True)
  }
}

pub fn assert_has_field_succeeds_for_existing_field_test() {
  let body = "{\"field\": \"value\"}"

  case assertions.assert_has_field(body, "field") {
    Ok(_) -> should.be_true(True)
    Error(_) -> should.fail()
  }
}

pub fn assert_has_field_fails_for_missing_field_test() {
  let body = "{\"other\": \"value\"}"

  case assertions.assert_has_field(body, "field") {
    Ok(_) -> should.fail()
    Error(_) -> should.be_true(True)
  }
}
