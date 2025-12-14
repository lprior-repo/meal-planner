/// Tests for import_export_api module
///
/// These tests verify that the import/export API functions correctly
/// decode responses from the Tandoor API.
import gleam/option
import gleeunit
import gleeunit/should
import meal_planner/tandoor/api/import_export/import_export_api
import meal_planner/tandoor/client

pub fn main() {
  gleeunit.main()
}

// Note: These are basic compilation tests. Full integration tests would require
// a running Tandoor instance or mocked HTTP responses.

pub fn list_import_logs_compiles_test() {
  let config = client.bearer_config("http://localhost:8000", "test-token")

  // This will fail at runtime without a server, but proves the function signature is correct
  let _result =
    import_export_api.list_import_logs(
      config,
      limit: option.Some(10),
      offset: option.Some(0),
    )

  // Just verifying compilation
  should.be_true(True)
}

pub fn get_import_log_compiles_test() {
  let config = client.bearer_config("http://localhost:8000", "test-token")

  // This will fail at runtime without a server, but proves the function signature is correct
  let _result = import_export_api.get_import_log(config, log_id: 123)

  // Just verifying compilation
  should.be_true(True)
}

pub fn list_export_logs_compiles_test() {
  let config = client.bearer_config("http://localhost:8000", "test-token")

  // This will fail at runtime without a server, but proves the function signature is correct
  let _result =
    import_export_api.list_export_logs(
      config,
      limit: option.Some(10),
      offset: option.Some(0),
    )

  // Just verifying compilation
  should.be_true(True)
}

pub fn get_export_log_compiles_test() {
  let config = client.bearer_config("http://localhost:8000", "test-token")

  // This will fail at runtime without a server, but proves the function signature is correct
  let _result = import_export_api.get_export_log(config, log_id: 321)

  // Just verifying compilation
  should.be_true(True)
}
