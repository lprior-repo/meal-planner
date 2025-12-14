/// Tests for Import/Export decoders
///
/// This test module verifies JSON decoding for ImportLog and ExportLog types.
import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/decoders/import_export/export_log_decoder
import meal_planner/tandoor/decoders/import_export/import_log_decoder

pub fn import_log_decode_complete_test() {
  // Arrange - JSON from Tandoor API with keyword
  let json_string =
    "{
      \"id\": 123,
      \"type\": \"nextcloud\",
      \"msg\": \"Import in progress\",
      \"running\": true,
      \"keyword\": {
        \"id\": 5,
        \"name\": \"italian\",
        \"label\": \"Italian\",
        \"description\": \"Italian recipes\",
        \"icon\": null,
        \"parent\": null,
        \"numchild\": 0,
        \"created_at\": \"2024-01-01T00:00:00Z\",
        \"updated_at\": \"2024-01-01T00:00:00Z\",
        \"full_name\": \"Italian\"
      },
      \"total_recipes\": 50,
      \"imported_recipes\": 25,
      \"created_by\": 1,
      \"created_at\": \"2024-12-14T12:00:00Z\"
    }"

  // Act
  let result = json.decode(json_string, import_log_decoder.import_log_decoder())

  // Assert
  case result {
    Ok(log) -> {
      log.id |> should.equal(123)
      log.import_type |> should.equal("nextcloud")
      case log.keyword {
        Some(kw) -> kw.id |> should.equal(5)
        None -> panic as "Expected keyword"
      }
    }
    Error(_) -> panic as "Decoding should succeed"
  }
}

pub fn export_log_decode_complete_test() {
  // Arrange
  let json_string =
    "{
      \"id\": 321,
      \"type\": \"zip\",
      \"msg\": \"Export in progress\",
      \"running\": true,
      \"total_recipes\": 100,
      \"exported_recipes\": 45,
      \"cache_duration\": 3600,
      \"possibly_not_expired\": true,
      \"created_by\": 3,
      \"created_at\": \"2024-12-14T13:00:00Z\"
    }"

  // Act
  let result = json.decode(json_string, export_log_decoder.export_log_decoder())

  // Assert
  case result {
    Ok(log) -> {
      log.id |> should.equal(321)
      log.export_type |> should.equal("zip")
      log.running |> should.equal(True)
    }
    Error(_) -> panic as "Decoding should succeed"
  }
}
