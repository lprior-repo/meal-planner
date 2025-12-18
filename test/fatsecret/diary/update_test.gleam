/// Tests for Diary Entry Update Operations
///
/// Tests PATCH /api/fatsecret/diary/entries/:id
/// - Single field updates (number_of_units only)
/// - Multiple field updates (number_of_units + meal)
import gleeunit/should
import integration/helpers/http

pub fn patch_diary_entry_single_field_update_test() {
  // Test PATCH with only number_of_units field
  let body = "{\"number_of_units\": 2.5}"
  let result = http.patch("/api/fatsecret/diary/entries/123456", body)

  case result {
    Ok(#(status, _body)) -> should.equal(status, 200)
    Error(_) -> should.fail()
  }
}

pub fn patch_diary_entry_bulk_update_test() {
  // Test PATCH with multiple fields (number_of_units + meal)
  let body = "{\"number_of_units\": 3.0, \"meal\": \"dinner\"}"
  let result = http.patch("/api/fatsecret/diary/entries/789012", body)

  case result {
    Ok(#(status, _body)) -> should.equal(status, 200)
    Error(_) -> should.fail()
  }
}
